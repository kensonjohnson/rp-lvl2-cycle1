    scp -i ./id_ed25519 -o StrictHostKeyChecking=no install-webserver.sh infradog@$(multipass info infradog | grep IPv4 | awk '{print $2}'):/home/infradog


    echo $( hostname -I | awk '{ print $1 }' )

    /etc/gitlab/initial_root_password

    /var/lib/jenkins/secrets/initialAdminPassword