#!/bin/bash

region=$1
name=$2

aws elb describe-load-balancers --region ${region} --query 'LoadBalancerDescriptions[*].[LoadBalancerName]' --output text > configs/lb.txt

while read lb
do
  tag=$(aws elb describe-tags --load-balancer-name ${lb} --region ${region} | grep ${name} | wc -l)
  if [ $tag -gt 0 ]
  then
    echo "${lb}"
  fi
done < configs/lb.txt

rm -rf configs/lb.txt
