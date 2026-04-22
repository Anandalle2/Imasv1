# 📐 IMAS System Architecture Diagrams
This document contains the structural, behavioral, and interaction diagrams for the IMAS (Intelligent Monitoring for Advanced Safety) platform, using your target AWS architecture.

---

## 1. System Architecture Block Diagram (The 6 Layers)
This diagram illustrates the full end-to-end data flow from the edge device (vehicle) through the AWS cloud layers to the end-user applications.

```mermaid
flowchart TD
    %% Define Layers
    subgraph Layer1[1. Edge Layer]
        RK[RK3588 Device]
        Cams[Driver & Road Cameras]
        Sensors[GPS, IMU, CAN Bus]
        RK --- Cams
        RK --- Sensors
    end

    subgraph Layer2[2. Ingestion Layer]
        IoT[AWS IoT Core]
        Rules[IoT Rules Engine]
        IoT --> Rules
    end

    subgraph Layer3[3. Processing Layer]
        Lambda[AWS Lambda]
        KVS[Kinesis Video Streams]
    end

    subgraph Layer4[4. Compute / Microservices Layer]
        ECS[ECS Fargate Microservices]
        AuthSvc[Auth Service]
        VehSvc[Vehicle Service]
        VidSvc[Video Service]
        AlertSvc[Alert Service]
        AnalytSvc[Analytics Service]
        
        ECS --- AuthSvc
        ECS --- VehSvc
        ECS --- VidSvc
        ECS --- AlertSvc
        ECS --- AnalytSvc
    end

    subgraph Layer5[5. Storage Layer]
        DDB[(DynamoDB - Telemetry)]
        RDS[(RDS PostgreSQL - Users/Auth)]
        S3[(S3 - Video Archiving)]
    end

    subgraph Layer6[6. Delivery Layer]
        API[API Gateway]
        CDN[CloudFront CDN]
    end

    subgraph Users[End Users]
        App[Flutter Mobile App]
        Web[Web Dashboard]
    end

    %% Connections
    RK -- "MQTT over TLS 1.2" --> IoT
    Rules -- "Telemetry Data" --> DDB
    Rules -- "Alerts" --> Lambda
    Rules -- "Video Streams" --> KVS
    
    Lambda -- "Process Alerts" --> AlertSvc
    Lambda -- "Push Notifications" --> SNS((AWS SNS))
    SNS -.-> App
    
    KVS -- "Archive" --> S3
    
    AuthSvc <--> RDS
    VehSvc <--> RDS
    AlertSvc <--> RDS
    AnalytSvc <--> DDB
    VidSvc <--> KVS
    
    API <--> ECS
    CDN <--> API
    
    App <--> API
    Web <--> CDN
```

---

## 2. System Use Case Diagram
Shows the primary actors interacting with the IMAS system and the standard operations they perform.

```mermaid
flowchart LR
    %% Actors
    Owner[👤 Fleet Owner]
    Driver[👤 Driver]
    System[🤖 RK3588 Edge Device]

    %% System Boundary
    subgraph IMAS_Platform[IMAS Platform]
        UC1((Register Vehicle))
        UC2((View Live Fleet Map))
        UC3((Acknowledge Alerts))
        UC4((View Trip History))
        UC5((Monitor Driver Behavior))
        UC6((Receive Push Notifications))
        
        UC7((Transmit Telemetry))
        UC8((Trigger SOS Alert))
        UC9((Stream Video))
    end

    %% Fleet Owner Relationships
    Owner --> UC1
    Owner --> UC2
    Owner --> UC3
    Owner --> UC4
    Owner --> UC5
    Owner --> UC6

    %% Driver Relationships
    Driver --> UC8
    Driver --> UC4
    
    %% Edge Device Auto-Relationships
    System --> UC7
    System --> UC8
    System --> UC9
```

---

## 3. Sequence Diagram: Real-Time Telemetry Flow
This sequence maps exactly what happens when the RK3588 device transmits vehicle speed, fuel, and GPS location.

```mermaid
sequenceDiagram
    participant Vehicle as RK3588 Node
    participant IoTCore as AWS IoT Core
    participant Rule as IoT Rules Engine
    participant DB as DynamoDB
    participant API as API Gateway + ECS
    participant App as Flutter Frontend

    Vehicle->>IoTCore: Publish MQTT (topic: vehicle/{id}/data) [JSON Telemetry]
    IoTCore->>Rule: Intercept message based on Topic Rules
    Rule->>DB: Write Record (vehicle_id, timestamp, speed, lat, lng)
    
    loop Every 5 Seconds
    App->>API: GET /telemetry/live/{vehicle_id} (or via WebSocket)
    API->>DB: Query latest telemetry record where vehicle_id = X
    DB-->>API: Return latest JSON data
    API-->>App: Return 200 OK + JSON
    App-->>App: Update Map Marker & Speedometer UI
    end
```

---

## 4. Sequence Diagram: Critical SOS / Collision Alert Handling
This sequence shows the critical path when an emergency event (like drowsy driver or physical collision) is detected.

```mermaid
sequenceDiagram
    participant Edge as RK3588 Node (AI)
    participant IoTCore as AWS IoT Core
    participant Lambda as AWS Lambda
    participant SNS as AWS SNS (Push)
    participant RDS as RDS (Postgres)
    participant App as Flutter Frontend

    Note over Edge: YOLO detects collision/drowsiness
    Edge->>IoTCore: Publish MQTT (topic: vehicle/{id}/alerts) [Type: Critical]
    IoTCore->>Lambda: Trigger Alert Processor Function
    
    par Parallel Execution
        Lambda->>RDS: Insert Alert Log (severity, type, vehicle_id)
        Lambda->>SNS: Trigger Urgent Push Notification Topic
    end
    
    SNS-->>App: Deliver FCM Push Notification Payload (Wake app)
    App-->>App: Display Full-Screen Red SOS Dialog overlay
    
    Note over App: Fleet Owner is alerted instantly
    App->>App: User presses "Acknowledge"
    App->>RDS: PATCH /alerts/acknowledge/{alert_id}
```

---

## 5. Current "As-Is" Data Flow Diagram (Firebase Setup)
Since your app currently relies strictly on Firebase (as analyzed previously), here is how the architecture looks **right now** before the AWS migration.

```mermaid
flowchart TD
    subgraph Mobile Apps
        Flutter[IMAS Flutter App]
    end

    subgraph Google Cloud / Firebase
        Auth[Firebase Auth]
        Store[Cloud Firestore]
        FCM[Firebase Cloud Messaging]
    end

    subgraph Future Hardware Edge
        RK[RK3588 Device\n(Not Connected Yet)]
    end

    %% Login & Registration
    Flutter <-->|1. Email/Google Auth| Auth

    %% Live Subscriptions
    Flutter <-->|2. Stream Vehicles\n(telemetry.speed/lat)| Store
    Flutter <-->|3. Stream safety_alerts| Store

    %% FCM
    Flutter -->|4. Save FCM Token| Store
    FCM -.-x|5. Push Notification\n(No trigger yet)| Flutter

    %% Hardware
    RK -.->|Missing Link:\nNeeds Python script to update Firestore natively| Store

    classDef future stroke-dasharray: 5 5, fill:#222, stroke:#aaa;
    class RK future;
```

---

## 6. Project Implementation Sequence Diagram (Roadmap to Completion)
This sequence diagram shows the step-by-step execution required by the developer and devops team to build, connect, and finalize the blocks from the architecture to complete the project.

```mermaid
sequenceDiagram
    actor Developer
    participant RK3588 as RK3588 Edge (Layer 1)
    participant AWS as AWS Setup (Layers 2/3/5)
    participant Backend as Microservices (Layer 4/6)
    participant Flutter as Flutter App (Frontend)

    Note over Developer, Flutter: Phase 1: Edge & Ingestion Setup
    Developer->>AWS: Create AWS IoT Core Things & Certificates
    Developer->>AWS: Provision DynamoDB Telemetry Table
    Developer->>RK3588: Install IoT SDK & Configure TLS Certs
    RK3588->>AWS: Test MQTT connection pushing dummy telemetry
    
    Note over Developer, Flutter: Phase 2: Processing & Alerts
    Developer->>AWS: Create IoT Rules (Route MQTT -> DynamoDB)
    Developer->>AWS: Deploy Lambda Function for SOS Alerts
    Developer->>RK3588: Integrate YOLO/MediaPipe AI script w/ MQTT
    RK3588->>AWS: Send real AI-detected Alerts via MQTT
    AWS->>AWS: Lambda pushes alert to AWS SNS
    
    Note over Developer, Flutter: Phase 3: Microservices & API
    Developer->>Backend: Build Go/Node.js API Microservices (Auth, Vehicle, Alerts)
    Developer->>Backend: Dockerize Microservices
    Developer->>AWS: Setup ECS Fargate & Deploy Containers
    Developer->>AWS: Configure API Gateway to route to ECS
    Backend->>AWS: Services read from RDS & DynamoDB
    
    Note over Developer, Flutter: Phase 4: Frontend Integration & Finalization
    Developer->>Flutter: Migrate from Firebase Auth to API Gateway JWT
    Developer->>Flutter: Update Map & Dashboard to fetch API Gateway endpoints
    Flutter->>Backend: Request Telemetry & Alert History
    Developer->>RK3588: Deploy Kinesis Video Stream script
    Developer->>Flutter: Integrate AWS IVS/HLS video player for live feed
    
    Note over Developer, Flutter: Project Completed! System fully operational on AWS.
```
