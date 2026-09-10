# ColabEdu Inference Services (`ce-open-llm`)

This repository manages the high-performance AI inference backends for ColabEdu, specifically tailored to support robust, multi-lingual language models for teacher grading workflows and educational interactions.

## Functional Specifications

The primary functionality of this repository is to expose private, OpenAI-compatible REST APIs hosted natively within our Google Cloud Run and MicroK8s infrastructure. 
It guarantees data privacy by keeping LLM computation internal (bypassing commercial 3rd party APIs) while providing low-latency, scalable "Time-To-First-Token" responses crucial for real-time educational assistance and high-throughput batch grading.

## Technical Specifications

The infrastructure leverages distinct inference engines optimized for different neural network architectures, precision types, and cloud environments:

1. **RunPod Serverless vLLM Pipeline (For ALIA 40B High Concurrency)**
   * **Engine:** `runpod/vllm:v0.4.2` (or newer)
   * **Target Model (ALIA 40B):** `ALIA-40b-instruct` (via profile `cloud-alia-runpod`)
   * **Architecture:** RunPod Serverless Endpoint on RTX 5090 / A100. Designed as the default, most cost-effective solution for massive concurrent grading. Uses a very low `idle_timeout` to ensure we only pay per second of active inference, while *PagedAttention* in vLLM handles dozens of concurrent evaluations seamlessly without OOM errors.

2. **GCP vLLM Pipeline (For AWQ / GPTQ / BF16 Safetensors)**
   * **Engine:** `vllm/vllm-openai:latest`
   * **Target Model (Qwen 3 MoE):** `Qwen/Qwen3-30B-A3B-Instruct-AWQ` (via profile `cloud-qwen3-vllm`)
   * **Architecture:** Baked/Optimized container deployment on Cloud Run. Ideal for high-throughput production grading with *Continuous Batching* when using GCP credits.

3. **Llama.cpp FUSE Pipeline (For GGUF Quantized Models)**
   * **Engine:** `ghcr.io/ggerganov/llama.cpp:server-cuda`
   * **Target Models:** 
     * `ALIA-40b-instruct-Q4_K_M.gguf` (via profile `local-alia-llamacpp`) for local/sequential evaluations with ultra-low latency.
     * `Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf` with `--mmproj mmproj-F16.gguf` for vision/audio support (via profile `local-qwen3-llamacpp`).
     * Default legacy target: `qwen2.5-0.5b-instruct` (via profile `local-open-llm`).
   * **Architecture:** Volatile/Local Mount. Weights reside on fast local NVMe storage or Cloud Storage FUSE and are mounted into the container at `/mnt/models`.

---

## 🛠️ Staging and Deploying Next Times

Depending on the format and model generation you intend to deploy, select the appropriate workflow below.

### 1. Deploying ALIA 40B (Default for Pedagogical Evaluation)

* **RunPod Serverless Deployment (Cost-Effective / High Concurrency):**
  Uses the vLLM container on RunPod to evaluate entire classrooms simultaneously with minimal cost. Requires the `deploy_runpod_alia.sh` script to configure the GraphQL endpoint.
  ```bash
  skaffold run -p cloud-alia-runpod
  ```
  *(Or via the CLI: `./ce-devops/colabedu.sh up prod-hybrid --with-alia --with-runpod`)*

* **Local Development Deployment (llama.cpp GGUF):**
  Uses llama.cpp with CUDA in MicroK8s for ultra-fast, single-user latency.
  ```bash
  skaffold run -p local-alia-llamacpp
  ```
  *(Or via the CLI: `./ce-devops/colabedu.sh up dev --with-local-workers --with-alia`)*

### 2. Deploying Qwen 3 (MoE with Multimodal)

* **Production Cloud Deployment (vLLM AWQ):**
  Uses vLLM on Knative/Cloud Run.
  ```bash
  skaffold run -p cloud-qwen3-vllm
  ```

* **Local Development Deployment (llama.cpp GGUF with Multimodal):**
  Loads Qwen 3 MoE GGUF along with its vision/audio projector:
  ```bash
  skaffold run -p local-qwen3-llamacpp
  ```

### 3. Deploying Legacy Qwen 2.5 / Salamandra (GGUF via GCS FUSE)

The GGUF workflow for Cloud Run uses **GCS FUSE**. You just upload the new weights to the cloud bucket!

**Step 1: Staging the Model (Run Once per new model)**
1. Open `setup-salamandra-gcs.sh` and update the `MODEL_FILENAME`.
2. Execute the staging script to upload to `gs://prevvy1-llm-models`.
   ```bash
   ./setup-salamandra-gcs.sh
   ```

**Step 2: Connecting the Inference Server**
1. Open `deploy-salamandra.sh` and ensure `MODEL_FILENAME` points to the staged file.
2. Deploy the server.
   ```bash
   ./deploy-salamandra.sh
   ```
