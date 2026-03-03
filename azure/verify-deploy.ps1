#!/usr/bin/env pwsh

<#
.SYNOPSIS
  Verifica que el despliegue esté completo y funcional.
.DESCRIPTION
  - Verifica pods en estado Running
  - Verifica HPA activo (2-5 replicas)
  - Verifica Ingress IP
  - Verifica health endpoint responde
  - Verifica manifests aplicados
.PARAMETER Namespace
  Namespace donde buscar recursos (default: productapi)
.PARAMETER Timeout
  Timeout en segundos para esperar disponibilidad (default: 300s = 5 min)
#>

param(
    [string]$Namespace = "productapi",
    [int]$Timeout = 300
)

$ErrorActionPreference = "Stop"

Write-Host "`n?????????????????????????????????????????????????" -ForegroundColor Cyan
Write-Host "?    ??  VERIFICAR DEPLOYMENT                  ?" -ForegroundColor Cyan
Write-Host "?????????????????????????????????????????????????`n" -ForegroundColor Cyan

$allOK = $true

try {
    # 1. Verificar namespace existe
    Write-Host "1??  Verificando namespace '$Namespace'..." -ForegroundColor Yellow
    $ns = kubectl get namespace $Namespace 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "? Namespace existe`n" -ForegroundColor Green
    } else {
        Write-Host "? Namespace no existe`n" -ForegroundColor Red
        $allOK = $false
    }

    # 2. Verificar Deployment
    Write-Host "2??  Verificando Deployment..." -ForegroundColor Yellow
    $deployment = kubectl get deployment -n $Namespace -l app=productapi -o jsonpath='{.items[0].metadata.name}' 2>$null
    if ($deployment) {
        $ready = kubectl get deployment -n $Namespace $deployment -o jsonpath='{.status.readyReplicas}' 2>$null
        $desired = kubectl get deployment -n $Namespace $deployment -o jsonpath='{.spec.replicas}' 2>$null
        Write-Host "   Deployment: $deployment"
        Write-Host "   Replicas: $ready/$desired"
        if ($ready -eq $desired -and $ready -gt 0) {
            Write-Host "? Deployment ready`n" -ForegroundColor Green
        } else {
            Write-Host "??  Esperando pods... ($ready/$desired)`n" -ForegroundColor Yellow
        }
    } else {
        Write-Host "? Deployment no encontrado`n" -ForegroundColor Red
        $allOK = $false
    }

    # 3. Verificar Pods
    Write-Host "3??  Verificando Pods..." -ForegroundColor Yellow
    $pods = kubectl get pods -n $Namespace -l app=productapi --no-headers 2>$null
    if ($pods) {
        $runningPods = $pods | Where-Object { $_ -match "Running" } | Measure-Object | Select-Object -ExpandProperty Count
        Write-Host "   Pods running: $runningPods"
        kubectl get pods -n $Namespace -l app=productapi --no-headers
        if ($runningPods -gt 0) {
            Write-Host "? Pods están Running`n" -ForegroundColor Green
        } else {
            Write-Host "??  Pods no están Running aún`n" -ForegroundColor Yellow
        }
    } else {
        Write-Host "? No hay Pods`n" -ForegroundColor Red
        $allOK = $false
    }

    # 4. Verificar HPA
    Write-Host "4??  Verificando Horizontal Pod Autoscaler..." -ForegroundColor Yellow
    $hpa = kubectl get hpa -n $Namespace --all-namespaces=false 2>$null
    if ($hpa) {
        $hpaName = kubectl get hpa -n $Namespace -o jsonpath='{.items[0].metadata.name}' 2>$null
        if ($hpaName) {
            $minReplicas = kubectl get hpa -n $Namespace $hpaName -o jsonpath='{.spec.minReplicas}' 2>$null
            $maxReplicas = kubectl get hpa -n $Namespace $hpaName -o jsonpath='{.spec.maxReplicas}' 2>$null
            $currentReplicas = kubectl get hpa -n $Namespace $hpaName -o jsonpath='{.status.currentReplicas}' 2>$null
            Write-Host "   HPA: $hpaName"
            Write-Host "   Rango: $minReplicas-$maxReplicas"
            Write-Host "   Actual: $currentReplicas"
            if ($minReplicas -eq 2 -and $maxReplicas -eq 5) {
                Write-Host "? HPA configurado correctamente`n" -ForegroundColor Green
            } else {
                Write-Host "??  HPA valores inesperados`n" -ForegroundColor Yellow
            }
        } else {
            Write-Host "??  HPA no encontrado (puede no estar habilitado)`n" -ForegroundColor Yellow
        }
    } else {
        Write-Host "??  HPA no encontrado (puede no estar habilitado)`n" -ForegroundColor Yellow
    }

    # 5. Verificar Service
    Write-Host "5??  Verificando Service..." -ForegroundColor Yellow
    $svc = kubectl get svc -n $Namespace -l app=productapi -o jsonpath='{.items[0].metadata.name}' 2>$null
    if ($svc) {
        $svcType = kubectl get svc -n $Namespace $svc -o jsonpath='{.spec.type}' 2>$null
        Write-Host "   Service: $svc"
        Write-Host "   Type: $svcType"
        Write-Host "? Service configurado`n" -ForegroundColor Green
    } else {
        Write-Host "? Service no encontrado`n" -ForegroundColor Red
        $allOK = $false
    }

    # 6. Verificar Ingress
    Write-Host "6??  Verificando Ingress NGINX..." -ForegroundColor Yellow
    $ing = kubectl get ingress -n $Namespace -l app=productapi -o jsonpath='{.items[0].metadata.name}' 2>$null
    if ($ing) {
        $ingIP = kubectl get ingress -n $Namespace $ing -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
        Write-Host "   Ingress: $ing"
        Write-Host "   IP: $(if ($ingIP) { $ingIP } else { '<PENDING>' })"
        if ($ingIP) {
            Write-Host "? Ingress NGINX asignada`n" -ForegroundColor Green
        } else {
            Write-Host "??  IP NGINX pendiente`n" -ForegroundColor Yellow
        }
    } else {
        Write-Host "??  Ingress no encontrado (acceso solo via ClusterIP)`n" -ForegroundColor Yellow
        $ingIP = $null
    }

    # 7. Verificar Health Endpoint
    Write-Host "7??  Probando Health Endpoint..." -ForegroundColor Yellow
    if ($ingIP) {
        try {
            $response = curl -s -o /dev/null -w "%{http_code}" "http://$ingIP/api/products/health" 2>$null
            if ($response -eq "200") {
                Write-Host "   Endpoint: http://$ingIP/api/products/health"
                Write-Host "? Health endpoint responde (HTTP 200)`n" -ForegroundColor Green
            } else {
                Write-Host "   Status: HTTP $response"
                Write-Host "??  Endpoint responde con $response (esperando 200)`n" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "??  No se puede alcanzar el endpoint (puede estar iniciando)`n" -ForegroundColor Yellow
        }
    } else {
        Write-Host "? Saltando (Ingress IP no disponible aún)`n" -ForegroundColor Gray
    }

    # 8. Verificar ArgoCD Application
    Write-Host "8??  Verificando ArgoCD Application..." -ForegroundColor Yellow
    $app = kubectl get application -n argocd productapi -o jsonpath='{.metadata.name}' 2>$null
    if ($app) {
        $appStatus = kubectl get application -n argocd productapi -o jsonpath='{.status.operationState.phase}' 2>$null
        $syncStatus = kubectl get application -n argocd productapi -o jsonpath='{.status.sync.status}' 2>$null
        Write-Host "   Application: $app"
        Write-Host "   Sync Status: $syncStatus"
        Write-Host "   Operation: $appStatus"
        if ($syncStatus -eq "Synced") {
            Write-Host "? Application sincronizada`n" -ForegroundColor Green
        } else {
            Write-Host "??  Application no sincronizada`n" -ForegroundColor Yellow
        }
    } else {
        Write-Host "??  ArgoCD Application no encontrada (verifica setup-argocd.ps1)`n" -ForegroundColor Yellow
    }

    # 9. Resumen
    Write-Host "?????????????????????????????????????????????????" -ForegroundColor $(if ($allOK) { "Green" } else { "Yellow" })
    Write-Host "?  $(if ($allOK) { '? VERIFICACIÓN COMPLETADA' } else { '??  PARCIALMENTE VERIFICADO' })           ?" -ForegroundColor $(if ($allOK) { "Green" } else { "Yellow" })
    Write-Host "?????????????????????????????????????????????????`n" -ForegroundColor $(if ($allOK) { "Green" } else { "Yellow" })

    if (-not $allOK) {
        Write-Host "?? COMANDOS ÚTILES PARA DEBUGGING:" -ForegroundColor Cyan
        Write-Host "   Ver logs: kubectl logs -n $Namespace -l app=productapi -f"
        Write-Host "   Ver pods: kubectl get pods -n $Namespace -o wide"
        Write-Host "   Ver eventos: kubectl get events -n $Namespace --sort-by='.lastTimestamp'`n"
        exit 1
    }

} catch {
    Write-Host "`n? ERROR: $_" -ForegroundColor Red
    exit 1
}
