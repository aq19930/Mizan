# MIZAN — Production Deployment Guide: Google Cloud Run, Cloud SQL & Firebase

This comprehensive guide details the step-by-step procedure to deploy the **Mizan** backend to **Google Cloud Run**, connect to **Google Cloud SQL for SQL Server**, integrate **Firebase** and **Google Maps Platform**, and configure the **Flutter** mobile client for production.

---

## 1. Production Architecture Overview

```
Flutter Mobile App (iOS / Android)
        │
        │ HTTPS (Encrypted TLS 1.3)
        ▼
Google Cloud Run (ASP.NET Core .NET 10 Web API)
  ├── Port: 0.0.0.0:8080 (Cloud Run edge SSL termination)
  ├── Middleware: ForwardedHeaders, RateLimiter, GlobalExceptionHandler
  ├── Health Endpoint: GET /health (Returns {"status": "Healthy"})
  ├── Protected Job Endpoints: POST /internal/jobs/* (Guarded with X-Internal-Token)
        │
        ├── Reads Secrets ──► Google Secret Manager
        ├── SQL Connection (TCP Proxy / Encrypted) ──► Google Cloud SQL (SQL Server 2022)
        ├── Push Notifications ──► Firebase Cloud Messaging (FCM HTTP v1)
        └── AI Financial Advisor ──► Google Gemini API
```

---

## 2. Prerequisites & Environment Setup

Ensure you have:
1. A Google Cloud account with an active billing account.
2. The Google Cloud SDK (`gcloud` CLI) installed on your management machine:
   ```bash
   gcloud --version
   ```
3. Authenticate and set your target project ID:
   ```bash
   gcloud auth login
   gcloud config set project YOUR_PROJECT_ID
   ```

---

## 3. Enable Required Google Cloud APIs

Execute the following command to enable all necessary service APIs:

```bash
gcloud services enable \
    run.googleapis.com \
    sqladmin.googleapis.com \
    artifactregistry.googleapis.com \
    secretmanager.googleapis.com \
    cloudscheduler.googleapis.com \
    cloudbuild.googleapis.com
```

---

## 4. Google Artifact Registry Setup

Create an Artifact Registry Docker repository in your preferred region (e.g., `me-central1` for Saudi Arabia / Middle East, or `europe-west1`):

```bash
# Variables
export REGION="me-central1"
export PROJECT_ID="YOUR_PROJECT_ID"
export REPO_NAME="mizan"
export IMAGE_NAME="mizan-api"
export TAG="v1.0.0"

# Create repository
gcloud artifacts repositories create $REPO_NAME \
    --repository-format=docker \
    --location=$REGION \
    --description="Mizan Production Docker Repository"

# Configure Docker authentication
gcloud auth configure-docker ${REGION}-docker.pkg.dev
```

### Building and Pushing Container Image

#### Option A: Google Cloud Build (Recommended — No local Docker required)
From the repository root:
```bash
gcloud builds submit --tag ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:${TAG} .
```

#### Option B: Local Docker Build
```bash
docker build -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:${TAG} .
docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:${TAG}
```

---

## 5. Google Cloud SQL (SQL Server) Provisioning

### 5.1 Create Cloud SQL Instance
For cost-effective production startup, select `db-custom-2-7680` (or `db-custom-2-8192`) with SQL Server 2022 Standard or Web edition:

```bash
export DB_INSTANCE_NAME="mizan-sql-prod"

gcloud sql instances create $DB_INSTANCE_NAME \
    --database-version=SQLSERVER_2022_STANDARD \
    --tier=db-custom-2-8192 \
    --region=$REGION \
    --storage-type=SSD \
    --storage-size=20GB \
    --storage-auto-increase \
    --backup \
    --start-time=02:00 \
    --retained-backups-count=7 \
    --retained-transaction-log-days=7 \
    --root-password="YOUR_STRONG_SQL_SA_PASSWORD"
```

> [!CAUTION]
> Do **NOT** expose `0.0.0.0/0` in authorized networks. Cloud Run connects natively to Cloud SQL using the Cloud SQL Auth Proxy integration (`--add-cloudsql-instances`).

### 5.2 Create Database (`MizanDb`)
```bash
gcloud sql databases create MizanDb --instance=$DB_INSTANCE_NAME
```

### 5.3 Create Dedicated Application User (Least Privilege)
Never connect the API as `sa` (system administrator). Create a dedicated application user:

```bash
gcloud sql users create mizan_app \
    --instance=$DB_INSTANCE_NAME \
    --password="YOUR_STRONG_APP_USER_PASSWORD"
```

---

## 6. Google Secret Manager Setup

Decouple all secrets from application configuration. Create each required secret:

```bash
# 1. Connection string
# Note: Cloud SQL connector on Cloud Run exposes SQL Server on 127.0.0.1:1433
echo -n "Server=127.0.0.1;Database=MizanDb;User Id=mizan_app;Password=YOUR_STRONG_APP_USER_PASSWORD;Encrypt=True;TrustServerCertificate=True;Max Pool Size=50;Min Pool Size=5;Connection Timeout=30;" | \
gcloud secrets create ConnectionStrings__DefaultConnection --data-file=-

# 2. JWT Signing Key (64+ character random string)
echo -n "YOUR_LONG_RANDOM_HMAC_SHA256_JWT_SECRET_KEY_MINIMUM_64_CHARACTERS" | \
gcloud secrets create Jwt__Key --data-file=-

# 3. Gemini AI API Key
echo -n "YOUR_GEMINI_API_KEY" | \
gcloud secrets create AI__ApiKey --data-file=-

# 4. Internal Scheduled Jobs Token (used by Cloud Scheduler)
echo -n "YOUR_STRONG_RANDOM_INTERNAL_JOBS_SECRET" | \
gcloud secrets create Jobs__InternalSecret --data-file=-

# 5. Firebase Credentials (Service Account JSON string)
gcloud secrets create Firebase__CredentialsJson \
    --data-file=/path/to/firebase-adminsdk-service-account.json
```

### Grant Cloud Run Service Account Access to Secrets
Find your Cloud Run service account (or compute default service account: `PROJECT_NUMBER-compute@developer.gserviceaccount.com`):

```bash
export SERVICE_ACCOUNT="PROJECT_NUMBER-compute@developer.gserviceaccount.com"

# Grant Secret Accessor role
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SERVICE_ACCOUNT}" \
    --role="roles/secretmanager.secretAccessor"

# Grant Cloud SQL Client role
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SERVICE_ACCOUNT}" \
    --role="roles/cloudsql.client"
```

---

## 7. Database Migration Strategy

> [!IMPORTANT]
> Never execute schema migrations automatically on normal Cloud Run web container start. When instances scale out, concurrent `EnsureCreated()` or `Migrate()` calls can race and corrupt production schema.

### Option A: Cloud Run Job (Recommended for Automated Pipelines)
Create a dedicated migration job using the same container image with `RUN_MIGRATIONS=true`:

```bash
# Create migration job
gcloud run jobs create mizan-db-migrate \
    --image=${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:${TAG} \
    --region=$REGION \
    --set-env-vars=RUN_MIGRATIONS=true \
    --set-secrets=ConnectionStrings__DefaultConnection=ConnectionStrings__DefaultConnection:latest \
    --add-cloudsql-instances=${PROJECT_ID}:${REGION}:${DB_INSTANCE_NAME}

# Execute migration job
gcloud run jobs execute mizan-db-migrate --region=$REGION --wait
```

### Option B: Local EF Core Update via Cloud SQL Proxy
From your local workstation with Cloud SQL Auth Proxy running:
```bash
cloud-sql-proxy ${PROJECT_ID}:${REGION}:${DB_INSTANCE_NAME} --port 1433 &
dotnet tool run dotnet-ef database update --project src/Mizan.Infrastructure --startup-project src/Mizan.Infrastructure --connection "Server=127.0.0.1;Database=MizanDb;User Id=mizan_app;Password=YOUR_APP_PASSWORD;Encrypt=True;TrustServerCertificate=True;"
```

---

## 8. Deploy Backend to Google Cloud Run

Deploy the ASP.NET Core API service to Cloud Run:

```bash
export SERVICE_NAME="mizan-api"

gcloud run deploy $SERVICE_NAME \
    --image=${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:${TAG} \
    --platform=managed \
    --region=$REGION \
    --port=8080 \
    --memory=1Gi \
    --cpu=1 \
    --min-instances=0 \
    --max-instances=10 \
    --concurrency=80 \
    --timeout=60s \
    --allow-unauthenticated \
    --add-cloudsql-instances=${PROJECT_ID}:${REGION}:${DB_INSTANCE_NAME} \
    --set-env-vars=ASPNETCORE_ENVIRONMENT=Production,AI__Provider=Gemini,Firebase__ProjectId=mizan-finance-sa \
    --set-secrets="ConnectionStrings__DefaultConnection=ConnectionStrings__DefaultConnection:latest,Jwt__Key=Jwt__Key:latest,AI__ApiKey=AI__ApiKey:latest,Jobs__InternalSecret=Jobs__InternalSecret:latest,Firebase__CredentialsJson=Firebase__CredentialsJson:latest"
```

### Scaling & Cost Trade-off:
- `--min-instances=0`: **Zero cost** when idle; instances spin down completely. Cold starts take ~1.5 to 2.5 seconds on first request.
- `--min-instances=1`: **Instant responsiveness**; keeps 1 warm instance continuously running (~$15–$25/month depending on region and memory).

### Verify Service Health
Retrieve the Cloud Run URL and test the health endpoint:

```bash
export SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --platform managed --region $REGION --format 'value(status.url)')
echo "Service URL: $SERVICE_URL"

# Test /health probe
curl -i "${SERVICE_URL}/health"
# Expected response: HTTP/2 200 OK -> {"status":"Healthy"}

# Test system version info
curl -i "${SERVICE_URL}/api/system/version"
```

---

## 9. Google Cloud Scheduler Setup (Background Jobs)

Cloud Run container instances can spin down when idle. Background schedules are reliably triggered via Google Cloud Scheduler targeting the secured internal endpoints.

### 9.1 Daily Financial Summary Job
Triggers every evening at 21:00 (9:00 PM AST / Riyadh time):

```bash
gcloud scheduler jobs create http mizan-daily-summary \
    --location=$REGION \
    --schedule="0 21 * * *" \
    --time-zone="Asia/Riyadh" \
    --uri="${SERVICE_URL}/internal/jobs/daily-summary" \
    --http-method=POST \
    --headers="X-Internal-Token=YOUR_STRONG_RANDOM_INTERNAL_JOBS_SECRET"
```

### 9.2 Upcoming Commitment Reminders Job
Triggers every morning at 09:00 AM AST:

```bash
gcloud scheduler jobs create http mizan-commitment-reminders \
    --location=$REGION \
    --schedule="0 9 * * *" \
    --time-zone="Asia/Riyadh" \
    --uri="${SERVICE_URL}/internal/jobs/commitment-reminders" \
    --http-method=POST \
    --headers="X-Internal-Token=YOUR_STRONG_RANDOM_INTERNAL_JOBS_SECRET"
```

---

## 10. Flutter Mobile Client Production Configuration

The Flutter app supports dynamic environment switching via `ApiConfig` in `mobile/lib/core/config/api_config.dart`.

### 10.1 Compile Production APK
Build the release APK specifying the Cloud Run production base URL:

```bash
cd mobile

flutter build apk --release \
    --dart-define=MIZAN_ENV=prod \
    --dart-define=API_BASE_URL="${SERVICE_URL}/api"
```

### 10.2 Compile Production App Bundle (.aab for Google Play)
```bash
flutter build appbundle --release \
    --dart-define=MIZAN_ENV=prod \
    --dart-define=API_BASE_URL="${SERVICE_URL}/api"
```

### 10.3 Firebase App Distribution for Testers
Upload the release APK to Firebase App Distribution for internal testing:
```bash
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
    --app YOUR_FIREBASE_ANDROID_APP_ID \
    --groups "mizan-testers" \
    --release-notes "MIZAN v1.0.0 Production Cloud Run Release"
```

---

## 11. Rollback Strategy

If a newly deployed Cloud Run revision introduces an issue, rollback takes seconds by shifting traffic to the previous healthy revision:

```bash
# List revisions
gcloud run revisions list --service=$SERVICE_NAME --region=$REGION

# Route 100% traffic immediately to the previous revision
gcloud run services update-traffic $SERVICE_NAME \
    --region=$REGION \
    --to-revisions=PREVIOUS_REVISION_NAME=100
```

---

## 12. Manual Production Deployment Checklist

| Status | Task |
| :---: | :--- |
| [ ] | Google Cloud project created with active billing. |
| [ ] | Required APIs enabled (`run`, `sqladmin`, `artifactregistry`, `secretmanager`, `cloudscheduler`). |
| [ ] | Artifact Registry repository `mizan` created. |
| [ ] | Cloud SQL SQL Server instance created (`mizan-sql-prod`) with automated backups enabled. |
| [ ] | `MizanDb` database and dedicated `mizan_app` database user created. |
| [ ] | Secrets added to Secret Manager (`ConnectionStrings__DefaultConnection`, `Jwt__Key`, `AI__ApiKey`, `Jobs__InternalSecret`, `Firebase__CredentialsJson`). |
| [ ] | Service account granted `secretmanager.secretAccessor` and `cloudsql.client` roles. |
| [ ] | Docker image built and pushed via Cloud Build / local Docker. |
| [ ] | Initial EF Core migration applied (`InitialCreate`). |
| [ ] | Cloud Run service `mizan-api` deployed with `--add-cloudsql-instances` and `--set-secrets`. |
| [ ] | Health probe `GET /health` verified returning `{"status": "Healthy"}`. |
| [ ] | Cloud Scheduler jobs created for Daily Summary (21:00 AST) and Commitment Reminders (09:00 AST). |
| [ ] | Flutter mobile app compiled with `--dart-define=API_BASE_URL=https://<SERVICE_URL>/api`. |
| [ ] | Tested end-to-end on Android device: Login, Register, Transactions, Budgets, AI Advisor, FCM Token registration. |
