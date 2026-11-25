#!/usr/bin/env bash
# omarchy-widgets Widget Validation Script
#
# Validates all widgets for a specific user.
#
# Usage: ./scripts/validate-my-widgets.sh <username> [options]
#
# Arguments:
#   username     Your GitHub username
#
# Options:
#   --strict     Enable strict validation (fail on warnings)
#   --quiet      Only show errors
#   --help       Show this help message

set -euo pipefail

# Parse arguments
USERNAME="${1:?Usage: validate-my-widgets.sh <username> [options]}"
STRICT=false
QUIET=false

shift
while [[ $# -gt 0 ]]; do
    case "$1" in
        --strict)
            STRICT=true
            shift
            ;;
        --quiet)
            QUIET=true
            shift
            ;;
        --help)
            echo "Usage: $0 <username> [options]"
            echo ""
            echo "Arguments:"
            echo "  username     Your GitHub username"
            echo ""
            echo "Options:"
            echo "  --strict     Enable strict validation (fail on warnings)"
            echo "  --quiet      Only show errors"
            echo "  --help       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validate username
if ! [[ "$USERNAME" =~ ^[a-z0-9-]+$ ]]; then
    echo "Error: Username must be lowercase alphanumeric with hyphens only"
    exit 1
fi

WIDGETS_DIR="widgets/$USERNAME"

if [ ! -d "$WIDGETS_DIR" ]; then
    echo "Error: Widgets directory not found: $WIDGETS_DIR"
    echo "Make sure the username is correct and you have widgets in this directory"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Counters
TOTAL=0
PASSED=0
FAILED=0
WARNINGS=0

# Function to print message
print_message() {
    local LEVEL="$1"
    local MESSAGE="$2"
    
    if [ "$QUIET" = true ] && [ "$LEVEL" != "ERROR" ]; then
        return
    fi
    
    case "$LEVEL" in
        "ERROR")
            echo "  [✗] $MESSAGE"
            ;;
        "WARNING")
            echo "  [⚠️ ] $MESSAGE"
            ;;
        "INFO")
            echo "  [ℹ] $MESSAGE"
            ;;
        "SUCCESS")
            echo "  [✓] $MESSAGE"
            ;;
    esac
}

echo "=========================================="
echo "  Validating Widgets for $USERNAME"
echo "=========================================="
echo ""

# Find all widget directories
for WIDGET_DIR in "$WIDGETS_DIR"/*/; do
    if [ -f "$WIDGET_DIR/widget.owl" ]; then
        WIDGET_NAME=$(basename "$WIDGET_DIR")
        TOTAL=$((TOTAL + 1))
        
        echo "Validating: $WIDGET_NAME"
        HAS_ERRORS=false
        
        # 1. Check syntax
        if ! java -jar "$PROJECT_DIR/tools/owl.jar" check "$WIDGET_DIR/widget.owl" >/dev/null 2>&1; then
            print_message "ERROR" "Syntax error in widget.owl"
            FAILED=$((FAILED + 1))
            HAS_ERRORS=true
        fi
        
        # 2. Check if meta exists
        if ! grep -q "meta {" "$WIDGET_DIR/widget.owl"; then
            print_message "ERROR" "Missing meta section"
            FAILED=$((FAILED + 1))
            HAS_ERRORS=true
        else
            # 3. Check required meta fields
            for FIELD in description version license; do
                if ! grep -q "$FIELD:" "$WIDGET_DIR/widget.owl"; then
                    print_message "ERROR" "Missing meta.$FIELD"
                    FAILED=$((FAILED + 1))
                    HAS_ERRORS=true
                fi
            done
            
            # 4. Check category (optional but recommended)
            if ! grep -q "category:" "$WIDGET_DIR/widget.owl"; then
                print_message "WARNING" "Missing category (will default to 'other')"
                WARNINGS=$((WARNINGS + 1))
            fi
            
            # 5. Check description length (10-200 characters)
            DESC=$(grep "description:" "$WIDGET_DIR/widget.owl" | sed "s/.*description: \"//;s/\"//" | head -1)
            DESC_LEN=${#DESC}
            if [ "$DESC_LEN" -lt 10 ] || [ "$DESC_LEN" -gt 200 ]; then
                print_message "ERROR" "Description must be 10-200 characters (found: $DESC_LEN)"
                FAILED=$((FAILED + 1))
                HAS_ERRORS=true
            fi
            
            # 6. Check for requires if using commands
            if grep -q "cmd(" "$WIDGET_DIR/widget.owl" && ! grep -q "requires { pacman:" "$WIDGET_DIR/widget.owl"; then
                print_message "WARNING" "Widget uses cmd() but has no requires { pacman: [...] }"
                WARNINGS=$((WARNINGS + 1))
            fi
            
            # 7. Check for proper value escaping in commands
            if grep -q "cmd.*\${[^s]" "$WIDGET_DIR/widget.owl" || grep -q "cmd.*\${int" "$WIDGET_DIR/widget.owl"; then
                # This is a simplified check - proper validation is done by owl.jar
                : # Placeholder for future enhancement
            fi
        fi
        
        # 8. Check preview.png size (if exists)
        if [ -f "$WIDGET_DIR/preview.png" ]; then
            SIZE=$(stat -f%z "$WIDGET_DIR/preview.png" 2>/dev/null || stat -c%s "$WIDGET_DIR/preview.png")
            if [ "$SIZE" -gt 307200 ]; then
                print_message "WARNING" "preview.png exceeds 300KB limit ($((SIZE / 1024)) KB)"
                WARNINGS=$((WARNINGS + 1))
            fi
        fi
        
        # 9. Check theme previews size (if exist)
        if [ -d "$WIDGET_DIR/previews" ]; then
            for PREVIEW in "$WIDGET_DIR/previews"/*.webp; do
                if [ -f "$PREVIEW" ]; then
                    SIZE=$(stat -f%z "$PREVIEW" 2>/dev/null || stat -c%s "$PREVIEW")
                    if [ "$SIZE" -gt 102400 ]; then
                        PREVIEW_NAME=$(basename "$PREVIEW")
                        print_message "WARNING" "$PREVIEW_NAME exceeds 100KB limit ($((SIZE / 1024)) KB)"
                        WARNINGS=$((WARNINGS + 1))
                    fi
                fi
            done
        fi
        
        # 10. Check for README.md
        if [ ! -f "$WIDGET_DIR/README.md" ]; then
            print_message "INFO" "No README.md found (optional but recommended)"
        fi
        
        if [ "$HAS_ERRORS" = false ]; then
            PASSED=$((PASSED + 1))
            if [ "$QUIET" = false ]; then
                print_message "SUCCESS" "Widget is valid"
            fi
        fi
        
        echo ""
    fi
done

echo "=========================================="
echo "  Validation Summary"
echo "=========================================="
echo ""
echo "Total widgets: $TOTAL"
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "Warnings: $WARNINGS"
echo ""

if [ "$FAILED" -eq 0 ] && ([ "$STRICT" = false ] || [ "$WARNINGS" -eq 0 ]); then
    echo "✓ All widgets are valid!"
    exit 0
else
    echo "✗ Validation failed"
    if [ "$STRICT" = true ] && [ "$WARNINGS" -gt 0 ]; then
        echo "  (Strict mode: warnings treated as errors)"
    fi
    exit 1
fi
