#!/bin/bash

# AWS IAM Roles Anywhere Demo Cleanup Script
set -e

echo "🧹 Cleaning up AWS IAM Roles Anywhere Demo resources..."

# Remove AWS resources
echo "🗑️  Removing AWS resources..."

# Delete profile
PROFILE_ID=$(aws rolesanywhere list-profiles --query 'profiles[?name==`DemoProfile`].profileId' --output text 2>/dev/null || echo "")
if [ ! -z "$PROFILE_ID" ]; then
    aws rolesanywhere delete-profile --profile-id $PROFILE_ID
    echo "✅ Profile deleted"
fi

# Delete trust anchor
TRUST_ANCHOR_ID=$(aws rolesanywhere list-trust-anchors --query 'trustAnchors[?name==`DemoTrustAnchor`].trustAnchorId' --output text 2>/dev/null || echo "")
if [ ! -z "$TRUST_ANCHOR_ID" ]; then
    aws rolesanywhere delete-trust-anchor --trust-anchor-id $TRUST_ANCHOR_ID
    echo "✅ Trust anchor deleted"
fi

# Detach policy and delete role
aws iam detach-role-policy --role-name IAMRolesAnywhereDemo --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess 2>/dev/null || echo "Policy already detached"
aws iam delete-role --role-name IAMRolesAnywhereDemo 2>/dev/null || echo "Role already deleted"
echo "✅ IAM role deleted"

# Remove local files
echo "🗑️  Removing local files..."
rm -rf certificates/
rm -f aws_signing_helper
rm -f ~/.aws/config-roles-anywhere

echo "✅ Cleanup completed successfully!"
echo "📝 All AWS resources and local files have been removed."