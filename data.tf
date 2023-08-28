data "dns_a_record_set" "public" {
  host = var.dns_name
}