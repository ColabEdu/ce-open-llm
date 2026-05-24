# Arquitectura de Despliegue Híbrida (Local + Nube)

Este repositorio contiene la infraestructura y configuración para el despliegue del motor de inferencia Open Source (llama.cpp) utilizado en ColabEdu.

La arquitectura está diseñada para maximizar el throughput y minimizar costos utilizando un modelo "Edge Processing" (Home Lab) con un Fallback automático en la nube.

## 1. Topología del Sistema

El ecosistema está compuesto por tres capas principales de procesamiento:

1. **LLM Local (MicroK8s):** Desplegado en servidores locales (ej. RTX 3090, 24GB VRAM) mediante Knative. Atiende el 90-95% de las peticiones diarias de los profesores Freemium y Tier 1 a costo marginal cero.
2. **LLM Cloud Run (Google Cloud):** El mismo contenedor desplegado en GPUs L4 serverless. Actúa como Fallback en caso de cortes eléctricos, pérdida de red local, o picos masivos de uso (fin de semestre).
3. **Audio Routing (Gemini API):** Las peticiones acústicas (mp3, wav) se rutean siempre a la API de Gemini (Flash-Lite o Flash) para una evaluación prosódica nativa de alta fidelidad.

## 2. Configuración de Skaffold y Knative

El despliegue está unificado gracias a **Skaffold** y **Knative**.

Se utiliza el mismo `Dockerfile` base (`ghcr.io/ggerganov/llama.cpp:server-cuda`). Las diferencias de entorno se manejan a nivel de *Profiles* en Skaffold:

*   **Perfil `local-open-llm`:** Usa el archivo `k8s/service-local.yaml`. Despliega el modelo apuntando a discos locales NVMe donde residen los pesos GGUF (Qwen 3.6-27B).
*   **Perfil `cloud-open-llm`:** Usa el archivo `k8s/service-cloud.yaml`. Despliega el modelo en Cloud Run, descargando los pesos desde Google Cloud Storage o construyendo la imagen dinámicamente.

## 3. Matriz de Autenticación Híbrida

La seguridad se gestiona diferente según la ubicación del contenedor, garantizando que el modelo nunca esté expuesto de forma insegura.

| Entorno | Ubicación | Autenticación Requerida por el LLM | Configuración del Worker (Backend) |
| :--- | :--- | :--- | :--- |
| **Producción (Fallback)** | Cloud Run | Google IAM (`--no-allow-unauthenticated`) | `llm.openllm.use_oidc=true`. El backend usa su Service Account para generar un token Bearer automáticamente. |
| **Local (MicroK8s)** | Home Lab | API Key (Pasada como argumento `--api-key`) | `llm.openllm.use_oidc=false`. El backend apunta al DNS interno de K8s e inyecta la API Key en texto plano, la cual viaja segura dentro de la intranet virtual. |

---

### Beneficios del Despliegue Local con Knative

Desplegar el LLM como un Knative Service en el MicroK8s local permite aprovechar funcionalidades nativas de la nube en hardware propio:
- **DNS Interno Limpio:** Los workers locales simplemente apuntan a `http://ce-llm-inference-local.namespace.svc.cluster.local:8080/v1`.
- **Auto-Reinicio y Gestión de GPU:** Kubernetes maneja caídas por Out-Of-Memory (OOM) y reinicia los contenedores, reservando la GPU exclusiva a través del plugin de NVIDIA.
