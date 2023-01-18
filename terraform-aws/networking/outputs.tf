# --- networking/outputs.tf ----

output "vpc_id" {
  value = aws_vpc.myvpc_vpc.id
}