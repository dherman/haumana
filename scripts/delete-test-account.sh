#!/bin/bash

# Script to delete a test account from Haumana databases
# Usage: ./delete-test-account.sh <email-or-user-id>
#
# You can pass either:
#   - An email address (will look up user ID from users table or pieces table)
#   - A Google user ID directly (numeric string like "116501050889958732345")

set -e

# AWS region - adjust if your tables are in a different region
AWS_REGION="${AWS_REGION:-us-west-2}"

# Cognito User Pool ID
COGNITO_USER_POOL_ID="${COGNITO_USER_POOL_ID:-us-west-2_Au01WZBqZ}"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Check if email parameter is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <email-or-user-id>"
    echo "Example: $0 test@example.com"
    echo "Example: $0 116501050889958732345"
    exit 1
fi

INPUT="$1"

# Detect if input is an email or user ID
if [[ "$INPUT" =~ ^[0-9]+$ ]]; then
    IS_USER_ID=true
    USER_ID="$INPUT"
    EMAIL="(user ID: $USER_ID)"
else
    IS_USER_ID=false
    EMAIL="$INPUT"
fi

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
if [ "$IS_USER_ID" = true ]; then
    read -p "Type the user ID to confirm deletion: " -r CONFIRM_INPUT
else
    read -p "Type the email address to confirm deletion: " -r CONFIRM_INPUT
fi
echo

if [ "$IS_USER_ID" = true ]; then
    if [[ "$CONFIRM_INPUT" != "$USER_ID" ]]; then
        echo "User IDs do not match. Operation cancelled."
        exit 1
    fi
else
    if [[ "$CONFIRM_INPUT" != "$EMAIL" ]]; then
        echo "Email addresses do not match. Operation cancelled."
        exit 1
    fi
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

# Function to get user ID from email using Cognito and DynamoDB
get_user_id() {
    local email="$1"

    echo "Looking up user ID for email: $email"

    # First, try Cognito User Pool (most reliable source)
    # Username format is google_<userId>
    echo "  - Checking Cognito User Pool..."
    COGNITO_USER=$(aws cognito-idp list-users \
        --user-pool-id "$COGNITO_USER_POOL_ID" \
        --region "$AWS_REGION" \
        --filter "email = \"$email\"" \
        --output json 2>/dev/null || echo "{}")

    # Extract user ID from Username (format: google_<userId>)
    COGNITO_USERNAME=$(echo "$COGNITO_USER" | jq -r '.Users[0].Username // empty')
    if [ -n "$COGNITO_USERNAME" ]; then
        USER_ID=$(echo "$COGNITO_USERNAME" | sed 's/^google_//')
        if [ -n "$USER_ID" ]; then
            echo "Found user ID in Cognito: $USER_ID"
            return 0
        fi
    fi

    # Try the DynamoDB Users table
    # Users table uses PK=USER#<userId>, SK=USER#<userId>
    echo "  - Checking DynamoDB users table..."
    USER_DATA=$(aws dynamodb scan \
        --table-name haumana-users \
        --region "$AWS_REGION" \
        --filter-expression "email = :email" \
        --expression-attribute-values "{\":email\":{\"S\":\"$email\"}}" \
        --output json 2>/dev/null || echo "{}")

    # Extract user ID from PK (format: USER#<userId>)
    USER_ID=$(echo "$USER_DATA" | jq -r '.Items[0].PK.S // empty' | sed 's/^USER#//')

    if [ -n "$USER_ID" ]; then
        echo "Found user ID in DynamoDB users table: $USER_ID"
        return 0
    fi

    echo -e "${YELLOW}No user found with email: $email${NC}"
    echo ""
    echo "Tip: You can also pass the Google user ID directly if you know it."
    echo "To find user IDs with pieces, run:"
    echo "  aws dynamodb scan --table-name haumana-pieces --region $AWS_REGION | jq '.Items[] | {userId: .userId.S, title: .title.S}'"
    return 1
}

# Function to delete from Cognito User Pool
delete_from_cognito() {
    local user_id="$1"

    echo "Deleting from Cognito User Pool..."
    local cognito_username="google_${user_id}"

    aws cognito-idp admin-delete-user \
        --user-pool-id "$COGNITO_USER_POOL_ID" \
        --region "$AWS_REGION" \
        --username "$cognito_username" \
        2>/dev/null && echo "  ✓ Deleted Cognito user: $cognito_username" \
        || echo "  (Cognito user not found or already deleted)"
}

# Function to delete from DynamoDB
delete_from_dynamodb() {
    local user_id="$1"

    echo "Deleting from AWS DynamoDB (region: $AWS_REGION)..."

    # Delete user record
    # Users table: PK=USER#<userId>, SK=USER#<userId>
    echo "  - Deleting user record from DynamoDB..."
    aws dynamodb delete-item \
        --table-name haumana-users \
        --region "$AWS_REGION" \
        --key "{\"PK\": {\"S\": \"USER#$user_id\"}, \"SK\": {\"S\": \"USER#$user_id\"}}" \
        2>/dev/null || echo "    (User record not found or already deleted)"

    # Delete all pieces for this user
    # Pieces table: userId (partition key), pieceId (sort key)
    echo "  - Deleting user's pieces..."

    # Query all pieces for this user
    PIECES=$(aws dynamodb query \
        --table-name haumana-pieces \
        --region "$AWS_REGION" \
        --key-condition-expression "userId = :userId" \
        --expression-attribute-values "{\":userId\":{\"S\":\"$user_id\"}}" \
        --output json 2>/dev/null || echo "{}")

    PIECE_COUNT=$(echo "$PIECES" | jq -r '.Items | length')
    echo "    Found $PIECE_COUNT pieces to delete"

    # Delete each piece
    echo "$PIECES" | jq -r '.Items[]? | @base64' | while read -r piece_data; do
        _jq() {
            echo "${piece_data}" | base64 --decode | jq -r "${1}"
        }
        PIECE_ID=$(_jq '.pieceId.S')

        aws dynamodb delete-item \
            --table-name haumana-pieces \
            --region "$AWS_REGION" \
            --key "{\"userId\": {\"S\": \"$user_id\"}, \"pieceId\": {\"S\": \"$PIECE_ID\"}}" \
            2>/dev/null || true
        echo "    Deleted piece: $PIECE_ID"
    done

    # Delete all sessions for this user
    # Sessions table: pk (partition key), sk (sort key) - lowercase!
    echo "  - Deleting user's practice sessions..."

    # Query all sessions for this user
    SESSIONS=$(aws dynamodb query \
        --table-name haumana-sessions \
        --region "$AWS_REGION" \
        --key-condition-expression "pk = :pk" \
        --expression-attribute-values "{\":pk\":{\"S\":\"USER#$user_id\"}}" \
        --output json 2>/dev/null || echo "{}")

    SESSION_COUNT=$(echo "$SESSIONS" | jq -r '.Items | length')
    echo "    Found $SESSION_COUNT sessions to delete"

    # Delete each session
    echo "$SESSIONS" | jq -r '.Items[]? | @base64' | while read -r session_data; do
        _jq() {
            echo "${session_data}" | base64 --decode | jq -r "${1}"
        }
        SESSION_SK=$(_jq '.sk.S')

        aws dynamodb delete-item \
            --table-name haumana-sessions \
            --region "$AWS_REGION" \
            --key "{\"pk\": {\"S\": \"USER#$user_id\"}, \"sk\": {\"S\": \"$SESSION_SK\"}}" \
            2>/dev/null || true
        echo "    Deleted session: $SESSION_SK"
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

# Get user ID and delete from all backends
if [ "$IS_USER_ID" = true ]; then
    # User ID was provided directly
    echo "Using provided user ID: $USER_ID"
    echo ""
    delete_from_cognito "$USER_ID"
    echo ""
    delete_from_dynamodb "$USER_ID"
elif get_user_id "$EMAIL"; then
    # Found user ID from email lookup
    echo ""
    delete_from_cognito "$USER_ID"
    echo ""
    delete_from_dynamodb "$USER_ID"
else
    echo -e "${YELLOW}Skipping backend deletion (user not found)${NC}"
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