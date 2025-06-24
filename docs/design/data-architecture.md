# Haumana Data Architecture

## Overview

This document defines the data architecture for Haumana, an iOS app for Hawaiian art and culture practice management. The architecture uses AWS services exclusively and is designed for scalability, multi-device support, and future feature expansion.

## AWS Services Architecture

### Core Services
- **Authentication**: AWS Cognito
  - Google Sign-in initially
  - Extensible for future providers
- **API**: AWS AppSync (GraphQL) or API Gateway + Lambda (REST)
- **Database**: DynamoDB
- **Search**: Amazon OpenSearch (for advanced text search)
- **Storage**: S3 (reserved for future media files)
- **Compute**: Lambda functions

## Data Models

### 1. User Table
**Table Name**: `haumana-users`

| Attribute | Type | Description |
|-----------|------|-------------|
| userId (PK) | String (UUID) | Unique user identifier |
| email | String | User's email address |
| name | String | User's display name |
| googleId | String | Google authentication ID |
| createdAt | Timestamp | Account creation time |
| lastLogin | Timestamp | Last login timestamp |
| preferences | Map | User preferences (theme, etc.) |

### 2. Piece Table
**Table Name**: `haumana-pieces`

| Attribute | Type | Description |
|-----------|------|-------------|
| pieceId (PK) | String (UUID) | Unique piece identifier |
| ownerId (SK) | String (UUID) | Current owner (for future sharing) |
| title | String | Piece title (required) |
| category | String (Enum) | "oli" \| "mele" \| "hula" |
| lyrics | String | Original lyrics text |
| language | String (ISO 639) | Language code |
| englishTranslation | String | Optional English translation |
| author | String | Optional author name |
| sourceUrl | String | Optional source URL |
| notes | String | Optional notes/information |
| thumbnailKey | String | S3 key for thumbnail image |
| thumbnailSource | String (Enum) | "url" \| "upload" \| "generated" |
| isFavorite | Boolean | Favorite flag |
| creatorId | String (UUID) | Original creator (immutable) |
| visibility | String (Enum) | "private" \| "shared" \| "public" |
| sharedWith | List<String> | List of userIds (future use) |
| createdAt | Timestamp | Creation timestamp |
| updatedAt | Timestamp | Last modification timestamp |

**Global Secondary Indexes (GSIs)**:
- GSI1: `userId-category-index` (userId, category)
- GSI2: `userId-updatedAt-index` (userId, updatedAt)
- GSI3: `userId-language-index` (userId, language)
- GSI4: `userId-isFavorite-index` (userId, isFavorite)

### 3. Session Table
**Table Name**: `haumana-sessions`

| Attribute | Type | Description |
|-----------|------|-------------|
| sessionId (PK) | String (UUID) | Unique session identifier |
| userId (SK) | String (UUID) | User who practiced |
| pieceId | String (UUID) | Piece practiced |
| startedAt | Timestamp | Session start time |
| endedAt | Timestamp | Session end time (nullable) |
| endedAtSource | String (Enum) | "manual" \| "automatic" \| "estimated" |

**Global Secondary Index**:
- GSI1: `userId-startedAt-index` (userId, startedAt)

### 4. Access Table (Future)
**Table Name**: `haumana-access`

Reserved for future sharing functionality.

| Attribute | Type | Description |
|-----------|------|-------------|
| userId (PK) | String (UUID) | User with access |
| pieceId (SK) | String (UUID) | Piece being accessed |
| accessType | String (Enum) | "owner" \| "viewer" \| "editor" |
| grantedAt | Timestamp | When access was granted |

## Access Patterns

### Primary Access Patterns
1. **Get all pieces for a user** → Query Piece table by ownerId
2. **Random piece selection** → Fetch all pieceIds, select randomly in Lambda
3. **Browse pieces by category** → Query GSI1 (userId-category)
4. **View recent pieces** → Query GSI2 (userId-updatedAt)
5. **Filter by language** → Query GSI3 (userId-language)
6. **View favorites** → Query GSI4 (userId-isFavorite)
7. **Get practice history** → Query Session table by userId
8. **Full-text search** → OpenSearch query on title/lyrics

### Performance Specifications
- Expected repertoire size: dozens to thousands (rarely tens of thousands)
- Pagination: 25-50 items per page for browse views
- Caching: Client-side caching for offline access

## Authentication Flow

1. User initiates Google Sign-in on iOS
2. Google returns authentication token
3. Token sent to Cognito for validation
4. Cognito creates/updates user pool entry
5. Cognito returns JWT tokens (ID, Access, Refresh)
6. App uses tokens for API authentication

## Multi-Device Support

- Stateless architecture - all data in cloud
- Automatic sync on app launch and periodically
- Offline mode with local cache
- Conflict resolution: last-write-wins
- Device tracking: optional lastSyncTimestamp per device

## Security Considerations

- All API calls require valid Cognito JWT
- Row-level security via userId validation
- Pieces are private by default (visibility = "private")
- Future sharing will require explicit permissions

## Future Extensibility

### Planned Features
1. **Sharing**: Access table and permission system ready
2. **Additional Auth Providers**: Cognito supports multiple identity providers
3. **Media Files**: S3 integration for audio/video references
4. **Practice Metrics**: Session table can be extended with quality ratings, duration stats
5. **Categories**: Enum can be expanded (e.g., add "hula")
6. **Difficulty Levels**: Can be added as optional field to Piece table

### API Design Considerations
- GraphQL preferred for flexible queries and subscriptions
- REST alternative if simpler implementation needed
- Real-time updates via AppSync subscriptions

## Media Storage Architecture

### Thumbnail Storage Strategy

**S3 Bucket Structure**:
```
haumana-media-{environment}/
├── thumbnails/
│   ├── {userId}/
│   │   ├── {pieceId}/
│   │   │   ├── original.{ext}     # Original uploaded/generated image
│   │   │   ├── thumb_400x400.jpg  # Standard thumbnail
│   │   │   └── thumb_200x200.jpg  # Small thumbnail
```

**Image Processing Pipeline**:
1. **Upload from Photo Library**:
   - Accept JPEG, PNG, HEIF formats
   - Convert HEIF to JPEG for web compatibility
   - Generate standard thumbnail sizes

2. **URL Import**:
   - Download image from provided URL
   - Validate image format and size
   - Process through standard pipeline

3. **Auto-Generated**:
   - Create thumbnail based on piece metadata
   - Use category-specific templates (oli/mele/hula)
   - Generate using Lambda + ImageMagick/Sharp

**S3 Configuration**:
- Bucket: `haumana-media-{environment}`
- Lifecycle rules: Move to Glacier after 1 year
- CloudFront CDN for fast global access
- Pre-signed URLs for secure uploads

**Security**:
- Images private by default
- Pre-signed URLs for upload (15 min expiry)
- CloudFront signed URLs for viewing
- Max file size: 10MB per image

## Cost Optimization

1. DynamoDB on-demand pricing for variable workload
2. Lambda functions for compute (pay per invocation)
3. OpenSearch t3.small.search instance for search (can start with DynamoDB-only)
4. S3 intelligent tiering for thumbnail storage
5. CloudFront CDN for static assets and thumbnails
6. Lambda@Edge for on-demand image resizing

## Monitoring and Analytics

- CloudWatch for system metrics
- X-Ray for distributed tracing
- Custom metrics for:
  - Active users (daily/monthly)
  - Pieces per user
  - Practice sessions per day
  - Popular pieces/categories