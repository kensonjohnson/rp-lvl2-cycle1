#!/bin/env bash

# A script to install an GitLab webserver

if ( which gitlab )
then 
    echo "gitlab"
else 
    echo -e "Installing GitLab"
    # Get dependencies
    sudo apt update
    sudo apt install -y curl openssh-server ca-certificates tzdata perl

    # Install smtp server
    sudo apt install -y postfix

    # Download GitLab and run installer
    curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash

    # TODO: Setup external URL
    # sudo EXTERNAL_URL="https://gitlab.example.com" apt-get install gitlab-ee

fi
