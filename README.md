
<div align="center">
    <h1> Relative Path Level 2 Cycle 1 </h1>
</div>
A fully automated application pipeline.


## Usage
The run-vm.sh script installs and configures multipass to run a virtual machine that will host a chosen server on an ARM or X86 Ubuntu based Linux node.  It has a few options available to help install a virtual machine and configure Nginx, Jenkins or GitLab in a virtual machine.  Those options are:

```bash

$ bash run-vm.sh [options]

    -a        Has the options of nginx, gitlab or jenkins.
                        Default: nginx

    -d        Is the domain name that will be used.
                        Default: relativepath.tech

    -h        Is the hostname that will be used.
                        Default: nginx

    -p        Password for the server service being created.
                        Default: adminServerPassword

    -u        Is the username that will be configured on the VM.
                        Default: $USER
                        Your local user account on the host machine.

    -?        This Usage message.

```

Each flag takes one argument.
Example: `bash run-vm.sh -a gitlab -d exampl.com -p gitlabPassword`
