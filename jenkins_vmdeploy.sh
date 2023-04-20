#!/bin/bash

# This script automates the installation of GitLab on a VM.

sudo true

# Install homebrew
if ( which brew > /dev/null )
then 
  echo -e "\n\033[1;32m==== Brew installed ====\033[0m\n"
else
  echo -e "\n\033[1;33m==== Installing brew ====\033[0m\n"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install multipass
if ( which multipass > /dev/null )
then 
  echo -e "\n\033[1;32m==== Multipass installed ====\033[0m\n"
else
  echo -e "\n\033[1;33m==== Installing Multipass ====\033[0m\n"
  brew install multipass
fi

# Install rsync
if ( which rsync > /dev/null )
then
  echo -e "\n\033[1;32m==== Rsync installed ====\033[0m\n"
else
  echo -e "\n\033[1;33m==== Installing Rsync ====\033[0m\n"
  brew install rsync
fi

# Create SSh keys
if [ -f ./id_ed25519 ]
then
echo -e "\n\033[1;32m==== SSH key present ====\033[0m\n"
else 
echo -e "\n\033[1;33m==== Creating SSH key  ====\033[0m\n"
  ssh-keygen -t ed25519 -f ./id_ed25519 -N ""
fi

# Create cloud-init.yaml file
if [ -f ./cloud-init.yaml ]
then
  echo -e "\n\033[1;32m==== Cloud-init.yaml present ====\033[0m\n"
else
  echo -e "\n\033[1;33m==== Writing cloud-init.yaml  ====\033[0m\n"
  cat <<- EOF > cloud-init.yaml
users:
  - default
  - name: $USER
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - $(cat id_ed25519.pub)
EOF
fi

# Launch relativepath instance
if ( multipass list | grep relativepath | grep Running > /dev/null )
then 
  echo -e "\n\033[1;32m==== Relativepath VM present ====\033[0m\n"
else 
  echo -e "\n\033[1;33m==== Creating relativepath VM ====\033[0m\n"
  multipass launch --cpus 4 --memory 7G --disk 50G --name relativepath --cloud-init cloud-init.yaml
fi

echo -e "\n\033[1;32m==== Transferring files to VM ====\033[0m\n"
rsync -av -e "ssh -o StrictHostKeyChecking=no -i ./id_ed25519" --delete --exclude={'id_ed25519*','cloud-init.yaml','README.md','gitlab_vmdeploy','vm_destroy','commands.txt'} "$(pwd)" "$USER@$(multipass info relativepath |  grep '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | awk '{print $2}'):/home/$USER" 
 
echo -e "\n\033[1;32m==== Execute gitlab_install.sh on VM ====\033[0m\n"
ssh -o StrictHostKeyChecking=no -i ./id_ed25519 "$USER@$(multipass info relativepath | grep '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | awk '{print $2}') 'cd relativepath_leveltwo && bash jenkins_install.sh'"

echo -e "\n\033[1;32m==== SSH into VM ====\033[0m\n"
ssh -o StrictHostKeyChecking=no -i ./id_ed25519 "$USER@$(multipass info relativepath | grep '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | awk '{print $2}')"
