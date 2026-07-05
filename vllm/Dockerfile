FROM vllm/vllm-openai:v0.7.3

# Set environment variables for better GPU utilization in Cloud Run
ENV VLLM_PORT=8000
ENV HOST=0.0.0.0
ENV PYTHONUNBUFFERED=1

# Expose the port
EXPOSE 8000

# The base image already has the correct entrypoint: `python3 -m vllm.entrypoints.openai.api_server`
# We will pass the model arguments at runtime via Cloud Run.
