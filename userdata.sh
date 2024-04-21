#!bin/bash

#update instance and install ansible
#this instance is an ubuntu system
# as apt-get cmd is for ubuntu system
sudo apt-get update -y
sudo apt-get install software-properties-common -y
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt-get install ansible -y
sudo hostnamectl set-hostname ansible