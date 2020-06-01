resource "aws_launch_template" "this" {
  name_prefix            = "${var.project}-${var.env}-"
  image_id               = data.aws_ami.this.id
  instance_type          = var.instance_types[0]
  vpc_security_group_ids = [aws_security_group.node.id]
  user_data              = base64encode(local.userdata)

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_type           = "gp2"
      volume_size           = 100
      delete_on_termination = true
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.node.name
  }

  monitoring {
    enabled = true
  }

  lifecycle {
    create_before_destroy = true
  }
  
  tags = {
    Name    = "${var.project}-${var.env}-node"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_autoscaling_group" "this" {
  name_prefix               = "${var.project}-${var.env}-"
  max_size                  = var.max_size
  min_size                  = var.min_size
  desired_capacity          = var.desired_capacity
  health_check_type         = "ELB"
  health_check_grace_period = 300
  vpc_zone_identifier       = aws_subnet.pri.*.id
  default_cooldown          = 300
  metrics_granularity       = "1Minute"
  enabled_metrics           = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.this.id
        version            = "$Latest"
      }

      override {
        instance_type = var.instance_types[0]
      }
      override {
        instance_type = var.instance_types[1]
      }
      override {
        instance_type = var.instance_types[2]
      }
      override {
        instance_type = var.instance_types[3]
      }
    }
    instances_distribution {
      on_demand_percentage_above_base_capacity = var.on_demand_percentage_above_base_capacity
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project}-${var.env}-node"
    propagate_at_launch = true
  }
  tag {
    key                 = "Project"
    value               = var.project
    propagate_at_launch = true
  }
  tag {
    key                 = "Env"
    value               = var.env
    propagate_at_launch = true
  }
  tag {
    key                 = "kubernetes.io/cluster/${var.project}-${var.env}"
    value               = "owned"
    propagate_at_launch = true
  }
  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = true
  }
  tag {
    key                 = "k8s.io/cluster-autoscaler/${var.project}-${var.env}"
    value               = "owned"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}