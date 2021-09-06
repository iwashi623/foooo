variable "vpc_cidr" {
  type    = string
  default = "172.31.0.0/16"
}
variable "azs" {
  type = map(object({
    public_cidr  = string
    private_cidr = string
  }))
  default = {
    a = {
      public_cidr  = "172.31.0.0/20"
      private_cidr = "172.31.48.0/20"
    },
    c = {
      public_cidr  = "172.31.16.0/20"
      private_cidr = "172.31.64.0/20"
    }
  }
}
# nat_gatewayを使うときだけtrueでapplyする。
variable "enable_nat_gateway" {
  type    = bool
  default = true
}
# nat gatewayが各AZには必要なく、一つだけでいい場合、trueでapplyする。
variable "single_nat_gateway" {
  type    = bool
  default = true
}
