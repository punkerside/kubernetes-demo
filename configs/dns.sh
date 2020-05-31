#!/bin/bash

profile=$1
region=$2
name=$3

aws elb describe-load-balancers --profile ${profile} --region ${region} --query 'LoadBalancerDescriptions[*].[LoadBalancerName]' --output text > configs/lb.txt

while read lb
do
  tag=$(aws elb describe-tags --load-balancer-name ${lb} --profile ${profile} --region ${region} | grep ${name} | wc -l)
  if [ $tag -gt 0 ]
  then
    echo "${lb}"
  fi
done < configs/lb.txt

rm -rf configs/lb.txt
