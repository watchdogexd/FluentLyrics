#!/bin/bash

VERSION_STRING=$(echo "$RELEASE_VERSION" | sed 's/^v//')
IFS='+'
read -r -a parts <<< "$VERSION_STRING"
unset IFS

VERSION_NAME="${parts[0]}"
VERSION_CODE="${parts[1]}"

echo "## Release $RELEASE_VERSION" > release.md
echo "" >> release.md
echo "New version has been released!" >> release.md
echo "" >> release.md
echo "### Changes" >> release.md
echo "" >> release.md
git log --pretty=format:"* %s" "$(git describe --tags --abbrev=0 HEAD^ 2>/dev/null || git rev-list --max-parents=0 HEAD)..HEAD" >> release.md
echo "" >> release.md
echo "" >> release.md

# Use envsubst to replace variables in the template
VERSION_NAME=$VERSION_NAME envsubst < .github/release-template.md >> release.md
