# Use vLLM for high-throughput OpenAI-compatible serving
FROM vllm/vllm-openai:latest

# Environment variables for Qwen 2.5 optimization
ENV MODEL_NAME="Qwen/Qwen2.5-7B-Instruct"
ENV PORT=8080

# Optimization Directives for NVIDIA L4 (Ada Lovelace Architecture):
# 1. --dtype bfloat16: Native L4 support for high-speed computation.
# 2. --gpu-memory-utilization 0.90: Maximize VRAM while leaving overhead.
# 3. --max-model-len 8192: Optimal context window for pedagogical prompts.

ENTRYPOINT ["python3", "-m", "vllm.entrypoints.openai.api_server", \
            "--model", "Qwen/Qwen2.5-7B-Instruct", \
            "--dtype", "bfloat16", \
            "--max-model-len", "8192", \
            "--gpu-memory-utilization", "0.90", \
            "--port", "8080"]
