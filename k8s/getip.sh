#!/bin/bash

OWNER=$1
ENV=$2
AWS_REGION=$3

mkdir -p tmp/ && rm -rf tmp/elb.txt
aws elb --region ${AWS_REGION} describe-load-balancers --query 'LoadBalancerDescriptions[].LoadBalancerName' --output text > tmp/elb.txt

while read line
do
    ELB_CHECK=`aws elb describe-tags --region ${AWS_REGION} --load-balancer-name ${line} | grep ${OWNER}-${ENV} | wc -l`
    if [ ${ELB_CHECK} -gt 0 ]; then
        ELB_DNS=`aws elb describe-load-balancers --region ${AWS_REGION} --load-balancer-name ${line} --query 'LoadBalancerDescriptions[].CanonicalHostedZoneName' --output text`
    fi
done <  tmp/elb.txt

ELB_IP=`host ${ELB_DNS} | grep -v "found" | wc -l`
while :
do
    if [ ${ELB_IP} -gt 0 ]; then
        ELB_IP=`host ${ELB_DNS} | head -1 | grep -v "found" | awk '{print $4}'`
        echo "${ELB_IP} guestbook.kubernetes.io"
        break
    fi    
	echo "esperando resolucion dns del elb"
	sleep 15
    ELB_IP=`host ${ELB_DNS} | grep -v "found" | wc -l`
done

rm -rf tmp/elb.txt
