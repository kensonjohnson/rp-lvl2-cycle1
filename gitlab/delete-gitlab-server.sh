#!/bin/zsh

# Remove SSH fingerprint in known_hosts
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$(multipass info gitlab | grep IPv4 | awk '{print $2}')"

# Delete the VM
if ( multipass info gitlab > /dev/null ) 
then
  echo -e "Deleting 'gitlab' VM."
  multipass delete gitlab && multipass purge
fi 
echo -e "'gitlab' VM deleted."

# Destroy SSH keys
echo -e "Cleaning up files."
rm id_ed25519*

# Remove yaml file
rm cloud-init.yaml
