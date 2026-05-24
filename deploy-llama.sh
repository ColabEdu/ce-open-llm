#!/bin/bash
set -e

PROJECT_ID="prevvy1"
REGION="us-central1"
SERVICE_NAME="ce-llm-inference"
BUCKET_NAME="${PROJECT_ID}-llm-models"

# Allows overriding the model. Example: ./deploy-llama.sh salamandraTA-7B-instruct-Q4_K_M.gguf
MODEL_FILENAME="${1:-Qwen_Qwen3.6-27B-Q4_K_M.gguf}"

# Utilizamos directamente la imagen oficial acelerada por CUDA.
# Cloud Run usará GCS FUSE para "montar" mágicamente el bucket en el contenedor.
IMAGE_TAG="us-central1-docker.pkg.dev/prevvy1/inference-services/llama.cpp:server-l4-cuda12.6-latest"

echo "☁️ Desplegando servidor Llama.cpp en Cloud Run (vía conectores GCS FUSE)..."
echo "Modelo apuntado: gs://${BUCKET_NAME}/${MODEL_FILENAME}"

# Argumentos vitales para eficiencia de memoria en la GPU L4 (24GB)
LLAMA_ARGS="-m,/mnt/models/${MODEL_FILENAME},--host,0.0.0.0,--port,8080,-c,8192,-ngl,999,-fit,off,--parallel,1,--flash-attn,on,--threads,8,--cache-type-k,q4_0,--cache-type-v,q4_0,--no-mmap"

if [[ "$MODEL_FILENAME" == *"Qwen"* ]]; then
  echo "👁️  Modelo Qwen detectado. Añadiendo proyector multimodal (--mmproj)..."
  LLAMA_ARGS="${LLAMA_ARGS},--mmproj,/mnt/models/mmproj-Qwen_Qwen3.6-27B-f16.gguf"
fi

gcloud run deploy $SERVICE_NAME \
  --image "$IMAGE_TAG" \
  --region $REGION \
  --project $PROJECT_ID \
  --execution-environment gen2 \
  --gpu 1 \
  --gpu-type nvidia-l4 \
  --cpu 8 \
  --memory 32Gi \
  --timeout 600 \
  --no-cpu-throttling \
  --cpu-boost \
  --concurrency 4 \
  --max-instances 1 \
  --no-gpu-zonal-redundancy \
  --port 8080 \
  --no-allow-unauthenticated \
  --service-account="ce-llm-runner@${PROJECT_ID}.iam.gserviceaccount.com" \
  --add-volume="name=model-volume,type=cloud-storage,bucket=${BUCKET_NAME}" \
  --add-volume-mount="volume=model-volume,mount-path=/mnt/models" \
  --args="${LLAMA_ARGS}"

echo "🎉 ¡Completado! El servidor GGUF (OpenAI-compatible) ya está en línea (Privado) y lee en tiempo real desde Cloud Storage."
