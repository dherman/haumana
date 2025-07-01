#!/bin/bash
# View CloudWatch logs for Haumana Lambda functions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Fetching Lambda function names...${NC}"

# Get the Lambda function name from CloudFormation stack
SYNC_FUNCTION=$(aws cloudformation describe-stacks \
    --stack-name HaumanaStack \
    --region us-west-2 \
    --query "Stacks[0].Outputs[?OutputKey=='SyncPiecesFunctionName'].OutputValue" \
    --output text 2>/dev/null || echo "")

if [ -z "$SYNC_FUNCTION" ]; then
    # Try to find it by listing functions
    echo -e "${YELLOW}Couldn't find function name from stack outputs, searching for it...${NC}"
    SYNC_FUNCTION=$(aws lambda list-functions \
        --region us-west-2 \
        --query "Functions[?contains(FunctionName, 'sync-pieces')].FunctionName" \
        --output text | head -n1)
fi

if [ -z "$SYNC_FUNCTION" ]; then
    echo -e "${RED}Error: Could not find SyncPiecesFunction${NC}"
    exit 1
fi

echo -e "${GREEN}Found Lambda function: ${SYNC_FUNCTION}${NC}"
echo ""

# Function to view logs
view_logs() {
    local function_name=$1
    local minutes=${2:-10}
    
    echo -e "${YELLOW}Fetching logs from the last ${minutes} minutes...${NC}"
    
    # Calculate start time
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        START_TIME=$(date -u -v-${minutes}M '+%Y-%m-%dT%H:%M:%S')
    else
        # Linux
        START_TIME=$(date -u -d "${minutes} minutes ago" '+%Y-%m-%dT%H:%M:%S')
    fi
    
    # Get log group name
    LOG_GROUP="/aws/lambda/${function_name}"
    
    # Fetch and display logs
    aws logs filter-log-events \
        --log-group-name "${LOG_GROUP}" \
        --region us-west-2 \
        --start-time $(date -j -f "%Y-%m-%dT%H:%M:%S" "${START_TIME}" +%s)000 2>/dev/null || \
    aws logs filter-log-events \
        --log-group-name "${LOG_GROUP}" \
        --region us-west-2 \
        --start-time $(date -d "${START_TIME}" +%s)000 2>/dev/null || \
    echo -e "${RED}Error fetching logs. The function might not have been invoked yet.${NC}"
}

# Main menu
while true; do
    echo ""
    echo "=== Haumana Lambda Logs Viewer ==="
    echo "1. View last 10 minutes of logs"
    echo "2. View last 30 minutes of logs"
    echo "3. View last hour of logs"
    echo "4. Tail logs (real-time)"
    echo "5. Search logs"
    echo "6. Exit"
    echo ""
    read -p "Select an option (1-6): " choice

    case $choice in
        1)
            view_logs "${SYNC_FUNCTION}" 10
            ;;
        2)
            view_logs "${SYNC_FUNCTION}" 30
            ;;
        3)
            view_logs "${SYNC_FUNCTION}" 60
            ;;
        4)
            echo -e "${YELLOW}Tailing logs (press Ctrl+C to stop)...${NC}"
            aws logs tail "/aws/lambda/${SYNC_FUNCTION}" --region us-west-2 --follow --format short
            ;;
        5)
            read -p "Enter search term: " search_term
            echo -e "${YELLOW}Searching for '${search_term}'...${NC}"
            aws logs filter-log-events \
                --log-group-name "/aws/lambda/${SYNC_FUNCTION}" \
                --region us-west-2 \
                --filter-pattern "\"${search_term}\"" \
                --max-items 50
            ;;
        6)
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            ;;
    esac
done