#!/usr/bin/env pwsh

<#
.SYNOPSIS
  Crea cluster AKS con configuración optimizada, instala NGINX Ingress.
.DESCRIPTION
  - Crea Resource Group
  - Crea AKS cluster (2 nodos, Standard_B2s)
  - Instala NGINX Ingress Controller
  - Espera LoadBalancer IP
  - Exporta credenciales kubectl
.PARAMETER ResourceGroup
  Nombre del Resource Group (default: productapi-rg)
.PARAMETER ClusterName
  Nombre del cluster AKS (default: productapi-aks)
.PARAMETER Location
  Región Azure (default: eastus)
.PARAMETER NodeCount
  Cantidad de nodos (default: 2)
.PARAMETER VmSize
  Tamaño de VM (default: Standard_B2s)
#>

param(
    [string]$ResourceGroup = "productapi-rg",
    [string]$ClusterName = "productapi-aks",
    [string]$Location = "eastus",
    [int]$NodeCount = 1,
    [string]$VmSize = "Standard_B2s"
)

$ErrorActionPreference = "Stop"

Write-Host "`n╔═══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║      🚀 CREAR CLUSTER AKS                   ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "📋 CONFIGURACIÓN:" -ForegroundColor Yellow
Write-Host "   Resource Group: $ResourceGroup"
Write-Host "   Cluster: $ClusterName"
Write-Host "   Región: $Location"
Nodos: $NodeCount x $VmSize (Azure for Students: max 3 vCPUs)`n"

try {
    # 1. Crear Resource Group
    Write-Host "1️⃣  Creando Resource Group '$ResourceGroup'..." -ForegroundColor Yellow
    $rg = az group show --name $ResourceGroup 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Resource Group ya existe`n" -ForegroundColor Green
    } else {
        az group create --name $ResourceGroup --location $Location | Out-Null
        Write-Host "✅ Resource Group creado`n" -ForegroundColor Green
    }

    # 2. Crear AKS cluster
    Write-Host "2️⃣  Creando cluster AKS (esto puede tomar 5-10 minutos)..." -ForegroundColor Yellow
    $cluster = az aks show --resource-group $ResourceGroup --name $ClusterName 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Cluster AKS ya existe`n" -ForegroundColor Green
    } else {
        az aks create `
            --resource-group $ResourceGroup `
            --name $ClusterName `
            --node-count $NodeCount `
            --vm-set-type VirtualMachineScaleSets `
            --load-balancer-sku standard `
            --enable-managed-identity `
            --network-plugin kubenet `
            --vm-size $VmSize `
            --yes | Out-Null
        Write-Host "✅ Cluster creado`n" -ForegroundColor Green
    }

    # 3. Obtener credenciales
    Write-Host "3️⃣  Configurando kubectl..." -ForegroundColor Yellow
    az aks get-credentials `
        --resource-group $ResourceGroup `
        --name $ClusterName `
        --overwrite-existing | Out-Null
    Write-Host "✅ kubectl configurado`n" -ForegroundColor Green

    # 4. Verificar conexión
    Write-Host "4️⃣  Verificando conexión al cluster..." -ForegroundColor Yellow
    $nodes = kubectl get nodes --no-headers 2>$null | Measure-Object | Select-Object -ExpandProperty Count
    if ($nodes -gt 0) {
        Write-Host "✅ Conectado. Nodos: $nodes`n" -ForegroundColor Green
        kubectl get nodes --no-headers
        Write-Host ""
    } else {
        throw "No se puede conectar al cluster"
    }

    # 5. Instalar NGINX Ingress Controller
    Write-Host "5️⃣  Instalando NGINX Ingress Controller..." -ForegroundColor Yellow
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 2>$null
    helm repo update 2>$null

    # Limpiar recursos previos no gestionados por Helm (idempotente)
    kubectl delete clusterrole ingress-nginx ingress-nginx-admission --ignore-not-found=true 2>$null | Out-Null
    kubectl delete clusterrolebinding ingress-nginx ingress-nginx-admission --ignore-not-found=true 2>$null | Out-Null
    kubectl delete ValidatingWebhookConfiguration ingress-nginx-admission --ignore-not-found=true 2>$null | Out-Null
    kubectl delete ingressclass nginx --ignore-not-found=true 2>$null | Out-Null

    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx `
        --namespace ingress-nginx `
        --create-namespace `
        --set controller.service.type=LoadBalancer `
        --wait --timeout 5m 2>$null
    Write-Host "✅ NGINX Ingress instalado`n" -ForegroundColor Green

    # 6. Esperar LoadBalancer IP
    Write-Host "6️⃣  Esperando IP de NGINX LoadBalancer..." -ForegroundColor Yellow
    $elapsed = 0
    $timeout = 600
    $interval = 10
    $nginxIP = $null

    while ($elapsed -lt $timeout) {
        $nginxIP = kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
        if ($nginxIP -and $nginxIP -ne "") {
            Write-Host "✅ NGINX IP: $nginxIP`n" -ForegroundColor Green
            break
        }
        Write-Host "⏳ Esperando IP... (${elapsed}s/${timeout}s)" -ForegroundColor Gray
        Start-Sleep -Seconds $interval
        $elapsed += $interval
    }

    if (-not $nginxIP -or $nginxIP -eq "") {
        Write-Host "⚠️  IP de NGINX no disponible (esperando manualmente)" -ForegroundColor Yellow
    }

    # Resumen
    Write-Host "╔═══════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║  ✅ CLUSTER AKS CREADO EXITOSAMENTE         ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════╝`n" -ForegroundColor Green

    Write-Host "📍 INFORMACIÓN DEL CLUSTER:" -ForegroundColor Cyan
    Write-Host "   Resource Group: $ResourceGroup"
    Write-Host "   Cluster: $ClusterName"
    Write-Host "   Región: $Location"
    Write-Host "   Nodos: $NodeCount`n"

    Write-Host "🌐 INGRESS:" -ForegroundColor Cyan
    Write-Host "   IP: $(if ($nginxIP) { $nginxIP } else { '<PENDING>' })" -ForegroundColor White
    Write-Host "   Namespace: ingress-nginx`n"

    Write-Host "⏭️  PRÓXIMO PASO: Ejecutar setup-acr-and-deploy.ps1" -ForegroundColor Yellow

} catch {
    Write-Host "`n❌ ERROR: $_" -ForegroundColor Red
    exit 1
}
