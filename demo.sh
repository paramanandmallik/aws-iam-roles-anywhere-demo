#!/bin/bash

# AWS IAM Roles Anywhere Demo Script
set -e

echo "🎯 AWS IAM Roles Anywhere Demo"
echo "================================"

# Check if setup was run
if [ ! -f "certificates/ca-cert.pem" ] || [ ! -f "certificates/client-cert.pem" ]; then
    echo "❌ Certificates not found. Please run ./setup.sh first."
    exit 1
fi

if [ ! -f "aws_signing_helper" ]; then
    echo "❌ AWS signing helper not found. Please run ./setup.sh first."
    exit 1
fi

# Get current directory for absolute paths
DEMO_DIR=$(pwd)

# Create temporary AWS config
mkdir -p ~/.aws
cat > ~/.aws/config-roles-anywhere << EOF
[profile roles-anywhere-demo]
credential_process = ${DEMO_DIR}/aws_signing_helper credential-process --certificate ${DEMO_DIR}/certificates/client-cert.pem --private-key ${DEMO_DIR}/certificates/client-key.pem --trust-anchor-arn $(aws rolesanywhere list-trust-anchors --query 'trustAnchors[?name==`DemoTrustAnchor`].trustAnchorArn' --output text) --profile-arn $(aws rolesanywhere list-profiles --query 'profiles[?name==`DemoProfile`].profileArn' --output text) --role-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/IAMRolesAnywhereDemo
EOF

echo ""
echo "🔐 Testing IAM Roles Anywhere authentication..."
echo ""

# Test 1: Get caller identity
echo "📋 Test 1: Getting caller identity with certificate-based authentication"
AWS_CONFIG_FILE=~/.aws/config-roles-anywhere aws sts get-caller-identity --profile roles-anywhere-demo

echo ""
echo "📋 Test 2: Listing S3 buckets (ReadOnly access)"
AWS_CONFIG_FILE=~/.aws/config-roles-anywhere aws s3 ls --profile roles-anywhere-demo

echo ""
echo "📋 Test 3: Trying to create S3 bucket (should fail - ReadOnly access)"
AWS_CONFIG_FILE=~/.aws/config-roles-anywhere aws s3 mb s3://test-bucket-should-fail-$(date +%s) --profile roles-anywhere-demo 2>&1 || echo "✅ Expected failure - ReadOnly access working correctly"

echo ""
echo "🎉 Demo completed successfully!"
echo ""
echo "📝 What happened:"
echo "   • Used X.509 certificates instead of AWS access keys"
echo "   • aws_signing_helper exchanged certificates for temporary AWS credentials"
echo "   • Assumed IAM role with ReadOnlyAccess policy"
echo "   • Demonstrated both successful operations and permission boundaries"
echo ""
echo "🧹 Cleanup: Run ./cleanup.sh to remove demo resources"