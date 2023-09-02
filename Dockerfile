FROM debian:latest

RUN apt-get update && apt-get install -y \
  curl \
  musl-dev \
  musl-tools \
  make \
  xutils-dev \
  automake \
  autoconf \
  libtool \
  g++ \
  gcc-aarch64-linux-gnu

RUN apt-get install ca-certificates
# Install rust using rustup
RUN curl -k "https://static.rust-lang.org/rustup/dist/x86_64-unknown-linux-gnu/rustup-init" -o rustup-init && \
    chmod +x rustup-init && \
    ./rustup-init -y --profile minimal && \
    rm rustup-init

ENV PATH=/usr/local/bin:/root/.cargo/bin:$PATH \
    PKG_CONFIG_PATH=/usr/local/lib/pkgconfig \
    LD_LIBRARY_PATH=$PREFIX
RUN rustup target add aarch64-unknown-linux-musl
RUN cargo install cargo-deb 

# This musl section copied from rust-embedded/cross, see musl.sh for license
COPY musl.sh /
RUN /musl.sh \
    TARGET=aarch64-linux-musl

RUN echo "[build]\ntarget = \"aarch64-unknown-linux-musl\"" > ~/.cargo/config
RUN echo "[target.aarch64-unknown-linux-musl]\nlinker = \"aarch64-linux-musl-gcc\"\nstrip = { path = \"aarch64-linux-musl-strip\" }" > ~/.cargo/config
WORKDIR /volume
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

