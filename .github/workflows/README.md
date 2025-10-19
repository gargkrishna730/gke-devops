# CI/CD Workflows Documentation

This document explains the GitHub Actions workflows that automate building, scanning, and pushing Docker images to Google Artifact Registry.

## Overview

The CI/CD pipeline is designed to:
1. **Build** Docker images for backend and frontend applications
2. **Scan** images for security vulnerabilities
3. **Push** images to GCP Artifact Registry
4. **Report** security findings in GitHub Actions

## Workflow Files

### 1. Backend CI/CD Workflow
**File:** `.github/workflows/backend-ci.yml`

Automatically triggered when changes are pushed to the `master` branch in `application/backend/` directory.

### 2. Frontend CI/CD Workflow
**File:** `.github/workflows/frontend-ci.yml`

Automatically triggered when changes are pushed to the `master` branch in `application/frontend/` directory.

## Trigger Events

Both workflows are triggered on:
- **Push to master branch** with changes in:
  - `application/backend/**` (for backend workflow)
  - `application/frontend/**` (for frontend workflow)
  - `.github/workflows/*.yml` (workflow file itself)

This ensures the workflow only runs when relevant code changes, saving CI/CD minutes.

## Pipeline Stages

### 1. 📥 Checkout Code
- Uses `actions/checkout@v4`
- Retrieves the latest code from the repository
- Enables access to Dockerfile and application files

### 2. 🔨 Setup Docker Buildx
- Uses `docker/setup-buildx-action@v3`
- Enables multi-architecture (multi-arch) Docker builds
- Supports both `linux/amd64` and `linux/arm64` platforms

### 3. 🔐 Google Cloud Authentication
- Uses `google-github-actions/auth@v2`
- Authenticates using GCP service account credentials
- Enables access to GCP services like Artifact Registry

### 4. ☁️ Setup Google Cloud SDK
- Uses `google-github-actions/setup-gcloud@v2`
- Installs and configures gcloud CLI tools
- Prepares for artifact registry operations

### 5. 🐳 Configure Docker Authentication
- Configures Docker to authenticate with GCP Artifact Registry
- Enables pushing images to `us-central1-docker.pkg.dev`

### 6. 🏷️ Generate Image Tag
- Creates a unique image tag using git commit SHA
- Format: `us-central1-docker.pkg.dev/{PROJECT_ID}/{REPO}/{IMAGE_NAME}:{COMMIT_SHA}`
- Example: `us-central1-docker.pkg.dev/elegant-atom-475415-c4/backend/wobot-backend:a1b2c3d4e5f6...`

### 7. 🏗️ Build and Push Multi-Architecture Image
- Uses `docker/build-push-action@v4`
- Builds Docker image for multiple architectures:
  - `linux/amd64` - Intel/AMD processors
  - `linux/arm64` - ARM processors (Apple Silicon, newer ARM servers)
- Pushes directly to Artifact Registry (no local storage needed)
- Significantly faster with buildx native builder

### 8. 🔍 Dockerfile Linting with Hadolint
- Uses `hadolint/hadolint-action@v3.1.0`
- Validates Dockerfile best practices
- Checks for:
  - Unused base image stages
  - Missing labels
  - Inefficient layer usage
  - Security issues in Dockerfile
- Failure threshold: `warning` (allows warnings but fails on errors)

### 9. 📁 Create Scan Results Directory
- Creates `scan-results/` directory for storing vulnerability reports
- Ensures directory exists before Trivy scan

### 10. 🛡️ Scan Docker Image with Trivy
- Uses `aquasecurity/trivy-action@master`
- Scans the built image for vulnerabilities
- Configuration:
  - **Scanner:** Vulnerabilities only
  - **Severity Levels:** MEDIUM, HIGH, CRITICAL
  - **Format:** JSON output for processing
  - **Output File:** `scan-results/scan-report.json`

Trivy checks for:
- CVEs (Common Vulnerabilities and Exposures)
- Vulnerable dependencies
- Misconfigurations
- Security risks in base images

### 11. 📊 Generate Trivy Report Summary
- Parses Trivy JSON report
- Creates a GitHub Actions Step Summary with:
  - Vulnerability count by severity
  - Image details and timestamp
  - Easy-to-read table format
- Shows on workflow run summary page

### 12. 📦 Upload Scan Results
- Uses `actions/upload-artifact@v4`
- Uploads `scan-results/` directory as workflow artifact
- Retention: 30 days
- Name: `security-scan-results-{backend/frontend}-{COMMIT_SHA}`
- Allows downloading reports after workflow completion

## Environment Variables

Both workflows use these environment variables:

```yaml
REGISTRY: us-central1-docker.pkg.dev
PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
REPOSITORY: backend | frontend
IMAGE_NAME: wobot-backend | wobot-frontend
IMAGE_TAG: ${{ github.sha }}  # Git commit SHA
```

## Required Secrets

Configure these secrets in GitHub repository settings:

### `GCP_SERVICE_ACCOUNT_KEY`
- **Type:** GCP Service Account JSON credentials
- **Permissions Needed:**
  - `artifactregistry.repositories.downloadArtifacts`
  - `artifactregistry.files.get`
  - `storage.buckets.get`
- **How to Create:**
  ```bash
  gcloud iam service-accounts create github-actions-ci
  gcloud projects add-iam-policy-binding PROJECT_ID \
    --member=serviceAccount:github-actions-ci@PROJECT_ID.iam.gserviceaccount.com \
    --role=roles/artifactregistry.writer
  gcloud iam service-accounts keys create key.json \
    --iam-account=github-actions-ci@PROJECT_ID.iam.gserviceaccount.com
  ```

### `GCP_PROJECT_ID`
- **Value:** Your GCP project ID
- **Example:** `elegant-atom-475415-c4`

## Image Naming Convention

Images follow this pattern:

```
{REGISTRY}/{PROJECT_ID}/{REPOSITORY}/{IMAGE_NAME}:{TAG}
```

Example:
- **Backend:** `us-central1-docker.pkg.dev/elegant-atom-475415-c4/backend/wobot-backend:abc123def456`
- **Frontend:** `us-central1-docker.pkg.dev/elegant-atom-475415-c4/frontend/wobot-frontend:abc123def456`

The git commit SHA ensures:
- ✅ Unique image for every commit
- ✅ Full traceability to source code
- ✅ Easy rollback to previous versions
- ✅ No image conflicts or overwrites

## Workflow Execution Flow

```
┌─────────────────────────────────────────────────┐
│ Push to master branch (backend/ or frontend/)   │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│ 1. Checkout Code                                │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│ 2. Setup Docker Buildx (multi-arch)             │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│ 3. Authenticate to Google Cloud                 │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│ 4. Setup Cloud SDK                              │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│ 5. Configure Docker Registry Auth               │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│ 6. Generate Image Tag (with commit SHA)         │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│ 7. Build & Push Multi-Arch Image                │
│    ├─ linux/amd64                               │
│    └─ linux/arm64                               │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│ 8. Lint Dockerfile (Hadolint)                   │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│ 9. Scan Image (Trivy)                           │
│    └─ Check for vulnerabilities (CVE)           │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│ 10. Generate Report Summary                     │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│ 11. Upload Scan Results (Artifacts)             │
└────────────────┬────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────┐
│ ✅ Workflow Complete                            │
│ Image pushed to Artifact Registry               │
│ Security report available                       │
└─────────────────────────────────────────────────┘
```

## Monitoring and Debugging

### View Workflow Runs
1. Go to **GitHub Repository** → **Actions** tab
2. Click on workflow run to see details
3. View individual step logs
4. Download artifacts (security reports)

### Check Artifact Registry
```bash
# List images in backend repository
gcloud artifacts docker images list us-central1-docker.pkg.dev/PROJECT_ID/backend

# List images in frontend repository
gcloud artifacts docker images list us-central1-docker.pkg.dev/PROJECT_ID/frontend

# View tags for an image
gcloud artifacts docker images describe \
  us-central1-docker.pkg.dev/PROJECT_ID/backend/wobot-backend
```

### Pull and Run Image Locally
```bash
# Configure authentication
gcloud auth configure-docker us-central1-docker.pkg.dev

# Pull image
docker pull us-central1-docker.pkg.dev/PROJECT_ID/backend/wobot-backend:COMMIT_SHA

# Run image
docker run -p 3001:3001 \
  us-central1-docker.pkg.dev/PROJECT_ID/backend/wobot-backend:COMMIT_SHA
```

### Download Security Reports
1. Go to **GitHub Actions** → workflow run
2. Scroll to **Artifacts** section
3. Download `security-scan-results-{backend/frontend}-{SHA}.zip`
4. Extract and review `scan-report.json`

## Troubleshooting

### Workflow Fails at Build Step
**Cause:** Dockerfile issues or missing files
**Solution:**
1. Check Dockerfile syntax: `docker build ./application/backend`
2. Verify file paths in COPY commands
3. Check git commit includes all needed files

### Authentication Failure
**Cause:** Invalid GCP service account credentials
**Solution:**
1. Verify `GCP_SERVICE_ACCOUNT_KEY` secret is set
2. Check service account has `artifactregistry.writer` role
3. Ensure secret is valid JSON

### Multi-arch Build Takes Long Time
**Expected:** First build takes 5-10 minutes (builds two architectures)
**Optimization:** buildx caches layers between runs (subsequent builds faster)

### Trivy Scan Shows Too Many Vulnerabilities
**Options:**
1. Update base image to latest stable version
2. Address high/critical vulnerabilities in application
3. Review and accept known false positives

## Best Practices

### 1. Commit Messages Should Be Descriptive
- Describes what changed
- Helps identify issues later
- SHA will be part of image tag

### 2. Keep Base Images Updated
- Use latest stable versions
- Reduces vulnerability exposure
- Check regularly for updates

### 3. Fix Hadolint Warnings
- Improves Dockerfile efficiency
- Reduces image size
- Follows Docker best practices

### 4. Address Critical Vulnerabilities
- Review Trivy reports
- Update affected dependencies
- Re-run workflow to verify fix

### 5. Use Specific Base Image Versions
- Instead of: `FROM node:latest`
- Use: `FROM node:18.17.1-alpine`
- Ensures reproducible builds

## Related Kubernetes Deployment

Once images are pushed to Artifact Registry, they can be deployed to Kubernetes:

```yaml
containers:
- name: backend
  image: us-central1-docker.pkg.dev/PROJECT_ID/backend/wobot-backend:COMMIT_SHA
  imagePullSecrets:
  - name: gcr-json-key
```

See `kubernetes/README.md` for deployment details.

## Security Considerations

### Multi-Architecture Builds
- ✅ Ensures application runs on Intel and ARM
- ✅ Supports Apple Silicon and ARM servers
- ✅ No performance penalties

### Trivy Vulnerability Scanning
- ✅ Scans base image
- ✅ Scans application dependencies
- ✅ Reports CVEs with severity levels

### Image Immutability
- ✅ Commit SHA ensures immutable tags
- ✅ Easy to roll back to previous versions
- ✅ Full audit trail

## Performance Metrics

### Typical Workflow Execution Times
- **Checkout & Setup:** 30-45 seconds
- **Build & Push (Multi-arch):** 3-5 minutes (first run), 1-2 minutes (cached)
- **Dockerfile Linting:** 5-10 seconds
- **Security Scanning (Trivy):** 30-60 seconds
- **Report & Upload:** 5-10 seconds
- **Total:** 5-8 minutes (first run), 3-5 minutes (subsequent)

### Optimization Tips
1. Reduce Dockerfile layers
2. Use `.dockerignore` to exclude unnecessary files
3. Leverage build cache with layer ordering
4. Consider separate workflows if they're independent

## Next Steps

1. **Setup Secrets:** Add `GCP_SERVICE_ACCOUNT_KEY` and `GCP_PROJECT_ID` to GitHub
2. **Make a Commit:** Push changes to `master` in `application/backend/` or `application/frontend/`
3. **Monitor Workflow:** Check GitHub Actions tab for execution
4. **Review Artifacts:** Download security reports after workflow completes
5. **Deploy:** Use pushed images in Kubernetes deployment

## Support

For issues or improvements:
1. Check workflow logs in GitHub Actions
2. Review Docker build errors
3. Consult Trivy documentation: https://github.com/aquasecurity/trivy
4. Check Hadolint rules: https://github.com/hadolint/hadolint/wiki
