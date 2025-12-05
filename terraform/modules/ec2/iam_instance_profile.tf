resource "aws_iam_instance_profile" "test_profile" {
  name = var.instance-profile-name
  role = aws_iam_role.iam_role.name
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# resource "aws_iam_role" "role" {
#   name               = "iam_role"
#   path               = "/"
#   assume_role_policy = data.aws_iam_policy_document.assume_role.json
# }
