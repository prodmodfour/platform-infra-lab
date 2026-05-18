# Cost Notes

Detailed cost-awareness documentation will be completed in a later ticket. Costs change, so exact current prices are not claimed here.

## Current implemented cost drivers

The network module includes an optional NAT gateway. NAT gateways can be a meaningful ongoing cost driver when provisioned because they bill while running and can also charge for processed traffic. The dev environment disables NAT by default; the prod example enables it to show private egress intent.

Other implemented VPC components such as subnets, route tables, and an internet gateway are part of the network model. Any optional manual provisioning can incur cloud cost and should be reviewed, user-owned, and cleaned up by the operator.

Future content will describe qualitative AWS cost drivers such as RDS, ALB, ECS/Fargate, CloudWatch, and optional Redis/ElastiCache.
