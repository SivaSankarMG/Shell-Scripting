#!/bin/bash

set -x

# Store the AWS account ID in a variable
aws_account_id=$(aws sts get-caller-identity --query 'Account' --output text)

# Print the AWS account ID from the variable
echo "AWS Account ID: $aws_account_id"

# Set AWS region and bucket name
aws_region="ap-south-1"
bucket_name="blogs-store"
lambda_func_name="s3-lambda-function"
role_name="s3-lambda-sns"
email_address="xyz@gmail.com"

# Check if IAM Role already exists
existing_role=$(aws iam get-role --role-name "$role_name" 2>/dev/null)

if [ -z "$existing_role" ]; then
  echo "Creating IAM role $role_name..."
  role_response=$(aws iam create-role --role-name $role_name --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": [
           "lambda.amazonaws.com",
           "s3.amazonaws.com",
           "sns.amazonaws.com"
        ]
      }
    }]
  }')

  # Extract the role ARN from the JSON response and store it in a variable
  role_arn=$(echo "$role_response" | jq -r '.Role.Arn')
  echo "Role ARN: $role_arn"

  # Attach Permissions to the Role
  aws iam attach-role-policy --role-name $role_name --policy-arn arn:aws:iam::aws:policy/AWSLambda_FullAccess
  aws iam attach-role-policy --role-name $role_name --policy-arn arn:aws:iam::aws:policy/AmazonSNSFullAccess
else
  echo "IAM role $role_name already exists."
fi

# Check if S3 bucket exists
existing_bucket=$(aws s3api head-bucket --bucket "$bucket_name" 2>/dev/null)

if [ $? -ne 0 ]; then
  echo "Creating S3 bucket $bucket_name..."
  bucket_output=$(aws s3api create-bucket --bucket "$bucket_name" --region "$aws_region" --create-bucket-configuration LocationConstraint=$aws_region)
  echo "Bucket creation output: $bucket_output"
else
  echo "S3 bucket $bucket_name already exists."
fi

# Check if Lambda function exists
existing_lambda=$(aws lambda get-function --function-name "$lambda_func_name" 2>/dev/null)

if [ -z "$existing_lambda" ]; then
  echo "Creating Lambda function $lambda_func_name..."
  zip -r s3-lambda-function.zip ./lambda-functions

  aws lambda create-function \
    --region "$aws_region" \
    --function-name $lambda_func_name \
    --runtime "python3.8" \
    --handler "lambda-functions/s3-lambda-function.lambda_handler" \
    --memory-size 128 \
    --timeout 30 \
    --role "arn:aws:iam::$aws_account_id:role/$role_name" \
    --zip-file "fileb://./s3-lambda-function.zip"
else
  echo "Lambda function $lambda_func_name already exists."
fi

# Check if Lambda permission for S3 exists
permission_exists=$(timeout 10 aws lambda get-policy --function-name "$lambda_func_name" | grep "s3.amazonaws.com" 2>/dev/null)

if [ -z "$permission_exists" ]; then
  echo "Adding S3 permission to Lambda function $lambda_func_name..."
  aws lambda add-permission \
    --function-name "$lambda_func_name" \
    --statement-id "s3-lambda-sns" \
    --action "lambda:InvokeFunction" \
    --principal s3.amazonaws.com \
    --source-arn "arn:aws:s3:::$bucket_name"
else
  echo "Lambda permission for S3 already exists."
fi

# Check if S3 event trigger is already set up
existing_notification=$(aws s3api get-bucket-notification-configuration --bucket "$bucket_name" 2>/dev/null | grep "$lambda_func_name")

if [ -z "$existing_notification" ]; then
  echo "Adding S3 event trigger for Lambda function $lambda_func_name..."
  LambdaFunctionArn="arn:aws:lambda:ap-south-1:$aws_account_id:function:$lambda_func_name"
  aws s3api put-bucket-notification-configuration \
    --region "$aws_region" \
    --bucket "$bucket_name" \
    --notification-configuration '{
      "LambdaFunctionConfigurations": [{
          "LambdaFunctionArn": "'"$LambdaFunctionArn"'",
          "Events": ["s3:ObjectCreated:*"]
      }]
    }'
else
  echo "S3 event trigger for Lambda function $lambda_func_name already exists."
fi

# Check if SNS topic exists
topic_arn=$(aws sns list-topics --query "Topics[?contains(TopicArn, '$lambda_func_name')].TopicArn" --output text)

if [ -z "$topic_arn" ]; then
  echo "Creating SNS topic..."
  topic_arn=$(aws sns create-topic --name $lambda_func_name --output json | jq -r '.TopicArn')
else
  echo "SNS topic already exists: $topic_arn"
fi

# Check if SNS subscription exists for the email
existing_subscription=$(aws sns list-subscriptions-by-topic --topic-arn "$topic_arn" --query "Subscriptions[?Endpoint=='$email_address']" --output text)

if [ -z "$existing_subscription" ]; then
  echo "Subscribing $email_address to SNS topic $topic_arn..."
  aws sns subscribe \
    --topic-arn "$topic_arn" \
    --protocol email \
    --notification-endpoint "$email_address"
else
  echo "Email $email_address is already subscribed to SNS topic."
fi
