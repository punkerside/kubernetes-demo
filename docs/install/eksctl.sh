#!/bin/bash

curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
<<<<<<< HEAD
sudo mv /tmp/eksctl /usr/local/bin
=======
sudo mv /tmp/eksctl /usr/local/bin
>>>>>>> 8ababbf (corrigiendo errores)
