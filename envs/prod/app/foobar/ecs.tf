resource "aws_ecs_cluster" "this" {
  name = "${local.name_prefix}-${local.service_name}"
  capacity_providers = [
    "FARGATE",
    # fargate_spotはfargateのスポットインスタンスのようなもの
    "FARGATE_SPOT"
  ]
  tags = {
    Name = "${local.name_prefix}-${local.service_name}"
  }
}

resource "aws_ecs_task_definition" "this" {
  family = "${local.name_prefix}-${local.service_name}"

  task_role_arn = aws_iam_role.ecs_task.arn

  # fargateはawsvpcを指定。
  network_mode = "awsvpc"

  requires_compatibilities = [
    "FARGATE",
  ]
  execution_role_arn = aws_iam_role.ecs_task_execution.arn

  memory = "512"
  cpu    = "256"

  container_definitions = jsonencode(
    [
      {
        name  = "nginx"
        image = "${module.nginx.ecr_repository_this_repository_url}:latest"

        # どのポート番号でトラフィックを送受信するか
        portMappings = [
          {
            containerPort = 80
            protocol      = "tcp"
          }
        ]

        # コンテナに渡す環境変数
        environment = []
        secrets     = []
        dependsOn = [
          {
            containerName = "php"
            condition     = "START"
          }
        ]

        mountPoints = [
          {
            containerPath = "/var/run/php-fpm"
            sourceVolume  = "php-fpm-socket"
          }
        ]

        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = "/ecs/${local.name_prefix}-${(local.service_name)}/nginx"
            awslogs-region        = data.aws_region.current.id
            awslogs-stream-prefix = "ecs"
          }
        }
      },

      {
        name  = "php"
        image = "${module.php.ecr_repository_this_repository_url}:latest"

        portMappings = []

        environment = []

        # Secrets Managerを指定すると、その値がコンテナの環境変数
        secrets = [
          {
            name      = "APP_KEY"
            valueFrom = "/${local.system_name}/${local.env_name}/${local.service_name}/APP_KEY"
          }
        ]

        # nginxとPHPコンテナ同士の通信
        mountPoints = [
          {
            containerPath = "/var/run/php-fpm"
            sourceVolume  = "php-fpm-socket"
          }
        ]

        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = "/ecs/${local.name_prefix}-${(local.service_name)}/php"
            awslogs-region        = data.aws_region.current.id
            awslogs-stream-prefix = "ecs"
          }
        }
      }
    ]
  )

  volume {
    name = "php-fpm-socket"
  }

  tags = {
    Name = "${local.name_prefix}-${local.service_name}"
  }
}

resource "aws_ecs_service" "this" {
  name    = "${local.name_prefix}-${local.service_name}"
  cluster = aws_ecs_cluster.this.arn
  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    base              = 0
    weight            = 1
  }
  platform_version                   = "1.4.0"

  # ECSサービスで使用するタスク定義のARN
  task_definition                    = aws_ecs_task_definition.this.arn

  # 起動させておくタスク数
  desired_count                      = var.desired_count

  # 全体で最低何個のタスクを起動
  deployment_minimum_healthy_percent = 100

  # ローリングアップデート時に全体で最大何個までタスクを起動
  deployment_maximum_percent         = 200

  # ロードバランサーがトラフィックをフォワードするコンテナ名とポート番号
  load_balancer {
    container_name   = "nginx"
    container_port   = 80
    target_group_arn = data.terraform_remote_state.routing_appfoobar_link.outputs.lb_target_group_foobar_arn
  }

  # ヘルスチェックで異常が出たとしても無視する猶予期間
  health_check_grace_period_seconds = 60
  network_configuration {
    assign_public_ip = false
    security_groups = [
      data.terraform_remote_state.network_main.outputs.security_group_vpc_id
    ]
    subnets = [
      for s in data.terraform_remote_state.network_main.outputs.subnet_private : s.id
    ]
  }

  # ECS Exec
  enable_execute_command = true
  tags = {
    Name = "${local.name_prefix}-${local.service_name}"
  }
}
