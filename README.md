# MLC-LLM Build, Test, and Release Documentation

This document describes prerequisites, dependencies, local development workflows, CI/CD pipelines, and release processes for the MLC-LLM codebase. It is designed for contributors, release engineers, and infrastructure maintainers.

---

## Overview

The build and release system is designed around the following principles:

- Single source of truth for build environments (Docker)
- Test-driven deployment (tests gate all downstream stages)
- Cross-platform artifact generation (Linux + Windows)
- Reproducibility across local development and CI

Artifacts produced:

- Docker image published to GitHub Container Registry (GHCR)
- Python wheels published to GitHub Releases

The goal is to make MLC LLM easy to build, test, and deploy in automated environments.

---

## Architecture

```
    A[Source Code] --> B[Docker Build]
    B --> C[Container Tests]
    C --> D[Publish Image]
```

---

## Prerequisites

### Required

- Docker >= 20.10
- Git

### Optional (GPU Support)

- NVIDIA Container Toolkit
- Compatible GPU drivers

---

## Dependencies

The Docker image includes:

- Python 3
- mlc-llm
- TVM runtime
- System build tools
- Test dependencies

All dependencies are installed during the Docker build.

---

## Repository Structure

```
.
├── Dockerfile
├── entrypoint.sh
├── test_mlc_llm_tvm.py
├── testing_script.py
├── .github/
│   └── workflows/
│       └── main.yml
└── README.md
```

---

## Building the Docker Image

Clone the repository:

```bash
git clone https://github.com/sfoxdev/mlc-llm-docker.git
cd mlc-llm-docker
```

Build the image:

```bash
docker build -t mlc-llm-docker:latest .
```

---

## Running the Container

Basic run:

```bash
docker run --rm -it mlc-llm-docker:latest
```

Run with GPU access:

```bash
docker run --rm -it --gpus all mlc-llm-docker:latest
```

Mount local models:

```bash
docker run --rm -it \
  -v $(pwd):/workspace \
  mlc-llm-docker:latest
```

Build a Wheel Locally

```bash
docker run --rm mlc-llm-dev build
```

---

## Testing

Tests are designed to be:

- Fast
- Deterministic
- Environment-agnostic

Test categories:

- Import validation
- TVM integration sanity checks
- Registry and config tests

## Test Execution

```bash
docker run --rm -it mlc-llm-docker:latest \
  pytest /tests
```

Tests run:

- Inside Docker (Linux)
- On native Windows runners (CI)

Failures block all downstream pipeline stages.

You can also run include test script:

```bash
docker run --rm -it mlc-llm-docker:latest \
  python test_mlc_llm_tvm.py
```

This validates that the MLC LLM runtime initializes correctly.

---

## GitHub Actions Workflows

Workflows are located in `.github/workflows/`.

---

### main.yml

**Triggers**
- push to `main`
- pull requests
- Git tag push (`v*.*.*`)

**Jobs**
- Checkout repository
- Build tagged image
- Push image to registry

---

## Notes

- GPU acceleration requires correct host drivers.
- Use `--shm-size` for large models if needed.
- Image can be extended to bundle specific models.

---

## DRY Principles Applied

Area	        |   Technique
Build env	    |   Single Docker image
Dependencies	|   Centralized in Dockerfile
Test logic	  |   Same pytest command
CI structure	|   Reused jobs and artifacts

---

## Best Practices Summary

- Immutable build environments
- Tests before artifacts
- Minimal CI host dependencies
- Clear separation of concerns
- Explicit versioned releases

---

## Appendix: Quick Reference

Common Commands

```bash
# Dev shell
docker run -it -v $(pwd):/workspace mlc-llm-docker

# Run tests
docker run mlc-llm-docker pytest /tests

# Build wheel
docker run --name builder-container mlc-llm-docker build
docker cp builder-container:/src/mlc-llm/python/dist ./dist
docker rm builder-container

```

---

## License

This project follows the same license terms as MLC LLM unless stated otherwise.
