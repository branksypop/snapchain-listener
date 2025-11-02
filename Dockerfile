# ---------- build stage ----------
FROM rust:bookworm AS builder
WORKDIR /app
# Cache deps first for faster rebuilds
COPY Cargo.toml Cargo.lock ./
# if you have a workspace or build.rs/proto, copy those too:
COPY build.rs ./
COPY proto ./proto
RUN mkdir src && echo "fn main(){}" > src/main.rs
RUN cargo build --release || true
# now copy the real sources
COPY . .
RUN cargo build --release

# ---------- runtime stage ----------
FROM debian:bookworm-slim AS runner
# Minimal CA certs so the node can speak TLS to peers if needed
#RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app

# ---- security: run as non-root
#RUN useradd -u 10001 -r -s /sbin/nologin appuser
#USER 10001:10001

# Copy the release binary from the builder
# (the cargo package/binary is named "snapchain-listener")
COPY --from=builder /app/target/release/snapchain-listener /app/snapchain-listener

# ---- defaults per README (can be overridden at deploy time)
ENV WS_PORT=8080 \
#    RUST_LOG=info
# DON'T bake BEARER_TOKEN into the image; set it as a Koyeb secret

EXPOSE 8080
ENTRYPOINT ["/app/snapchain-listener"]
