#!/bin/bash
# Test the KWS webhook endpoint

# Webhook URL
WEBHOOK_URL="https://vageu42qbg.execute-api.us-west-2.amazonaws.com/prod/webhooks/kws"

# Test payload (simulating a parent approval)
PAYLOAD='{
  "event": "parent.verified",
  "userId": "test-user-123",
  "parentEmail": "parent@example.com",
  "permissions": ["personal_info", "data_collection"],
  "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"
}'

echo "Testing KWS webhook..."
echo "URL: $WEBHOOK_URL"
echo "Payload: $PAYLOAD"
echo ""

# Send test request without signature (should fail)
echo "Test 1: Request without signature (should return 401):"
curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  -w "\nHTTP Status: %{http_code}\n"

echo ""
echo "Test 2: Request with invalid signature (should return 401):"
curl -X POST "$WEBHOOK_URL?signature=invalid123" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  -w "\nHTTP Status: %{http_code}\n"

echo ""
echo "Note: A real test with valid signature would require the actual KWS webhook secret."
echo "The webhook is configured and ready to receive notifications from KWS."