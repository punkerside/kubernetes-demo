#!/bin/bash

version="0.12.26"

cd /opt && wget https://releases.hashicorp.com/terraform/${version}/terraform_${version}_linux_amd64.zip
unzip terraform_${version}_linux_amd64.zip
chmod +x terraform
sudo mv terraform /usr/sbin/
rm -rf terraform_${version}_linux_amd64.zip
