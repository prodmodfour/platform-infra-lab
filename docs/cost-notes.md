# Cost Notes

Detailed cost-awareness documentation will be completed in a later ticket. Costs change, so exact current prices are not claimed here.

## Current implemented cost drivers

The network module includes an optional NAT gateway. NAT gateways can be a meaningful ongoing cost driver when provisioned because they bill while running and can also charge for processed traffic. The dev environment disables NAT by default; the prod example enables it to show private egress intent.

Other implemented VPC components such as subnets, route tables, an internet gateway, security groups, and IAM roles are part of the network/security model. Security groups and IAM roles do not have standalone hourly cost, but they enable resources that do: ALB traffic, ECS/Fargate tasks, RDS PostgreSQL, optional Redis/ElastiCache, NAT egress, CloudWatch logs/metrics, Secrets Manager, SSM Parameter Store advanced parameters, and KMS requests.

The load-balancer module adds cost drivers if manually provisioned:

- an Application Load Balancer running continuously
- load balancer capacity and processed traffic
- public edge data transfer
- optional ALB access log storage and requests when a user-owned bucket is supplied

The Secrets Manager reference module adds cost drivers if manually provisioned:

- one Secrets Manager secret metadata container per modeled service secret
- Secrets Manager API usage when ECS resolves secrets at task start
- optional customer-managed KMS key requests if a user-owned key is supplied
- any separate secure pipeline that creates or rotates secret values

The module intentionally creates no secret versions or values in Terraform, but Secrets Manager resources themselves can still incur cost.

The ECS service module adds cost drivers if manually provisioned:

- Fargate vCPU and memory for each running task
- desired task count and autoscaling maximum capacity
- CloudWatch log ingestion and retention for each service log group
- ALB target group and listener-rule usage attached to the load balancer
- private egress through NAT gateways or VPC endpoints for image pulls, logs, ECS APIs, and secret references

Dev examples keep one small task per service and short log retention. Prod examples show two tasks per service and wider autoscaling ranges to demonstrate production intent, not a recommendation to provision without review.

The RDS PostgreSQL module adds cost drivers if manually provisioned:

- RDS instance class and continuous runtime
- single-AZ versus Multi-AZ placement
- allocated storage and storage autoscaling ceiling
- backup retention, final snapshots, and retained automated backups
- CloudWatch PostgreSQL log exports
- optional Performance Insights/Database Insights retention
- KMS usage when user-owned keys are supplied

Dev uses a small single-AZ PostgreSQL shape, short backup retention, and skipped final snapshot to stay disposable. Prod shows Multi-AZ, deletion protection, final snapshot, longer backup retention, larger storage, and Performance Insights to demonstrate production intent. These settings can create ongoing cost if provisioned.

The Redis cache module adds cost drivers if manually provisioned:

- ElastiCache node type and continuous runtime
- total cache node count, including replicas
- automatic failover and Multi-AZ settings that require replicas
- snapshot retention and final snapshots
- cache traffic between private ECS services and cache nodes
- KMS usage when user-owned keys are supplied

Dev keeps Redis disabled by default and defines a small node shape for optional experiments. Prod enables a small private cache with one replica, Multi-AZ/failover intent, encryption, snapshot retention, and a final snapshot identifier to demonstrate production posture. These settings can create ongoing cost if provisioned.

The observability module adds cost drivers if manually provisioned:

- CloudWatch dashboard usage
- CloudWatch alarms for ALB, ECS, and RDS metrics
- CloudWatch Logs Insights queries shown in dashboard log widgets
- log ingestion and retention from ECS service log groups created by the ECS module
- RDS PostgreSQL log exports configured by the RDS module

Committed alarm action lists are empty. If a user-owned environment connects alarms to SNS topics or incident-routing systems, those integrations can have their own cost and ownership considerations.

Any optional manual provisioning can incur cloud cost and should be reviewed, user-owned, and cleaned up by the operator.

Future content will expand qualitative AWS cost drivers and cleanup guidance.
