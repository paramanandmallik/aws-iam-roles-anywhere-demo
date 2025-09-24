#!/bin/bash

# Setup AWS config for IAM Roles Anywhere Java Demo
set -e

echo "🔧 Setting up AWS config for Java SDK demo..."

# Get current directory (should be JavaDemo)
DEMO_DIR=$(pwd)
PROJECT_ROOT=$(dirname "$DEMO_DIR")

# Get ARNs from AWS
echo "📋 Retrieving AWS resource ARNs..."

ROLE_ARN=$(aws iam get-role --role-name IAMRolesAnywhereDemo --query 'Role.Arn' --output text)
TRUST_ANCHOR_ARN=$(aws rolesanywhere list-trust-anchors --query 'trustAnchors[?name==`DemoTrustAnchor`].trustAnchorArn' --output text)
PROFILE_ARN=$(aws rolesanywhere list-profiles --query 'profiles[?name==`DemoProfile`].profileArn' --output text)

echo "Role ARN: $ROLE_ARN"
echo "Trust Anchor ARN: $TRUST_ANCHOR_ARN"
echo "Profile ARN: $PROFILE_ARN"

# Create AWS config directory if it doesn't exist
mkdir -p ~/.aws

# Create or update config file
CONFIG_FILE=~/.aws/config

# Check if rolesanywhere-demo profile already exists
if grep -q "\[profile rolesanywhere-demo\]" "$CONFIG_FILE" 2>/dev/null; then
    echo "ℹ️  Profile 'rolesanywhere-demo' already exists in $CONFIG_FILE"
    echo "Please manually update it with the following configuration:"
else
    echo "📝 Adding rolesanywhere-demo profile to $CONFIG_FILE"
    cat >> "$CONFIG_FILE" << EOF

[profile rolesanywhere-demo]
credential_process = $PROJECT_ROOT/aws_signing_helper credential-process --certificate $PROJECT_ROOT/certificates/client-cert.pem --private-key $PROJECT_ROOT/certificates/client-key.pem --trust-anchor-arn $TRUST_ANCHOR_ARN --profile-arn $PROFILE_ARN --role-arn $ROLE_ARN
EOF
fi

echo ""
echo "Configuration:"
echo "credential_process = $PROJECT_ROOT/aws_signing_helper credential-process --certificate $PROJECT_ROOT/certificates/client-cert.pem --private-key $PROJECT_ROOT/certificates/client-key.pem --trust-anchor-arn $TRUST_ANCHOR_ARN --profile-arn $PROFILE_ARN --role-arn $ROLE_ARN"

echo ""
echo "✅ Setup complete! You can now run the Java demo with:"
echo "   cd JavaDemo"
echo "   mvn compile exec:java"