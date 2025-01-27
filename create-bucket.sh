#!/usr/bin/env bash

# Check if the number of command-line arguments is correct
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <bucket_name>"
    exit 1
fi

# pass the bucket name as a positional parameter
bucket_name=$1

# Check if the bucket exists
if aws s3api head-bucket --bucket "$bucket_name" 2>/dev/null; then
    echo "Bucket $bucket_name already exists."
else
  # change the line below
  aws s3api create-bucket --bucket "$bucket_name" \
        --region "$region" \
        --create-bucket-configuration LocationConstraint="$region"
  echo "Bucket '$bucket_name' created successfully in region '$region'."
fi

