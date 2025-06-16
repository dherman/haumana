#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { HaumanaStack } from './lib/haumana-stack';

const app = new cdk.App();

// Get Google credentials from environment or context
const googleClientId = app.node.tryGetContext('googleClientId') || process.env.GOOGLE_CLIENT_ID || 'placeholder-for-bootstrap';
const googleClientSecret = app.node.tryGetContext('googleClientSecret') || process.env.GOOGLE_CLIENT_SECRET || 'placeholder-for-bootstrap';

// Only check for real credentials during deployment
const isBootstrap = process.argv.includes('bootstrap');
if (!isBootstrap && (googleClientId === 'placeholder-for-bootstrap' || googleClientSecret === 'placeholder-for-bootstrap')) {
  throw new Error('Google OAuth credentials must be provided via context or environment variables for deployment');
}

new HaumanaStack(app, 'HaumanaStack', {
  googleClientId,
  googleClientSecret,
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: 'us-west-2',
  },
  description: 'Haumana cloud sync infrastructure',
});