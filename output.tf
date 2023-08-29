output "ips" {
  value = data.dns_a_record_set.public.addrs
}