#!/bin/bash

user=$1
passwd=$2
domain=$3

echo "Checking for Java installation..."
if ( java -version )
then
    echo "Java is installed."
else
    echo "Installing Java..."
    sudo apt update
    sudo apt install openjdk-11-jdk -yq
    echo "Java installed."
fi

echo "Checking for Jenkins..."
if ( sudo systemctl status jenkins ) > /dev/null
then
    echo "Jenkins already installed."
else
    echo "Installing Jenkins..."
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
        /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null
    
    sudo apt update
    sudo apt install jenkins -yq
    
    echo "Jenkins installed."  
fi

if ( netstat -an | grep -w LISTEN | grep -w :8080 ) >/dev/null
then
    echo "Port 8080 is in use."
    port=8081
else
    echo "Port 8080 is available."
    port=8080
if

java -jar jenkins.war --httpPort=$port
perm="--permanent"
serv="$perm --service=jenkins"

echo "Checking if firewall is enabled..."
if [ "ufw status | grep -q 'Status: active'" ]
then
    echo "Firewall is enabled"
else
    echo "Firewall is disabled. Enabling..."
    sudo ufw enable
fi

echo "Configuring the firewall to allow Jenkins..."
sudo ufw $perm --new-service=jenkins
sudo ufw $serv --set-short="Jenkins ports"
sudo ufw $serv --set-description="Jenkins port exceptions"
sudo ufw $serv --add-port=$port/tcp
sudo ufw $perm --add-service=jenkins
sudo ufw --zone=public --add-service=http --permanent
sudo ufw --reload


echo "Starting jenkins service..."
sudo systemctl start jenkins.service

if ( wget -V )
then
    echo "Wget is already installed."
else
    echo "Installing wget..."
    sudo apt install -yq wget
fi

if [ -e ./jenkins/jnlpJars/jenkins-cli.jar ]
then
    echo "Jenkins-cli already exists."
else
    echo "Downloading jenkins-cli.jar..."
    wget -nHP jenkins "http://localhost:$port/jnlpJars/jenkins-cli.jar"
fi

echo "--httpPort $port" | java -jar ./jenkins/jnlpJars/jenkins.war --paramsFromStdIn

if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]
then
    echo "Retrieving jenkins initial password..."
    jenkinsPassword=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
else
    echo "InitialAdminPassword file does not exist."
fi

if [ -f /etc/sysconfig/jenkins ]
then
    jenkinsUser=$(grep JENKINS_USER /etc/sysconfig/jenkins)
else
    jenkinsUser="admin"
fi

echo "Installing recommended plugins..."
java -jar /usr/share/jenkins/cli.jar -auth $jenkinsUser:$jenkinsPassword -s http://localhost:$port install-plugin < /usr/share/jenkins/ref/plugins/recommended.txt

echo "Creating $user account in Jenkins..."
echo 'jenkins.model.Jenkins.instance.securityRealm.createAccount("$user", "$passwd")' | java -jar ./jenkins-cli.jar -s "http://127.0.0.1:$port" -auth $jenkinsUser:$jenkinsPassword 

if ! ( cat /etc/hosts | grep jenkins )
then
    echo "Adding jenkins host entry..."
    sudo echo "127.0.0.1 jenkins jenkins" >> /etc/hosts
else
    echo "There is already a jenkins entry in hosts."
fi
exit