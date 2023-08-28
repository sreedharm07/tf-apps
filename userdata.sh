#!/bin/bash

yum install ansible python3.11-pip.noarch boto3 botocore -y &>>/opt/userdata.log
python3.11-pip.noarch boto3 botocore -y &>>/opt/userdata.log

ansible-pull -i localhost, -U https://github.com/sreedharm07/learn-ansible.git main.yml -e component=${component} -e env=${env} &>>/opt/userdata.log


