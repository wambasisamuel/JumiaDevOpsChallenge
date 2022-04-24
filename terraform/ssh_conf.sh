#!/bin/bash
sudo sed -i 's/^#?Port 22$/Port 1337/g' /etc/ssh/sshd_config
sudo service sshd restart 
