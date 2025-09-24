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

# Generate client certificate signed by CA
openssl x509 -req -in certificates/client.csr -CA certificates/ca-cert.pem -CAkey certificates/ca-key.pem \
    -CAcreateserial -out certificates/client-cert.pem -days 365 \
    -extensions v3_req -extfile <(
cat <<EOF
[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation,digitalSignature,keyEncipherment
EOF
)

# Clean up CSR
rm certificates/client.csr

echo "✅ Certificates generated successfully!"

# Setup AWS resources
echo "🔧 Setting up AWS resources..."

# Create IAM role
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
      ],
      "Condition": {
        "StringEquals": {
          "aws:SourceArn": "arn:aws:rolesanywhere:*:*:trust-anchor/*"
        }
      }
    }
  ]
}'

aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document "$TRUST_POLICY" || echo "Role may already exist"

# Attach read-only policy
aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess || echo "Policy may already be attached"

# Get role ARN
ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME --query 'Role.Arn' --output text)
echo "Role ARN: $ROLE_ARN"

# Create trust anchor
TRUST_ANCHOR_ARN=$(aws rolesanywhere create-trust-anchor \
    --name "DemoTrustAnchor" \
    --source sourceType=CERTIFICATE_BUNDLE,sourceData="{\"x509CertificateData\":\"$(cat certificates/ca-cert.pem | base64 -w 0)\"}" \
    --query 'trustAnchor.trustAnchorArn' --output text 2>/dev/null || echo "Trust anchor may already exist")

if [ "$TRUST_ANCHOR_ARN" != "Trust anchor may already exist" ]; then
    echo "Trust Anchor ARN: $TRUST_ANCHOR_ARN"
fi

# Create profile
PROFILE_ARN=$(aws rolesanywhere create-profile \
    --name "DemoProfile" \
    --role-arns "$ROLE_ARN" \
    --query 'profile.profileArn' --output text 2>/dev/null || echo "Profile may already exist")

if [ "$PROFILE_ARN" != "Profile may already exist" ]; then
    echo "Profile ARN: $PROFILE_ARN"
fi

echo "✅ AWS resources created successfully!"

# Download signing helper if not exists
if [ ! -f "aws_signing_helper" ]; then
    echo "📥 Downloading AWS signing helper..."
    curl -L -o aws_signing_helper https://rolesanywhere.amazonaws.com/releases/1.7.1/X86_64/Linux/aws_signing_helper
    chmod +x aws_signing_helper
    echo "✅ AWS signing helper downloaded!"
fi

echo ""
echo "🎉 Setup complete! Next steps:"
echo "1. Run: ./demo.sh"
echo "2. Check the output to see IAM Roles Anywhere in action!"