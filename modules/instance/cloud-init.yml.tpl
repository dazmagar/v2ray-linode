#cloud-config
users:
  - default
  - name: ${username}
    groups: [sudo, docker]
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ${public_key}

package_update: true
package_upgrade: false
