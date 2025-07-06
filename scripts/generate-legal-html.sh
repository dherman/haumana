#!/bin/bash

# Generate HTML from markdown legal documents

set -e

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "Generating HTML from markdown legal documents..."

# Ensure we're in the repository root
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

# Create HTML template function
create_html() {
    local title=$1
    local content=$2
    
    cat << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$title - Haumana</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background-color: white;
            padding: 40px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1, h2, h3 {
            color: #2c5282;
        }
        h1 {
            border-bottom: 2px solid #e2e8f0;
            padding-bottom: 10px;
        }
        h2 {
            margin-top: 30px;
        }
        h3 {
            margin-top: 20px;
        }
        a {
            color: #2c5282;
        }
        .updated {
            color: #666;
            font-style: italic;
        }
        ul {
            margin-left: 20px;
        }
        strong {
            color: #2c5282;
        }
        @media (max-width: 600px) {
            body {
                padding: 10px;
            }
            .container {
                padding: 20px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
$content
        <hr style="margin-top: 50px; border: 1px solid #e2e8f0;">
        <p style="text-align: center; color: #666; font-size: 14px;">
            <a href="/">Home</a> | 
            <a href="/legal/privacy-policy">Privacy Policy</a> | 
            <a href="/legal/terms-of-service">Terms of Service</a>
        </p>
    </div>
</body>
</html>
EOF
}

# Function to convert markdown to HTML using sed
markdown_to_html() {
    local input=$1
    
    # Start with the input
    local html="$input"
    
    # Convert headers
    html=$(echo "$html" | sed -E 's/^### (.+)$/<h3>\1<\/h3>/g')
    html=$(echo "$html" | sed -E 's/^## (.+)$/<h2>\1<\/h2>/g')
    html=$(echo "$html" | sed -E 's/^# (.+)$/<h1>\1<\/h1>/g')
    
    # Convert bold
    html=$(echo "$html" | sed -E 's/\*\*([^*]+)\*\*/<strong>\1<\/strong>/g')
    
    # Convert italic
    html=$(echo "$html" | sed -E 's/\*([^*]+)\*/<em class="updated">\1<\/em>/g')
    
    # Convert links
    html=$(echo "$html" | sed -E 's/\[([^]]+)\]\(([^)]+)\)/<a href="\2">\1<\/a>/g')
    
    # Convert line breaks and paragraphs
    html=$(echo "$html" | awk '
        BEGIN { in_list = 0; in_para = 0 }
        /^$/ { 
            if (in_para) { print "</p>"; in_para = 0 }
            if (in_list) { print "</ul>"; in_list = 0 }
            print ""
            next
        }
        /^- / { 
            if (in_para) { print "</p>"; in_para = 0 }
            if (!in_list) { print "<ul>"; in_list = 1 }
            sub(/^- /, "<li>")
            print $0 "</li>"
            next
        }
        /^[[:space:]]+- / { 
            sub(/^[[:space:]]+- /, "<li>")
            print "    " $0 "</li>"
            next
        }
        {
            if (in_list) { print "</ul>"; in_list = 0 }
            if (!in_para && $0 !~ /^<h[123]>/ && $0 !~ /^<ul>/ && $0 !~ /^<\/ul>/) { 
                print "<p>" $0
                in_para = 1
            } else if (in_para && $0 !~ /^<h[123]>/) {
                print $0
            } else {
                if (in_para) { print "</p>"; in_para = 0 }
                print $0
            }
        }
        END { 
            if (in_para) { print "</p>" }
            if (in_list) { print "</ul>" }
        }
    ')
    
    echo "$html"
}

# Generate Privacy Policy HTML
echo -e "${GREEN}Converting privacy-policy.md...${NC}"
privacy_content=$(markdown_to_html "$(cat legal/privacy-policy.md)")
create_html "Privacy Policy" "$privacy_content" > web/legal/privacy-policy.html

# Generate Terms of Service HTML
echo -e "${GREEN}Converting terms-of-service.md...${NC}"
terms_content=$(markdown_to_html "$(cat legal/terms-of-service.md)")
create_html "Terms of Service" "$terms_content" > web/legal/terms-of-service.html

echo -e "${GREEN}✅ HTML generation complete!${NC}"
echo ""
echo "Generated files:"
echo "  - web/legal/privacy-policy.html"
echo "  - web/legal/terms-of-service.html"