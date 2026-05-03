
module "alb_public" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.13"

  name               = "${var.name_prefix}-pub-alb"
  load_balancer_type = "application"
  internal           = false

  enable_deletion_protection = false

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  create_security_group = false
  security_groups       = [aws_security_group.alb_public.id]

  access_logs = {
    bucket  = module.s3_alb_logs.s3_bucket_id
    prefix  = "public"
    enabled = true
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "main-backend"
      }
    }
  }

  target_groups = {
    main-backend = {
      name              = "${var.name_prefix}-mb-tg"
      protocol          = "HTTP"
      port              = 8000
      target_type       = "ip"
      create_attachment = false

      health_check = {
        enabled             = true
        path                = "/health"
        matcher             = "200"
        interval            = 15
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 3
      }
    }
  }
}


module "alb_internal" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.13"

  name               = "${var.name_prefix}-int-alb"
  load_balancer_type = "application"
  internal           = true

  enable_deletion_protection = false

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.private_subnets

  create_security_group = false
  security_groups       = [aws_security_group.alb_internal.id]

  access_logs = {
    bucket  = module.s3_alb_logs.s3_bucket_id
    prefix  = "internal"
    enabled = true
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      fixed_response = {
        content_type = "text/plain"
        message_body = "not found"
        status_code  = "404"
      }

      rules = {
        extract = {
          priority = 10
          actions = [{
            type             = "forward"
            target_group_key = "extractor"
          }]
          conditions = [{
            path_pattern = { values = ["/extract*"] }
          }]
        }
        parse = {
          priority = 20
          actions = [{
            type             = "forward"
            target_group_key = "parser"
          }]
          conditions = [{
            path_pattern = { values = ["/parse*"] }
          }]
        }
      }
    }
  }

  target_groups = {
    extractor = {
      name              = "${var.name_prefix}-ex-tg"
      protocol          = "HTTP"
      port              = 8001
      target_type       = "ip"
      create_attachment = false
      health_check      = { enabled = true, path = "/health", matcher = "200", interval = 15, timeout = 5, healthy_threshold = 2, unhealthy_threshold = 3 }
    }
    parser = {
      name              = "${var.name_prefix}-pa-tg"
      protocol          = "HTTP"
      port              = 8002
      target_type       = "ip"
      create_attachment = false
      health_check      = { enabled = true, path = "/health", matcher = "200", interval = 15, timeout = 5, healthy_threshold = 2, unhealthy_threshold = 3 }
    }
  }
}
