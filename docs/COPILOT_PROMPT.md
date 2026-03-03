# Prompt para sesión Copilot/ChatGPT (modelo premium)

Pega todo esto tal cual en la otra sesión. Contiene contexto, estado actual, problemas detectados, y tareas exactas para refactorizar los scripts y automatizar ArgoCD.

---

## Contexto general

- Repo: `UnisabanaArq1Grupo2PatronesActividad3` (branch `main`)
- Stack: .NET 10 (ASP.NET Core), Docker Buildx, Helm, Kubernetes (AKS), Azure (ACR), GitHub Actions, ArgoCD (GitOps)
- Objetivo: Hacer los scripts idempotentes y mantenibles; eliminar YAML embebido de `.ps1`; automatizar instalación de ArgoCD; dejar manifiestos versionados y aplicables.

## Archivos clave (revisar/editar)

- Scripts Azure: `azure/create-aks-cluster.ps1`, `azure/setup-acr-and-deploy.ps1`, `azure/setup-argocd.ps1`, `azure/delete-all-resources.ps1`, `azure/verify-deploy.ps1` (crear si falta)
- ArgoCD: `argocd/namespace.yaml`, `argocd/application.yaml`, `argocd/INSTALLATION.md`
- Helm: `helm/Chart.yaml`, `helm/values.yaml`, `helm/values-acr.yaml`, `helm/templates/*` (`deployment.yaml`, `service.yaml`, `ingress.yaml`, `hpa.yaml`)
- CI: `.github/workflows/ci-cd.yml`
- Docs: `README.md`, `SUMMARY.md`, `docs/*`, `azure/README.md`
- Otros: `.dockerignore` (contiene `argocd/`, `helm/` — correcto para build, pero manifests deben permanecer versionados en repo)

## Estado actual importante

- El despliegue funciona en AKS; ArgoCD está instalado en cluster (se instaló manualmente) y sincroniza `argocd/application.yaml`.
- Algunos scripts `.ps1` y `.sh` contienen manifiestos YAML embebidos como strings o escriben archivos temporales con contenido "pegado".
- No hay un paso idempotente y oficial que instale ArgoCD desde los manifests oficiales y aplique `argocd/application.yaml`.
- `.dockerignore` excluye `argocd/` y `helm/` del contexto de build (intencional).

## Problemas detectados (por prioridad)

1. YAML embebido dentro de scripts → no mantenible, difícil revisión.
2. Instalación de ArgoCD manual → falta automatización reproducible.
3. Scripts no idempotentes / logs pobres / sin timeouts robustos.
4. Documentación no refleja el flujo final automatizado completo (instalación ArgoCD incluida).

## Objetivo del trabajo que debe realizar el modelo premium

- Refactorizar scripts para que:
  - No contengan YAML embebido.
  - Apliquen archivos versionados en `argocd/`, `helm/`, `k8s/`.
  - Sean idempotentes, con logging y validaciones.
- Añadir/asegurar un script `azure/setup-argocd.ps1` que:
  - Crea namespace `argocd` si no existe.
  - Instala ArgoCD con manifiestos oficiales:
    - `kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml`
  - Espera a que `argocd-server` obtenga LoadBalancer IP (poll con timeout configurable).
  - (Opcional) Anota el Service con Azure DNS label para obtener `productapi-argocd.centralus.cloudapp.azure.com`.
  - Aplica `argocd/application.yaml`.
  - Imprime comando para obtener password admin:
    - `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
- Refactorizar `azure/create-aks-cluster.ps1`:
  - Quitar YAML embebido.
  - Instalar NGINX Ingress Controller preferiblemente con `kubectl apply -f https://...` o aplicando los manifiestos locales `k8s/nginx/` (si existen).
  - Esperar IP del LoadBalancer y exportar la URL.
- Refactorizar `azure/setup-acr-and-deploy.ps1`:
  - Generar `helm/values-acr.yaml` o usar plantilla `helm/values-acr.yaml` ya en repo; no incrustar el YAML.
  - Usar `docker buildx build --provenance=false --sbom=false --platform linux/amd64 -t <acr>/productapi:<tag> --push`.
  - Ejecutar `helm upgrade --install productapi helm/ -f helm/values-acr.yaml --wait --timeout 10m`.
- Crear `azure/verify-deploy.ps1`:
  - Verifica: pods `Running` en `productapi`, HPA (2-5) activo, Ingress IP responde a health endpoint.
  - Salida clara y códigos de error.

## Requisitos técnicos y de calidad

- Idempotencia: ejecutar varias veces no rompe el estado.
- Timeouts y retries: polls con intervalos (ej. cada 10s) y timeout configurable (ej. 10–15 minutos para IP/pods).
- No commitear secretos: si se requieren valores sensibles, documentar la creación de `kubectl create secret generic ...`.
- Logging claro y códigos de salida no nulos en fallos.
- Commits separados por tarea (ver mensajes sugeridos abajo).
- Mantener `argocd/` y `helm/` en el repo (aunque `.dockerignore` los excluya del contexto Docker).

## Entregables esperados del modelo premium

1. Parche(s) (o diffs) listos para aplicar al repo que:
   - Refactoricen `azure/create-aks-cluster.ps1` y `azure/setup-acr-and-deploy.ps1`.
   - Añadan `azure/setup-argocd.ps1`.
   - Añadan `azure/verify-deploy.ps1`.
   - Actualicen `README.md` con flujo de despliegue final y comandos de verificación.
2. Instrucciones claras para ejecutar (orden y comandos exactos).
3. Comandos de verificación y checklist.
4. Sugerencia de CI (si corresponde) para ejecutar parte del proceso en GitHub Actions.

## Comandos y comprobaciones sugeridas para la verificación final

- Unit tests: `cd src/ProductAPI.Tests && dotnet test`
- Helm deploy:  
  `helm upgrade --install productapi helm/ -f helm/values-acr.yaml --wait --timeout 10m`
- Instalar ArgoCD (desde script):  
  `kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml`
- Apply Argo application: `kubectl apply -f argocd/application.yaml`
- Obtener ArgoCD admin pwd:  
  `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
- Verificar HPA: `kubectl get hpa -n productapi`
- Verificar pods: `kubectl get pods -n productapi -o wide`
- Health check endpoint: `curl -sS http://productapi.centralus.cloudapp.azure.com/api/products/health`

## Mensajes de commit sugeridos

- `chore(azure): refactor create-aks-cluster to use external manifests and wait logic`
- `chore(azure): refactor setup-acr-and-deploy to use helm values file and buildx push`
- `feat(azure): add setup-argocd.ps1 to install ArgoCD and apply application manifest`
- `feat(azure): add verify-deploy.ps1 to validate deployment health`
- `docs: update README with new deployment flow and verification steps`

## Formato de salida pedido al modelo premium

- Preferencia A: Proveer un conjunto de patches en formato `git`/`diff` (o instrucciones `apply_patch`) listos para aplicar.
- Preferencia B: Si no puede generar patches, entregar los contenidos completos de los archivos nuevos/actualizados y un script `apply-patch.sh` que el usuario pueda ejecutar para aplicar los cambios.
- Incluir un checklist de verificación paso a paso y los comandos exactos para ejecutar localmente.

## Notas finales / restricciones

- No incluir secretos ni valores sensibles en los commits.
- Mantener compatibilidad con .NET 10 preview en CI (`dotnet-quality: preview` u opciones necesarias).
- `.dockerignore` puede continuar excluyendo `argocd/` y `helm/` del contexto Docker; eso no impide que los manifests estén versionados.

Fin del prompt.
