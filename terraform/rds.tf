resource "random_password" "db" {
  length  = 24
  special = false
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.name_prefix}-db-subnets"
  subnet_ids = aws_subnet.private_data[*].id

  tags = { Name = "${var.name_prefix}-db-subnets" }
}

resource "aws_db_instance" "postgres" {
  identifier                 = "${var.name_prefix}-pg15"
  engine                     = "postgres"
  engine_version             = "15"
  instance_class             = "db.t4g.micro"
  allocated_storage          = 20
  max_allocated_storage      = 50
  storage_type               = "gp3"
  db_name                    = var.db_name
  username                   = var.db_user
  password                   = random_password.db.result
  db_subnet_group_name       = aws_db_subnet_group.main.name
  vpc_security_group_ids     = [aws_security_group.rds.id]
  multi_az                   = true
  skip_final_snapshot        = true
  publicly_accessible        = false
  backup_retention_period    = 1
  auto_minor_version_upgrade = true

  tags = { Name = "${var.name_prefix}-rds" }
}