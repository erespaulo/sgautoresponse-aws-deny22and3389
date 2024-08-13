# AWS Lambda Deployment - Sg Auto Response - Denying port 22 and 3389 via Terraform

This project makes it easy to create and configure the following resources in AWS using Terraform:

1. **Lambda Function**: Function to automate responses to changes in Security Groups.
2. **SNS Subscription**: Subscribes to the email address for automatic notifications.
3. **EventBridge CloudWatch Event Rule**: Creates event rules to monitor changes in Security Groups.
4. **IAM Role**: Defines the permissions required for Lambda to execute its functions.

## Prerequisites

Before running the code, make sure you have the following items ready:

1. **Lambda ZIP**: Upload the ZIP file containing the Lambda code to an S3 bucket in the target account.
2. **VPC ID**: Identify the ID of the VPC in which the Lambda will be executed.
3. **Endereço de Email para Notificações**: Have the email address that will be subscribed to SNS to receive notifications ready.

## How to run

1. **Upload the code**:
   - Upload the Lambda ZIP file to an S3 bucket in your target account.

2. **Identify the VPC**:
   - Find the ID of the VPC where Lambda will be deployed

3. **Running Terraform**:
   - Run the terraform apply command, specifying the VPC ID, the email address for notifications, and the name of the bucket where the ZIP file was uploaded.

### Command example:

```bash
terraform apply -var 'vpc_id=vpc-00000XPTO' -var 'notification_email_address=email@example.com' -var 'namebucket=name_of_bucket_s3'
```

Based on AWS Cloudformation : https://s3.amazonaws.com/aws-security-blog-content/public/sample/revertsecuritygroupchanges/security-group-change-auto-response.yaml
