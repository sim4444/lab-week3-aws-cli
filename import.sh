#!/usr/bin/env bash

set -eu

# Set key name (change if needed)
key_name="bcitkey"

# Path to existing public key (update if your key is stored elsewhere)
public_key_path="$HOME/do-key.pub"

# Check if the public key file exists
if [ ! -f "$public_key_path" ]; then
    echo "Error: Public key file '$public_key_path' not found!"
    exit 1
fi

# Check if key already exists in AWS
if aws ec2 describe-key-pairs --key-names "$key_name" 2>/dev/null; then
    echo "Key pair '$key_name' already exists in AWS."
    exit 0
fi

# Import the public key to AWS
aws ec2 import-key-pair --key-name "$key_name" --public-key-material fileb://"$public_key_path"

echo "Key pair '$key_name' has been imported successfully."
