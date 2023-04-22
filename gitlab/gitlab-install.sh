#!/bin/bash

domain=$1

echo 'Executing installation of gitlab...'
if ! ( apt list --installed | grep gitlab ) > /dev/null
then
  if ! (apt list --installed | grep tzdata || apt list --installed | grep ca-certificates || apt list --installed | grep openssh-server )
  then
    echo "Installing gitlab dependencies..."
    sudo apt install -yq curl openssh-server ca-certificates tzdata perl lynx
  else
    echo "Gitlab dependencies are already installed."
  fi
    # debconf-set-selections <<< "postfix postfix/mailname string $domain"
    # debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Local only'" 
    # or
    # echo "postfix postfix/mailname string $domain" | debconf-set-selections;
    # echo "postfix postfix/main_mailer_type string 'Local only'" | debconf-set-selections
  if ! (apt list --installed | grep postfix)
  then
    echo "Installing postfix..."
    echo "postfix postfix/mailname string mail.$domain" | debconf-set-selections
    echo "postfix postfix/main_mailer_type string 'No configuration'" | debconf-set-selections
    sudo DEBIAN_FRONTEND=noninteractive apt install -yq postfix
  else
    echo "Postfix already installed."
  fi

  if ( apt list --installed | grep gitlab-ee )
  then
    echo "Retrieving and running gitlab script..."
    curl "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh" |  sudo bash 

    sudo EXTERNAL_URL="gitlab.$domain" apt install -yq gitlab-ee
    
    if ( apt list --installed | grep gitlab-ee )
    then
      echo "Installed gitlab."
      echo " "
    else
      echo "Gitlab not installed: $?"
    fi
  else
    echo "Gitlab is already installed."
  fi
fi

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
  
  if [ $? == 1 ]
  then
    echo "Gitlab daemon started."
    echo "Status: "
    sudo systemctl status gitlab-ctl
  else
    echo "There was an issue starting gitlab: $?"
  fi
  
  echo " "
  echo "The initial password is:  $gitlabPassword"
  echo " "

  
  # letsencrypt['enable'] = false
  # letsencrypt['contact_emails'] = [ ]

  # sudo gitlab-ctl reconfigure
fi
