/* デプロイ用IAMユーザーの作成 */
resource "aws_iam_user" "github" {
  name = "${local.name_prefix}-${local.service_name}-github"

  tags = {
    "Name" = "${local.name_prefix}-${local.service_name}-github"
  }
}

/* デプロイ用IAMロールの作成 */
resource "aws_iam_role" "deployer" {
  name = "${local.name_prefix}-${local.service_name}-deployer"

  /* 作成するIAMロールを一時的なAssume Roleにする設定 */
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "sts:AssumeRole",
            /* これがないとaws-actions/configure-aws-credentialsでエラーになるため設定 */
            "sts:TagSession"
          ],
          "Principal" : {
            "AWS" : aws_iam_user.github.arn
          }
        }
      ]
    }
  )
  tags = {
    Name = "${local.name_prefix}-${local.service_name}-deployer"
  }
}

/* dataは、このディレクトリのtfstateでは管理してないリソースを参照する際などに使用 */
data "aws_iam_policy" "ecr_power_user" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}
/* 作成したユーザーにロールを付与 */
resource "aws_iam_role_policy_attachment" "role_deployer_policy_ecr_power_user" {
  role       = aws_iam_role.deployer.name
  policy_arn = data.aws_iam_policy.ecr_power_user.arn
}
