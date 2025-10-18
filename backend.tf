# terraform {
#   backend "s3" {
#     bucket         = "REPLACE_ME-state-bucket"
#     key            = "simplewebapp/dev/terraform.tfstate"
#     region         = "us-east-2"
#     dynamodb_table = "REPLACE_ME-locks"
#     encrypt        = true
#   }
# }
