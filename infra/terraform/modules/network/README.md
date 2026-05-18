# Network module

This module models the base AWS network for the public-safe platform lab.

It creates:

- one VPC with DNS support enabled by default
- public subnets for internet-facing entry points such as an Application Load Balancer
- private subnets for ECS services, databases, and caches
- an internet gateway and public route table
- one private route table per private subnet
- an optional single NAT gateway for private subnet egress
- common public-safe tags on taggable resources

The module intentionally does not create security groups. Security group boundaries are added separately so reviewers can inspect network placement and traffic policy independently.

## Public and private subnet intent

Public subnets have a route to the internet gateway and are intended for public edge components only, such as a load balancer or NAT gateway. They should not host databases or caches.

Private subnets do not receive public IP addresses from this module. They are intended for ECS tasks and stateful services that should only be reached through controlled security group rules added by later modules.

When `enable_nat_gateway = false`, private subnet route tables do not get a default route to the internet. That is useful for low-cost lab review and for workloads that do not need outbound internet access.

When `enable_nat_gateway = true`, the module creates one NAT gateway in the first public subnet and adds default routes from private route tables to it. This demonstrates the private-egress pattern without adding a NAT gateway per availability zone.

## Cost notes

NAT gateways can be a meaningful ongoing cost driver because they bill while provisioned and can also charge for data processing. Dev defaults should generally keep NAT disabled unless outbound internet access is being reviewed.

This module also creates VPC networking resources such as subnets, route tables, an internet gateway, and optional elastic IP allocation for NAT. Any real provisioning is optional, user-owned, and should be cleaned up by the operator when no longer needed.

## Production hardening gaps

This module is intentionally reviewable rather than exhaustive. Before production use, review at least:

- whether private egress needs one NAT gateway per availability zone instead of a single shared NAT gateway
- whether VPC endpoints can reduce NAT dependency for AWS service traffic
- whether network ACLs are needed for additional subnet-level controls
- whether IPv6 is required
- whether CIDR sizing supports expected service, database, and cache growth
- whether subnet placement matches the account's enabled availability zones
- whether flow logs should be enabled through a future observability/security module

## Inputs

Key inputs:

- `name_prefix` — public-safe resource naming prefix
- `environment` — environment label for review context
- `vpc_cidr` — VPC CIDR block
- `availability_zones` — subnet placement zones
- `public_subnet_cidrs` — public subnet CIDR blocks
- `private_subnet_cidrs` — private subnet CIDR blocks
- `enable_nat_gateway` — creates one NAT gateway and private default routes when true
- `common_tags` — public-safe tags merged with module tags

## Outputs

Important outputs include:

- `vpc_id`
- `vpc_cidr_block`
- `public_subnet_ids`
- `private_subnet_ids`
- `public_subnet_cidrs`
- `private_subnet_cidrs`
- `public_route_table_id`
- `private_route_table_ids`
- `internet_gateway_id`
- `nat_gateway_id`
