# CloudWatch Alarms Setup for Haumana

This document describes the CloudWatch alarms configured for monitoring the Haumana infrastructure.

## Alarms Overview

The CloudWatch alarms monitor the following components:

### Lambda Function Alarms
For each Lambda function (Sync Pieces, Sync Sessions, Auth Sync, Google Token Authorizer):
- **Errors**: Triggers when > 5 errors in 5 minutes
- **Throttles**: Triggers when any throttling occurs
- **Duration**: Triggers when execution time > 80% of timeout (approaching timeout)

### API Gateway Alarms
- **4XX Errors**: Triggers when > 20 client errors in 5 minutes
- **5XX Errors**: Triggers when > 5 server errors in 5 minutes
- **High Latency**: Triggers when average latency > 1 second for 10 minutes

### DynamoDB Alarms
For each table (Pieces, Sessions):
- **User Errors**: Triggers when > 10 throttling errors in 5 minutes
- **System Errors**: Triggers when > 5 system errors in 5 minutes

## Deployment Instructions

### Option 1: Deploy with Email Notifications

```bash
cd aws/infrastructure/cdk

# Deploy with alarm email
npm run deploy -- \
  --context googleClientId=872799888201-rdv0c48nup16mo4b19jjred0jgpjoltc.apps.googleusercontent.com \
  --context alarmEmail=david.herman@gmail.com
```

### Option 2: Deploy without Alarms (Default)

```bash
# Deploy without alarms
npm run deploy -- \
  --context googleClientId=872799888201-rdv0c48nup16mo4b19jjred0jgpjoltc.apps.googleusercontent.com
```

### Option 3: Use Environment Variables

```bash
export ALARM_EMAIL=david.herman@gmail.com
export GOOGLE_CLIENT_ID=872799888201-rdv0c48nup16mo4b19jjred0jgpjoltc.apps.googleusercontent.com
npm run deploy
```

## Email Confirmation

After deployment with alarms:
1. You'll receive an email from AWS SNS to confirm the subscription
2. Click the confirmation link in the email
3. Alarms will start sending notifications to your email

## Alarm Thresholds

Current thresholds are set conservatively for development/early production:

| Alarm | Threshold | Period | Reasoning |
|-------|-----------|---------|-----------|
| Lambda Errors | 5 errors | 5 min | Catches error spikes |
| Lambda Throttles | 1 throttle | 5 min | Any throttling is concerning |
| Lambda Duration | 80% timeout | 5 min | Early warning before timeout |
| API 4XX | 20 errors | 5 min | Normal client errors allowed |
| API 5XX | 5 errors | 5 min | Server errors are critical |
| API Latency | 1 second | 5 min | User experience threshold |
| DynamoDB Throttle | 10 errors | 5 min | Indicates capacity issues |
| DynamoDB System | 5 errors | 5 min | AWS-side issues |

## Adjusting Thresholds

To adjust thresholds, edit `lib/cloudwatch-alarms.ts`:

```typescript
// Example: Change Lambda error threshold
threshold: 10, // Changed from 5
```

Then redeploy the stack.

## Testing Alarms

To test that alarms are working:

1. **Test Lambda Error Alarm**:
   ```bash
   # Call API with invalid data repeatedly
   for i in {1..6}; do
     curl -X POST https://your-api-url/prod/pieces \
       -H "Authorization: Bearer invalid-token"
   done
   ```

2. **Check CloudWatch**:
   - Go to CloudWatch Console > Alarms
   - Look for alarms prefixed with "Haumana-"
   - Verify alarm states

## Alarm Actions

When an alarm triggers:
1. Email notification sent immediately
2. Alarm state visible in CloudWatch Console
3. Alarm history retained for 14 days

## Cost Considerations

- CloudWatch Alarms: $0.10/alarm/month
- Total cost with all alarms: ~$1.50/month
- SNS email notifications: Free

## Disabling Alarms

To remove alarms:
```bash
# Deploy without alarm email
npm run deploy -- \
  --context googleClientId=872799888201-rdv0c48nup16mo4b19jjred0jgpjoltc.apps.googleusercontent.com
```

This will remove all alarms from the stack.