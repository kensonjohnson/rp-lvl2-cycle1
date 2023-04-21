#!/bin/env bash

# A script to install an GitLab webserver

if ( which gitlab )
then 
    echo "gitlab"
else 
    echo -e "Installing GitLab"
    # Get dependencies
    sudo apt-get update
    sudo apt-get install -y curl openssh-server ca-certificates tzdata perl

    # Install smtp server
    # debconf-set-selections <<< "postfix postfix/mailname string your.hostname.com"
    # debconf-set-selections <<< "postfix postfix/main_mailer_type string 'No Configuration'"
    echo "postfix postfix/main_mailer_type select 'No Configuration" | debconf-set-selections
    echo "postfix postfix/mailname string relative.path" | debconf-set-selections
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y postfix

    # Download GitLab and run installer
    curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash

    # TODO: Setup external URL
    sudo EXTERNAL_URL="https://gitlab.example.com" apt install gitlab-ee -y

fi
