# Terraformでは、あるtfstateにおいてoutputとして宣言された値を、
# ter-raform_remote_stateというデータソースを使うことで、
# 別のディレクトリから参照することが可能
output "s3_bucket_this_id" {
  value = aws_s3_bucket.this.id
}
