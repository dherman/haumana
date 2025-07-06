# Haumana Web Content

This directory contains the static web content for haumana.app, hosted on GitHub Pages.

## Structure

```
web/
├── index.html          # Main landing page (placeholder with logo)
├── legal/              # Legal documents
│   ├── privacy-policy.html
│   └── terms-of-service.html
├── assets/             # Static assets
│   └── lehua.png      # Haumana logo
├── 404.html           # Custom 404 page
├── CNAME              # Custom domain configuration
└── .nojekyll          # Disable Jekyll processing
```

## Deployment

To deploy updates to the website:

```bash
./scripts/deploy-web.sh
```

This script will:
1. Copy web content to the gh-pages branch
2. Commit any changes
3. Push to GitHub
4. Return to your original branch

## Domain Setup

The site is configured to use the custom domain `haumana.app`. 

### DNS Configuration Required

Add these DNS records to your domain:

**For apex domain (haumana.app):**
```
A     185.199.108.153
A     185.199.109.153
A     185.199.110.153
A     185.199.111.153
```

Or if your DNS provider supports ALIAS/ANAME:
```
ALIAS/ANAME -> dherman.github.io
```

### Verify Setup

After DNS propagation (can take up to 48 hours):
- https://haumana.app should show the landing page
- https://haumana.app/legal/privacy-policy should show the privacy policy
- https://haumana.app/legal/terms-of-service should show the terms of service

## Local Testing

To test the site locally:

```bash
cd web
python3 -m http.server 8000
```

Then visit http://localhost:8000

## Updating Legal Documents

1. Edit the markdown files in `/legal/`
2. Regenerate HTML files in `/web/legal/`
3. Run the deploy script

## URLs for App Store

Use these URLs when submitting to the App Store:
- Privacy Policy: `https://haumana.app/legal/privacy-policy`
- Terms of Service: `https://haumana.app/legal/terms-of-service`