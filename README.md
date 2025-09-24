# AWS IAM Roles Anywhere Demo

A complete demonstration of AWS IAM Roles Anywhere using certificate-based authentication to obtain temporary AWS credentials without storing long-term access keys.

## What is IAM Roles Anywhere?

AWS IAM Roles Anywhere enables workloads outside of AWS to access AWS resources by using X.509 certificates instead of long-term AWS access keys. This provides:

- **Enhanced Security**: No long-term credentials to manage or rotate
- **Certificate-based Authentication**: Uses PKI infrastructure you already have
- **Temporary Credentials**: Short-lived tokens with automatic expiration
- **Fine-grained Access Control**: Standard IAM policies and roles

## Prerequisites

- AWS CLI installed and configured with administrative permissions
- OpenSSL installed
- Bash shell (Linux/macOS/WSL)

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

4. **Cleanup** (removes all resources):
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
    "UserId": "AROA...:botocore-session-1234567890",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:assumed-role/IAMRolesAnywhereDemo/botocore-session-1234567890"
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
└── certificates/      # Generated certificates (after setup)
    ├── ca-cert.pem    # Certificate Authority certificate
    ├── ca-key.pem     # CA private key
    ├── client-cert.pem # Client certificate
    └── client-key.pem  # Client private key
```

## Security Considerations

- **Certificate Security**: Keep private keys secure and rotate certificates regularly
- **Least Privilege**: The demo uses ReadOnlyAccess; use minimal permissions in production
- **Certificate Validation**: AWS validates certificate chain and expiration
- **Audit Trail**: All actions are logged in CloudTrail with certificate-based identity

## Troubleshooting

### Common Issues

1. **"Multiple matching identities"**: Clean up duplicate trust anchors
2. **"AccessDeniedException"**: Check IAM role trust policy format
3. **Certificate errors**: Ensure certificates have proper extensions

### Debug Commands

```bash
# Check trust anchors
aws rolesanywhere list-trust-anchors

# Check profiles
aws rolesanywhere list-profiles

# Verify certificate
openssl x509 -in certificates/client-cert.pem -text -noout
```

## Production Considerations

- Use enterprise CA certificates instead of self-signed
- Implement certificate rotation procedures
- Monitor certificate expiration
- Use specific IAM policies instead of ReadOnlyAccess
- Consider regional deployment for high availability

## Learn More

- [AWS IAM Roles Anywhere Documentation](https://docs.aws.amazon.com/rolesanywhere/)
- [IAM Roles Anywhere User Guide](https://docs.aws.amazon.com/rolesanywhere/latest/userguide/)
- [Certificate Requirements](https://docs.aws.amazon.com/rolesanywhere/latest/userguide/trust-model.html)

---

**Note**: This demo is for educational purposes. In production, use proper certificate management and minimal IAM permissions.