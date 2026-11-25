# Post-Installation Guide - omarchy-widgets

This guide covers what to do after setting up your development environment for omarchy-widgets or after installing widgets on your device.

## Table of Contents

1. [After Setting Up Development Environment](#1-after-setting-up-development-environment)
2. [After Creating a Widget](#2-after-creating-a-widget)
3. [After Submitting a Widget](#3-after-submitting-a-widget)
4. [After Installing Widgets on Device](#4-after-installing-widgets-on-device)
5. [Post-Installation Scripts](#5-post-installation-scripts)

---

## 1. After Setting Up Development Environment

### 1.1 Verify Setup

```bash
# Check Java version
java -version
# Should be 21+

# Verify owl.jar is present and working
java -jar tools/owl.jar --help

# Check git
 git --version
```

### 1.2 Clone and Prepare Repository

```bash
# Clone the repository
git clone https://github.com/soli-rsa/omarchy-widgets.git
cd omarchy-widgets

# Verify owl.jar
ls -la tools/owl.jar

# Test the checker
java -jar tools/owl.jar check widgets/simonschubert/clock/widget.owl
```

### 1.3 Set Up Omalauncher for Testing

To test widgets, you need Omalauncher installed on an Android device:

1. **Install Omalauncher**
   - From Play Store: [Omalauncher on Google Play](https://play.google.com/store/apps/details?id=dev.omalauncher)
   - Or from GitHub releases: Download APK from [releases](https://github.com/soli-rsa/omalauncher/releases)

2. **Enable Developer Options**
   ```
   Settings → About phone → Tap "Build number" 7 times
   Settings → Developer options → Enable USB debugging
   ```

3. **Connect Device to ADB**
   ```bash
   adb devices
   # Should show your device
   ```

4. **Verify Omalauncher is Running**
   ```bash
   adb shell pm list packages | grep omalauncher
   ```

---

## 2. After Creating a Widget

### 2.1 Validate Your Widget

```bash
# Check syntax
java -jar tools/owl.jar check widgets/myusername/my-widget/widget.owl

# Review (shows what it runs and installs)
java -jar tools/owl.jar review . widgets/myusername/my-widget/widget.owl

# Check for programs used
java -jar tools/owl.jar programs widgets/myusername/my-widget/widget.owl
```

### 2.2 Generate Preview Images

```bash
# Generate preview.png
java -jar tools/owl.jar preview widgets/myusername/my-widget/widget.owl widgets/myusername/my-widget/preview.png

# Generate theme-specific previews
mkdir -p widgets/myusername/my-widget/previews
java -jar tools/owl.jar preview --theme tokyo-night widgets/myusername/my-widget/widget.owl widgets/myusername/my-widget/previews/tokyo-night.webp

# Or use the store preview script (generates for all themes)
./scripts/store-previews.sh
```

### 2.3 Test Locally

#### On Device

```bash
# Push widget to device
adb push widgets/myusername/my-widget/widget.owl /sdcard/Download/

# Import in Omalauncher
# Long-press home screen → Add widget → Import → Select widget.owl

# Check for errors
adb shell "cat /sdcard/Android/data/dev.omalauncher/files/widgets/.errors/my-widget.txt"
```

#### Verify Widget Works

1. **Check Rendering**
   - Does the widget display correctly?
   - Are all elements visible?
   - Does it respect the size constraints?

2. **Check Updates**
   - If using `clock` or `cmd` sources, do they update?
   - Tap the widget - does it respond to taps?

3. **Check Theme Colors**
   - Change theme in Omalauncher settings
   - Does the widget adapt to theme colors?

### 2.4 Add Documentation

Create a `README.md` for your widget:

```markdown
# My Widget

A simple widget that displays the current time.

## Features
- Shows time in HH:mm format
- Updates every second
- Uses theme colors

## Installation
1. Import widget.owl in Omalauncher
2. Add to home screen

## Customization
- Change `format` in the source to modify time display
- Adjust `size` to change widget dimensions

## Requirements
- Omalauncher 1.8+
- OWL level 1+

## License
MIT
```

---

## 3. After Submitting a Widget

### 3.1 PR Review Process

After submitting your PR:

1. **Automated Checks (review.yml)**
   - CI runs syntax validation
   - Checks package dependencies in Arch
   - Flags security issues
   - Generates review summary

2. **Manual Review**
   - Maintainer reviews your widget
   - Checks for:
     - Proper metadata
     - Declared dependencies
     - Safe commands
     - Good description
   - May request changes

3. **Approval and Merge**
   - Once approved, maintainer merges PR
   - CI publishes to store (publish.yml)

### 3.2 Post-Merge

After your widget is merged:

1. **Store Publishing**
   - CI automatically builds catalogs
   - Widget appears in store within minutes
   - Available at: https://soli-rsa.github.io/omarchy-widgets/

2. **Update Your Local Copy**
   ```bash
   git pull origin main
   ```

3. **Tell Others**
   - Share your widget on social media
   - Mention it in Omalauncher discussions
   - Update your widget's README with store link

### 3.3 Updating Your Widget

To update an existing widget:

1. **Make Changes**
   - Modify widget.owl
   - **Increment version** in meta
   - Update changelog in README if significant

2. **Test Thoroughly**
   - Validate: `java -jar tools/owl.jar check`
   - Test on device
   - Check for breaking changes

3. **Submit Update**
   - Create new PR with changes
   - Mention it's an update in PR description
   - If commands/packages changed, users will need to re-approve

---

## 4. After Installing Widgets on Device

### 4.1 Using Installed Widgets

1. **Add to Home Screen**
   - Long-press home screen
   - Tap "Add widget"
   - Browse or search for your widget
   - Tap to add

2. **Resize Widget**
   - Long-press widget
   - Drag corners to resize
   - Release to confirm

3. **Move Widget**
   - Long-press and drag
   - Drop in new location

4. **Remove Widget**
   - Long-press and drag to "Remove"
   - Or: Long-press → Edit → Delete

### 4.2 Widget Management

#### View Widget Info
- Long-press widget → Edit
- Shows: name, version, author, description

#### Update Widget
- Settings → Widgets → Updates
- Or: Long-press widget → Edit → Update

#### Re-approve Widget
If widget was updated with new commands/packages:
- Long-press widget → Edit → Re-approve
- Review what changed
- Confirm to continue using

#### Reset Widget
- Long-press widget → Edit → Reset
- Clears widget state (persistent variables)

### 4.3 Troubleshooting Widgets

**Widget Not Showing**
- Check: Is widget installed?
  - Settings → Widgets → Installed
- Fix: Re-import widget

**Widget Shows Error**
- Check error file:
  ```bash
  adb shell "cat /sdcard/Android/data/dev.omalauncher/files/widgets/.errors/<widget>.txt"
  ```
- Common errors:
  - Syntax error in widget.owl
  - Missing required packages
  - Commands failing

**Widget Not Updating**
- Check: Is Linux installed? (if widget uses commands)
  - Settings → Linux → Check status
- Fix: Install Linux or use widgets that don't need Linux

**Widget Looks Wrong**
- Check: Theme colors being used?
- Fix: Use theme color variables (accent, foreground, etc.)

---

## 5. Post-Installation Scripts

### 5.1 Widget Creation Script

Create a new widget with proper structure:

```bash
# Save as scripts/create-widget.sh
#!/usr/bin/env bash
set -euo pipefail

# Usage: create-widget.sh <username> <widget-name> [description]
USERNAME="${1:?Usage: create-widget.sh <username> <widget-name> [description]}"
WIDGET_NAME="${2:?}"
DESCRIPTION="${3:-My widget}"

WIDGET_DIR="widgets/$USERNAME/$WIDGET_NAME"

echo "=== Creating Widget: $USERNAME/$WIDGET_NAME ==="
echo ""

# Create directory
mkdir -p "$WIDGET_DIR"
echo "✓ Created directory: $WIDGET_DIR"

# Create widget.owl
cat > "$WIDGET_DIR/widget.owl" << EOF
widget "$WIDGET_NAME" {
  meta {
    description: "$DESCRIPTION"
    version: "1.0"
    license: "MIT"
    category: "dev"
    owl: 1
  }
  size: 2x2

  source now = clock every 1s

  Text {
    text: fmtTime(now, "HH:mm:ss")
    style: title
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

## Installation
1. Import widget.owl in Omalauncher
2. Add to home screen

## Requirements
- Omalauncher 1.0+
- OWL level 1+

## License
MIT
EOF
echo "✓ Created README.md"

# Validate widget
java -jar tools/owl.jar check "$WIDGET_DIR/widget.owl"
echo "✓ Widget validates successfully"

echo ""
echo "=== Widget Created! ==="
echo ""
echo "Next steps:"
echo "1. Edit $WIDGET_DIR/widget.owl to customize"
echo "2. Generate preview: java -jar tools/owl.jar preview $WIDGET_DIR/widget.owl $WIDGET_DIR/preview.png"
echo "3. Test on device"
echo "4. Submit PR to omarchy-widgets"
```

### 5.2 Widget Validation Script

Validate all widgets in your directory:

```bash
# Save as scripts/validate-my-widgets.sh
#!/usr/bin/env bash
set -euo pipefail

USERNAME="${1:?Usage: validate-my-widgets.sh <username>}"
WIDGETS_DIR="widgets/$USERNAME"

echo "=== Validating Widgets for $USERNAME ==="
echo ""

ERRORS=0
WIDGETS=0

for WIDGET_DIR in "$WIDGETS_DIR"/*/; do
    if [ -f "$WIDGET_DIR/widget.owl" ]; then
        WIDGET_NAME=$(basename "$WIDGET_DIR")
        WIDGETS=$((WIDGETS + 1))
        
        echo "Checking: $WIDGET_NAME"
        
        # Validate syntax
        if ! java -jar tools/owl.jar check "$WIDGET_DIR/widget.owl" >/dev/null 2>&1; then
            echo "  ❌ Syntax error"
            ERRORS=$((ERRORS + 1))
            continue
        fi
        
        # Check meta
        if ! grep -q "meta {" "$WIDGET_DIR/widget.owl"; then
            echo "  ⚠️  Missing meta"
            ERRORS=$((ERRORS + 1))
            continue
        fi
        
        # Check for required meta fields
        MISSING=0
        for FIELD in description version license; do
            if ! grep -q "$FIELD:" "$WIDGET_DIR/widget.owl"; then
                echo "  ⚠️  Missing meta.$FIELD"
                MISSING=$((MISSING + 1))
            fi
        done
        ERRORS=$((ERRORS + MISSING))
        
        if [ $MISSING -eq 0 ]; then
            echo "  ✓ Valid"
        fi
    fi
done

echo ""
echo "=== Validation Complete ==="
echo "Widgets checked: $WIDGETS"
echo "Errors found: $ERRORS"

if [ $ERRORS -eq 0 ]; then
    echo "✓ All widgets are valid!"
else
    echo "❌ Please fix the errors above"
    exit 1
fi
```

### 5.3 Batch Preview Generator

Generate previews for all your widgets:

```bash
# Save as scripts/generate-previews.sh
#!/usr/bin/env bash
set -euo pipefail

USERNAME="${1:?Usage: generate-previews.sh <username>}"
THEME="${2:-tokyo-night}"
WIDGETS_DIR="widgets/$USERNAME"

echo "=== Generating Previews for $USERNAME ==="
echo "Theme: $THEME"
echo ""

for WIDGET_DIR in "$WIDGETS_DIR"/*/; do
    if [ -f "$WIDGET_DIR/widget.owl" ]; then
        WIDGET_NAME=$(basename "$WIDGET_DIR")
        PREVIEW_DIR="$WIDGET_DIR/previews"
        PREVIEW_FILE="$PREVIEW_DIR/$THEME.webp"
        
        echo "Generating preview for: $WIDGET_NAME"
        
        # Create previews directory
        mkdir -p "$PREVIEW_DIR"
        
        # Generate preview
        java -jar tools/owl.jar preview --theme "$THEME" \
            "$WIDGET_DIR/widget.owl" "$PREVIEW_FILE"
        
        # Check if preview was created
        if [ -f "$PREVIEW_FILE" ]; then
            SIZE=$(stat -f%z "$PREVIEW_FILE" 2>/dev/null || stat -c%s "$PREVIEW_FILE")
            echo "  ✓ Created: $PREVIEW_FILE ($SIZE bytes)"
            
            # Check size limit
            if [ "$SIZE" -gt 102400 ]; then
                echo "  ⚠️  Preview exceeds 100KB limit"
            fi
        else
            echo "  ❌ Failed to create preview"
        fi
    fi
done

echo ""
echo "=== Preview Generation Complete ==="
```

### 5.4 Test All Widgets on Device

Push and test all your widgets on a connected device:

```bash
# Save as scripts/test-my-widgets.sh
#!/usr/bin/env bash
set -euo pipefail

USERNAME="${1:?Usage: test-my-widgets.sh <username> [serial]}"
SERIAL="${2:-}"

ADB_CMD="adb"
if [ -n "$SERIAL" ]; then
    ADB_CMD="adb -s $SERIAL"
fi

PKG="dev.omalauncher"
WIDGETS_DIR="widgets/$USERNAME"
DEVICE_BASE="/sdcard/Download/omarchy-widgets-test"

echo "=== Testing Widgets for $USERNAME ==="
echo ""

# Create device directory
$ADB_CMD shell "mkdir -p $DEVICE_BASE"

# Push all widgets
for WIDGET_DIR in "$WIDGETS_DIR"/*/; do
    if [ -f "$WIDGET_DIR/widget.owl" ]; then
        WIDGET_NAME=$(basename "$WIDGET_DIR")
        echo "Pushing: $WIDGET_NAME"
        $ADB_CMD push "$WIDGET_DIR/widget.owl" "$DEVICE_BASE/$WIDGET_NAME.owl"
    fi
done

echo ""
echo "Widgets pushed to device: $DEVICE_BASE/"
echo ""
echo "To import and test:"
echo "1. Open Omalauncher on your device"
echo "2. Long-press home screen → Add widget → Import"
echo "3. Navigate to: $DEVICE_BASE/"
echo "4. Select a widget to import"
echo ""
echo "Check for errors:"
echo "  adb shell \"cat /sdcard/Android/data/$PKG/files/widgets/.errors/*.txt\""
```

### 5.5 PR Preparation Script

Prepare your widgets for PR submission:

```bash
# Save as scripts/prepare-pr.sh
#!/usr/bin/env bash
set -euo pipefail

USERNAME="${1:?Usage: prepare-pr.sh <username>}"
WIDGETS_DIR="widgets/$USERNAME"

echo "=== Preparing PR for $USERNAME ==="
echo ""

# Validate all widgets
echo "1. Validating widgets..."
./scripts/validate-my-widgets.sh "$USERNAME" || { echo "Validation failed"; exit 1; }

# Generate previews
echo ""
echo "2. Generating previews..."
./scripts/generate-previews.sh "$USERNAME" tokyo-night
./scripts/generate-previews.sh "$USERNAME" gruvbox-dark
./scripts/generate-previews.sh "$USERNAME" catppuccin-mocha

# Review all widgets
echo ""
echo "3. Running review..."
for WIDGET_DIR in "$WIDGETS_DIR"/*/; do
    if [ -f "$WIDGET_DIR/widget.owl" ]; then
        WIDGET_NAME=$(basename "$WIDGET_DIR")
        echo "Reviewing: $WIDGET_NAME"
        java -jar tools/owl.jar review . "$WIDGET_DIR/widget.owl" | grep -E "(Error|Warning|✓)" || echo "  ✓ No issues"
    fi
done

echo ""
echo "4. Checking git status..."
git status --short

echo ""
echo "=== PR Preparation Complete ==="
echo ""
echo "Next steps:"
echo "1. Review changes: git diff"
echo "2. Commit: git add . && git commit -m 'Add/Update widgets'"
echo "3. Push: git push origin <branch>"
echo "4. Create PR on GitHub"
```

---

## Quick Reference Commands

### Widget Development
```bash
# Validate widget
java -jar tools/owl.jar check widgets/username/name/widget.owl

# Review widget
java -jar tools/owl.jar review . widgets/username/name/widget.owl

# Generate preview
java -jar tools/owl.jar preview widget.owl preview.png

# Generate theme preview
java -jar tools/owl.jar preview --theme tokyo-night widget.owl tokyo-night.webp

# Check programs used
java -jar tools/owl.jar programs widget.owl
```

### Git Commands
```bash
# Create feature branch
git checkout -b widget/my-new-widget

# Add changes
git add widgets/username/name/

# Commit
git commit -m "Add my-new-widget: description"

# Push
git push origin widget/my-new-widget

# Create PR
gh pr create --fill
```

### ADB Commands
```bash
# Push widget to device
adb push widget.owl /sdcard/Download/

# Check widget errors
adb shell "cat /sdcard/Android/data/dev.omalauncher/files/widgets/.errors/*.txt"

# View widget state
adb shell "cat /sdcard/Android/data/dev.omalauncher/files/widgets/username/name/*.json"

# Restart Omalauncher
adb shell am force-stop dev.omalauncher
adb shell am start -n dev.omalauncher/.MainActivity
```

---

## Troubleshooting

### Widget Won't Validate
- **Error**: Syntax error at line X
- **Fix**: Check for missing braces, semicolons, or typos

### Preview Generation Failed
- **Error**: Cannot render widget
- **Fix**: Check widget doesn't use device-specific features

### Widget Not in Store
- **Check**: Was PR merged?
- **Check**: Did CI publish successfully?
- **Fix**: Wait for GitHub Pages deployment (usually < 5 minutes)

### ADB Not Working
- **Check**: Device connected via USB?
- **Check**: USB debugging enabled?
- **Fix**: `adb kill-server && adb start-server`

### Widget Shows "Needs Newer Launcher"
- **Check**: Widget's `meta { owl: N }`
- **Check**: Launcher's supported levels
- **Fix**: Update Omalauncher or reduce widget's owl requirement

---

## Next Steps

After completing post-installation:

1. **For Widget Users**: Browse the store and install useful widgets
2. **For Widget Developers**: 
   - Read the [Developer Guide](DEVELOPER_GUIDE.md)
   - Create your first widget
   - Submit to the store
3. **For Contributors**: 
   - Help review PRs
   - Improve documentation
   - Report issues

---

*Last updated: $(date +%Y-%m-%d)*
*Widget Store: https://soli-rsa.github.io/omarchy-widgets/*
*See also: [Developer Guide](DEVELOPER_GUIDE.md), [README](README.md)*
