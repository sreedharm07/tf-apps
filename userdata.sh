#!/bin/bash

wget https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem &>>/opt/userdata.log

ansible-pull -i localhost, -U https://github.com/sreedharm07/roboshop-ansible.git main.yml -e component=${component} -e env=${env} &>>/opt/userdata.log


