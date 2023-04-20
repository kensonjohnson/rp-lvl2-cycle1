#!/bin/bash

# This script installs GitLab on a Ubuntu.

sudo apt update

# Install GitLab
if ( which gitlab-ctl > /dev/null ) 
then
  echo -e "\n\033[1;32m==== GitLab present ====\033[0m\n"
else
  echo -e "\n\033[1;33m==== Installing GitLab ====\033[0m\n"
  # Install and configure dependencies
  sudo apt-get install -y curl openssh-server ca-certificates tzdata perl
  echo -e "\n\033[1;33m==== Configuring Postfix ====\033[0m\n"
  sudo debconf-set-selections <<< "postfix postfix/mailname string localhost"
  sudo debconf-set-selections <<< "postfix postfix/main_mailer_type string 'No configuration'"
  sudo apt-get install -y postfix
  # Add Gitlab repo
  echo -e "\n\033[1;33m==== Adding GitLab package repository ====\033[0m\n"
  curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash
  sudo EXTERNAL_URL="http://localhost" apt-get install -y gitlab-ee
  echo -e "\n\033[1;32mGitLab installation complete\033[0m\n"
fi

echo -e "\n\033[1m \033[32mIP Address:\033[0m \033[37m$( hostname -I | awk '{print $1}' ) \033[0m\n"

echo -e "\n\033[1m \033[32mIP Password:\033[0m \033[37m$( sudo cat /etc/gitlab/initial_root_password | sed -n 's/^Password: //p' ) \033[0m\n"

# The <<< is a Bash shell operator called a "here string" that allows you to pass a string as input to a command. It works similar to a pipe, but without creating a subshell. Instead of piping the output of one command to another command, a here string sends the contents of a string to a command as input.