#!/bin/bash

# More info at https://docs.docker.com/install/linux/docker-ce/centos/#set-up-the-repository

# ARE YOU ROOT (or sudo)?
if [[ $EUID -ne 0 ]]; then
	echo -e "\e[91mERROR: This script must be run as root\e[0m"
	exit 1
fi


kernel_version=$(uname -r | cut -f1 -d.)
centos_version=$(rpm -qa \*-release | grep -Ei "oracle|redhat|centos" | cut -d"-" -f3)


# kernel version 3.10 (or greater) is needed
if [ "$kernel_version" -lt 3 ]; then
  read -r -p "Your kernel needs an update. Update kernel (system will reboot)? [y/N] " response
  res=${response,,} # tolower
  if ! [[ $res =~ ^(yes|y)$ ]]; then
    echo "Aborted. Docker is not compatible with your kernel version :("
    exit 1
  fi
  
  rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
  if [ "$centos_version" -eq 6 ]; then
    rpm -Uvh http://www.elrepo.org/elrepo-release-6-8.el6.elrepo.noarch.rpm
  else
    rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
  fi
  yum --enablerepo=elrepo-kernel install kernel-lt
  
  # Many thanks to http://wiki.centos-webpanel.com/kernel-update
  sed -i "s|default=1|default=0|g" /etc/grub.conf # Activamos el nuevo kernel para el arranque
  
  echo "System is going to reboot now"
  echo -e "\e[91mDocker is not installed yet. Please, run this script again after reboot to install Docker.\e[0m"
  reboot
fi


if [ "$centos_version" -eq 6 ]; then
	# docker is part of Extra Packages for Enterprise Linux (EPEL)
	yum install epel-release -y
	#rpm -iUvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
	yum install docker-io -y
	service docker start
	
else
	# uninstall old versions:
	yum remove docker docker-common docker-selinux docker-engine
	# Images, containers, volumes, or customized configuration files on your host are not automatically removed.
	# To delete all images, containers, and volumes:
	# rm -rf /var/lib/docker

	# set up the repository:
	yum install -y yum-utils device-mapper-persistent-data lvm2

	yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo/ # needs last "/"

	# install docker ce:
	yum install docker-ce
	
	# Post-installation steps:
	echo "Read https://docs.docker.com/install/linux/linux-postinstall/ if you don't want to use sudo when you use the docker command."
	
fi

chkconfig docker on

docker run hello-world
