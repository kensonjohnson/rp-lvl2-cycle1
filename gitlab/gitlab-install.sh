#!/bin/bash

domain=$1

echo 'Executing installation of gitlab...'
if ! ( which gitlab-ctl ) > /dev/null
then
    sudo apt install -yq curl openssh-server ca-certificates tzdata perl lynx
    # debconf-set-selections <<< "postfix postfix/mailname string $domain"
    # debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Local only'" 
    # or
    # echo "postfix postfix/mailname string $domain" | debconf-set-selections;
    # echo "postfix postfix/main_mailer_type string 'Local only'" | debconf-set-selections
    echo "postfix postfix/mailname string mail.$domain" | debconf-set-selections
    echo "postfix postfix/main_mailer_type string 'Local only'" | debconf-set-selections
    sudo DEBIAN_FRONTEND=noninteractive apt install -yq postfix

    curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash

    sudo DEBIAN_FRONTEND=noninteractive EXTERNAL_URL="gitlab.$domain" apt install -yq gitlab-ee
    echo "Installed gitlab."
    echo " "
fi

gitlabPassword=$(sudo cat /etc/gitlab/initial_root_password | grep Password: | awk '{ print $2 }')

if [ -e ~/.ssh/authorized_keys ]
then
# GitLab.com ~/.ssh/config
    cat <<- EOF > ~/.ssh/config
# Private GitLab instance
Host gitlab.$domain 
  PreferredAuthentications publickey
  IdentityFile ~/.ssh/authorized_keys
EOF
fi
sudo systemctl start gitlab-ctl.service
sudo systemctl status gitlab-ctl
# letsencrypt['enable'] = false
# letsencrypt['contact_emails'] = [ ]

sudo gitlab-ctl reconfigure

