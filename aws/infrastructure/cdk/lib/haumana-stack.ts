import * as cdk from 'aws-cdk-lib';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import { NodejsFunction } from 'aws-cdk-lib/aws-lambda-nodejs';
import { Construct } from 'constructs';
import * as path from 'path';

export interface HaumanaStackProps extends cdk.StackProps {
  googleClientId: string;
}

export class HaumanaStack extends cdk.Stack {
  public readonly userPoolId: string;
  public readonly userPoolClientId: string;
  public readonly identityPoolId: string;
  public readonly apiEndpoint: string;
  public readonly cognitoDomain: string;

  constructor(scope: Construct, id: string, props: HaumanaStackProps) {
    super(scope, id, props);

    // ===== DynamoDB Tables =====
    const piecesTable = new dynamodb.Table(this, 'PiecesTable', {
      tableName: 'haumana-pieces',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'pieceId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      pointInTimeRecoverySpecification: { pointInTimeRecoveryEnabled: true },
    });

    piecesTable.addGlobalSecondaryIndex({
      indexName: 'userId-modifiedAt-index',
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'modifiedAt', type: dynamodb.AttributeType.STRING },
    });

    const sessionsTable = new dynamodb.Table(this, 'SessionsTable', {
      tableName: 'haumana-sessions',
      partitionKey: { name: 'pk', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'sk', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      pointInTimeRecoverySpecification: { pointInTimeRecoveryEnabled: true },
    });

    sessionsTable.addGlobalSecondaryIndex({
      indexName: 'pieceId-startedAt-index',
      partitionKey: { name: 'pieceId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'startedAt', type: dynamodb.AttributeType.STRING },
    });

    // ===== Cognito User Pool =====
    const userPool = new cognito.UserPool(this, 'UserPoolV2', {
      userPoolName: 'haumana-users-v2',
      selfSignUpEnabled: false, // Only allow federated sign-in for now
      signInAliases: {
        email: false,
        username: true, // Use username for federated users
      },
      autoVerify: {
        email: true,
      },
      standardAttributes: {
        // Don't require email as standard attribute since it causes issues with federated users
        fullname: {
          required: false,
          mutable: true,
        },
        email: {
          required: false,
          mutable: true,
        },
      },
      passwordPolicy: {
        minLength: 8,
        requireLowercase: true,
        requireUppercase: true,
        requireDigits: true,
        requireSymbols: false,
      },
      accountRecovery: cognito.AccountRecovery.EMAIL_ONLY,
      removalPolicy: cdk.RemovalPolicy.DESTROY, // Allow deletion since we're in development
    });

    // ===== Cognito Domain =====
    const cognitoDomain = new cognito.UserPoolDomain(this, 'CognitoDomain', {
      userPool,
      cognitoDomain: {
        domainPrefix: `haumana-v2-${cdk.Stack.of(this).account}`, // Ensures uniqueness
      },
    });

    // ===== Get Google Client Secret from Secrets Manager =====
    const googleClientSecret = secretsmanager.Secret.fromSecretNameV2(this, 'GoogleClientSecret', 'haumana-oauth');

    // ===== Google Identity Provider =====
    const googleProvider = new cognito.UserPoolIdentityProviderGoogle(this, 'GoogleProvider', {
      userPool,
      clientId: props.googleClientId,
      clientSecretValue: googleClientSecret.secretValue,
      scopes: ['profile', 'email', 'openid'],
      attributeMapping: {
        email: cognito.ProviderAttribute.GOOGLE_EMAIL,
        fullname: cognito.ProviderAttribute.GOOGLE_NAME,
        profilePicture: cognito.ProviderAttribute.GOOGLE_PICTURE,
      },
    });

    // ===== App Client =====
    const userPoolClient = new cognito.UserPoolClient(this, 'AppClient', {
      userPool,
      userPoolClientName: 'haumana-ios',
      generateSecret: false, // Mobile apps don't use secrets
      // No OAuth configuration needed since we're using hybrid auth
      authFlows: {
        adminUserPassword: true,
        custom: true,
      },
    });

    // Ensure Google provider is created before client
    userPoolClient.node.addDependency(googleProvider);

    // ===== Identity Pool =====
    const identityPool = new cognito.CfnIdentityPool(this, 'IdentityPool', {
      identityPoolName: 'haumana_identity',
      allowUnauthenticatedIdentities: false,
      cognitoIdentityProviders: [{
        clientId: userPoolClient.userPoolClientId,
        providerName: userPool.userPoolProviderName,
      }],
      supportedLoginProviders: {
        'accounts.google.com': props.googleClientId,
      },
    });

    // ===== IAM Roles for Identity Pool =====
    const authenticatedRole = new iam.Role(this, 'CognitoAuthenticatedRole', {
      assumedBy: new iam.FederatedPrincipal(
        'cognito-identity.amazonaws.com',
        {
          StringEquals: {
            'cognito-identity.amazonaws.com:aud': identityPool.ref,
          },
          'ForAnyValue:StringLike': {
            'cognito-identity.amazonaws.com:amr': 'authenticated',
          },
        },
        'sts:AssumeRoleWithWebIdentity'
      ),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('AWSIoTDataAccess'), // If using IoT
      ],
    });

    new cognito.CfnIdentityPoolRoleAttachment(this, 'IdentityPoolRoleAttachment', {
      identityPoolId: identityPool.ref,
      roles: {
        authenticated: authenticatedRole.roleArn,
      },
    });

    // ===== Lambda Functions =====
    const syncPiecesFunction = new NodejsFunction(this, 'SyncPiecesFunction', {
      functionName: 'haumana-sync-pieces',
      runtime: lambda.Runtime.NODEJS_18_X,
      entry: path.join(__dirname, '../../../lambdas/src/sync-pieces-lambda.ts'),
      handler: 'handler',
      environment: {
        PIECES_TABLE: piecesTable.tableName,
      },
      timeout: cdk.Duration.seconds(30),
      memorySize: 256,
    });

    const syncSessionsFunction = new NodejsFunction(this, 'SyncSessionsFunction', {
      functionName: 'haumana-sync-sessions',
      runtime: lambda.Runtime.NODEJS_18_X,
      entry: path.join(__dirname, '../../../lambdas/src/sync-sessions-lambda.ts'),
      handler: 'handler',
      environment: {
        SESSIONS_TABLE: sessionsTable.tableName,
      },
      timeout: cdk.Duration.seconds(30),
      memorySize: 256,
    });

    // Auth Sync Lambda Function
    const authSyncFunction = new NodejsFunction(this, 'AuthSyncFunction', {
      functionName: 'haumana-auth-sync',
      runtime: lambda.Runtime.NODEJS_18_X,
      entry: path.join(__dirname, '../../../lambda/auth-sync/index.ts'),
      handler: 'handler',
      environment: {
        USER_POOL_ID: userPool.userPoolId,
        GOOGLE_CLIENT_ID: props.googleClientId,
      },
      timeout: cdk.Duration.seconds(30),
      memorySize: 256,
    });

    // Grant permissions to auth sync function
    userPool.grant(authSyncFunction, 
      'cognito-idp:AdminCreateUser',
      'cognito-idp:AdminUpdateUserAttributes',
      'cognito-idp:AdminGetUser'
    );

    // Grant Lambda permissions to DynamoDB
    piecesTable.grantReadWriteData(syncPiecesFunction);
    sessionsTable.grantReadWriteData(syncSessionsFunction);

    // ===== Google Token Authorizer Lambda =====
    const googleTokenAuthorizerFunction = new lambda.Function(this, 'GoogleTokenAuthorizer', {
      runtime: lambda.Runtime.NODEJS_18_X,
      code: lambda.Code.fromAsset(path.join(__dirname, '../../../lambda/google-token-authorizer')),
      handler: 'index.handler',
      environment: {
        GOOGLE_WEB_CLIENT_ID: '872799888201-51c9jb50nkdl2cl4vu8fp9h5cs7tdmuj.apps.googleusercontent.com',
      },
      timeout: cdk.Duration.seconds(10),
      memorySize: 128,
    });

    // Grant permission for API Gateway to invoke the authorizer
    googleTokenAuthorizerFunction.grantInvoke(new iam.ServicePrincipal('apigateway.amazonaws.com'));

    // ===== API Gateway =====
    const api = new apigateway.RestApi(this, 'HaumanaApi', {
      restApiName: 'haumana-api',
      deployOptions: {
        stageName: 'prod',
      },
      defaultCorsPreflightOptions: {
        allowOrigins: apigateway.Cors.ALL_ORIGINS,
        allowMethods: apigateway.Cors.ALL_METHODS,
        allowHeaders: [
          'Content-Type',
          'X-Amz-Date',
          'Authorization',
          'X-Api-Key',
          'X-Amz-Security-Token',
        ],
      },
    });

    // Google Token Authorizer
    const googleAuthorizer = new apigateway.TokenAuthorizer(this, 'GoogleApiAuthorizer', {
      handler: googleTokenAuthorizerFunction,
      authorizerName: 'GoogleTokenAuthorizer',
      identitySource: 'method.request.header.Authorization',
      resultsCacheTtl: cdk.Duration.minutes(5), // Cache auth results for 5 minutes
    });


    // API Resources
    const piecesResource = api.root.addResource('pieces');
    piecesResource.addMethod('POST', new apigateway.LambdaIntegration(syncPiecesFunction), {
      authorizer: googleAuthorizer,
      authorizationType: apigateway.AuthorizationType.CUSTOM,
    });

    const sessionsResource = api.root.addResource('sessions');
    sessionsResource.addMethod('POST', new apigateway.LambdaIntegration(syncSessionsFunction), {
      authorizer: googleAuthorizer,
      authorizationType: apigateway.AuthorizationType.CUSTOM,
    });

    // Auth sync endpoint (no authorizer needed - it handles its own auth)
    const authResource = api.root.addResource('auth');
    const authSyncResource = authResource.addResource('sync');
    authSyncResource.addMethod('POST', new apigateway.LambdaIntegration(authSyncFunction));

    // ===== Outputs =====
    this.userPoolId = userPool.userPoolId;
    this.userPoolClientId = userPoolClient.userPoolClientId;
    this.identityPoolId = identityPool.ref;
    this.apiEndpoint = api.url;
    this.cognitoDomain = `https://${cognitoDomain.domainName}.auth.${this.region}.amazoncognito.com`;

    new cdk.CfnOutput(this, 'UserPoolId', { value: this.userPoolId });
    new cdk.CfnOutput(this, 'UserPoolClientId', { value: this.userPoolClientId });
    new cdk.CfnOutput(this, 'IdentityPoolId', { value: this.identityPoolId });
    new cdk.CfnOutput(this, 'ApiEndpoint', { value: this.apiEndpoint });
    new cdk.CfnOutput(this, 'CognitoDomainUrl', { value: this.cognitoDomain });
    new cdk.CfnOutput(this, 'GoogleRedirectUri', { 
      value: `${this.cognitoDomain}/oauth2/idpresponse`,
      description: 'Add this to Google OAuth Authorized redirect URIs' 
    });
  }
}