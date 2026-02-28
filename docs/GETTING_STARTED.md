# Guía de Inicio - Product API

## 1. Clonar el repositorio
git clone https://github.com/pmelo1981/UnisabanaArq1Grupo2PatronesActividad3.git

## 2. Ejecutar localmente
cd src/ProductAPI
dotnet run

## 3. Construir imagen Docker
docker build -f docker/Dockerfile -t productapi:v1.0 .

## 4. Crear clúster AKS
bash azure/create-aks-cluster.sh

## 5. Instalar ArgoCD
kubectl apply -f argocd/namespace.yaml
kubectl apply -f argocd/application.yaml
