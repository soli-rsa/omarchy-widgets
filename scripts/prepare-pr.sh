#!/usr/bin/env bash
# omarchy-widgets PR Preparation Script
#
# Prepares your widgets for PR submission by running validation,
# generating previews, and checking for common issues.
#
# Usage: ./scripts/prepare-pr.sh <username> [options]
#
# Arguments:
#   username     Your GitHub username
#
# Options:
#   --themes theme1,theme2,...  Comma-separated list of themes for previews
#   --skip-validation            Skip widget validation
#   --skip-previews             Skip preview generation
#   --strict                     Enable strict mode (fail on warnings)
#   --help                       Show this help message

set -euo pipefail

# Parse arguments
USERNAME="${1:?Usage: prepare-pr.sh <username> [options]}"
THEMES="tokyo-night,gruvbox-dark,catppuccin-mocha"
SKIP_VALIDATION=false
SKIP_PREVIEWS=false
STRICT=false

shift
while [[ $# -gt 0 ]]; do
    case "$1" in
        --themes)
            THEMES="$2"
            shift 2
            ;;
        --skip-validation)
            SKIP_VALIDATION=true
            shift
            ;;
        --skip-previews)
            SKIP_PREVIEWS=true
            shift
            ;;
        --strict)
            STRICT=true
            shift
            ;;
        --help)
            echo "Usage: $0 <username> [options]"
            echo ""
            echo "Arguments:"
            echo "  username     Your GitHub username"
            echo ""
            echo "Options:"
            echo "  --themes theme1,theme2,...  Comma-separated list of themes for previews"
            echo "  --skip-validation            Skip widget validation"
            echo "  --skip-previews             Skip preview generation"
            echo "  --strict                     Enable strict mode (fail on warnings)"
            echo "  --help                       Show this help message"
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
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Counters
TOTAL_WIDGETS=0
VALIDATION_PASSED=0
VALIDATION_FAILED=0
PREVIEWS_GENERATED=0
PREVIEWS_FAILED=0

echo "=========================================="
echo "  Preparing PR for $USERNAME"
echo "=========================================="
echo ""

# Step 1: Find all widgets
WIDGET_LIST=()
for WIDGET_DIR in "$WIDGETS_DIR"/*/; do
    if [ -f "$WIDGET_DIR/widget.owl" ]; then
        WIDGET_LIST+=("$(basename "$WIDGET_DIR")")
    fi
done

if [ ${#WIDGET_LIST[@]} -eq 0 ]; then
    echo "Error: No widgets found in $WIDGETS_DIR"
    exit 1
fi

TOTAL_WIDGETS=${#WIDGET_LIST[@]}
echo "Found $TOTAL_WIDGETS widget(s): ${WIDGET_LIST[*]}"
echo ""

# Step 2: Validate widgets
echo "Step 1: Validating widgets..."
echo "-------------------------------------------"

if [ "$SKIP_VALIDATION" = false ]; then
    VALIDATION_ARGS=()
    if [ "$STRICT" = true ]; then
        VALIDATION_ARGS+=("--strict")
    fi
    
    if "$SCRIPT_DIR/validate-my-widgets.sh" "$USERNAME" "${VALIDATION_ARGS[@]}" 2>&1; then
        VALIDATION_PASSED=$TOTAL_WIDGETS
    else
        VALIDATION_FAILED=$TOTAL_WIDGETS
        echo "✗ Widget validation failed"
        echo ""
        echo "Fix the validation errors above and try again."
        exit 1
    fi
else
    echo "⊘ Validation skipped"
fi
echo ""

# Step 3: Generate previews
echo "Step 2: Generating previews..."
echo "-------------------------------------------"

if [ "$SKIP_PREVIEWS" = false ]; then
    # Convert comma-separated themes to array
    IFS=',' read -ra THEME_ARRAY <<< "$THEMES"
    
    PREVIEW_ARGS=("$USERNAME")
    PREVIEW_ARGS+=("${THEME_ARRAY[@]}")
    
    if "$SCRIPT_DIR/generate-previews.sh" "${PREVIEW_ARGS[@]}" 2>&1; then
        PREVIEWS_GENERATED=$TOTAL_WIDGETS
    else
        echo "⚠️  Some previews failed to generate"
        PREVIEWS_FAILED=1
    fi
else
    echo "⊘ Preview generation skipped"
fi
echo ""

# Step 4: Review all widgets
echo "Step 3: Running full review..."
echo "-------------------------------------------"

REVIEW_ISSUES=0
for WIDGET_NAME in "${WIDGET_LIST[@]}"; do
    WIDGET_DIR="$WIDGETS_DIR/$WIDGET_NAME"
    echo "Reviewing: $WIDGET_NAME"
    
    # Run review and capture output
    REVIEW_OUTPUT=$(java -jar "$PROJECT_DIR/tools/owl.jar" review . "$WIDGET_DIR/widget.owl" 2>&1)
    
    # Check for errors
    if echo "$REVIEW_OUTPUT" | grep -q "Error"; then
        echo "  ❌ Review found errors:"
        echo "$REVIEW_OUTPUT" | grep -A 2 "Error"
        REVIEW_ISSUES=$((REVIEW_ISSUES + 1))
    fi
    
    # Check for warnings
    if echo "$REVIEW_OUTPUT" | grep -q "Warning"; then
        echo "  ⚠️  Review found warnings:"
        echo "$REVIEW_OUTPUT" | grep -A 2 "Warning"
        if [ "$STRICT" = true ]; then
            REVIEW_ISSUES=$((REVIEW_ISSUES + 1))
        fi
    fi
    
    # Show summary
    if echo "$REVIEW_OUTPUT" | grep -q "✓"; then
        echo "  ✓ Review passed"
    fi
done

if [ "$REVIEW_ISSUES" -gt 0 ]; then
    echo ""
    echo "✗ Review found $REVIEW_ISSUES issue(s)"
    if [ "$STRICT" = true ]; then
        echo "  (Strict mode: warnings treated as errors)"
        exit 1
    fi
fi
echo ""

# Step 5: Check git status
echo "Step 4: Checking git status..."
echo "-------------------------------------------"

cd "$PROJECT_DIR"
GIT_STATUS=$(git status --short 2>/dev/null || echo "Not a git repository")

if echo "$GIT_STATUS" | grep -q "Not a git repository"; then
    echo "⚠️  Not in a git repository"
elif [ -z "$GIT_STATUS" ]; then
    echo "✓ Git repository is clean"
else
    echo "Git status:"
    echo "$GIT_STATUS" | sed 's/^/  /'
fi
echo ""

# Step 6: Summary
echo "=========================================="
echo "  PR Preparation Summary"
echo "=========================================="
echo ""
echo "Widgets: $TOTAL_WIDGETS"
echo "Validation: $VALIDATION_PASSED passed, $VALIDATION_FAILED failed"
echo "Previews: $PREVIEWS_GENERATED generated, $PREVIEWS_FAILED failed"
echo "Review: $REVIEW_ISSUES issues found"
echo ""

if [ "$VALIDATION_FAILED" -eq 0 ] && 
   ([ "$SKIP_PREVIEWS" = true ] || [ "$PREVIEWS_FAILED" -eq 0 ]) && 
   ([ "$STRICT" = false ] || [ "$REVIEW_ISSUES" -eq 0 ]); then
    
    echo "✓ PR preparation successful!"
    echo ""
    echo "Next steps:"
    echo ""
    echo "1. Review your changes:"
    echo "   git diff"
    echo ""
    echo "2. Commit your changes:"
    echo "   git add widgets/$USERNAME/"
    echo "   git commit -m \"Add/Update widgets for $USERNAME\""
    echo ""
    echo "3. Push to your branch:"
    echo "   git push origin <your-branch>"
    echo ""
    echo "4. Create a PR on GitHub:"
    echo "   - Go to https://github.com/soli-rsa/omarchy-widgets"
    echo "   - Click 'Pull requests' → 'New pull request'"
    echo "   - Select your branch"
    echo "   - Add a descriptive title and description"
    echo "   - Submit the PR"
    echo ""
    echo "PR Review Process:"
    echo "   - CI will run automated checks (review.yml)"
    echo "   - Maintainer will review your PR"
    echo "   - Once approved, your widgets will be published to the store"
    echo ""
    
    exit 0
else
    echo "✗ PR preparation failed"
    echo ""
    echo "Fix the issues above and try again."
    exit 1
fi
