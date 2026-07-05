#!/bin/bash
set -e

# Este script descarga el modelo Qwen2.5-14B-Instruct-AWQ desde HuggingFace
# y lo sube directamente a tu bucket de Google Cloud Storage.

BUCKET_NAME="prevvy1-llm-models"
MODEL_REPO="Qwen/Qwen2.5-14B-Instruct-AWQ"
MODEL_DIR_NAME="Qwen2.5-14B-Instruct-AWQ"

echo "📦 Preparando descarga de $MODEL_REPO a gs://${BUCKET_NAME}/${MODEL_DIR_NAME}..."

# Verificamos si huggingface-cli está instalado
# Verificamos si huggingface_hub está instalado
if ! python3 -c "import huggingface_hub" &> /dev/null
then
    echo "huggingface_hub no encontrado. Instalando..."
    pip install -U "huggingface_hub[cli]" --break-system-packages
fi

# Descargamos el modelo localmente a una carpeta temporal
TMP_DIR="/tmp/$MODEL_DIR_NAME"
echo "⬇️ Descargando modelo a $TMP_DIR (esto puede tardar unos minutos)..."
python3 -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id='$MODEL_REPO', local_dir='$TMP_DIR', local_dir_use_symlinks=False)"

echo "☁️ Subiendo modelo a Google Cloud Storage..."
gcloud storage cp -r $TMP_DIR "gs://${BUCKET_NAME}/"

echo "🧹 Limpiando archivos temporales..."
rm -rf $TMP_DIR

echo "✅ ¡Modelo subido con éxito! Ahora puedes ejecutar ./deploy-vllm.sh"
