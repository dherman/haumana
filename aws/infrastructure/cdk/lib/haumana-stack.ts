import * as cdk from 'aws-cdk-lib';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import * as iam from 'aws-cdk-lib/aws-iam';
import { NodejsFunction } from 'aws-cdk-lib/aws-lambda-nodejs';
import { Construct } from 'constructs';
import * as path from 'path';

export interface HaumanaStackProps extends cdk.StackProps {
  googleClientId: string;
}

export class HaumanaStack extends cdk.Stack {
  public readonly userPoolId: string;
  public readonly apiEndpoint: string;

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

    // ===== Cognito User Pool (User Database Only) =====
    // This is used only to store user information synced from Google Sign-In
    // Authentication is handled by Google Sign-In SDK + Custom Authorizer
    const userPool = new cognito.UserPool(this, 'UserPoolV2', {
      userPoolName: 'haumana-users-v2',
      selfSignUpEnabled: false,
      signInAliases: {
        email: false,
        username: true, // Users are created as google_{googleUserId}
      },
      standardAttributes: {
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
      removalPolicy: cdk.RemovalPolicy.DESTROY,
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

    // Auth Sync Lambda Function (syncs Google users to Cognito User Pool)
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
      'cognito-idp:AdminGetUser',
      'cognito-idp:ListUsers'
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
      resultsCacheTtl: cdk.Duration.minutes(5),
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
    this.apiEndpoint = api.url;

    new cdk.CfnOutput(this, 'UserPoolId', { 
      value: this.userPoolId,
      description: 'Cognito User Pool ID (used for user data storage only)'
    });
    new cdk.CfnOutput(this, 'ApiEndpoint', { 
      value: this.apiEndpoint,
      description: 'API Gateway endpoint URL'
    });
  }
}