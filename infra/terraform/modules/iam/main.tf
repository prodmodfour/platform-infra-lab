locals {
  component_tags = merge(var.common_tags, {
    Environment = var.environment
    Component   = "iam"
  })

  execution_secret_read_policy_enabled = length(var.execution_secret_reference_arns) > 0 || length(var.execution_ssm_parameter_arns) > 0 || length(var.execution_kms_key_arns) > 0
  task_secret_read_policy_enabled      = length(var.task_secret_reference_arns) > 0 || length(var.task_ssm_parameter_arns) > 0 || length(var.task_kms_key_arns) > 0
}

data "aws_iam_policy_document" "ecs_tasks_assume_role" {
  statement {
    sid     = "AllowEcsTasksAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_execution" {
  name               = "${var.name_prefix}-ecs-task-execution"
  description        = "ECS task execution role for pulling images, writing logs, and resolving approved secret references"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json

  tags = merge(local.component_tags, {
    Name       = "${var.name_prefix}-ecs-task-execution"
    RoleScope  = "ecs-task-execution"
    Privilege  = "platform-runtime"
    SecretMode = "references-only"
  })
}

resource "aws_iam_role" "task" {
  name               = "${var.name_prefix}-ecs-task"
  description        = "Application task role for ECS workloads; starts with only explicitly supplied permissions"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json

  tags = merge(local.component_tags, {
    Name       = "${var.name_prefix}-ecs-task"
    RoleScope  = "application-task"
    Privilege  = "application-runtime"
    SecretMode = "references-only"
  })
}

resource "aws_iam_role_policy_attachment" "task_execution_managed_policy" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "execution_secret_references" {
  count = local.execution_secret_read_policy_enabled ? 1 : 0

  dynamic "statement" {
    for_each = length(var.execution_secret_reference_arns) > 0 ? [1] : []

    content {
      sid = "ReadSecretsManagerExecutionReferences"
      actions = [
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue",
      ]
      resources = var.execution_secret_reference_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.execution_ssm_parameter_arns) > 0 ? [1] : []

    content {
      sid = "ReadSsmExecutionParameters"
      actions = [
        "ssm:GetParameter",
        "ssm:GetParameters",
      ]
      resources = var.execution_ssm_parameter_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.execution_kms_key_arns) > 0 ? [1] : []

    content {
      sid       = "DecryptExecutionSecretReferences"
      actions   = ["kms:Decrypt"]
      resources = var.execution_kms_key_arns
    }
  }
}

resource "aws_iam_role_policy" "execution_secret_references" {
  count = local.execution_secret_read_policy_enabled ? 1 : 0

  name   = "${var.name_prefix}-ecs-exec-secret-read"
  role   = aws_iam_role.task_execution.id
  policy = data.aws_iam_policy_document.execution_secret_references[0].json
}

data "aws_iam_policy_document" "task_secret_references" {
  count = local.task_secret_read_policy_enabled ? 1 : 0

  dynamic "statement" {
    for_each = length(var.task_secret_reference_arns) > 0 ? [1] : []

    content {
      sid = "ReadSecretsManagerTaskReferences"
      actions = [
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue",
      ]
      resources = var.task_secret_reference_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.task_ssm_parameter_arns) > 0 ? [1] : []

    content {
      sid = "ReadSsmTaskParameters"
      actions = [
        "ssm:GetParameter",
        "ssm:GetParameters",
      ]
      resources = var.task_ssm_parameter_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.task_kms_key_arns) > 0 ? [1] : []

    content {
      sid       = "DecryptTaskSecretReferences"
      actions   = ["kms:Decrypt"]
      resources = var.task_kms_key_arns
    }
  }
}

resource "aws_iam_role_policy" "task_secret_references" {
  count = local.task_secret_read_policy_enabled ? 1 : 0

  name   = "${var.name_prefix}-ecs-task-secret-read"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task_secret_references[0].json
}
