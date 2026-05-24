# ColabEdu Inference Services (`ce-open-llm`)

This repository manages the high-performance AI inference backends for ColabEdu, specifically tailored to support robust, multi-lingual language models for teacher grading workflows and educational interactions.

## Functional Specifications

The primary functionality of this repository is to expose private, OpenAI-compatible REST APIs hosted natively within our Google Cloud Run and MicroK8s infrastructure. 
It guarantees data privacy by keeping LLM computation internal (bypassing commercial 3rd party APIs) while providing low-latency, scalable "Time-To-First-Token" responses crucial for real-time educational assistance and high-throughput batch grading.

## Technical Specifications

The infrastructure leverages two distinct inference engines optimized for different neural network architectures and precision types on NVIDIA L4 (or newer) hardware:

1. **vLLM Pipeline (For AWQ / GPTQ / BF16 Safetensors)**
   * **Engine:** `vllm/vllm-openai`
   * **Default Target:** `Qwen/Qwen3.5-35B-A3B-Instruct-AWQ`
   * **Architecture:** Baked container. The `Dockerfile` establishes the runtime with Qwen's specific reasoning parsers and prefix-caching enabled.
   * **Scaling:** Utilizes Cloud Run CPU Boost and continuous batching (concurrency: 4) to handle parallel grading requests without OOMing the GPU.

2. **Llama.cpp FUSE Pipeline (For GGUF Quantized Models)**
   * **Engine:** `llama.cpp:server-cuda`
   * **Default Target:** `BSC-LT/ALIA-40b-instruct` / `Salamandra` (GGUF iterations)
   * **Architecture:** Volatile Mount. The pipeline does *not* bake the massive 20GB+ GGUF files into a Docker image. Instead, it natively mounts a Google Cloud Storage (GCS) bucket into the Cloud Run container via FUSE, slashing deployment times to seconds.

---

## 🛠️ Staging and Deploying Next Times

Depending on the format of the model you intend to deploy, select the appropriate workflow below.

### 1. Deploying Safetensor Models (e.g., Qwen AWQ)

If you are updating the base Qwen model or switching to a new AWQ/Safetensor format, you must trigger a container build because the base `vLLM` container needs to be recompiled or redeployed.

1. **Update Configurations:** Change `MODEL_NAME` in `ce-qwen-inference/deploy-local.sh` and/or `k8s/service-cloud.yaml`.
2. **Execute Deployment:**
   To build the container locally and push directly via `gcloud`:
   ```bash
   ./deploy-local.sh
   ```
   To use the automated Skaffold pipeline (ideal for CI/CD):
   ```bash
   skaffold run -p cloud-qwen35-ocr --default-repo <tu-repo-de-artifact-registry>
   ```

### 2. Deploying GGUF Models (e.g., ALIA / Salamandra)

The GGUF workflow uses **GCS FUSE**, meaning you never need to build or push Docker images to Artifact Registry when upgrading the model. You just upload the new weights to the cloud bucket!

**Step 1: Staging the Model (Run Once per new model)**
1. Open `setup-salamandra-gcs.sh` and update the `MODEL_FILENAME` to the exact name of the new `.gguf` file.
2. Execute the staging script. It will automatically download the HuggingFace weights and synchronize them to your Google Cloud Storage bucket (`gs://prevvy1-llm-models`).
   ```bash
   ./setup-salamandra-gcs.sh
   ```

**Step 2: Connecting the Inference Server**
1. Open `deploy-salamandra.sh` and ensure `MODEL_FILENAME` points to the new `.gguf` file staged in step 1.
2. Deploy the server. Cloud Run will dynamically pull the official `llama.cpp` container and mount the Cloud Storage bucket to `/mnt/models` inside the container.
   ```bash
   ./deploy-salamandra.sh
   ```
