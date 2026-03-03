# Product API - Microservicio REST

API REST para gestión de productos con despliegue automatizado en Kubernetes/AKS, Helm, ArgoCD y CI/CD.

## 🚀 Tecnologías

- **.NET 10** - Framework
- **Docker** - Containerización (multietapa)
- **Kubernetes/AKS** - Orquestación
- **Helm 3** - Gestión de configuración
- **NGINX Ingress Controller** - Enrutamiento HTTP(S)
- **ArgoCD** - GitOps automático
- **GitHub Actions** - CI/CD
- **Azure Container Registry** - Registry de imágenes

## 📡 API REST

```
GET    /api/products              # Obtener todos
GET    /api/products/{id}         # Obtener por ID
POST   /api/products              # Crear
PUT    /api/products/{id}         # Actualizar
DELETE /api/products/{id}         # Eliminar
GET    /api/products/health       # Health check
```

## 📚 Documentación

- [ARCHITECTURE.md](docs/ARCHITECTURE.md) - Arquitectura y patrones
- [GETTING_STARTED.md](docs/GETTING_STARTED.md) - Inicio local
- [TESTING.md](docs/TESTING.md) - Pruebas unitarias y Swagger
- [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md) - Paso a paso manual
- [azure/README.md](azure/README.md) - Información de Azure

---

## 🚀 DEPLOYMENT RÁPIDO (5 pasos)

### Prerequisitos
```powershell
# Verificar que tengas esto
az account show              # Autenticado en Azure
docker --version             # Docker instalado
kubectl version --client     # kubectl instalado
helm version                 # Helm 3 instalado
```

### Paso 1: Crear Cluster AKS
```powershell
.\azure\create-aks-cluster.ps1
```
**Qué hace:**
- ✅ Crea Resource Group
- ✅ Crea cluster AKS (2 nodos Standard_B2s)
- ✅ Instala NGINX Ingress Controller
- ✅ Espera LoadBalancer IP
- ⏱️ Tiempo: 5-10 minutos

### Paso 2: Setup ACR y Deploy
```powershell
.\azure\setup-acr-and-deploy.ps1
```
**Qué hace:**
- ✅ Crea Azure Container Registry
- ✅ Build imagen Docker
- ✅ Push a ACR
- ✅ Genera helm/values-acr.yaml
- ✅ Deploy con Helm
- ⏱️ Tiempo: 3-5 minutos

### Paso 3: Instalar ArgoCD
```powershell
.\azure\setup-argocd.ps1
```
**Qué hace:**
- ✅ Crea namespace argocd
- ✅ Instala ArgoCD oficial
- ✅ Espera LoadBalancer IP
- ✅ Aplica application manifest
- ✅ Muestra credenciales
- ⏱️ Tiempo: 2-3 minutos

### Paso 4: Verificar Deployment
```powershell
.\azure\verify-deploy.ps1
```
**Qué hace:**
- ✅ Verifica pods Running
- ✅ Verifica HPA activo
- ✅ Verifica LoadBalancer IP
- ✅ Verifica health endpoint
- ✅ Verifica ArgoCD Application

### Paso 5: LIMPIAR (¡Importante!)
```powershell
az group delete --name productapi-rg --yes
```
⚠️ **Esto elimina TODO y detiene costos**

---

## 🔐 Acceder a ArgoCD UI

```powershell
# Terminal 1: Port-forward
kubectl port-forward svc/argocd-server -n argocd 8443:443

# Terminal 2: Obtener password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Navegador: https://localhost:8443
# Usuario: admin
# Contraseña: (output anterior)
```

---

## ✅ Probar Endpoints

```powershell
# Health check
curl http://<EXTERNAL-IP>/api/products/health

# Obtener todos
curl http://<EXTERNAL-IP>/api/products

# Crear producto
curl -X POST http://<EXTERNAL-IP>/api/products `
  -H "Content-Type: application/json" `
  -d '{"name":"Laptop","description":"High-end laptop","price":999.99,"stock":5}'
```

---

## 🔍 Debugging

```powershell
# Ver pods
kubectl get pods -n productapi -o wide

# Ver logs
kubectl logs -n productapi -l app=productapi -f

# Ver eventos
kubectl get events -n productapi --sort-by='.lastTimestamp'

# Ver HPA
kubectl get hpa -n productapi

# Ver todos los recursos
kubectl get all -n productapi
```

---

## 📊 Flujo GitOps

```
1. Push a GitHub (main branch)
        ↓
2. GitHub Actions
   - Build .NET
   - Tests
   - Build Docker image
   - Push a ACR
        ↓
3. ArgoCD (monitorea repo)
   - Detecta cambios
   - Sincroniza manifests
        ↓
4. Kubernetes
   - Aplica new deployment
   - Escala pods (HPA)
   - Actualiza servicios
```

---

## ⚙️ Estructura de Scripts

| Script | Propósito | Idempotente |
|--------|-----------|------------|
| `create-aks-cluster.ps1` | Crear AKS + NGINX Ingress | ✅ Sí |
| `setup-acr-and-deploy.ps1` | ACR + Docker Build + Helm Deploy | ✅ Sí |
| `setup-argocd.ps1` | Instalar ArgoCD + Application | ✅ Sí |
| `verify-deploy.ps1` | Verificar estado completo | ✅ Solo lectura |
| `delete-all-resources.ps1` | Limpiar Resource Group | ⚠️ Cuidado |

---

## 💾 Archivos Versionados (NO excluidos del repo)

```
✅ helm/                    # Charts y valores
✅ argocd/                  # Manifests de ArgoCD
✅ azure/                   # Scripts de deployment
✅ .github/workflows/       # CI/CD pipelines
✅ docker/                  # Dockerfile
```

**Nota:** `.dockerignore` excluye estos archivos del contexto Docker (intencional), pero están versionados en Git.

---

## 📋 Checklist de Deployment

- [ ] ✅ `az account show` funciona
- [ ] ✅ Ejecute `create-aks-cluster.ps1`
- [ ] ✅ Ejecute `setup-acr-and-deploy.ps1`
- [ ] ✅ Ejecute `setup-argocd.ps1`
- [ ] ✅ Ejecute `verify-deploy.ps1` (todo verde)
- [ ] ✅ Pruebe endpoints con curl
- [ ] ✅ Acceda a ArgoCD UI
- [ ] ✅ Ejecute `az group delete` para limpiar

---

## 💰 Costos Estimados

| Recurso | Costo |
|---------|-------|
| 2 x Standard_B2s (nodos AKS) | $30-50/mes |
| Load Balancer (x2) | ~$32/mes |
| Container Registry (Basic) | ~$5/mes |
| **TOTAL** | **~$70-85/mes** |

⏱️ **Durante pruebas (20 min):** ~$0.50

---

## 🆘 Troubleshooting

### LoadBalancer IP no aparece
```powershell
# Puede tomar 2-3 minutos
kubectl get svc -n productapi -w
```

### Pods no están Running
```powershell
# Ver logs
kubectl logs -n productapi -l app=productapi

# Describir pod
kubectl describe pod -n productapi <pod-name>
```

### ArgoCD no sincroniza
```powershell
# Ver Application status
kubectl get application -n argocd productapi

# Ver controller logs
kubectl logs -n argocd deployment/argocd-application-controller
```

### Limpiar antes de re-ejecutar
```powershell
# Si algo falla, limpiar todo
az group delete --name productapi-rg --yes

# Esperar ~10 minutos
# Luego re-ejecutar desde Paso 1
```

---

## 📝 Licencia

MIT

---

## 🎯 Próximos Pasos

1. ✅ Código .NET completo y testeado
2. ✅ Scripts de deployment automatizados e idempotentes
3. ⏭️ Ejecutar los 5 pasos de deployment
4. ⏭️ Grabar video demostrando todo funcionando
5. ⏭️ Presentar proyecto
