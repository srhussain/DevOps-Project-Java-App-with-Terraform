resource "aws_iam_role_policy" "iam-policy" {
  name   = var.iam-policy
  role   = aws_iam_role.iam_role.id
  policy = file("${path.module}/iam_policy.json")
}