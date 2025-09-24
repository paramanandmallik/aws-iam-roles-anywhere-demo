# Java SDK Demo for IAM Roles Anywhere

This demo shows how to use AWS IAM Roles Anywhere with the Java SDK using certificate-based authentication.

## Prerequisites

- Java 11 or higher
- Maven 3.6 or higher
- Completed main demo setup (certificates and AWS resources created)

## Quick Start

1. **Setup AWS configuration**:
   ```bash
   cd JavaDemo
   ./setup-config.sh
   ```

2. **Run the demo**:
   ```bash
   mvn compile exec:java
   ```

## What It Demonstrates

- **Certificate-based Authentication**: Uses existing certificates to authenticate with AWS
- **Automatic Credential Refresh**: SDK handles token renewal automatically
- **Permission Testing**: Shows both successful operations and permission boundaries
- **Standard SDK Pattern**: Uses ProfileCredentialsProvider like any other credential source

## Files

- `pom.xml` - Maven dependencies for AWS SDK
- `src/main/java/RolesAnywhereDemo.java` - Main demo application
- `setup-config.sh` - Script to configure AWS profile
- `README.md` - This file

## How It Works

1. The setup script creates an AWS profile named `rolesanywhere-demo` in `~/.aws/config`
2. This profile uses `credential_process` to call the `aws_signing_helper` tool
3. The Java application uses `ProfileCredentialsProvider` to load credentials from this profile
4. The SDK automatically calls the credential process when tokens need refresh

## Expected Output

```
🎯 AWS IAM Roles Anywhere Java SDK Demo
========================================

📋 Test 1: Getting caller identity with certificate-based authentication
User ID: AROA...:3495443a366e075b8cef160712fee5034339a042
Account: 123456789012
ARN: arn:aws:sts::123456789012:assumed-role/IAMRolesAnywhereDemo/3495443a366e075b8cef160712fee5034339a042

📋 Test 2: Listing S3 buckets (ReadOnly access)
2024-01-15T10:30:45Z my-bucket-1
2024-01-15T10:30:45Z my-bucket-2

📋 Test 3: Trying to create S3 bucket (should fail - ReadOnly access)
✅ Expected failure - ReadOnly access working correctly
Error: Access Denied

🎉 Demo completed successfully!
```