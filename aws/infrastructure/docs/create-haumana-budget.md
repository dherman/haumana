# Creating a Haumana-Specific AWS Budget

This document describes how to create an AWS Budget that tracks only Haumana-related costs using cost allocation tags.

## Prerequisites

1. **Tags have been deployed** - The CDK stack has been updated to tag all resources with:
   - `Project: Haumana`
   - `Environment: Production`
   - `CostCenter: Haumana`

2. **Cost allocation tags have been activated** - Tags must be activated in AWS Billing Console (takes 24 hours to propagate)

## Timeline

- **Day 1**: Deploy CDK with tags ✅ (Completed 2025-06-22)
- **Day 2**: Activate cost allocation tags in AWS Console ✅ (Completed 2025-06-23)
- **Day 3**: Create budget with tag filters (24 hours after activation)

## Step-by-Step Instructions

### Step 1: Verify Cost Allocation Tags are Active

1. Go to [AWS Billing Console](https://console.aws.amazon.com/billing/)
2. Click **"Cost allocation tags"** in the left menu
3. Verify these tags appear in the **"Active"** section:
   - `Project`
   - `Environment`
   - `CostCenter`

If not active yet:
1. Find them in the "Inactive" section
2. Select all three tags
3. Click "Activate"
4. Wait 24 hours before proceeding

### Step 2: Create the Budget

1. Go to [AWS Billing Console](https://console.aws.amazon.com/billing/)
2. Click **"Budgets"** in the left menu
3. Click **"Create budget"**
4. Choose **"Customize (advanced)"**
5. Select **"Cost budget"** and click **Next**

### Step 3: Configure Budget Details

1. **Budget name**: `Haumana-Monthly-Budget`
2. **Period**: Monthly
3. **Budget renewal type**: Recurring budget
4. **Start month**: Current month
5. **Budgeted amount**: $10.00

### Step 4: Add Tag Filter (Critical Step)

1. Under **"Filters"**, click **"Add filter"**
2. **Filter type**: Select "Tag"
3. **Tag key**: Select `Project` from dropdown
4. **Tag value**: Select `Haumana` from dropdown
5. The budget scope should now show "Filtered costs"

### Step 5: Configure Alerts

Add three alerts:

**Alert 1 - 80% Warning**
- **Threshold**: 80% of budgeted amount
- **Threshold type**: Percentage
- **Notification type**: Actual
- **Email recipients**: david.herman@gmail.com

**Alert 2 - 100% Exceeded**
- **Threshold**: 100% of budgeted amount
- **Threshold type**: Percentage
- **Notification type**: Actual
- **Email recipients**: david.herman@gmail.com

**Alert 3 - Forecast Warning**
- **Threshold**: 100% of budgeted amount
- **Threshold type**: Percentage
- **Notification type**: Forecasted
- **Email recipients**: david.herman@gmail.com

### Step 6: Review and Create

1. Review all settings
2. Verify the filter shows `Tag: Project = Haumana`
3. Click **"Create budget"**

## Verifying the Budget

After creation:
1. Go to AWS Cost Explorer
2. Filter by `Tag: Project = Haumana`
3. Verify only Haumana resources appear in the cost breakdown

## Expected Costs

Based on current usage patterns:
- **DynamoDB**: ~$0 (pay-per-request, minimal usage)
- **Lambda**: ~$0 (free tier: 1M requests/month)
- **API Gateway**: ~$0 (free tier: 1M requests/month)
- **Cognito**: ~$0 (free tier: 50,000 MAUs)

Total expected: **< $1/month** during development

## Troubleshooting

**Tags don't appear in dropdown:**
- Ensure 24 hours have passed since activation
- Refresh the page
- Check tags are active in Cost Allocation Tags

**Budget shows $0 or wrong amount:**
- New tags only track costs going forward
- Wait a few days for cost data to accumulate
- Verify filter is set correctly

**Not receiving alerts:**
- Check spam folder
- Verify email address is correct
- Ensure SNS notifications aren't blocked

## Next Steps

After the budget is created:
1. Monitor weekly via Cost Explorer
2. Add CloudWatch alarms for operational metrics
3. Consider adding AWS Cost Anomaly Detection for unexpected spikes