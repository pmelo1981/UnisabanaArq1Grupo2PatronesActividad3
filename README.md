# Product API - Microservicio REST

API REST para gestión de productos con despliegue automatizado en Kubernetes/AKS, Helm, ArgoCD y CI/CD.

## 🚀 Información del Despliegue

### URLs de Acceso

- **API Base URL:** http://productapi-mpn.centralus.cloudapp.azure.com
- **Swagger UI:** http://productapi-mpn.centralus.cloudapp.azure.com/swagger
- **Health Check:** http://productapi-mpn.centralus.cloudapp.azure.com/api/products/health
- **ArgoCD UI:** https://172.169.162.125 (Usuario: `admin`, Contraseña: `im43l6M5zfRwkBcY`)

### Infraestructura Actual

- **Suscripción:** Visual Studio Enterprise - MPN (347b668a-8017-473a-91d4-4157235aa2a3)
- **Resource Group:** productapi-rg-enterprise
- **AKS Cluster:** productapi-aks-mpn (1 nodo Standard_B2s, centralus)
- **Container Registry:** productapiacrmpn.azurecr.io
- **Ingress IP:** 172.168.96.52
- **ArgoCD IP:** 172.169.162.125

---

## 🚀 Tecnologías

- **.NET 10** - Framework
- **Docker** - Containerización (multietapa)
- **Kubernetes/AKS** - Orquestación
- **Helm 3** - Gestión de configuración
- **NGINX Ingress Controller** - Enrutamiento HTTP(S)
- **ArgoCD** - GitOps automático
- **GitHub Actions** - CI/CD (Build → Test → Docker Push → Auto-deploy)
- **Azure Container Registry** - Registry privado de imágenes

---

## 📡 API REST Endpoints

```
GET    /api/products              # Obtener todos los productos
GET    /api/products/{id}         # Obtener producto por ID
POST   /api/products              # Crear nuevo producto
PUT    /api/products/{id}         # Actualizar producto
DELETE /api/products/{id}         # Eliminar producto
GET    /api/products/stats        # Estadísticas (total, avg price, max/min)
GET    /api/products/health       # Health check
```

## 📚 Ejemplos de Uso

### Health Check
```bash
curl http://productapi-mpn.centralus.cloudapp.azure.com/api/products/health
# Output: {"status":"healthy","timestamp":"2026-03-05T17:14:30.9138504Z"}
```

### Obtener Todos los Productos
```bash
curl http://productapi-mpn.centralus.cloudapp.azure.com/api/products
```

### Crear Producto
```bash
curl -X POST http://productapi-mpn.centralus.cloudapp.azure.com/api/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Laptop","description":"High-end laptop","price":999.99,"stock":5}'
```

### Obtener Estadísticas
```bash
curl http://productapi-mpn.centralus.cloudapp.azure.com/api/products/stats
```

## 📚 Documentación

- [ARCHITECTURE.md](docs/ARCHITECTURE.md) - Arquitectura y patrones
- [GETTING_STARTED.md](docs/GETTING_STARTED.md) - Inicio local
- [TESTING.md](docs/TESTING.md) - Pruebas unitarias y Swagger
- [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md) - Paso a paso manual
- [azure/README.md](azure/README.md) - Información de Azure

---

## 🔐 Acceder a ArgoCD UI

**URL:** https://172.169.162.125

```powershell
# Usuario: admin
# Contraseña: im43l6M5zfRwkBcY
```

O desde kubectl:
```powershell
# Port-forward (alternativa)
kubectl port-forward svc/argocd-server -n argocd 8443:443

# Navegador: https://localhost:8443
```

---

## 🔍 Comandos de Verificación

```powershell
# Ver pods en ejecución
kubectl get pods -n productapi

# Ver logs
kubectl logs -n productapi -l app=productapi -f

# Ver estado de la aplicación en ArgoCD
kubectl get application productapi -n argocd

# Ver ingress
kubectl get ingress -n productapi

# Ver todos los recursos
kubectl get all -n productapi
```

---

## 📊 Flujo GitOps

```
1. Push a GitHub (main branch)
        ↓
2. GitHub Actions CI/CD
   - Build .NET 10
   - Run 14 unit tests
   - Build Docker image (multistage)
   - Push a ACR con SHA tag
   - Update values-acr.yaml con nuevo tag
        ↓
3. ArgoCD (auto-sync enabled)
   - Detecta cambios en repo
   - Sincroniza manifests automáticamente
   - Aplica valores de values-acr.yaml
        ↓
4. Kubernetes/AKS
   - Rolling update deployment
   - HPA escala pods (2-5 replicas)
   - NGINX Ingress enruta tráfico
```

---

## 💾 Archivos Clave

```
✅ helm/values.yaml            # Valores por defecto
✅ helm/values-acr.yaml        # ACR registry + image tag (auto-actualizado por CI/CD)
✅ argocd/applications/        # Manifests de ArgoCD
✅ .github/workflows/ci-cd.yml # Pipeline CI/CD
✅ docker/Dockerfile           # Multistage build
```

---

## 🆘 Troubleshooting

### Verificar pods
```powershell
kubectl get pods -n productapi
# Todos deben estar Running
```

### Ver logs de pod específico
```powershell
kubectl logs -n productapi <pod-name>
```

### Reiniciar deployment
```powershell
kubectl rollout restart deployment productapi-productapi -n productapi
```

### Verificar ingress
```powershell
kubectl describe ingress -n productapi
```

### Forzar sync en ArgoCD
```powershell
# Desde ArgoCD UI: Click en "Sync" → "Synchronize"
```

---

## 🔧 Configuración de GitHub Secrets

Para que el CI/CD funcione, estos secrets deben estar configurados en GitHub:

- `ACR_USERNAME`: productapiacrmpn
- `ACR_PASSWORD`: 6H9XxFCNYaxzw356NxED6TECZ9HvAKbYwDqqGuKD2pYaFhrjrpVJJQQJ99CCAC1i4TkEqg7NAAACAZCRv0vV

**URL de configuración:** https://github.com/pmelo1981/UnisabanaArq1Grupo2PatronesActividad3-productapi/settings/secrets/actions

---

## ✅ Estado del Despliegue

- ✅ AKS Cluster: productapi-aks-mpn (Running)
- ✅ Pods: 2 replicas Running
- ✅ NGINX Ingress: Configurado con FQDN
- ✅ ArgoCD: Synced + Healthy
- ✅ API: Accesible públicamente
- ✅ GitHub Actions: Pipeline funcional
- ✅ GitOps: End-to-end automatizado

---

**Autor:** Grupo 2 - Arquitectura 1  
**Universidad:** Unisabana  
**Fecha:** Marzo 2026
