#!/bin/bash

domain=$1

echo 'Executing installation of gitlab...'
if ! ( apt list --installed | grep gitlab ) > /dev/null
then
  if (apt list --installed | grep tzdata || apt list --installed | grep ca-certificates || apt list --installed | grep openssh-server )
  then
    echo "Gitlab dependencies are already installed."
  else
    echo "Installing gitlab dependencies..."
    sudo apt install -yq curl openssh-server ca-certificates tzdata perl lynx
  fi
    # debconf-set-selections <<< "postfix postfix/mailname string $domain"
    # debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Local only'" 
    # or
    # echo "postfix postfix/mailname string $domain" | debconf-set-selections;
    # echo "postfix postfix/main_mailer_type string 'Local only'" | debconf-set-selections
  if (apt list --installed | grep postfix)
  then
    echo "Postfix already installed."
  else
    echo "Installing postfix..."
    echo "postfix postfix/mailname string mail.$domain" | debconf-set-selections
    echo "postfix postfix/main_mailer_type string 'No configuration'" | debconf-set-selections
    sudo DEBIAN_FRONTEND=noninteractive apt install -yq postfix
  fi

  if ( apt list --installed | grep gitlab-ee )
  then
    echo "Gitlab is already installed."
  else
    cd /tmp
    
    if [ $(pwd) == "/tmp" ]
      echo "Retrieving and running gitlab script..."
      curl "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh" 
    fi
    
    if [ -f /tmp/script.deb.sh ]
      echo "Configuring sources for gitlab install..."
      sudo bash /tmp/script.deb.sh
      sudo rm /tmp/script.deb.sh
    else
      echo "Unable to retrieve the sources script for Gitlab."
      echo "Aborting Gitlab install."
      exit
    fi
    
    echo "Installing gitlab-ee..."
    sudo EXTERNAL_URL="gitlab.$domain" apt install -yq gitlab-ee
    
    if ( apt list --installed | grep gitlab-ee )
    then
      echo "Installed gitlab."
      echo " "
    else
      echo "Gitlab not installed: $?"
    fi
  fi
fi

if ( sudo ufw status | grep "Active" )
then
  echo "Firewall is enabled."
else
  echo "Enabling firewall..."
  sudo ufw enable
fi

echo "Configuring the firewall to allow Gitlab incomming connections..."
sudo ufw allow http
sudo ufw allow https
sudo ufw allow OpenSSH

if ( apt list --installed | grep gitlab-ee )
then
  if [ -f /etc/gitlab/initial_root_password ] > /dev/null
  then
    echo "Retrieving gitlab initial password..."
    gitlabPassword=$(sudo cat /etc/gitlab/initial_root_password | grep Password: | awk '{ print $2 }')
  else
    echo "Gitlab initial root password file doesn't exist."
  fi

  if [ -e ~/.ssh/authorized_keys ]
  then
    echo "Adding SSH key to github..."
    # GitLab.com ~/.ssh/config
      cat <<- EOF > ~/.ssh/config
# Private GitLab instance
Host gitlab.$domain 
  PreferredAuthentications publickey
  IdentityFile ~/.ssh/authorized_keys
EOF
    
    if [ -f ~/.ssh/config ]
    then
      echo "Gitlab SSH config file created."
    else
      echo "Couldn't create gitlab SSH config file."
    fi
  fi

  echo "Starting gitlab..."
  sudo systemctl start gitlab-ctl.service
  
  if ( sudo systemctl status gitlab-ctl ) > /dev/null
  then
    echo "Gitlab daemon started."
    echo "Status: "
    sudo systemctl status gitlab-ctl
  else
    echo "There was an issue starting gitlab: $?"
  fi
  
  if [ $gitlabPassword != "" ]
    echo " "
    echo "The initial password is:  $gitlabPassword"
    echo " "
  else
    echo "Could not retrieve initial password."
  fi

  # sed -i "s/^#letsencrypt['contact_emails'] = [ ] .letsencrypt['contact_emails'] = ['$USER@relativepath.tech',]" /etc/gitlab/gitlab.rb
  # sed -i "s/^#letsencrypt['enable'] = false .letsencrypt['enable'] = true" /etc/gitlab/gitlab.rb
  # sudo gitlab-ctl reconfigure
  
  exit
fi
