# Quick Build and Deploy Script

This script builds the frontend image using Google Cloud Build and deploys it to GKE.

## Option 1: Build using Google Cloud Build (Recommended - No Local Docker Required)

```bash
#!/bin/bash

# Variables
PROJECT_ID="elegant-atom-475415-c4"
REGISTRY="us-central1-docker.pkg.dev"
REPOSITORY="frontend"
IMAGE_NAME="wobot-frontend"
TAG="latest"

# Build using Cloud Build
gcloud builds submit \
  --project=$PROJECT_ID \
  --config=cloudbuild.yaml \
  ./application/frontend

# Tag and push
IMAGE_URL="$REGISTRY/$PROJECT_ID/$REPOSITORY/$IMAGE_NAME:$TAG"
echo "Image built and pushed to: $IMAGE_URL"

# Restart frontend deployments in GKE
kubectl rollout restart deployment/frontend-stable -n wobot
kubectl rollout restart deployment/frontend-canary -n wobot

# Wait for rollout
kubectl rollout status deployment/frontend-stable -n wobot
```

## Option 2: If Docker is Available Locally

First, start Docker Desktop, then:

```bash
cd /Users/krishnagarg/Documents/wobot-backend-app/application/frontend

# Build with buildx
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t us-central1-docker.pkg.dev/elegant-atom-475415-c4/frontend/wobot-frontend:latest \
  --push .
```

## Quickest Fix - Just Restart Current Frontend

If the Dockerfile changes are already in git, just restart the existing frontend:

```bash
# Restart frontend pods to pick up config changes
kubectl rollout restart deployment/frontend-stable -n wobot
kubectl rollout restart deployment/frontend-canary -n wobot

# Watch the rollout
kubectl rollout status deployment/frontend-stable -n wobot

# Verify config.js was created
kubectl exec -it deployment/frontend-stable -n wobot -- \
  cat /usr/share/nginx/html/config.js
```

## Create cloudbuild.yaml

Create this file in the project root:

```yaml
# cloudbuild.yaml
steps:
  # Build and push image for multiple architectures
  - name: 'gcr.io/cloud-builders/docker'
    args:
      - 'build'
      - '-t'
      - 'us-central1-docker.pkg.dev/$PROJECT_ID/frontend/wobot-frontend:latest'
      - '-t'
      - 'us-central1-docker.pkg.dev/$PROJECT_ID/frontend/wobot-frontend:$BUILD_ID'
      - './application/frontend'

  - name: 'gcr.io/cloud-builders/docker'
    args:
      - 'push'
      - 'us-central1-docker.pkg.dev/$PROJECT_ID/frontend/wobot-frontend:latest'

  # Run Hadolint for Dockerfile linting
  - name: 'gcr.io/cloud-builders/docker'
    args:
      - 'run'
      - '--rm'
      - '-i'
      - 'hadolint/hadolint'
      - 'hadolint'
      - '-'
      - '<'
      - './application/frontend/Dockerfile'

images:
  - 'us-central1-docker.pkg.dev/$PROJECT_ID/frontend/wobot-frontend:latest'
  - 'us-central1-docker.pkg.dev/$PROJECT_ID/frontend/wobot-frontend:$BUILD_ID'

timeout: '1800s'
```

## Test Connection After Restart

```bash
# Port forward to test locally
kubectl port-forward svc/frontend-service 3000:3000 -n wobot

# In another terminal
curl http://localhost:3000

# Check browser at http://localhost:3000
# Status should show ✓ Connected
```
