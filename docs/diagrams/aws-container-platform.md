# AWS container platform diagram

These diagrams describe the public-safe AWS/Terraform architecture modeled by this repository. They are text/Mermaid diagrams only; they do not contain private hostnames, real account identifiers, real resource names from private systems, credentials, Terraform state, or screenshots.

See [the architecture guide](../architecture.md) for the narrative version.

## High-level platform

```mermaid
flowchart TB
  Client[Public clients]
  CI[Validation-only CI]
  Reviewer[Human reviewer]

  subgraph Repo[Public repository]
    TF[Terraform modules and environments]
    Docs[Architecture and service docs]
    Guardrails[Public-safety and no-mutation guardrails]
  end

  subgraph AWS[User-owned AWS account if manually provisioned]
    subgraph VPC[Environment VPC]
      subgraph Public[Public subnets]
        ALB[Application Load Balancer]
        IGW[Internet gateway]
        NAT[Optional NAT gateway]
      end

      subgraph PrivateServices[Private ECS service subnets]
        Cluster[ECS cluster]
        Carbon[carbon-platform-api]
        Jobs[job-runner-platform]
        SaaS[multi-tenant-saas-api]
      end

      subgraph PrivateData[Private data subnets]
        Postgres[(RDS PostgreSQL)]
        Redis[(Optional Redis or Valkey cache)]
      end
    end

    Secrets[AWS Secrets Manager reference containers]
    IAM[IAM task execution role and task role]
    CW[CloudWatch logs metrics dashboards alarms]
  end

  Reviewer --> Repo
  Repo --> CI
  CI --> Guardrails
  TF -. optional manual user-owned provisioning .-> AWS
  Client --> ALB
  ALB -->|listener rules and target groups| Carbon
  ALB -->|listener rules and target groups| Jobs
  ALB -->|listener rules and target groups| SaaS
  Cluster --> Carbon
  Cluster --> Jobs
  Cluster --> SaaS
  Carbon --> Postgres
  SaaS --> Postgres
  Jobs -. optional queue coordination .-> Redis
  SaaS -. optional session or tenant cache .-> Redis
  IAM -. execution and runtime permissions .-> Cluster
  Secrets -. ARN references for ECS injection .-> Cluster
  ALB -. metrics .-> CW
  Cluster -. logs and metrics .-> CW
  Postgres -. metrics .-> CW
```

## Network layout

```mermaid
flowchart LR
  subgraph VPC[One VPC per environment]
    subgraph PublicA[Public subnet A]
      ALBA[ALB node]
      NATA[Optional NAT gateway]
    end
    subgraph PublicB[Public subnet B]
      ALBB[ALB node]
    end
    subgraph PublicC[Public subnet C in prod]
      ALBC[ALB node]
    end

    subgraph PrivateA[Private subnet A]
      TaskA[Fargate tasks]
      RDSA[RDS placement]
      RedisA[Cache placement]
    end
    subgraph PrivateB[Private subnet B]
      TaskB[Fargate tasks]
      RDSB[RDS placement]
      RedisB[Cache placement]
    end
    subgraph PrivateC[Private subnet C in prod]
      TaskC[Fargate tasks]
      RDSC[RDS placement]
      RedisC[Cache placement]
    end
  end

  Internet[Internet] --> IGW[Internet gateway]
  IGW --> PublicA
  IGW --> PublicB
  IGW --> PublicC
  PublicA --> PrivateA
  PublicB --> PrivateB
  PublicC --> PrivateC
```

`dev` uses two public/private subnet pairs and disables NAT by default. `prod` uses three public/private subnet pairs and enables one shared NAT gateway by default to demonstrate private egress intent.

## Security group boundaries

```mermaid
flowchart LR
  Internet[Public IPv4 CIDRs]
  ALBSG[ALB security group]
  ECSSG[ECS service security group]
  RDSSG[RDS PostgreSQL security group]
  RedisSG[Redis cache security group]

  Internet -->|HTTP listener port| ALBSG
  ALBSG -->|service port 8080| ECSSG
  ECSSG -->|PostgreSQL 5432| RDSSG
  ECSSG -. Redis 6379 when enabled .-> RedisSG
```

PostgreSQL and Redis do not accept public ingress. Private service-to-data access uses security group references instead of broad public CIDR ranges.

## Request flow

```mermaid
sequenceDiagram
  autonumber
  participant Client as Public client
  participant ALB as Application Load Balancer
  participant TG as Service target group
  participant ECS as Private Fargate task
  participant Secrets as Secrets Manager references
  participant DB as Private RDS PostgreSQL
  participant Cache as Optional private Redis or Valkey
  participant CW as CloudWatch

  Client->>ALB: HTTP request for a service path
  ALB->>ALB: Match listener rule such as /carbon*, /jobs*, or /saas*
  ALB->>TG: Forward to the matching target group
  TG->>ECS: Send request to a healthy private task
  Note over ECS,Secrets: Referenced secrets are resolved for the task by ECS runtime; Terraform stores ARNs only
  ECS->>DB: Query PostgreSQL if the service requires database access
  ECS-->>Cache: Use Redis or Valkey when the cache tier is enabled and required
  ECS-->>CW: Emit application logs and ECS metrics
  ALB-->>CW: Emit ALB metrics and target health
  DB-->>CW: Emit RDS metrics
  ECS-->>TG: Return service response
  TG-->>ALB: Return target response
  ALB-->>Client: Return public response
```

If a request path does not match a service listener rule, the ALB returns its fixed default response instead of forwarding to a backend.

## Deployment flow

```mermaid
flowchart LR
  Change[Change Terraform or service image reference]
  LocalGate[Run local quality gate]
  PR[Open pull request]
  CI[GitHub Actions validation-only quality gate]
  Review[Review Terraform and docs]
  Plan[Optional user-owned plan review]
  Manual[Optional manual user-owned provisioning]
  Rollout[ECS deployment updates tasks]
  Verify[Check health logs metrics alarms]

  Change --> LocalGate
  LocalGate --> PR
  PR --> CI
  CI --> Review
  Review --> Plan
  Plan --> Manual
  Manual --> Rollout
  Rollout --> Verify
```

The repository automates validation only. It does not configure cloud credentials in CI and does not run cloud mutation commands. Any real provisioning is optional, manual, user-owned, and can incur cost.

## Environment separation

```mermaid
flowchart TB
  Modules[Shared Terraform modules]
  Dev[dev root module]
  Prod[prod root module]

  Modules --> Dev
  Modules --> Prod

  Dev --> DevNet[Two AZ-style subnet pairs]
  Dev --> DevNat[NAT disabled by default]
  Dev --> DevRDS[Small single-AZ PostgreSQL]
  Dev --> DevRedis[Redis disabled by default]
  Dev --> DevECS[One task per demo service]

  Prod --> ProdNet[Three AZ-style subnet pairs]
  Prod --> ProdNat[NAT enabled by default]
  Prod --> ProdRDS[Multi-AZ PostgreSQL intent]
  Prod --> ProdRedis[Redis enabled with replica intent]
  Prod --> ProdECS[Two tasks per demo service]
```

Both environments keep backend configuration and variable values public-safe by committing only `backend.example.tf` and `terraform.tfvars.example` files.

## Observability coverage

```mermaid
flowchart LR
  ALB[ALB metrics]
  TargetHealth[Target group health]
  ECS[ECS CPU memory and logs]
  RDS[RDS CPU storage connections]
  Dashboard[CloudWatch dashboard]
  Alarms[CloudWatch alarms]

  ALB --> Dashboard
  TargetHealth --> Dashboard
  ECS --> Dashboard
  RDS --> Dashboard
  ALB --> Alarms
  TargetHealth --> Alarms
  ECS --> Alarms
  RDS --> Alarms
```

Committed alarm actions are empty. Real paging, SNS, or incident-routing ARNs belong in user-owned configuration outside this public repository.
