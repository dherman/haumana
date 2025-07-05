#!/bin/bash

# Script to delete a test account from Haumana databases
# Usage: ./delete-test-account.sh <email>

set -e

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Check if email parameter is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <email>"
    echo "Example: $0 test@example.com"
    exit 1
fi

EMAIL="$1"

# Display warning
echo -e "${RED}${BOLD}⚠️  WARNING: DANGEROUS OPERATION ⚠️${NC}"
echo -e "${RED}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${RED}${BOLD}This will PERMANENTLY DELETE all data for user: ${EMAIL}${NC}"
echo -e "${RED}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "This includes:"
echo "  • User account information"
echo "  • All pieces (oli/mele) created by this user"
echo "  • All practice sessions"
echo "  • Any other associated data"
echo ""
echo -e "${YELLOW}This action cannot be undone!${NC}"
echo ""

# Confirmation prompt
read -p "Are you sure you want to delete all data for ${EMAIL}? (yes/no): " -r
echo

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Operation cancelled."
    exit 1
fi

# Second confirmation for safety
echo -e "${RED}${BOLD}FINAL CONFIRMATION${NC}"
read -p "Type the email address to confirm deletion: " -r CONFIRM_EMAIL
echo

if [[ "$CONFIRM_EMAIL" != "$EMAIL" ]]; then
    echo "Email addresses do not match. Operation cancelled."
    exit 1
fi

echo "Proceeding with deletion..."
echo ""

# Function to check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}AWS CLI is not installed. Please install it first.${NC}"
        echo "Visit: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
        exit 1
    fi
}

# Function to get user ID from email using DynamoDB
get_user_id() {
    local email="$1"
    
    echo "Looking up user ID for email: $email"
    
    # Query the Users table to find the user by email
    # Note: This assumes you have a GSI on email or scan the table
    # The table name should match your CDK deployment
    USER_DATA=$(aws dynamodb scan \
        --table-name HaumanaStack-UsersTable \
        --filter-expression "email = :email" \
        --expression-attribute-values "{\":email\":{\"S\":\"$email\"}}" \
        --output json 2>/dev/null || echo "{}")
    
    USER_ID=$(echo "$USER_DATA" | jq -r '.Items[0].id.S // empty')
    
    if [ -z "$USER_ID" ]; then
        echo -e "${YELLOW}No user found with email: $email in DynamoDB${NC}"
        return 1
    fi
    
    echo "Found user ID: $USER_ID"
    return 0
}

# Function to delete from DynamoDB
delete_from_dynamodb() {
    local user_id="$1"
    
    echo "Deleting from AWS DynamoDB..."
    
    # Delete user record
    echo "  - Deleting user record..."
    aws dynamodb delete-item \
        --table-name HaumanaStack-UsersTable \
        --key "{\"id\": {\"S\": \"$user_id\"}}" \
        2>/dev/null || echo "    (User record not found or already deleted)"
    
    # Delete all pieces for this user
    echo "  - Deleting user's pieces..."
    
    # First, query all pieces for this user
    PIECES=$(aws dynamodb query \
        --table-name HaumanaStack-PiecesTable \
        --key-condition-expression "PK = :pk" \
        --expression-attribute-values "{\":pk\":{\"S\":\"USER#$user_id\"}}" \
        --output json 2>/dev/null || echo "{}")
    
    # Delete each piece
    echo "$PIECES" | jq -r '.Items[]? | @base64' | while read -r piece_data; do
        _jq() {
            echo "${piece_data}" | base64 --decode | jq -r "${1}"
        }
        PIECE_SK=$(_jq '.SK.S')
        
        aws dynamodb delete-item \
            --table-name HaumanaStack-PiecesTable \
            --key "{\"PK\": {\"S\": \"USER#$user_id\"}, \"SK\": {\"S\": \"$PIECE_SK\"}}" \
            2>/dev/null || true
    done
    
    # Delete all sessions for this user
    echo "  - Deleting user's practice sessions..."
    
    # Query all sessions for this user
    SESSIONS=$(aws dynamodb query \
        --table-name HaumanaStack-SessionsTable \
        --key-condition-expression "PK = :pk" \
        --expression-attribute-values "{\":pk\":{\"S\":\"USER#$user_id\"}}" \
        --output json 2>/dev/null || echo "{}")
    
    # Delete each session
    echo "$SESSIONS" | jq -r '.Items[]? | @base64' | while read -r session_data; do
        _jq() {
            echo "${session_data}" | base64 --decode | jq -r "${1}"
        }
        SESSION_SK=$(_jq '.SK.S')
        
        aws dynamodb delete-item \
            --table-name HaumanaStack-SessionsTable \
            --key "{\"PK\": {\"S\": \"USER#$user_id\"}, \"SK\": {\"S\": \"$SESSION_SK\"}}" \
            2>/dev/null || true
    done
    
    echo -e "${GREEN}  ✓ DynamoDB deletion complete${NC}"
}

# Function to delete from iOS local database
delete_from_ios() {
    local email="$1"
    
    echo "Deleting from iOS local database..."
    echo "  - This requires manual deletion from the iOS app or Xcode"
    echo "  - To delete from Xcode:"
    echo "    1. Open Xcode and run the app in simulator"
    echo "    2. Go to Debug menu → View Debugging → Capture View Hierarchy"
    echo "    3. Or use Device and Simulators window to delete app data"
    echo ""
    echo "  - To delete from the app (if implemented):"
    echo "    1. Sign in as the test user"
    echo "    2. Go to Profile → Settings → Delete Account"
    echo ""
    echo -e "${YELLOW}  ⚠ iOS local data must be deleted manually${NC}"
}

# Main execution
check_aws_cli

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}jq is not installed. Please install it first.${NC}"
    echo "Run: brew install jq"
    exit 1
fi

# Try to get user ID from DynamoDB
if get_user_id "$EMAIL"; then
    delete_from_dynamodb "$USER_ID"
else
    echo -e "${YELLOW}Skipping DynamoDB deletion (user not found)${NC}"
fi

echo ""
delete_from_ios "$EMAIL"

echo ""
echo -e "${GREEN}${BOLD}Deletion process complete!${NC}"
echo ""
echo "Note: Some data may be cached or retained in:"
echo "  • iOS Keychain (birthdate)"
echo "  • Google account settings"
echo "  • CloudFront CDN cache"
echo ""
echo "For complete cleanup, you may also need to:"
echo "  1. Delete and reinstall the iOS app"
echo "  2. Clear Safari/browser caches"
echo "  3. Remove the account from Google sign-in history"