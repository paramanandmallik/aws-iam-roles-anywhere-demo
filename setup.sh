#!/bin/bash

# AWS IAM Roles Anywhere Demo Setup Script
set -e

echo "🚀 Setting up AWS IAM Roles Anywhere Demo..."

# Check prerequisites
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install AWS CLI first."
    exit 1
fi

if ! command -v openssl &> /dev/null; then
    echo "❌ OpenSSL not found. Please install OpenSSL first."
    exit 1
fi

# Verify AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

# Generate certificates
echo "📜 Generating certificates..."
mkdir -p certificates

# Generate CA private key
openssl genrsa -out certificates/ca-key.pem 2048

# Generate CA certificate with proper extensions
openssl req -new -x509 -key certificates/ca-key.pem -out certificates/ca-cert.pem -days 365 \
    -subj "/C=US/ST=CA/L=San Francisco/O=Demo/CN=Demo CA" \
    -extensions v3_ca -config <(
cat <<EOF
[req]
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_ca]
basicConstraints = critical,CA:TRUE
keyUsage = critical,keyCertSign,cRLSign
EOF
)

# Generate client private key
openssl genrsa -out certificates/client-key.pem 2048

# Generate client certificate signing request
openssl req -new -key certificates/client-key.pem -out certificates/client.csr \
    -subj "/C=US/ST=CA/L=San Francisco/O=Demo/CN=Demo Client"

# Generate client certificate signed by CA with required extensions for IAM Roles Anywhere
openssl x509 -req -in certificates/client.csr -CA certificates/ca-cert.pem -CAkey certificates/ca-key.pem \
    -CAcreateserial -out certificates/client-cert.pem -days 365 \
    -extensions v3_req -extfile <(
cat <<EOF
[v3_req]
basicConstraints = CA:FALSE
keyUsage = critical,digitalSignature,keyEncipherment
EOF
)

# Clean up CSR
rm certificates/client.csr

echo "✅ Certificates generated successfully!"

# Setup AWS resources
echo "🔧 Setting up AWS resources..."

# Create IAM role with proper trust policy
ROLE_NAME="IAMRolesAnywhereDemo"
TRUST_POLICY='{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "rolesanywhere.amazonaws.com"
      },
      "Action": [
        "sts:AssumeRole",
        "sts:TagSession",
        "sts:SetSourceIdentity"
      ]
    }
  ]
}'

if aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document "$TRUST_POLICY" 2>/dev/null; then
    echo "✅ IAM role created: $ROLE_NAME"
else
    echo "ℹ️  IAM role already exists: $ROLE_NAME"
    # Update trust policy in case it was incorrect
    aws iam update-assume-role-policy --role-name $ROLE_NAME --policy-document "$TRUST_POLICY"
fi

# Attach read-only policy
if aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess 2>/dev/null; then
    echo "✅ ReadOnlyAccess policy attached"
else
    echo "ℹ️  ReadOnlyAccess policy already attached"
fi

# Get role ARN
ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME --query 'Role.Arn' --output text)
echo "Role ARN: $ROLE_ARN"

# Create trust anchor using the SAME CA certificate that signed the client certificate
echo "📋 Creating trust anchor..."

# Delete existing trust anchor with same name to avoid conflicts
EXISTING_TA_ID=$(aws rolesanywhere list-trust-anchors --query 'trustAnchors[?name==`DemoTrustAnchor`].trustAnchorId' --output text 2>/dev/null)
if [ -n "$EXISTING_TA_ID" ] && [ "$EXISTING_TA_ID" != "None" ]; then
    echo "🗑️  Removing existing trust anchor to ensure certificate consistency"
    aws rolesanywhere delete-trust-anchor --trust-anchor-id "$EXISTING_TA_ID" >/dev/null 2>&1 || true
fi

# Handle base64 encoding cross-platform
if base64 --help 2>&1 | grep -q "wrap" 2>/dev/null; then
    CERT_DATA=$(cat certificates/ca-cert.pem | base64 -w 0)
else
    CERT_DATA=$(cat certificates/ca-cert.pem | base64 | tr -d '\n')
fi

# Create JSON file for trust anchor
cat > /tmp/trust-anchor.json <<EOF
{
  "name": "DemoTrustAnchor",
  "source": {
    "sourceType": "CERTIFICATE_BUNDLE",
    "sourceData": {
      "x509CertificateData": "$CERT_DATA"
    }
  },
  "enabled": true
}
EOF

if TRUST_ANCHOR_ARN=$(aws rolesanywhere create-trust-anchor --cli-input-json file:///tmp/trust-anchor.json --query 'trustAnchor.trustAnchorArn' --output text 2>/dev/null); then
    echo "✅ Trust anchor created with current CA certificate: $TRUST_ANCHOR_ARN"
else
    echo "❌ Failed to create trust anchor"
    exit 1
fi

# Delete existing profile to ensure clean state
EXISTING_PROFILE_ID=$(aws rolesanywhere list-profiles --query 'profiles[?name==`DemoProfile`].profileId' --output text 2>/dev/null)
if [ -n "$EXISTING_PROFILE_ID" ] && [ "$EXISTING_PROFILE_ID" != "None" ]; then
    echo "🗑️  Removing existing profile to ensure clean state"
    aws rolesanywhere delete-profile --profile-id "$EXISTING_PROFILE_ID" >/dev/null 2>&1 || true
fi

# Create profile (enabled by default)
if PROFILE_ARN=$(aws rolesanywhere create-profile --name "DemoProfile" --role-arns "$ROLE_ARN" --enabled --query 'profile.profileArn' --output text 2>/dev/null); then
    echo "✅ Profile created and enabled: $PROFILE_ARN"
else
    echo "❌ Failed to create profile"
    exit 1
fi

# Clean up temp file
rm -f /tmp/trust-anchor.json

echo "✅ AWS resources configured successfully!"

# Download signing helper with platform detection
if [ ! -f "aws_signing_helper" ]; then
    echo "📥 Downloading AWS signing helper..."
    
    OS=$(uname -s)
    ARCH=$(uname -m)
    
    case "$OS-$ARCH" in
        Darwin-x86_64) URL="https://rolesanywhere.amazonaws.com/releases/1.7.1/X86_64/MacOS/Ventura/aws_signing_helper" ;;
        Darwin-arm64) URL="https://rolesanywhere.amazonaws.com/releases/1.7.1/Aarch64/MacOS/Sonoma/aws_signing_helper" ;;
        Linux-x86_64) URL="https://rolesanywhere.amazonaws.com/releases/1.7.1/X86_64/Linux/Amzn2023/aws_signing_helper" ;;
        Linux-aarch64) URL="https://rolesanywhere.amazonaws.com/releases/1.7.1/Aarch64/Linux/Amzn2023/aws_signing_helper" ;;
        CYGWIN*|MINGW*|MSYS*) URL="https://rolesanywhere.amazonaws.com/releases/1.7.1/X86_64/Windows/Server2019/aws_signing_helper.exe" ;;
        *) echo "❌ Unsupported platform: $OS-$ARCH"; echo "Please download manually from: https://docs.aws.amazon.com/rolesanywhere/latest/userguide/credential-helper.html"; exit 1 ;;
    esac
    
    if curl -L -f -o aws_signing_helper "$URL" && [ -s aws_signing_helper ]; then
        chmod +x aws_signing_helper
        echo "✅ AWS signing helper downloaded for $OS-$ARCH"
    else
        echo "❌ Failed to download aws_signing_helper"
        echo "Please download manually from: https://docs.aws.amazon.com/rolesanywhere/latest/userguide/credential-helper.html"
        exit 1
    fi
fi

echo ""
echo "🎉 Setup complete! Next steps:"
echo "1. Run: ./demo.sh"
echo "2. Check the output to see IAM Roles Anywhere in action!"