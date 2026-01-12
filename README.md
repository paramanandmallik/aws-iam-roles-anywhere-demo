# AWS IAM Roles Anywhere Demo

A complete demonstration of AWS IAM Roles Anywhere using certificate-based authentication to obtain temporary AWS credentials without storing long-term access keys.

## What is IAM Roles Anywhere?

AWS IAM Roles Anywhere enables workloads outside of AWS to access AWS resources by using X.509 certificates instead of long-term AWS access keys. This provides:

- **Enhanced Security**: No long-term credentials to manage or rotate
- **Certificate-based Authentication**: Uses PKI infrastructure you already have
- **Temporary Credentials**: Short-lived tokens with automatic expiration
- **Fine-grained Access Control**: Standard IAM policies and roles
- **Zero Trust Architecture**: Aligns with modern security frameworks

## Prerequisites

- AWS CLI installed and configured with administrative permissions
- OpenSSL installed
- Bash shell (Linux/macOS/WSL)
- Internet connection for downloading AWS signing helper

## Quick Start

1. **Clone and setup**:
   ```bash
   git clone <repository-url>
   cd iam-roles-anywhere-demo
   chmod +x *.sh
   ```

2. **Run setup** (creates certificates and AWS resources):
   ```bash
   ./setup.sh
   ```

3. **Run demo** (shows IAM Roles Anywhere in action):
   ```bash
   ./demo.sh
   ```

4. **Test with Java SDK** (optional):
   ```bash
   cd JavaDemo
   ./setup-config.sh
   mvn compile exec:java
   ```

5. **Cleanup** (removes all resources):
   ```bash
   ./cleanup.sh
   ```

## What the Demo Shows

The demo demonstrates:

1. **Certificate Generation**: Creates a CA certificate and client certificate with proper extensions
2. **AWS Resource Setup**: Creates IAM role, trust anchor, and profile
3. **Authentication Flow**: Uses `aws_signing_helper` to exchange certificates for AWS credentials
4. **Permission Testing**: Shows both successful operations and permission boundaries

### Demo Output Example

```
🎯 AWS IAM Roles Anywhere Demo
================================

🔐 Testing IAM Roles Anywhere authentication...

📋 Test 1: Getting caller identity with certificate-based authentication
{
    "UserId": "AROA...:3495443a366e075b8cef160712fee5034339a042",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:assumed-role/IAMRolesAnywhereDemo/3495443a366e075b8cef160712fee5034339a042"
}

📋 Test 2: Listing S3 buckets (ReadOnly access)
2024-01-15 10:30:45 my-bucket-1
2024-01-15 10:30:45 my-bucket-2

📋 Test 3: Trying to create S3 bucket (should fail - ReadOnly access)
✅ Expected failure - ReadOnly access working correctly
```

## How It Works

1. **Certificate Authority**: Creates a self-signed CA certificate
2. **Client Certificate**: Generates a client certificate signed by the CA
3. **Trust Anchor**: Registers the CA certificate with AWS IAM Roles Anywhere
4. **Profile**: Links the trust anchor to an IAM role
5. **Authentication**: `aws_signing_helper` uses the client certificate to assume the role

## Architecture

```
[Client Certificate] → [aws_signing_helper] → [Trust Anchor] → [Profile] → [IAM Role] → [AWS Resources]
```

## Files Structure

```
iam-roles-anywhere-demo/
├── README.md           # This guide
├── setup.sh           # Setup certificates and AWS resources
├── demo.sh            # Run the demonstration
├── cleanup.sh         # Remove all resources
├── JavaDemo/          # Java SDK demonstration
│   ├── pom.xml        # Maven dependencies
│   ├── setup-config.sh # AWS config setup
│   ├── README.md      # Java demo instructions
│   └── src/main/java/
│       └── RolesAnywhereDemo.java # Java demo application
└── certificates/      # Generated certificates (after setup)
    ├── ca-cert.pem    # Certificate Authority certificate
    ├── ca-key.pem     # CA private key
    ├── client-cert.pem # Client certificate
    └── client-key.pem  # Client private key
```

## Java SDK Integration

The demo includes a Java SDK example that demonstrates the same certificate-based authentication using the AWS SDK for Java 2.x.

### Prerequisites for Java Demo
- Java 11 or higher
- Maven 3.6 or higher
- Completed main demo setup

### Running Java Demo
```bash
cd JavaDemo
./setup-config.sh  # Configure AWS profile
mvn compile exec:java  # Run the demo
```

### Java Demo Features
- **ProfileCredentialsProvider**: Uses AWS config file with `credential_process`
- **Automatic Refresh**: SDK handles credential renewal automatically
- **Standard Pattern**: Same approach works with any AWS service client
- **Error Handling**: Demonstrates both successful operations and permission boundaries

### Java Demo Output
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

🎉 Demo completed successfully!
```

## Platform Support

The demo automatically detects your platform and downloads the appropriate AWS signing helper:

- **macOS**: Intel (x86_64) and Apple Silicon (arm64)
- **Linux**: Intel (x86_64) and ARM (aarch64)
- **Windows**: x86_64 (via WSL or Git Bash)

## Security Considerations

### Certificate Security
- **Private Key Protection**: Keep private keys secure and restrict access
- **Certificate Rotation**: Rotate certificates regularly (demo uses 365-day validity)
- **Certificate Validation**: AWS validates certificate chain and expiration
- **Audit Trail**: All actions are logged in CloudTrail with certificate-based identity

### IAM Best Practices
- **Least Privilege**: The demo uses ReadOnlyAccess; use minimal permissions in production
- **Trust Policy Conditions**: Consider adding certificate-based conditions for production
- **Regular Review**: Monitor and review certificate usage and permissions

### Production Recommendations
- Use enterprise CA certificates instead of self-signed
- Implement certificate lifecycle management
- Monitor certificate expiration with AWS notifications
- Use specific IAM policies instead of managed policies
- Consider regional deployment for high availability
- Implement certificate revocation procedures

## Troubleshooting

### Common Issues

1. **"Multiple matching identities"**: Clean up duplicate trust anchors
2. **"AccessDeniedException"**: Check IAM role trust policy format
3. **Certificate errors**: Ensure certificates have proper extensions
4. **Platform not supported"**: Download signing helper manually from AWS documentation

### Debug Commands

```bash
# Check trust anchors
aws rolesanywhere list-trust-anchors

# Check profiles
aws rolesanywhere list-profiles

# Verify certificate
openssl x509 -in certificates/client-cert.pem -text -noout

# Test AWS credentials
aws sts get-caller-identity
```

### Manual Binary Download

If automatic download fails, download the AWS signing helper manually:

1. Visit: https://docs.aws.amazon.com/rolesanywhere/latest/userguide/credential-helper.html
2. Download the appropriate binary for your platform
3. Place it in the demo directory as `aws_signing_helper`
4. Make it executable: `chmod +x aws_signing_helper`

## Production Considerations

### Certificate Management
- **Enterprise CA Integration**: Use your organization's PKI infrastructure
- **Certificate Templates**: Define standard certificate templates with required extensions
- **Automated Renewal**: Implement automated certificate renewal processes
- **Revocation Lists**: Maintain and distribute certificate revocation lists

### Security Hardening
- **Trust Policy Conditions**: Add certificate subject/issuer conditions
- **Session Policies**: Use session policies to further restrict permissions
- **Monitoring**: Implement comprehensive logging and monitoring
- **Network Security**: Use VPC endpoints for private connectivity

### Operational Excellence
- **Infrastructure as Code**: Use CloudFormation or Terraform for resource management
- **CI/CD Integration**: Integrate certificate-based authentication in deployment pipelines
- **Documentation**: Maintain comprehensive documentation for certificate procedures
- **Training**: Ensure teams understand certificate-based authentication concepts

## Learn More

- [IAM Roles Anywhere User Guide](https://docs.aws.amazon.com/rolesanywhere/latest/userguide/)
- [Certificate Requirements](https://docs.aws.amazon.com/rolesanywhere/latest/userguide/trust-model.html)
- [Security Best Practices](https://docs.aws.amazon.com/prescriptive-guidance/latest/certificate-based-access-controls/)
- [AWS Private CA](https://docs.aws.amazon.com/privateca/latest/userguide/)

## Support

For issues with this demo:
1. Check the troubleshooting section above
2. Verify your AWS CLI configuration
3. Ensure all prerequisites are installed
4. Review AWS CloudTrail logs for detailed error information

---

**Note**: This demo is for educational purposes. In production, use proper certificate management, enterprise PKI infrastructure, and minimal IAM permissions following the principle of least privilege.
