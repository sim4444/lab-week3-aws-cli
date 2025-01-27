#!/usr/bin/env bash

set -eu

# Variables
region="us-west-2"
vpc_cidr="10.0.0.0/16"
subnet_cidr="10.0.1.0/24"
key_name="bcitkey"

# Create VPC
vpc_id=$(aws ec2 create-vpc --cidr-block $vpc_cidr --query 'Vpc.VpcId' --output text --region $region)
aws ec2 create-tags --resources $vpc_id --tags Key=Name,Value=MyVPC --region $region

echo "created VPC: $vpc_id"

# enable dns hostname
aws ec2 modify-vpc-attribute --vpc-id $vpc_id --enable-dns-hostnames Value=true --region $region

# Create public subnet
subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id \
  --cidr-block $subnet_cidr \
  --availability-zone ${region}a \
  --query 'Subnet.SubnetId' \
  --output text --region $region)

aws ec2 create-tags --resources $subnet_id --tags Key=Name,Value=PublicSubnet --region $region

# Create internet gateway
igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' \
  --output text --region $region)

aws ec2 attach-internet-gateway --vpc-id $vpc_id --internet-gateway-id $igw_id --region $region

# Create route table
route_table_id=$(aws ec2 create-route-table --vpc-id $vpc_id \
  --query 'RouteTable.RouteTableId' \
  --region $region \
  --output text)

# Associate route table with public subnet
aws ec2 associate-route-table --subnet-id $subnet_id --route-table-id $route_table_id --region $region

# Create route to the internet via the internet gateway
aws ec2 create-route --route-table-id $route_table_id \
  --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id --region $region

# Write infrastructure data to a file
echo "vpc_id=${vpc_id}" > infrastructure_data
echo "subnet_id=${subnet_id}" >> infrastructure_data

