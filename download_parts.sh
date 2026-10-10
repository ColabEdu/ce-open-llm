#!/bin/bash
set -e

DIR="/home/jmolmo/git/colabedu/ce-open-llm/models/DeepSeek-V4-Distill-14B-AWQ"
cd "${DIR}"

echo "Starting download of model-00001-of-00002.safetensors..."
wget -c "https://huggingface.co/casperhansen/deepseek-r1-distill-qwen-14b-awq/resolve/main/model-00001-of-00002.safetensors"

echo "Starting download of model-00002-of-00002.safetensors..."
wget -c "https://huggingface.co/casperhansen/deepseek-r1-distill-qwen-14b-awq/resolve/main/model-00002-of-00002.safetensors"

echo "Upload to GCS..."
gcloud storage cp -r "${DIR}/*" gs://prevvy1-llm-models/DeepSeek-V4-Distill-14B-AWQ/

echo "ALL_DONE"
