resource "random_id" "aws_iam_user_name" {
  count       = var.iam_user_count
  prefix      = "demo-${local.owner_email}" # Do Not Remove/Edit. This is a requirement to obtain access in creating a iam user in the dev account.
  byte_length = 4
}

resource "aws_iam_user" "user" {
  count                = var.iam_user_count
  name                 = random_id.aws_iam_user_name[count.index].dec
  force_destroy        = true
  permissions_boundary = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/DemoUser" # Do Not Remove/Edit. This is a requirement to obtain access in creating a iam user in the dev account.
}

resource "aws_iam_access_key" "user_initial_key" {
  count = var.iam_user_count
  user  = aws_iam_user.user[count.index].name
}

resource "random_id" "aws_ec2_policy_name" {
  prefix      = "BoundaryPluginHost"
  byte_length = 4
}

resource "aws_iam_policy" "ec2_describeinstances" {
  name = random_id.aws_ec2_policy_name.dec

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DescribeInstances"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_user_policy_attachment" "user_ec2_describeinstances_attachment" {
  count      = var.iam_user_count
  user       = aws_iam_user.user[count.index].name
  policy_arn = aws_iam_policy.ec2_describeinstances.arn
}

resource "random_id" "aws_iam_policy_name" {
  count       = var.iam_user_count
  prefix      = "BoundaryPluginCredentials"
  byte_length = 4
}

resource "aws_iam_policy" "user_self_manage_policy" {
  count = var.iam_user_count
  name  = random_id.aws_iam_policy_name[count.index].dec

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "iam:DeleteAccessKey",
        "iam:GetUser",
        "iam:CreateAccessKey"
      ],
      "Effect": "Allow",
      "Resource": "${aws_iam_user.user[count.index].arn}"
    }
  ]
}
EOF
}

resource "aws_iam_user_policy_attachment" "user_self_manage_policy_attachment" {
  count      = var.iam_user_count
  user       = aws_iam_user.user[count.index].name
  policy_arn = aws_iam_policy.user_self_manage_policy[count.index].arn
}

# Session Recording
# For now, using the old method for creating a user as this was the only way we could create a user
# with sufficient privileges (the cloudsec team only granted BoundaryDemoPermissionsBoundary with
# s3 operations)
resource "random_id" "storage_user_name" {
  prefix      = "boundary-aws-demo-stack-iam-user" # Do Not Remove/Edit. This is a requirement to obtain access in creating a iam user in the dev account.
  byte_length = 4
}

resource "aws_iam_user" "storage_user" {
  name                 = random_id.storage_user_name.dec
  force_destroy        = true
  permissions_boundary = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/BoundaryDemoPermissionsBoundary" # Do Not Remove/Edit. This is a requirement to obtain access in creating a iam user in the dev account.
  tags = {
    "boundary-demo" = local.owner_email # Do Not Remove/Edit. This is a requirement to obtain access in creating a iam user in the dev account.
  }
}

resource "random_id" "storage_user_policy_name" {
  prefix      = "BoundaryPluginStorage"
  byte_length = 4
}

resource "aws_iam_policy" "storage_user_policy" {
  name = random_id.storage_user_policy_name.dec

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:GetObjectAttributes"
      ],
      "Resource": "${aws_s3_bucket.storage_bucket.arn}/*"
    }
  ]
}
EOF
}

resource "aws_iam_user_policy_attachment" "storage_user_policy_attachment" {
  user       = aws_iam_user.storage_user.name
  policy_arn = aws_iam_policy.storage_user_policy.arn
}

resource "aws_iam_access_key" "storage_user_key" {
  user = aws_iam_user.storage_user.name
}
