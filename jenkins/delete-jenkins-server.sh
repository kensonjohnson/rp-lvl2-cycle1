#!/bin/zsh

# Remove SSH fingerprint in known_hosts
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$(multipass info jenkins | grep IPv4 | awk '{print $2}')"

# Delete the VM
if ( multipass info jenkins > /dev/null ) 
then
  echo -e "Deleting 'jenkins' VM."
  multipass delete jenkins && multipass purge
fi 
echo -e "'jenkins' VM deleted."

# Destroy SSH keys
echo -e "Cleaning up files."
rm id_ed25519*

# Remove yaml file
rm cloud-init.yaml
