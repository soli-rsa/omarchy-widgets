#!/usr/bin/env bash
# omarchy-widgets Preview Generation Script
#
# Generates preview images for all widgets of a specific user.
#
# Usage: ./scripts/generate-previews.sh <username> [theme1] [theme2] ...
#
# Arguments:
#   username     Your GitHub username
#   themes       Theme names to generate (default: tokyo-night, gruvbox-dark, catppuccin-mocha)

set -euo pipefail

# Parse arguments
USERNAME="${1:?Usage: generate-previews.sh <username> [theme1] [theme2] ...]"

# Default themes
THEMES=("tokyo-night" "gruvbox-dark" "catppuccin-mocha")

# If additional themes are provided, use them
if [ $# -gt 1 ]; then
    THEMES=("${@:2}")
fi

# Validate username
if ! [[ "$USERNAME" =~ ^[a-z0-9-]+$ ]]; then
    echo "Error: Username must be lowercase alphanumeric with hyphens only"
    exit 1
fi

WIDGETS_DIR="widgets/$USERNAME"

if [ ! -d "$WIDGETS_DIR" ]; then
    echo "Error: Widgets directory not found: $WIDGETS_DIR"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OWL_JAR="$PROJECT_DIR/tools/owl.jar"

# Counters
TOTAL=0
SUCCESS=0
FAILED=0

echo "=========================================="
echo "  Generating Previews for $USERNAME"
echo "=========================================="
echo ""
echo "Themes: ${THEMES[*]}"
echo ""

# Find all widget directories
for WIDGET_DIR in "$WIDGETS_DIR"/*/; do
    if [ -f "$WIDGET_DIR/widget.owl" ]; then
        WIDGET_NAME=$(basename "$WIDGET_DIR")
        TOTAL=$((TOTAL + 1))
        
        echo "Generating previews for: $WIDGET_NAME"
        
        # Create previews directory
        mkdir -p "$WIDGET_DIR/previews"
        
        # Generate preview for each theme
        for THEME in "${THEMES[@]}"; do
            PREVIEW_FILE="$WIDGET_DIR/previews/${THEME}.webp"
            
            echo "  Generating $THEME preview..."
            
            if java -jar "$OWL_JAR" preview --theme "$THEME" \
                "$WIDGET_DIR/widget.owl" "$PREVIEW_FILE" 2>/dev/null; then
                
                # Check if file was created
                if [ -f "$PREVIEW_FILE" ]; then
                    SIZE=$(stat -f%z "$PREVIEW_FILE" 2>/dev/null || stat -c%s "$PREVIEW_FILE")
                    
                    # Check size limit
                    if [ "$SIZE" -gt 102400 ]; then
                        echo "    ⚠️  Preview exceeds 100KB limit ($((SIZE / 1024)) KB)"
                        FAILED=$((FAILED + 1))
                    else
                        echo "    ✓ Created ($((SIZE / 1024)) KB)"
                        SUCCESS=$((SUCCESS + 1))
                    fi
                else
                    echo "    ✗ Failed to create preview"
                    FAILED=$((FAILED + 1))
                fi
            else
                echo "    ✗ Preview generation failed"
                FAILED=$((FAILED + 1))
            fi
        done
        
        echo ""
    fi
done

echo "=========================================="
echo "  Preview Generation Summary"
echo "=========================================="
echo ""
echo "Total widgets: $TOTAL"
echo "Successful previews: $SUCCESS"
echo "Failed previews: $FAILED"
echo ""

if [ "$FAILED" -eq 0 ]; then
    echo "✓ All previews generated successfully!"
    exit 0
else
    echo "✗ Some previews failed to generate"
    exit 1
fi
