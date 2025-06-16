#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { HaumanaStack } from './lib/haumana-stack';

const app = new cdk.App();

// Get Google Client ID from environment or context
const googleClientId = app.node.tryGetContext('googleClientId') || process.env.GOOGLE_CLIENT_ID;

if (!googleClientId) {
  throw new Error('Google OAuth Client ID must be provided via context or environment variable');
}

new HaumanaStack(app, 'HaumanaStack', {
  googleClientId,
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: 'us-west-2',
  },
  description: 'Haumana cloud sync infrastructure',
});