# ProductAPI — Información del proyecto

Resumen breve con lo esencial para verificación y despliegue.

Acceso
- API: `http://productapi-mpn.centralus.cloudapp.azure.com`
- Swagger UI: `http://productapi-mpn.centralus.cloudapp.azure.com/swagger`
- Health: `http://productapi-mpn.centralus.cloudapp.azure.com/api/products/health`

Comprobaciones rápidas
```
kubectl get application productapi -n argocd -o jsonpath='{.status.sync.status} {.status.health.status}'
kubectl get pods -n productapi -o wide
curl -v http://productapi-mpn.centralus.cloudapp.azure.com/api/products/health
```

Imagen desplegada: `productapiacrmpn.azurecr.io/productapi:0b09ff4`

Obtener contraseña admin ArgoCD (desde el cluster):
```
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 --decode
```

Comandos útiles
```
kubectl get pods -n productapi
kubectl logs -n productapi -l app=productapi -f
kubectl get ingress -n productapi
kubectl rollout restart deployment productapi-productapi -n productapi
```

Estado
- AKS: productapi-aks-mpn
- ArgoCD: Synced, Healthy
- Pods: 2 replicas Running

Última actualización: 2026-03-05

Autor: Grupo 2 - Arquitectura 1
