#!/usr/bin/env bash
# omarchy-widgets Widget Creation Script
#
# Creates a new widget with proper structure and template.
#
# Usage: ./scripts/create-widget.sh <username> <widget-name> [options]
#
# Arguments:
#   username     Your GitHub username (lowercase)
#   widget-name  Name of the widget (lowercase, no spaces)
#
# Options:
#   --desc "Description"    Set widget description
#   --cat category         Set widget category (default: dev)
#   --license "License"    Set license (default: MIT)
#   --owl N                Set OWL level (default: 1)
#   --size WxH             Set widget size (default: 2x2)
#   --help                 Show this help message
#
# Categories: news, dev, productivity, time, world, sport, finance, media, games, pets, fun, home, system

set -euo pipefail

# Parse arguments
USERNAME=""
WIDGET_NAME=""
DESCRIPTION=""
CATEGORY="dev"
LICENSE="MIT"
OWL_LEVEL="1"
SIZE="2x2"

# Parse named arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --desc)
            DESCRIPTION="$2"
            shift 2
            ;;
        --cat)
            CATEGORY="$2"
            shift 2
            ;;
        --license)
            LICENSE="$2"
            shift 2
            ;;
        --owl)
            OWL_LEVEL="$2"
            shift 2
            ;;
        --size)
            SIZE="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 <username> <widget-name> [options]"
            echo ""
            echo "Arguments:"
            echo "  username     Your GitHub username (lowercase)"
            echo "  widget-name  Name of the widget (lowercase, no spaces)"
            echo ""
            echo "Options:"
            echo "  --desc \"Description\"    Set widget description"
            echo "  --cat category         Set widget category (default: dev)"
            echo "  --license \"License\"    Set license (default: MIT)"
            echo "  --owl N                Set OWL level (default: 1)"
            echo "  --size WxH             Set widget size (default: 2x2)"
            echo "  --help                 Show this help message"
            echo ""
            echo "Categories: news, dev, productivity, time, world, sport, finance, media, games, pets, fun, home, system"
            exit 0
            ;;
        *)
            if [ -z "$USERNAME" ]; then
                USERNAME="$1"
            elif [ -z "$WIDGET_NAME" ]; then
                WIDGET_NAME="$1"
            else
                echo "Unknown argument: $1"
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate required arguments
if [ -z "$USERNAME" ] || [ -z "$WIDGET_NAME" ]; then
    echo "Error: Missing required arguments"
    echo "Usage: $0 <username> <widget-name> [options]"
    exit 1
fi

# Validate widget name (lowercase, alphanumeric, hyphens only)
if ! [[ "$WIDGET_NAME" =~ ^[a-z0-9-]+$ ]]; then
    echo "Error: Widget name must be lowercase alphanumeric with hyphens only"
    exit 1
fi

# Validate username (lowercase)
if ! [[ "$USERNAME" =~ ^[a-z0-9-]+$ ]]; then
    echo "Error: Username must be lowercase alphanumeric with hyphens only"
    exit 1
fi

# Validate category
VALID_CATEGORIES="news dev productivity time world sport finance media games pets fun home system"
if ! echo "$VALID_CATEGORIES" | grep -qw "$CATEGORY"; then
    echo "Error: Invalid category. Valid categories: $VALID_CATEGORIES"
    exit 1
fi

# Set default description if not provided
if [ -z "$DESCRIPTION" ]; then
    DESCRIPTION="A widget for Omalauncher"
fi

# Create widget directory
WIDGET_DIR="widgets/$USERNAME/$WIDGET_NAME"
mkdir -p "$WIDGET_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "  Creating Widget: $USERNAME/$WIDGET_NAME"
echo "=========================================="
echo ""
echo "Configuration:"
echo "  Description: $DESCRIPTION"
echo "  Category: $CATEGORY"
echo "  License: $LICENSE"
echo "  OWL Level: $OWL_LEVEL"
echo "  Size: $SIZE"
echo ""

# Create widget.owl
cat > "$WIDGET_DIR/widget.owl" << EOF
widget "$WIDGET_NAME" {
  meta {
    description: "$DESCRIPTION"
    version: "1.0"
    license: "$LICENSE"
    category: "$CATEGORY"
    owl: $OWL_LEVEL
  }
  size: $SIZE

  source now = clock every 1s

  Column {
    Text {
      text: fmtTime(now, "HH:mm")
      style: title
    }
    Text {
      text: "$WIDGET_NAME"
      style: muted
    }
  }
}
EOF

echo "✓ Created widget.owl"

# Create README.md
cat > "$WIDGET_DIR/README.md" << EOF
# $WIDGET_NAME

$DESCRIPTION

## Features
- Displays current time
- Updates every second
- Simple and clean design

## Installation
1. Import widget.owl in Omalauncher
2. Add to home screen

## Customization
- Modify the `fmtTime` format string to change time display
- Adjust `size` to change widget dimensions
- Add more elements to the Column

## Requirements
- Omalauncher 1.0+
- OWL level $OWL_LEVEL+

## License
$LICENSE
EOF

echo "✓ Created README.md"

# Create .gitignore for widget directory
cat > "$WIDGET_DIR/.gitignore" << EOF
# Ignore preview images (generated)
preview.png
previews/

# Ignore temporary files
*.tmp
*.swp
EOF

echo "✓ Created .gitignore"

# Validate widget
cd "$PROJECT_DIR"
if java -jar tools/owl.jar check "$WIDGET_DIR/widget.owl" >/dev/null 2>&1; then
    echo "✓ Widget validates successfully"
else
    echo "⚠️  Widget has validation errors"
    echo "   Run: java -jar tools/owl.jar check $WIDGET_DIR/widget.owl"
fi

echo ""
echo "=========================================="
echo "  Widget Created!"
echo "=========================================="
echo ""

echo "Widget directory: $WIDGET_DIR/"
echo ""

echo "Next steps:"
echo ""
echo "1. Edit $WIDGET_DIR/widget.owl to customize your widget"
echo "   - Change the layout"
echo "   - Add sources (cmd, http, etc.)"
echo "   - Add state and handlers"
echo ""
echo "2. Generate preview images:"
echo "   java -jar tools/owl.jar preview $WIDGET_DIR/widget.owl $WIDGET_DIR/preview.png"
echo "   ./scripts/generate-previews.sh $USERNAME"
echo ""
echo "3. Test on device:"
echo "   adb push $WIDGET_DIR/widget.owl /sdcard/Download/"
echo "   Import in Omalauncher: Long-press → Add widget → Import"
echo ""
echo "4. When ready, submit a PR:"
echo "   git add $WIDGET_DIR/"
echo "   git commit -m \"Add $WIDGET_NAME: $DESCRIPTION\""
echo "   git push origin widget/$WIDGET_NAME"
echo "   Create PR on GitHub"
echo ""

echo "Need help?"
echo "   - Read POST_INSTALL_GUIDE.md for testing instructions"
echo "   - Read DEVELOPER_GUIDE.md for development workflow"
echo "   - Check docs/LANGUAGE.md for OWL language reference"
echo ""

exit 0
