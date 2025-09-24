#!/bin/bash

# AWS IAM Roles Anywhere Demo Cleanup Script
set -e

echo "🧹 Cleaning up AWS IAM Roles Anywhere Demo resources..."

# Function to safely delete resources
safe_delete() {
    local resource_type="$1"
    local command="$2"
    local resource_name="$3"
    
    if eval "$command" 2>/dev/null; then
        echo "✅ Deleted $resource_type: $resource_name"
    else
        echo "ℹ️  $resource_type not found or already deleted: $resource_name"
    fi
}

# Delete Profile
PROFILE_ID=$(aws rolesanywhere list-profiles --query 'profiles[?name==`DemoProfile`].profileId' --output text 2>/dev/null || echo "")
if [ -n "$PROFILE_ID" ]; then
    safe_delete "Profile" "aws rolesanywhere delete-profile --profile-id $PROFILE_ID" "DemoProfile"
fi

# Delete Trust Anchor
TRUST_ANCHOR_ID=$(aws rolesanywhere list-trust-anchors --query 'trustAnchors[?name==`DemoTrustAnchor`].trustAnchorId' --output text 2>/dev/null || echo "")
if [ -n "$TRUST_ANCHOR_ID" ]; then
    safe_delete "Trust Anchor" "aws rolesanywhere delete-trust-anchor --trust-anchor-id $TRUST_ANCHOR_ID" "DemoTrustAnchor"
fi

# Detach policy from role
safe_delete "Policy attachment" "aws iam detach-role-policy --role-name IAMRolesAnywhereDemo --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess" "ReadOnlyAccess from IAMRolesAnywhereDemo"

# Delete IAM role
safe_delete "IAM Role" "aws iam delete-role --role-name IAMRolesAnywhereDemo" "IAMRolesAnywhereDemo"

# Clean up local files
echo "🗂️  Cleaning up local files..."
rm -rf certificates/
rm -f aws_signing_helper
rm -f ~/.aws/config-roles-anywhere

echo ""
echo "✅ Cleanup completed!"
echo ""
echo "📝 What was cleaned up:"
echo "   • IAM Roles Anywhere Profile (DemoProfile)"
echo "   • IAM Roles Anywhere Trust Anchor (DemoTrustAnchor)"
echo "   • IAM Role (IAMRolesAnywhereDemo)"
echo "   • Local certificates and signing helper"
echo "   • Temporary AWS config file"