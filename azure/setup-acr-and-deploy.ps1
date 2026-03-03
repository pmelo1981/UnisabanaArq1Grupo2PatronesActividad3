#!/usr/bin/env pwsh

<#
.SYNOPSIS
  Configura ACR, build y deploy de imagen Docker con Helm.
.DESCRIPTION
  - Crea Azure Container Registry
  - Build imagen Docker
  - Push a ACR
  - Deploy con Helm usando --set (sin modificar archivos YAML)
.PARAMETER ResourceGroup
  Nombre del Resource Group
.PARAMETER RegistryName
  Nombre del ACR (default: auto-generado)
.PARAMETER ImageTag
  Tag de la imagen Docker (default: latest)
#>

param(
    [string]$ResourceGroup = "productapi-rg",
    [string]$RegistryName = "",
    [string]$ImageTag = "latest"
)

$ErrorActionPreference = "Stop"

# Auto-generar nombre de registry si no se proporciona
if ([string]::IsNullOrEmpty($RegistryName)) {
    $RegistryName = "productapi" + (Get-Random -Maximum 100000)
}

Write-Host "`n╔═══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   📦 SETUP ACR Y DEPLOY CON HELM           ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "📋 CONFIGURACIÓN:" -ForegroundColor Yellow
Write-Host "   Resource Group: $ResourceGroup"
Write-Host "   Registry: $RegistryName"
Write-Host "   Image Tag: $ImageTag`n"

try {
    # 1. Crear Container Registry
    Write-Host "1️⃣  Creando Azure Container Registry..." -ForegroundColor Yellow
    $acr = az acr show --resource-group $ResourceGroup --name $RegistryName 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ ACR ya existe`n" -ForegroundColor Green
    } else {
        az acr create --resource-group $ResourceGroup --name $RegistryName --sku Basic | Out-Null
        Write-Host "✅ ACR creado`n" -ForegroundColor Green
    }

    # 2. Obtener ACR login server
    Write-Host "2️⃣  Obteniendo ACR login server..." -ForegroundColor Yellow
    $acrLoginServer = az acr show --resource-group $ResourceGroup --name $RegistryName --query loginServer -o tsv
    Write-Host "✅ ACR URL: $acrLoginServer`n" -ForegroundColor Green

    # 3. Login a ACR
    Write-Host "3️⃣  Autenticando con ACR..." -ForegroundColor Yellow
    az acr login --name $RegistryName
    Write-Host "✅ Autenticado`n" -ForegroundColor Green

    # 4. Build imagen
    Write-Host "4️⃣  Building Docker image..." -ForegroundColor Yellow
    $imageName = "$acrLoginServer/productapi:$ImageTag"
    docker build -f docker/Dockerfile -t $imageName . --quiet
    Write-Host "✅ Imagen construida: $imageName`n" -ForegroundColor Green

    # 5. Push a ACR
    Write-Host "5️⃣  Pushing imagen a ACR..." -ForegroundColor Yellow
    docker push $imageName
    Write-Host "✅ Imagen pushed`n" -ForegroundColor Green

    # 6. Verificar que values-acr.yaml existe (versionado, no se modifica)
    # 6. Actualizar values-acr.yaml con imagen real y commitear (GitOps)
    Write-Host "6️⃣  Actualizando helm/values-acr.yaml para GitOps..." -ForegroundColor Yellow
    if (-not (Test-Path "helm/values-acr.yaml")) {
        throw "helm/values-acr.yaml no encontrado en el repo"
    }
    $valuesContent = Get-Content "helm/values-acr.yaml" -Raw
    $valuesContent = $valuesContent -replace 'repository: ".*"', "repository: `"$acrLoginServer/productapi`""
    $valuesContent = $valuesContent -replace 'tag: .*', "tag: $ImageTag"
    [System.IO.File]::WriteAllText((Resolve-Path "helm/values-acr.yaml"), $valuesContent)
    Write-Host "✅ values-acr.yaml actualizado (repository + tag)`n" -ForegroundColor Green

    Write-Host "   Commiteando para ArgoCD GitOps..." -ForegroundColor Yellow
    git add helm/values-acr.yaml 2>$null
    git commit -m "ci: update image to $acrLoginServer/productapi:$ImageTag" 2>$null
    git push 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Git push completado - ArgoCD auto-sincronizará`n" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Git push falló - ArgoCD necesitará sync manual`n" -ForegroundColor Yellow
    }

    # 7. Deploy con Helm (inmediato, sin esperar a ArgoCD)
    Write-Host "7️⃣  Deployando con Helm..." -ForegroundColor Yellow
    helm upgrade --install productapi helm/ `
        -f helm/values-acr.yaml `
        --namespace productapi `
        --create-namespace `
        --wait --timeout 10m
    Write-Host "✅ Deployment completado`n" -ForegroundColor Green

    # Resumen
    Write-Host "╔═══════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║  ✅ ACR Y HELM DEPLOYMENT EXITOSO           ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════╝`n" -ForegroundColor Green

    Write-Host "📍 INFORMACIÓN:" -ForegroundColor Cyan
    Write-Host "   Registry: $acrLoginServer"
    Write-Host "   Imagen: $imageName"
    Write-Host "   Namespace: productapi"
    Write-Host "   Values file: helm/values-acr.yaml (commiteado en git)`n"

    Write-Host "🔍 PRÓXIMOS PASOS:" -ForegroundColor Yellow
    Write-Host "   1. Ejecutar setup-argocd.ps1"
    Write-Host "   2. Ejecutar verify-deploy.ps1" -ForegroundColor White

} catch {
    Write-Host "`n❌ ERROR: $_" -ForegroundColor Red
    exit 1
}