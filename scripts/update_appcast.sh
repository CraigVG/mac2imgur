#!/usr/bin/env bash
# update_appcast.sh - inserts a new <item> into appcast.xml for a release.
#
# Usage:
#   update_appcast.sh <tag> <zip_url> <zip_path> <sparkle_sig_output>
#
# Where:
#   tag                  - git tag name like "v2.0.1"
#   zip_url              - public URL to download the zipped .app
#   zip_path             - local path to the zip (used to compute file size)
#   sparkle_sig_output   - exact stdout from `sign_update`, e.g.
#                          'sparkle:edSignature="abc..." sparkle:length="123"'
set -euo pipefail

TAG="$1"
ZIP_URL="$2"
ZIP_PATH="$3"
SIG_LINE="$4"

# Strip leading "v" for marketing version
VERSION="${TAG#v}"

# Build number = current_project_version. Read from xcodebuild settings or project.yml.
BUILD=$(grep CURRENT_PROJECT_VERSION project.yml | head -1 | awk '{print $2}' | tr -d '"')
if [[ -z "$BUILD" ]]; then
    BUILD="$VERSION"
fi

PUB_DATE=$(date -u +"%a, %d %b %Y %H:%M:%S +0000")
LENGTH=$(stat -f%z "$ZIP_PATH")

ITEM=$(cat <<EOF
    <item>
      <title>Version ${VERSION}</title>
      <pubDate>${PUB_DATE}</pubDate>
      <sparkle:version>${BUILD}</sparkle:version>
      <sparkle:shortVersionString>${VERSION}</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <enclosure
        url="${ZIP_URL}"
        type="application/octet-stream"
        ${SIG_LINE} />
    </item>
EOF
)

# Insert the new item just before </channel>
TMP=$(mktemp)
awk -v item="$ITEM" '
  /<\/channel>/ { print item; print; next }
  { print }
' appcast.xml > "$TMP"
mv "$TMP" appcast.xml

echo "Inserted appcast item for ${TAG} (build ${BUILD}, ${LENGTH} bytes)"
