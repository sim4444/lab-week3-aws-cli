#!/usr/bin/env bash

set -eu  # Exit on error and undefined variables

region="us-west-2"
key_name="bcitkey"

# Load VPC and Subnet info from infrastructure_data
if [ ! -f ./infrastructure_data ]; then
    echo "Error: infrastructure_data file not found! Run complete_vpc.sh first."
    exit 1
fi

source ./infrastructure_data

# Get the latest Ubuntu 23.04 AMI ID
ubuntu_ami=$(aws ec2 describe-images --region $region \
    --owners amazon \
    --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-lunar-23.04-amd64-server*" \
    --query 'sort_by(Images, &CreationDate)[-1].ImageId' --output text)

echo "Using Ubuntu AMI: $ubuntu_ami"

# Create security group allowing SSH (22) and HTTP (80)
security_group_id=$(aws ec2 create-security-group --group-name MySecurityGroup \
    --description "Allow SSH and HTTP" --vpc-id $vpc_id --query 'GroupId' --region $region --output text)

echo "Created Security Group: $security_group_id"

aws ec2 authorize-security-group-ingress --group-id $security_group_id --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $region
aws ec2 authorize-security-group-ingress --group-id $security_group_id --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $region

# Launch an EC2 instance in the public subnet with auto-assign public IP enabled
instance_id=$(aws ec2 run-instances --image-id $ubuntu_ami \
    --count 1 --instance-type t2.micro \
    --key-name $key_name \
    --security-group-ids $security_group_id \
    --subnet-id $subnet_id \
    --associate-public-ip-address \
    --query 'Instances[0].InstanceId' --output text --region $region)

echo "Launching EC2 Instance: $instance_id"

# Wait for EC2 instance to be running
aws ec2 wait instance-running --instance-ids $instance_id --region $region
echo "Instance $instance_id is now running."

# Retrieve the public IP address
public_ip=$(aws ec2 describe-instances --instance-ids $instance_id \
    --query 'Reservations[0].Instances[0].PublicIpAddress' --output text --region $region)

# Associate an Elastic IP if auto-assigned public IP is missing
if [[ -z "$public_ip" || "$public_ip" == "None" ]]; then
    echo "Instance did not receive a public IP. Assigning an Elastic IP..."
    
    allocation_id=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text --region $region)
    aws ec2 associate-address --instance-id $instance_id --allocation-id $allocation_id --region $region

    # Retrieve the newly assigned Elastic IP
    public_ip=$(aws ec2 describe-addresses --allocation-ids $allocation_id \
        --query 'Addresses[0].PublicIp' --output text --region $region)
fi

echo "EC2 Instance Public IP: $public_ip"

# Write instance details to a file
echo "Instance ID: $instance_id" > instance_data
echo "Public IP: $public_ip" >> instance_data

echo "Instance launched successfully! Connect using:"
echo "ssh -i $key_name ubuntu@$public_ip"
