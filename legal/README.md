# Legal Documents for Haumana

This directory contains the legal documents for the Haumana iOS application.

## Documents

- **privacy-policy.md**: Privacy Policy covering data collection, storage, and user rights
- **terms-of-service.md**: Terms of Service covering usage rules and limitations

## Important Notes

### Before Publishing

1. **Replace Placeholder Information**:
   - `[your-email@example.com]` - Add your actual contact email
   - `[Your State/Country]` - Add your jurisdiction (e.g., "Hawaii, United States")
   - `[Your Jurisdiction]` - Add specific court jurisdiction (e.g., "Honolulu County, Hawaii")

2. **Legal Review Recommended**:
   - These are templates to get you started
   - Consider having a lawyer review before publishing
   - Especially important if you plan to monetize or widely distribute

3. **App Store Requirements**:
   - Apple requires links to privacy policy and terms of service
   - Links must be accessible from App Store listing
   - Must also be accessible within the app

### Hosting Options

1. **GitHub Pages** (Free):
   ```bash
   # Create a docs branch
   git checkout -b gh-pages
   # Copy legal docs to root
   cp legal/*.md .
   # Push to GitHub
   git push origin gh-pages
   ```
   URLs will be: `https://[username].github.io/haumana/privacy-policy`

2. **Your Website**:
   - Upload to your personal/company website
   - Ensure HTTPS is enabled
   - Keep URLs permanent

3. **Within the App**:
   - Can be displayed in a WebView
   - Or as formatted text in the app

### Updating Documents

When you update these documents:
1. Update the "Last updated" date
2. Consider notifying users of material changes
3. Keep previous versions for reference
4. Update all locations where they're hosted

### Integration with App

Add links in your app:
```swift
// In your Settings or About view
Link("Privacy Policy", destination: URL(string: "https://your-domain.com/privacy-policy")!)
Link("Terms of Service", destination: URL(string: "https://your-domain.com/terms-of-service")!)
```

### Compliance Considerations

- **COPPA**: If users under 13 might use the app
- **CCPA**: For California residents' rights
- **GDPR**: If you might have EU users
- **Hawaiian Law**: Any specific cultural heritage protections

The templates include basic provisions for these, but consult a lawyer for full compliance.