# Changelog

## [0.9.8] - 2026-10-10

### Added
- **DeepSeek & Salamandra Model Deployment Profiles**:
  - `k8s/service-cloud-vllm-deepseek.yaml`: Knative Cloud Run profile for DeepSeek LLM evaluation backend.
  - `k8s/service-cloud-vllm-salamandra.yaml`: Knative Cloud Run profile for BSC Salamandra Spanish language foundation model.
  - Multipart download and upload orchestration scripts (`download_and_upload_deepseek.sh`, `download_part2_and_upload.sh`, `download_parts.sh`).
  - Automated visual testing verification scripts (`run_deepseek_visual_test.sh`, `run_salamandra_visual_test.sh`).

### Changed
- **Skaffold Multi-Profile Matrix**:
  - Updated `skaffold.yaml` and architecture documentation with unified profiles for DeepSeek and Salamandra inference engines.

## [0.9.2] - 2026-09-10

### Added
- **ALIA 40B Deployment Profiles**:
  - `local-alia-llamacpp`: High-throughput local MicroK8s deployment using llama.cpp with CUDA acceleration (`k8s/service-local-llamacpp-alia.yaml`).
  - `cloud-alia-vllm`: Production Cloud Run service using vLLM (`k8s/service-cloud-vllm-alia.yaml`).
  - `cloud-alia-runpod`: Serverless profile for cost-effective massive classroom batch evaluations (`deploy_runpod_alia.sh`).
- **Qwen 3 MoE (Mixture of Experts) Architecture**:
  - `cloud-qwen3-vllm`: Knative / Cloud Run profile for `Qwen3-30B-A3B-Instruct-AWQ` with 32k context window and fragmented safetensors (`k8s/service-cloud-vllm-qwen3.yaml`).
  - `local-qwen3-llamacpp`: MicroK8s local NVMe deployment for GGUF MoE with audio & vision multimodal projector (`--mmproj`, `k8s/service-local-llamacpp-qwen3.yaml`).
- **Skaffold & Knative Matrix Alignment**:
  - Multi-profile definitions in `skaffold.yaml` for unified developer and production operations.
  - Calibrated context length and memory settings in `vllm/deploy-vllm.sh`.

## [0.1.0] - 2026-05-24

### Added
- Initial release of the ColabEdu Open LLM Inference module (`ce-open-llm`).
- Setup scripts and configuration files for model deployment (Llama/Salamandra/Qwen).
- Kubernetes manifests and Skaffold configuration for local and cloud deployment.
- Dockerfiles optimized for CPU/GPU inference.
