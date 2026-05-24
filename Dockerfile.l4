FROM nvidia/cuda:12.6.2-devel-ubuntu22.04 AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    cmake \
    curl \
    libcurl4-openssl-dev \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Clone llama.cpp
RUN git clone https://github.com/ggerganov/llama.cpp.git /app
WORKDIR /app

# Expose CUDA stubs to the linker
ENV LIBRARY_PATH=/usr/local/cuda/lib64/stubs:$LIBRARY_PATH
RUN ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/lib/x86_64-linux-gnu/libcuda.so.1

# Build llama.cpp for CUDA 12.x and Architecture 89 (Nvidia L4)
RUN cmake -B build \
    -DGGML_CUDA=ON \
    -DCMAKE_CUDA_ARCHITECTURES="89" \
    -DGGML_NATIVE=OFF \
    -DLLAMA_CURL=ON \
    -DBUILD_SHARED_LIBS=OFF

RUN cmake --build build --config Release -j$(nproc) --target llama-server

# Create runtime image
FROM nvidia/cuda:12.2.2-runtime-ubuntu22.04

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libcurl4 \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Copy the server binary
COPY --from=builder /app/build/bin/llama-server /usr/local/bin/llama-server

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/llama-server"]
