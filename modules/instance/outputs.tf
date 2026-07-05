output "vpn_instance" {
  value = linode_instance.vpn_instance
}

output "instance_id" {
  value = linode_instance.vpn_instance.id
}

output "instance_ip" {
  value = one([
    for addr in tolist(linode_instance.vpn_instance.ipv4) : addr
    if !startswith(addr, "192.168.")
  ])
}
