#!/bin/bash

# Script to view test account data from Haumana databases
# Usage: ./view-test-account.sh <email>

set -e

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Check if email parameter is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <email>"
    echo "Example: $0 test@example.com"
    exit 1
fi

EMAIL="$1"

echo -e "${BLUE}${BOLD}Viewing data for user: ${EMAIL}${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Function to check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo -e "${YELLOW}AWS CLI is not installed. Skipping DynamoDB lookup.${NC}"
        return 1
    fi
    return 0
}

# Function to get user data from DynamoDB
view_dynamodb_data() {
    local email="$1"
    
    echo -e "${GREEN}AWS DynamoDB Data:${NC}"
    echo ""
    
    # Query the Users table
    echo "1. User Record:"
    USER_DATA=$(aws dynamodb scan \
        --table-name HaumanaStack-UsersTable \
        --filter-expression "email = :email" \
        --expression-attribute-values "{\":email\":{\"S\":\"$email\"}}" \
        --output json 2>/dev/null || echo "{}")
    
    if [ "$(echo "$USER_DATA" | jq '.Count // 0')" -eq 0 ]; then
        echo "   No user found with email: $email"
        return
    fi
    
    echo "$USER_DATA" | jq -r '.Items[0] | {
        id: .id.S,
        email: .email.S,
        displayName: .displayName.S,
        createdAt: .createdAt.S,
        lastLoginAt: .lastLoginAt.S
    }'
    
    USER_ID=$(echo "$USER_DATA" | jq -r '.Items[0].id.S')
    echo ""
    
    # Query pieces for this user
    echo "2. User's Pieces:"
    PIECES=$(aws dynamodb query \
        --table-name HaumanaStack-PiecesTable \
        --key-condition-expression "PK = :pk" \
        --expression-attribute-values "{\":pk\":{\"S\":\"USER#$USER_ID\"}}" \
        --output json 2>/dev/null || echo "{}")
    
    PIECE_COUNT=$(echo "$PIECES" | jq '.Count // 0')
    echo "   Found $PIECE_COUNT pieces"
    
    if [ "$PIECE_COUNT" -gt 0 ]; then
        echo "$PIECES" | jq -r '.Items[] | "   - " + .title.S + " (" + .category.S + ")"'
    fi
    echo ""
    
    # Query sessions for this user
    echo "3. Practice Sessions:"
    SESSIONS=$(aws dynamodb query \
        --table-name HaumanaStack-SessionsTable \
        --key-condition-expression "PK = :pk" \
        --expression-attribute-values "{\":pk\":{\"S\":\"USER#$USER_ID\"}}" \
        --output json 2>/dev/null || echo "{}")
    
    SESSION_COUNT=$(echo "$SESSIONS" | jq '.Count // 0')
    echo "   Found $SESSION_COUNT practice sessions"
    
    if [ "$SESSION_COUNT" -gt 0 ]; then
        echo "$SESSIONS" | jq -r '.Items[] | "   - Session on " + .startTime.S'
    fi
}

# Function to display iOS data info
view_ios_info() {
    echo ""
    echo -e "${GREEN}iOS Local Database:${NC}"
    echo ""
    echo "To view iOS local data:"
    echo "1. Open Xcode and run the app in simulator"
    echo "2. Use the Debug Navigator to inspect Core Data"
    echo "3. Or add debug logging to the app"
    echo ""
    echo "Local data includes:"
    echo "  • User profile (cached)"
    echo "  • Offline pieces"
    echo "  • Pending sync items"
    echo "  • Birthdate (in Keychain)"
}

# Main execution
if check_aws_cli; then
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}jq is not installed. Please install it first.${NC}"
        echo "Run: brew install jq"
        exit 1
    fi
    
    view_dynamodb_data "$EMAIL"
fi

view_ios_info

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"