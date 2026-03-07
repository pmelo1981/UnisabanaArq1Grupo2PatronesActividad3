# Infraestructura — Guía de verificación

Comprobaciones mínimas
```bash
# Estado de la aplicación en ArgoCD
kubectl get application productapi -n argocd -o jsonpath='{.status.sync.status} {.status.health.status}'

# Ver pods en el namespace productapi
kubectl get pods -n productapi -o wide

# Forzar re-evaluación del repositorio en ArgoCD
kubectl patch application productapi -n argocd -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}' --type=merge
```

Acceso a ArgoCD
```bash
# Obtener URL del servicio argocd-server
kubectl -n argocd get svc argocd-server
```

Credenciales (admin)
```
Usuario: admin
Contraseña: im43l6M5zfRwkBcY
```

Imagen desplegada
```text
productapiacrmpn.azurecr.io/productapi:0b09ff4


**Ultima actualizacion:** 05/03/2026  
**URL en vivo:** http://productapi-mpn.centralus.cloudapp.azurecrmpn.azurecrmpn.cloudapp.azurecom