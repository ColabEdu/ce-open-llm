#!/bin/bash
set -e

PROJECT_ID="prevvy1"
REGION="us-central1"
SERVICE_NAME="ce-llm-inference" # Reusing the same service name so the backend doesn't need to change URLs
BUCKET_NAME="${PROJECT_ID}-llm-models"
IMAGE_NAME="vllm"
IMAGE_TAG="us-central1-docker.pkg.dev/${PROJECT_ID}/inference-services/${IMAGE_NAME}:latest"

# 1. Parse model size parameter (default to 14b)
MODEL_SIZE="14b"
if [ "$1" == "32b" ]; then
  MODEL_SIZE="32b"
fi

if [ "$MODEL_SIZE" == "32b" ]; then
  MODEL_DIR_NAME="Qwen2.5-32B-Instruct-AWQ"
  MAX_MODEL_LEN=3072
  GPU_MEM_UTIL=0.96
  CPU_CORES=8
  MEMORY_LIMIT="32Gi"
  echo "🚀 Configurando despliegue para Qwen 2.5 32B AWQ (L4 GPU)..."
else
  MODEL_DIR_NAME="Qwen2.5-14B-Instruct-AWQ"
  MAX_MODEL_LEN=8192
  GPU_MEM_UTIL=0.95
  CPU_CORES=8
  MEMORY_LIMIT="32Gi"
  echo "🚀 Configurando despliegue para Qwen 2.5 14B AWQ (L4 GPU)..."
fi

echo "☁️ Usando imagen de vLLM previamente compilada..."
# gcloud builds submit --tag "$IMAGE_TAG" .

echo "☁️ Desplegando servidor vLLM en Cloud Run (vía conectores GCS FUSE)..."
echo "Modelo apuntado: gs://${BUCKET_NAME}/${MODEL_DIR_NAME}"
# Argumentos vitales para vLLM en GPU L4 (24GB) con AWQ
# GCS FUSE and safetensors mmap don't play well together (causes freezing), so we copy to /tmp first
ENTRYPOINT_CMD="cp -r /mnt/models/${MODEL_DIR_NAME} /tmp/model && exec python3 -m vllm.entrypoints.openai.api_server --model /tmp/model --quantization awq --max-model-len ${MAX_MODEL_LEN} --gpu-memory-utilization ${GPU_MEM_UTIL} --enforce-eager --disable-frontend-multiprocessing"

gcloud run deploy $SERVICE_NAME \
  --image "$IMAGE_TAG" \
  --region $REGION \
  --project $PROJECT_ID \
  --execution-environment gen2 \
  --gpu 1 \
  --gpu-type nvidia-l4 \
  --cpu $CPU_CORES \
  --memory $MEMORY_LIMIT \
  --timeout 600 \
  --no-cpu-throttling \
  --cpu-boost \
  --concurrency 10 \
  --max-instances 1 \
  --no-gpu-zonal-redundancy \
  --port 8000 \
  --startup-probe="tcpSocket.port=8000,initialDelaySeconds=240,timeoutSeconds=240,periodSeconds=240,failureThreshold=4" \
  --no-allow-unauthenticated \
  --service-account="ce-llm-runner@${PROJECT_ID}.iam.gserviceaccount.com" \
  --add-volume="name=model-volume,type=cloud-storage,bucket=${BUCKET_NAME}" \
  --add-volume-mount="volume=model-volume,mount-path=/mnt/models" \
  --command="bash" \
  --args="-c,${ENTRYPOINT_CMD}"

echo "🎉 ¡Completado! El servidor vLLM (OpenAI-compatible) ya está en línea (Privado) y lee en tiempo real desde Cloud Storage."
echo "IMPORTANTE: Asegúrate de que la carpeta gs://${BUCKET_NAME}/${MODEL_DIR_NAME} existe y contiene los archivos del modelo (config.json, safetensors, etc)."
