#!/bin/bash

# Create a local models directory
mkdir -p /home/jmolmo/git/colabedu/ce-open-llm/models
cd /home/jmolmo/git/colabedu/ce-open-llm/models

echo "Downloading Salamandra 7B..."
wget -c https://huggingface.co/BSC-LT/salamandraTA-7B-instruct-GGUF/resolve/main/salamandraTA-7B-instruct-Q4_K_M.gguf

echo "Downloading Qwen 3.6 27B..."
wget -c https://huggingface.co/bartowski/Qwen_Qwen3.6-27B-GGUF/resolve/main/Qwen_Qwen3.6-27B-Q4_K_M.gguf
wget -c https://huggingface.co/bartowski/Qwen_Qwen3.6-27B-GGUF/resolve/main/mmproj-Qwen_Qwen3.6-27B-f16.gguf

echo "Uploading to GCS..."
gcloud storage cp *.gguf gs://prevvy1-llm-models/

echo "Done!"
