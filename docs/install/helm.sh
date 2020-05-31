#!/bin/bash

version="v3.2.1"

cd /opt && wget https://get.helm.sh/helm-${version}-linux-amd64.tar.gz
tar -zxvf helm-${version}-linux-amd64.tar.gz
mv linux-amd64/helm /usr/sbin/
