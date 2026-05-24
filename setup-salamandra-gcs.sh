#!/bin/bash
set -e

PROJECT_ID="prevvy1"
REGION="us-central1"
BUCKET_NAME="${PROJECT_ID}-llm-models"
MODEL_FILENAME="salamandraTA-7B-instruct-Q4_K_M.gguf"
MODEL_URL="https://huggingface.co/BSC-LT/salamandraTA-7B-instruct-GGUF/resolve/main/${MODEL_FILENAME}"

echo "🚀 Iniciando configuración de Google Cloud Storage (GCS) para modelos GGUF..."

# 1. Crear el bucket de almacenamiento si no existe
if ! gcloud storage ls "gs://${BUCKET_NAME}" > /dev/null 2>&1; then
    echo "🪣 Creando bucket gs://${BUCKET_NAME} en ${REGION}..."
    gcloud storage buckets create "gs://${BUCKET_NAME}" --location="${REGION}" --project="${PROJECT_ID}"
else
    echo "✅ El bucket gs://${BUCKET_NAME} ya existe."
fi

# 2. Comprobar si el modelo ya está en el bucket
if gcloud storage ls "gs://${BUCKET_NAME}/${MODEL_FILENAME}" > /dev/null 2>&1; then
    echo "✅ El modelo ${MODEL_FILENAME} ya se encuentra alojado en el bucket."
else
    echo "⬇️ Descargando el modelo GGUF localmente (Esto tomará tiempo una sola vez)..."
    if [ ! -f "${MODEL_FILENAME}" ]; then
        wget -q --show-progress -O "${MODEL_FILENAME}" "${MODEL_URL}"
    fi

    echo "☁️ Subiendo el modelo al bucket en GCS..."
    gcloud storage cp "${MODEL_FILENAME}" "gs://${BUCKET_NAME}/${MODEL_FILENAME}"
    
    echo "🧹 Limpiando archivo local temporal para liberar espacio..."
    rm "${MODEL_FILENAME}"
    
    echo "✅ Modelo sincronizado exitosamente a gs://${BUCKET_NAME}/${MODEL_FILENAME}"
fi

echo "🎉 Fase de Staging de Modelos completada."
echo "👉 Ahora puedes proceder a ejecutar: ./deploy-salamandra.sh"
