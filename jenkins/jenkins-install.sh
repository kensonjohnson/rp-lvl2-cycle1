#!/bin/bash

user=$1
passwd=$2
domain=$3

# Necessary as a prerequisite of Jenkins
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

echo "Determining if port 8080 is in use..."
# Uses Netstat to list active internet connections.  This is piped to grep that 
# looks for the LISTEN state of a port.  When an entry is found it pipes the entry
# to another grep to examine the entry for port 8080.
if ( netstat -an | grep -w LISTEN | grep -w 8080 ) >/dev/null
then
    echo "Port 8080 is in use."
    port=8081
else
    echo "Port 8080 is available."
    port=8080
fi

# Setting the variables for the firewall configuration.
perm="--permanent"
serv="$perm --service=jenkins"

echo "Checking if firewall is enabled..."
if ( sudo ufw status | grep -q 'Status: active' )
then
    echo "Firewall is enabled"
else
    echo "Firewall is disabled. Enabling..."
    sudo ufw enable
fi

echo "Configuring the firewall to allow Jenkins..."
# Define the new service that will be configured in the firewall.
sudo ufw $perm --new-service=jenkins
# Define the short and long descriptions of the jenkin service firewall rule.
sudo ufw $serv --set-short="Jenkins ports"
sudo ufw $serv --set-description="Jenkins port exceptions"
# Assign the port to the service.
sudo ufw $serv --add-port=$port/tcp
# Add a firewall rule for the jenkins service.
sudo ufw $perm --add-service=jenkins
# Define the firewall rule for the jenkins service.
sudo ufw --zone=public --add-service=http --permanent
# Restart the firewall service to offer the new rule just created.
sudo ufw --reload


echo "Starting jenkins service..."
sudo systemctl start jenkins.service

echo "Checking if wget is installed..."
if ( wget -V )
then
    echo "Wget is already installed."
else
    echo "Installing wget..."
    sudo apt install -yq wget
fi

echo "Checking for the jenkins command line interface library..."
if [ -e ./jenkins/jnlpJars/jenkins-cli.jar ]
then
    echo "Jenkins-cli already exists."
else
    echo "Downloading jenkins-cli.jar..."
    wget -rnH -P jenkins "http://localhost:$port/jnlpJars/jenkins-cli.jar"
fi

# Ensuring the port to be used is assigned to the jenkins service.
echo "--httpPort $port" | java -jar ./jenkins/jnlpJars/jenkins-cli.jar --paramsFromStdIn

echo "Checking for the initial admin password..."
if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]
then
    echo "Retrieving jenkins initial password..."
    jenkinsPassword=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
else
    echo "InitialAdminPassword file does not exist."
fi

echo "Retrieving the jenkins default user..."
if [ -f /etc/sysconfig/jenkins ]
then
    jenkinsUser=$(grep JENKINS_USER /etc/sysconfig/jenkins)
else
    jenkinsUser="admin"
fi

echo "Installing recommended plugins..."
java -jar /jenkins/jnlpJars/cli.jar -auth $jenkinsUser:$jenkinsPassword -s http://localhost:$port install-plugin < /usr/share/jenkins/ref/plugins/recommended.txt

echo "Creating $user account in Jenkins..."
echo 'jenkins.model.Jenkins.instance.securityRealm.createAccount("$user", "$passwd")' | java -jar ./jenkins-cli.jar -s "http://127.0.0.1:$port" -auth $jenkinsUser:$jenkinsPassword 

exit