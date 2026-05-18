# Cost Notes

Detailed cost-awareness documentation will be completed in a later ticket. Costs change, so exact current prices are not claimed here.

## Current implemented cost drivers

The network module includes an optional NAT gateway. NAT gateways can be a meaningful ongoing cost driver when provisioned because they bill while running and can also charge for processed traffic. The dev environment disables NAT by default; the prod example enables it to show private egress intent.

Other implemented VPC components such as subnets, route tables, an internet gateway, security groups, and IAM roles are part of the network/security model. Security groups and IAM roles do not have standalone hourly cost, but they enable resources that do: ALB traffic, ECS/Fargate tasks, RDS PostgreSQL, optional Redis/ElastiCache, NAT egress, CloudWatch logs/metrics, Secrets Manager, SSM Parameter Store advanced parameters, and KMS requests.

The ECS service module adds cost drivers if manually provisioned:

- Fargate vCPU and memory for each running task
- desired task count and autoscaling maximum capacity
- CloudWatch log ingestion and retention for each service log group
- ALB target group and load balancer usage once the load balancer is wired
- private egress through NAT gateways or VPC endpoints for image pulls, logs, ECS APIs, and secret references

Dev examples keep one small task per service and short log retention. Prod examples show two tasks per service and wider autoscaling ranges to demonstrate production intent, not a recommendation to provision without review.

Any optional manual provisioning can incur cloud cost and should be reviewed, user-owned, and cleaned up by the operator.

Future content will describe qualitative AWS cost drivers such as RDS, ALB, CloudWatch alarms/dashboards, and optional Redis/ElastiCache.
