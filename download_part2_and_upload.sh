#!/bin/bash
set -e

DIR="/home/jmolmo/git/colabedu/ce-open-llm/models/DeepSeek-V4-Distill-14B-AWQ"
cd "${DIR}"

echo "Resuming download of model-00002-of-00002.safetensors..."
wget -c "https://huggingface.co/casperhansen/deepseek-r1-distill-qwen-14b-awq/resolve/main/model-00002-of-00002.safetensors"

echo "Uploading part 2 to GCS..."
gcloud storage cp model-00002-of-00002.safetensors gs://prevvy1-llm-models/DeepSeek-V4-Distill-14B-AWQ/

echo "COMPLETED_ALL"
