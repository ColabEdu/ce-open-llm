#!/bin/bash
set -euo pipefail

LOCAL_DIR="/home/jmolmo/git/colabedu/ce-open-llm/models/DeepSeek-V4-Distill-14B-AWQ"
mkdir -p "${LOCAL_DIR}"

echo "================================================================="
echo " 📥 1. Descargando DeepSeek 14B AWQ desde Hugging Face..."
echo "================================================================="
python3 -c "
from huggingface_hub import snapshot_download
local_dir = '${LOCAL_DIR}'
print('Descargando pesos a:', local_dir)
snapshot_download(
    repo_id='casperhansen/deepseek-r1-distill-qwen-14b-awq',
    local_dir=local_dir,
    local_dir_use_symlinks=False,
    ignore_patterns=['*.msgpack', '*.h5', '*.ot']
)
print('✅ Descarga local finalizada.')
"

echo "================================================================="
echo " ☁️ 2. Subiendo pesos a gs://prevvy1-llm-models/DeepSeek-V4-Distill-14B-AWQ/..."
echo "================================================================="
gcloud storage cp -r "${LOCAL_DIR}/*" gs://prevvy1-llm-models/DeepSeek-V4-Distill-14B-AWQ/

echo "================================================================="
echo " 🎉 ¡Pesos subidos con éxito a Cloud Storage!"
echo "================================================================="
