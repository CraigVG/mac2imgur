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
#                          'sparkle:edSignature="abc..." length="123"'
set -euo pipefail

TAG="$1"
ZIP_URL="$2"
ZIP_PATH="$3"
SIG_LINE="$4"

# Strip leading "v" for marketing version
VERSION="${TAG#v}"

# Build number = current_project_version. Read from project.yml.
BUILD=$(grep CURRENT_PROJECT_VERSION project.yml | head -1 | awk '{print $2}' | tr -d '"')
if [[ -z "$BUILD" ]]; then
    BUILD="$VERSION"
fi

PUB_DATE=$(date -u +"%a, %d %b %Y %H:%M:%S +0000")

# Build the new <item> in a temp file - portable across awk/sed flavors
ITEM_FILE=$(mktemp)
cat > "$ITEM_FILE" <<EOF
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

# Use python for safe XML insertion - portable, no awk/sed quirks
python3 - "$ITEM_FILE" <<'PYEOF'
import sys

with open(sys.argv[1]) as fh:
    item = fh.read()

with open("appcast.xml") as fh:
    content = fh.read()

content = content.replace("</channel>", item + "  </channel>")

with open("appcast.xml", "w") as fh:
    fh.write(content)

print("appcast.xml updated")
PYEOF

rm "$ITEM_FILE"
echo "Inserted appcast item for ${TAG} (build ${BUILD})"
