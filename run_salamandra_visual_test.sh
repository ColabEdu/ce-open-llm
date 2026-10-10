#!/bin/bash
# ==============================================================================
# ColabEdu BSC ALIA (Salamandra 7B) Cloud Run Lifecycle & Visual Audit Runner
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

REGION="${GCP_REGION:-us-central1}"
SERVICE_NAME="ce-salamandra-inference"
PROJECT_ID="${GCP_PROJECT_ID:-prevvy1}"

BOLD="\033[1m"
GREEN="\033[32m"
BLUE="\033[34m"
YELLOW="\033[33m"
CYAN="\033[36m"
RED="\033[31m"
RESET="\033[0m"

shutdown_cloudrun() {
    echo -e "\n${BOLD}${YELLOW}🛑 Eliminando el servicio Cloud Run (${SERVICE_NAME}) para garantizar coste \$0.00...${RESET}"
    gcloud run services delete "${SERVICE_NAME}" \
        --project="${PROJECT_ID}" \
        --region="${REGION}" \
        --quiet || true
    echo -e "${BOLD}${GREEN}✅ Servicio Cloud Run eliminado (Coste = \$0.00).${RESET}"
}

trap shutdown_cloudrun EXIT

echo -e "${BOLD}${BLUE}=================================================================${RESET}"
echo -e "${BOLD}${BLUE} 🚀 COLABEDU: ALIA (SALAMANDRA 7B) CLOUD RUN & AUDITORÍA VISUAL   ${RESET}"
echo -e "${BOLD}${BLUE}=================================================================${RESET}"
echo -e "• Proyecto GCP: ${BOLD}${PROJECT_ID}${RESET}"
echo -e "• Región: ${BOLD}${REGION}${RESET}"
echo -e "• Servicio: ${BOLD}${SERVICE_NAME}${RESET}"
echo -e "• Hardware: ${BOLD}NVIDIA L4 (24GB VRAM) con vLLM + BSC Salamandra 7B${RESET}\n"

echo -e "${CYAN}▶ Paso 1: Desplegando Salamandra 7B en Cloud Run (${SERVICE_NAME})...${RESET}"
gcloud run services replace "${SCRIPT_DIR}/k8s/service-cloud-vllm-salamandra.yaml" \
    --project="${PROJECT_ID}" \
    --region="${REGION}"

echo -e "\n${CYAN}▶ Paso 2: Obteniendo URL y credenciales del servicio...${RESET}"
SERVICE_URL=$(gcloud run services describe "${SERVICE_NAME}" \
    --project="${PROJECT_ID}" \
    --region="${REGION}" \
    --format="value(status.url)")

if [ -z "${SERVICE_URL}" ]; then
    echo -e "${RED}❌ Error: No se pudo obtener la URL de ${SERVICE_NAME}.${RESET}"
    exit 1
fi
echo -e "   • URL Asignada: ${BOLD}${SERVICE_URL}${RESET}"

echo -e "${CYAN}▶ Generando Identity Token para autenticación en Cloud Run...${RESET}"
ID_TOKEN=$(gcloud auth print-identity-token)

export OPENAI_BASE_URL="${SERVICE_URL}/v1"
export OPENAI_API_KEY="${ID_TOKEN}"
export OPENAI_MODEL_NAME="/mnt/models/salamandra-7b-instruct"

export COLABEDU_LLM_MODEL="${OPENAI_MODEL_NAME}"
export COLABEDU_BACKEND_VERSION="$(git rev-parse --short HEAD 2>/dev/null || echo 'v0.9.6')"
export COLABEDU_INFERENCE_HARDWARE="Google Cloud Run (NVIDIA L4 24GB)"
export COLABEDU_TEST_TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
export COLABEDU_BENCHMARK_TAG="alia-salamandra-7b"

echo -e "${GREEN}✅ Endpoint vLLM y Metadatos configurados para ColabEdu:${RESET}"
echo -e "   • OPENAI_BASE_URL=${OPENAI_BASE_URL}"
echo -e "   • OPENAI_MODEL_NAME=${OPENAI_MODEL_NAME}"
echo -e "   • COLABEDU_BACKEND_VERSION=${COLABEDU_BACKEND_VERSION}"
echo -e "   • COLABEDU_INFERENCE_HARDWARE=${COLABEDU_INFERENCE_HARDWARE}"
echo -e "   • COLABEDU_TEST_TIMESTAMP=${COLABEDU_TEST_TIMESTAMP}"

echo -e "\n${CYAN}▶ Paso 3: Ejecutando Suite de Pruebas Grading V2 con Auditoría Visual...${RESET}"
"${WORKSPACE_ROOT}/ce-cli.sh" test grading --visual

echo -e "\n${CYAN}▶ Paso 4: Ejecutando Auditoría Visual Completa (160 Snapshots)...${RESET}"
"${WORKSPACE_ROOT}/ce-cli.sh" audit visual

echo -e "\n${BOLD}${GREEN}🎉 ¡Pruebas globales y auditoría visual completadas con éxito con ALIA Salamandra 7B!${RESET}"
