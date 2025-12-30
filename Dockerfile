FROM nvidia/cuda:13.1.0-devel-ubuntu22.04 as base

# Global env
ENV CMAKE_POLICY_VERSION_MINIMUM=3.5 \
    DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH="/src/mlc-llm/python:$PYTHONPATH"

# System dependencies
RUN apt-get update && apt-get install -y \
    git git-lfs build-essential \
    ca-certificates gpg curl wget lsb-release \
    python3-dev python3-pip python-is-python3 \
    llvm-15 llvm-15-dev && \
    rm -rf /var/lib/apt/lists/*

# CMake
RUN wget -qO- https://apt.kitware.com/keys/kitware-archive-latest.asc \
   | gpg --dearmor \
   | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] \
    https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/kitware.list && \
    apt-get update && \
    apt-get install -y cmake && \
    rm -rf /var/lib/apt/lists/* && \
    cmake --version

# Rust (required for tokenizer builds)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Python dependencies
RUN pip install --upgrade pip wheel setuptools \
    && pip install \
        pytest \
        tqdm \
        requests \
        fastapi \
        shortuuid \
        prompt_toolkit \
        pydantic

# Clone repository with submodules
WORKDIR /src
RUN git clone --recursive https://github.com/mlc-ai/mlc-llm.git

# Build TVM / MLC-LLM (expensive layer)
# =========================================================
WORKDIR /src/mlc-llm

ARG USE_CUDA=ON
ARG USE_VULKAN=OFF
ARG USE_OPENCL=ON
ARG USE_LLVM="llvm-config-15 --ignore-libllvm --link-static"

RUN pip install --pre -U -f https://mlc.ai/wheels mlc-ai-nightly-cpu

RUN mkdir build && cd build && \
    echo "set(USE_CUDA ${USE_CUDA})" >> config.cmake && \
    echo "set(USE_VULKAN ${USE_VULKAN})" >> config.cmake && \
    echo "set(USE_OPENCL ${USE_OPENCL})" >> config.cmake && \
    echo "set(USE_LLVM \"${USE_LLVM}\")" >> config.cmake && \
    echo "set(CMAKE_BUILD_TYPE RelWithDebInfo)" >> config.cmake && \
    echo "set(HIDE_PRIVATE_SYMBOLS ON)" >> config.cmake && \
    cmake .. && \
    cmake --build . --parallel $(nproc)

# Runtime validation (fast sanity checks)
RUN python -c "import tvm; print('tvm installed properly')" && \
    python -c "import mlc_llm; print('mlc_llm installed properly')"

# Test assets
COPY test* /tests/

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]

CMD ["bash"]
