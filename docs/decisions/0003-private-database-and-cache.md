# 0003 — Private database and cache

## Status

Accepted.

## Context

The reference backend services need realistic data-service patterns. A platform/SRE portfolio project should demonstrate that PostgreSQL and Redis/ElastiCache-style services are not exposed directly to the public internet, that access is controlled through security groups, and that stateful resources have clear backup, deletion protection, and cost considerations.

The repository is public-safe and validation-only. It cannot include real database credentials, real endpoints, production data, or automated provisioning. It should still model the architecture reviewers would expect in a production-intent AWS service platform.

## Decision

Model PostgreSQL/RDS and Redis/ElastiCache as private data tiers.

For PostgreSQL/RDS:

- the RDS subnet group uses private subnets
- `publicly_accessible` is fixed to `false`
- ingress is allowed only from the ECS service security group on the PostgreSQL port
- backup retention, storage, deletion protection, final snapshot, monitoring, and log export settings are explicit variables
- RDS-managed master credentials are exposed as secret references, not raw values

For Redis/ElastiCache:

- the cache subnet group uses private subnets
- ingress is allowed only from the ECS service security group on the Redis port
- the cache tier is optional and controlled by an environment-level enable flag
- `dev` disables Redis by default for cost-aware review
- `prod` enables Redis by default to show the production-intent private cache pattern

Database schema migrations, seed data, cache warm-up, credential creation, and application-level data handling remain outside this public repository.

## Consequences

This decision demonstrates private data-service placement, security group boundaries, environment-specific posture, and stateful-service operational concerns without exposing public database or cache ingress.

Private placement improves the network posture but creates additional operational requirements. Real ECS tasks may need a reviewed private egress strategy, such as NAT or VPC endpoints, for image pulls, logs, secrets resolution, AWS APIs, and external dependencies. Debugging private data tiers also requires user-owned access patterns such as SSM Session Manager, bastion hosts, VPN, or private observability tooling, none of which are provisioned by this lab.

RDS, Redis/ElastiCache, snapshots, logs, and related resources can incur ongoing cost if a user manually provisions them. Production use would require additional review of restore testing, point-in-time recovery objectives, encryption and KMS ownership, database users, migration roles, Redis AUTH or ACL decisions, audit logging, retention, high availability, and disaster recovery.
