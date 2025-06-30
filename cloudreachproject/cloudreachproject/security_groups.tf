

#########################################################
# CREATING SECURITY GROUPS
#########################################################
locals {
  security_group_rule_ingress = {
    backend_sg_rule = {
      from_port                = 8080
      to_port                  = 8080
      protocol                 = "tcp"
      source_security_group_id = aws_security_group.security["app_sg"].id
      security_group_id        = aws_security_group.security["backend_sg"].id
    }
    database_sg_rule = {
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      source_security_group_id = aws_security_group.security["backend_sg"].id
      security_group_id        = aws_security_group.security["database_sg"].id
    }
  }
  security_group_app = {
    https_rule = {
      from_port         = 443
      to_port           = 443
      protocol          = "tcp"
      security_group_id = aws_security_group.security["app_sg"].id
      cidr_block        = ["0.0.0.0/0"]
    }
  }
  security_group_rule_egress = {
    app_sg_rule = {
      to_port           = 0
      protocol          = "-1"
      cidr_block        = ["0.0.0.0/0"]
      from_port         = 0
      security_group_id = aws_security_group.security["app_sg"].id
    }
    backend_sg_rule = {
      to_port           = 0
      protocol          = "-1"
      cidr_block        = ["0.0.0.0/0"]
      from_port         = 0
      security_group_id = aws_security_group.security["backend_sg"].id
    }
    database_sg_rule = {
      to_port           = 0
      protocol          = "-1"
      cidr_block        = ["0.0.0.0/0"]
      from_port         = 0
      security_group_id = aws_security_group.security["database_sg"].id
    }
  }
  security_group = {
    app_sg = {
      name        = "${var.component}_app_sg"
      description = "allow alb on port 443"
    }
    backend_sg = {
      name        = "${var.component}_backend_sg"
      description = "allow alb on port 8080"
    }
    database_sg = {
      name        = "${var.component}_database_sg"
      description = "allow registration app on port 3306"
    }
  }

}

resource "aws_security_group" "security" {
  for_each    = local.security_group
  name        = each.value.name
  description = each.value.description
  vpc_id      = local.vpc_id


  tags = {
    Name = "${var.component}_${each.key}"
  }
}

resource "aws_security_group_rule" "ingress_rule_app" {
  for_each = local.security_group_app
  type     = "ingress"

  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = "tcp"
  cidr_blocks       = each.value.cidr_block
  security_group_id = each.value.security_group_id


}

resource "aws_security_group_rule" "egress_rule" {
  for_each          = local.security_group_rule_egress
  type              = "egress"
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_block
  from_port         = each.value.from_port
  security_group_id = each.value.security_group_id
}

resource "aws_security_group_rule" "ingress_rule" {
  for_each                 = local.security_group_rule_ingress
  type                     = "ingress"
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  source_security_group_id = each.value.source_security_group_id
  security_group_id        = each.value.security_group_id
}

