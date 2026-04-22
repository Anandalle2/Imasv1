# 🚗 IMAS Full System Architecture Guide
### Intelligent Monitoring for Advanced Safety — AWS Cloud Backend

---

## 🧭 Overview

Your IMAS system has **6 major layers**. Below is everything you need to build, what you need to use, and what can be done at each layer.

---

## 📐 Full Data Flow

```
[Vehicle Device — RK3588]
        │
        │  MQTT over TLS 1.2  (X.509 Certs)
        ▼
[AWS IoT Core]
        │
        │  Rules Engine (Topic: vehicle/+/data)
        ├──────────────────────────────┐
        ▼                              ▼
[DynamoDB — Telemetry]       [Lambda → SNS Alerts]
        │                              │
        ▼                              ▼
[Kinesis Video Streams]       [Alert Service (ECS)]
        │
        ▼
[ECS Fargate Microservices]
        │
        ▼
[API Gateway (REST / JWT)]
        │
        ▼
[Flutter App / Web Dashboard]
```

---

## 🔧 LAYER 1 — Edge (Vehicle Device)

### Hardware
| Component | Purpose |
|-----------|---------|
| **RK3588 SoC** | AI inference (drowsiness, collision) |
| **2× Cameras** | Driver-facing + Road-facing |
| **GPS Module** | Real-time location (lat/lng) |
| **IMU Sensor** | Acceleration, gyroscope |
| **CAN Bus** | Vehicle speed, RPM, fuel level |

### What Can Be Done
- Run **YOLO / MediaPipe** locally for real-time detection
- Send telemetry every **5 seconds** via **MQTT**
- Use **TFLite / TensorRT** for on-device AI (keep latency < 100ms)
- Buffer data locally if internet drops → sync on reconnect

### Tools You Need
- `paho-mqtt` (Python MQTT client)
- AWS IoT Device SDK v2 (for certificate-based auth)
- OpenCV + YOLO (on-device inference)
- Edge buffer storage: SQLite or flat file

---

## 🔧 LAYER 2 — Ingestion (AWS IoT Core)

### What It Does
- Authenticates your device using **X.509 certificates** (one per vehicle)
- Routes all incoming MQTT messages via **Rules Engine**

### Rules You Need to Create

| Rule | Topic Filter | Action |
|------|-------------|--------|
| Telemetry Rule | `vehicle/+/data` | → Write to **DynamoDB** |
| Alert Rule | `vehicle/+/alerts` | → Trigger **Lambda** → **SNS** |
| Video Metadata | `vehicle/+/video` | → Lambda → Kinesis |

### What Can Be Done
- Register devices securely with **AWS IoT Thing Registry**
- Use **Fleet Provisioning** for bulk device onboarding
- Set up **Shadow Documents** per vehicle (last known state)

### Tools You Need
- AWS IoT Core (managed, no server)
- AWS Certificate Manager (for X.509 certs)
- IoT Policy JSON (per device)

---

## 🔧 LAYER 3 — Processing (Lambda + Kinesis)

### Lambda Functions

| Function | Trigger | Job |
|---------|---------|-----|
| `alert-processor` | IoT Rule | Parse alert → write to RDS → push SNS notification |
| `video-metadata` | IoT Rule | Log video chunk info |
| `report-generator` | Scheduled (CloudWatch) | Daily driver score report |

### Kinesis Video Streams
- **Fragment Duration**: 2 seconds
- **Retention**: 24 hours (live playback)
- **Archive to S3**: after 24h (for history)
- Viewer accesses via **HLS / DASH** stream URL

### What Can Be Done
- Real-time **drowsiness alert** pushed to driver via SNS (SMS/email)
- Video timestamps aligned with alert events (click alert → jump to video)
- Serverless — no servers to manage

### Tools You Need
- AWS Lambda (Node.js or Python runtime)
- Amazon Kinesis Video Streams SDK
- Amazon SNS (SMS + Push notifications)
- AWS CloudWatch Events (scheduling)

---

## 🔧 LAYER 4 — Compute (ECS Fargate Microservices)

### Services to Build

#### 1. 🔐 Auth Service
```
POST /auth/login       → returns JWT token
POST /auth/signup      → creates user in RDS
POST /auth/refresh     → refresh token
```

#### 2. 🚗 Vehicle Service
```
POST /vehicle/register          → new vehicle
GET  /vehicle/{id}              → vehicle detail
GET  /vehicle/list              → all vehicles for user
PATCH /vehicle/{id}/status      → update status
```

#### 3. 📹 Video Service
```
GET /video/live/{vehicle_id}    → returns HLS stream URL
GET /video/history?date=...     → S3 signed URLs
```

#### 4. 🚨 Alert Service
```
GET  /alerts/{vehicle_id}       → fetch alerts
POST /alerts/acknowledge/{id}   → mark as read
```

#### 5. 📊 Analytics Service
```
GET /analytics/driver-score/{id}
GET /analytics/reports
GET /analytics/trips/{vehicle_id}
```

### Fargate Config

| Setting | Value |
|---------|-------|
| CPU | 512–1024 units |
| Memory | 1–2 GB |
| Min containers | 2 |
| Max containers | 20 |
| Scale trigger | CPU > 60% |

### What Can Be Done
- Each service deployed as **separate Docker container**
- Independent scaling (Alert service can scale separately from Video)
- Use **internal service mesh** (App Mesh or direct VPC calls)
- Use **gRPC** between services for high-speed internal calls

### Tools You Need
- Docker (containerize each service)
- AWS ECR (store Docker images)
- AWS ECS with Fargate launch type
- AWS App Mesh (optional, for service-to-service routing)

---

## 🔧 LAYER 5 — Storage

### DynamoDB (Telemetry — Hot Data)

| Field | Type | Notes |
|-------|------|-------|
| `vehicle_id` | PK (String) | Partition key |
| `timestamp` | SK (Number) | Sort key (epoch ms) |
| `speed` | Number | km/h |
| `latitude` | Number | |
| `longitude` | Number | |
| `driver_state` | String | `alert`, `drowsy`, `sleeping` |
| `fuel_level` | Number | % |
| **TTL** | auto | 7–30 days (auto delete old rows) |

### RDS PostgreSQL (Relational — Cold/Business Data)

```sql
-- Users
user_id UUID PK | name | email | phone | password_hash | role | created_at

-- Vehicles
vehicle_id UUID PK | user_id FK | device_id | model | plate | status | created_at

-- Trips
trip_id UUID PK | vehicle_id FK | start_time | end_time | distance | avg_speed

-- Alerts
alert_id UUID PK | vehicle_id | type | severity | timestamp | acknowledged | video_timestamp
```

### S3 (Video + Reports)

```
Bucket: imas-videos-prod/
  ├── videos/{vehicle_id}/{date}/{hour}/clip_{ts}.mp4
  └── reports/{user_id}/{month}/driver_report.pdf

Lifecycle:
  - 0–30 days  → Standard (hot)
  - 30–90 days → Glacier (cold archive)
  - 90+ days   → Deep Archive (very cheap)
```

### What Can Be Done
- Query last 24h telemetry from DynamoDB (fast, cheap)
- Run historical trip reports from RDS
- Download/stream video clips from S3 signed URLs
- TTL on DynamoDB saves cost automatically

---

## 🔧 LAYER 6 — Delivery (API Gateway + CloudFront)

### API Gateway Setup
- **Type**: REST API (or HTTP API for lower cost)
- **Rate Limit**: 1000 req/sec
- **Authentication**: JWT Authorizer (verifies on every request)
- **CORS**: Enabled (for web frontend)
- **Stages**: `dev`, `staging`, `prod`

### CloudFront (Optional but Recommended)
- CDN for the web dashboard
- Cache video stream manifests at edge
- Reduces latency for global users

---

## 🛠️ CI/CD Pipeline

```
Developer → GitHub Push
        ↓
AWS CodePipeline (triggered by main branch)
        ↓
CodeBuild:
  ✅ Build Docker image
  ✅ Run unit tests
  ✅ Security scan (ECR image scanning)
        ↓
Push → AWS ECR (container registry)
        ↓
Deploy → ECS Fargate (rolling update)
        ↓
Zero-downtime deployment ✅
```

### Environments
| Env | Branch | Purpose |
|-----|--------|---------|
| `dev` | `develop` | Active development |
| `staging` | `staging` | QA testing |
| `prod` | `main` | Live production |

### What You Need to Set Up
- GitHub repo with branch protection rules
- `buildspec.yml` for CodeBuild
- `task-definition.json` for ECS
- AWS Secrets Manager for all API keys / DB passwords
- CloudWatch dashboards for monitoring

---

## 📱 Flutter Frontend (Your IMAS App)

### What's Already There (from your workspace)
- `login_screen.dart` — Auth UI
- `home_screen.dart` — Dashboard
- `map_screen.dart` — GPS/Map tracking
- `profile_screen.dart` — Driver/owner profile
- `owner_profile_saving_screen.dart` — Profile management

### What To Connect Next

| Screen | API to Call | Data Source |
|--------|------------|-------------|
| Login | `POST /auth/login` | RDS via Auth Service |
| Home Dashboard | `GET /vehicle/list` | Vehicle Service |
| Map Screen | `GET /telemetry/live/{id}` | DynamoDB (WebSocket or polling) |
| Alerts | `GET /alerts/{vehicle_id}` | Alert Service |
| Video | `GET /video/live/{id}` | Kinesis HLS URL |
| Analytics | `GET /analytics/driver-score` | Analytics Service |

### Real-time Telemetry Strategy
Use **WebSocket via API Gateway** or **MQTT direct from device** for live GPS/speed updates in the Flutter map screen.

---

## ✅ What Can Be Done — Priority Roadmap

### 🟥 Phase 1 — Foundation (Do First)
- [ ] Set up AWS IoT Core → register devices + certificates
- [ ] DynamoDB table for telemetry (vehicle_id + timestamp)
- [ ] Auth Service (JWT login) + RDS Users table
- [ ] Vehicle Service + Vehicles table

### 🟧 Phase 2 — Core Features
- [ ] Alert Service + Lambda → SNS (drowsy/collision alerts)
- [ ] Kinesis Video Streams integration (live feed)
- [ ] Map Screen → real-time GPS polling from DynamoDB
- [ ] S3 video storage + lifecycle rules

### 🟨 Phase 3 — Analytics + CI/CD
- [ ] Analytics Service (driver score, trip reports)
- [ ] CI/CD pipeline (GitHub → CodePipeline → ECS)
- [ ] CloudWatch monitoring dashboards
- [ ] Separate dev/staging/prod environments

### 🟩 Phase 4 — Polish
- [ ] CloudFront CDN for frontend
- [ ] gRPC internal service communication
- [ ] Fleet provisioning for bulk device onboarding
- [ ] Automated PDF report generation

---

## 💰 Estimated AWS Cost (Monthly — Small Fleet ~10 Vehicles)

| Service | Estimated Cost |
|---------|---------------|
| AWS IoT Core | ~$5–10 |
| DynamoDB (On-demand) | ~$10–20 |
| RDS db.t3.medium (Multi-AZ) | ~$80–100 |
| ECS Fargate (2 containers) | ~$30–50 |
| Kinesis Video Streams | ~$15–25 |
| S3 + Glacier | ~$5–10 |
| Lambda + SNS | ~$1–5 |
| API Gateway | ~$5–10 |
| **Total (estimate)** | **~$150–230/month** |

---

## 🧰 Complete Tools & Services Checklist

### AWS Services
- [x] AWS IoT Core
- [x] AWS Lambda
- [x] Amazon DynamoDB
- [x] Amazon RDS (PostgreSQL)
- [x] Amazon S3
- [x] Amazon Kinesis Video Streams
- [x] Amazon SNS
- [x] Amazon ECS (Fargate)
- [x] Amazon ECR
- [x] AWS CodePipeline + CodeBuild
- [x] AWS API Gateway
- [x] AWS CloudFront
- [x] AWS Secrets Manager
- [x] AWS CloudWatch

### Development Tools
- [x] Docker (containerize microservices)
- [x] GitHub (source control)
- [x] Node.js or Python (backend services)
- [x] Flutter (frontend — already in progress)
- [x] Postman (API testing)
- [x] Terraform or AWS CDK (infrastructure as code — optional but recommended)

---

## 🧠 Key Recommendations

> [!IMPORTANT]
> **Start with IoT Core + DynamoDB + Auth Service.** These are the backbone. Everything else depends on them.

> [!TIP]
> Use **AWS CDK (TypeScript)** to define all your infrastructure as code. This makes it easy to replicate dev/staging/prod environments.

> [!WARNING]
> **Never hardcode credentials** in your Flutter app or Docker images. Always use AWS Secrets Manager + environment variables.

> [!NOTE]
> Your Flutter app already has login, map, and profile screens. Focus backend effort on connecting real APIs to these screens — the UI is ahead of the backend right now.
