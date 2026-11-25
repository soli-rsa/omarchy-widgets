# Developer Guide - omarchy-widgets

This guide covers development for the **omarchy-widgets** repository, the widget store for Omalauncher.

**For Omalauncher development, see:** [Omalauncher Developer Guide](https://github.com/soli-rsa/omalauncher/blob/main/DEVELOPER_GUIDE.md)

## Table of Contents

1. [Setup Instructions](#1-setup-instructions)
2. [Project Structure Overview](#2-project-structure-overview)
3. [Development Workflow](#3-development-workflow)
4. [Testing Approach](#4-testing-approach)
5. [Common Troubleshooting Steps](#5-common-troubleshooting-steps)

---

## 1. Setup Instructions

### 1.1 Prerequisites

- Java JDK 21+ (Temurin recommended)
- Git
- GitHub CLI (optional)
- Omalauncher installed on Android device (for testing)

### 1.2 Repository Setup

```bash
# Clone the repository
git clone https://github.com/soli-rsa/omarchy-widgets.git
cd omarchy-widgets

# Verify owl.jar is present
ls -la tools/owl.jar

# Test the checker
java -jar tools/owl.jar --help
```

### 1.3 Development Environment

**Recommended Tools:**
- **VS Code** or **IntelliJ IDEA** for editing
- **ADB** for device testing
- **GitHub Desktop** or CLI for repository management

**Optional for CI testing:**
- Docker (for Arch Linux container)
- Arch Linux (for package verification)

---

## 2. Project Structure Overview

```
omarchy-widgets/
├── widgets/                      # Widget collection
│   └── <author>/
│       └── <widget-name>/
│           ├── widget.owl         # Widget definition (REQUIRED)
│           ├── preview.png        # Screenshot (optional, <300KB)
│           ├── README.md          # Documentation (optional)
│           └── previews/          # Theme-specific previews (optional)
│               └── <theme>.webp   # Theme preview (<100KB each)
│
├── faces/                        # Home screen faces
│   └── <author>/
│       └── <face-name>/
│           ├── face.owl           # Face definition (REQUIRED)
│           ├── page-2.owl         # Additional pages (optional)
│           ├── page-3.owl         # ...
│           ├── preview.png        # Screenshot (optional)
│           └── screens/           # Page-specific previews
│               └── <page>/
│                   └── <theme>.webp
│
├── apps/                         # Full-screen apps
│   └── <author>/
│       └── <app-name>/
│           ├── app.owl            # App definition (REQUIRED)
│           ├── preview.png        # Screenshot (optional, <300KB)
│           ├── README.md          # Documentation (optional)
│           └── previews/          # Theme-specific previews (optional)
│               └── <theme>.webp
│
├── tools/                        # Development tools
│   ├── owl.jar                    # OWL checker and compiler
│   ├── rank.py                   # Widget ranking algorithm
│   ├── rank-apps-votes.jsonl     # App ranking votes
│   ├── rank-votes.jsonl          # Widget ranking votes
│   ├── collage.py                # Preview collage generation
│   └── verify-pr.sh              # PR verification script
│
├── runtimes/                     # Runtime implementations
│   └── quickshell/                # Quickshell runtime (for Linux desktop)
│       └── test/                  # Runtime conformance tests
│
├── docs/                         # Documentation
│   └── LANGUAGE.md               # OWL language reference
│
├── w/                            # Web interface
│   └── index.html                # Widget store landing page
│
├── .github/                      # GitHub configuration
│   ├── CODEOWNERS                # Code ownership rules
│   ├── pull_request_template.md # PR template
│   └── workflows/
│       ├── publish.yml           # Store publishing workflow
│       ├── review.yml            # PR review workflow
│       └── runtime.yml           # Runtime conformance workflow
│
├── announcements.json            # User announcements for Omalauncher
├── order.txt                     # Store widget ordering
├── owl.txt                       # Supported OWL language levels
├── rank.txt                      # Widget rankings (auto-generated)
├── rank-apps.txt                 # App rankings (auto-generated)
├── LICENSE
├── README.md
└── .gitignore
```

### 2.1 File Types

| File | Purpose | Required |
|------|---------|----------|
| `widget.owl` | Widget definition | Yes |
| `face.owl` | Face definition | Yes |
| `app.owl` | App definition | Yes |
| `page-*.owl` | Additional face pages | No |
| `preview.png` | Screenshot | No |
| `previews/<theme>.webp` | Theme-specific preview | No |
| `screens/<page>/<theme>.webp` | Face page preview | No |
| `README.md` | Documentation | No |

### 2.2 OWL Language Levels

The `owl.txt` file lists supported OWL language levels and the minimum launcher version required for each. Widgets, faces, and apps declare their required level with `meta { owl: N }`.

---

## 3. Development Workflow

### 3.1 Creating a Widget

#### 3.1.1 Basic Widget Structure

```owl
widget "hello" {
  meta {
    description: "A simple hello world widget"
    version: "1.0"
    license: "MIT"
    category: "dev"
    owl: 1
  }
  size: 2x2
  
  Text {
    text: "Hello, World!"
    style: title
  }
}
```

#### 3.1.2 Widget with Data Source

```owl
widget "clock" {
  meta {
    description: "Current time widget"
    version: "1.0"
    license: "MIT"
    category: "time"
    owl: 1
  }
  size: 2x2
  
  source now = clock every 1s
  
  Text {
    text: fmtTime(now, "HH:mm:ss")
    style: title
  }
}
```

#### 3.1.3 Widget with Commands

```owl
widget "memory" {
  meta {
    description: "Memory usage widget"
    version: "1.0"
    license: "MIT"
    category: "system"
    owl: 6
  }
  size: 3x2
  requires { pacman: ["free"] }
  
  source mem = cmd("free -b | awk '/Mem:/ {print $2, $3}'") every 5s
  let used = num(words(mem)[1])
  let total = num(words(mem)[0])
  let pct = total ? used / total * 100 : null
  
  onTap: terminal("btop")
  
  Column {
    Text { text: "Memory"; style: muted }
    Text { text: "${round(pct)}%"; style: title }
    Progress { value: pct }
  }
}
```

#### 3.1.4 Creating the Files

```bash
# Create widget directory
mkdir -p widgets/myusername/my-widget

# Create widget.owl
cat > widgets/myusername/my-widget/widget.owl << 'EOF'
widget "my-widget" {
  meta {
    description: "My test widget"
    version: "1.0"
    license: "MIT"
    category: "dev"
    owl: 1
  }
  size: 2x2
  
  source time = clock every 1s
  
  Text {
    text: fmtTime(time, "HH:mm:ss")
    style: title
  }
}
EOF

# Validate widget
java -jar tools/owl.jar check widgets/myusername/my-widget/widget.owl
```

### 3.2 Creating a Face

Faces are full home screen pages.

```owl
face "minimal" {
  meta {
    description: "Minimal home screen"
    version: "1.0"
    license: "MIT"
    category: "time"
    owl: 10
  }
  
  source now = clock every 1s
  
  Column {
    align: center
    Text {
      text: fmtTime(now, "HH:mm")
      fontSize: 96
      fontWeight: 200
    }
  }
}
```

**Multi-page faces:**
- Main file: `face.owl` (with meta)
- Additional pages: `page-2.owl`, `page-3.owl`, etc.
- Each page is a separate face definition
- Only `face.owl` needs meta tags
- All pages must declare the same or lower owl level than face.owl

### 3.3 Creating an App

Apps are full-screen views that open from the app drawer.

```owl
app "notes" {
  meta {
    owl: 8
    description: "Quick notes app"
    version: "1.0"
    license: "MIT"
    category: "productivity"
  }
  title: "Notes"
  icon: """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">
    <rect width="256" height="256" rx="56" fill="#24283B"/>
    <rect x="70" y="58" width="128" height="164" rx="14" fill="#16161E" fill-opacity="0.5"/>
    <rect x="64" y="50" width="128" height="164" rx="14" fill="#F4E3A1"/>
    <path d="M64 64a14 14 0 0 1 14-14h100a14 14 0 0 1 14 14v18H64z" fill="#E0AF68"/>
    <path d="M86 112h84M86 140h84M86 168h52" stroke="#B8A36A" stroke-width="10" stroke-linecap="round"/>
  </svg>"""
  
  state notes = [] persist
  
  Column {
    Input {
      placeholder: "Write a note..."
      clear: true
      onSubmit: notes = [value] + notes
    }
    for n in notes {
      Text { text: n }
    }
  }
}
```

### 3.4 Testing Widgets

#### 3.4.1 Local Validation

```bash
# Check syntax
java -jar tools/owl.jar check widgets/myusername/my-widget/widget.owl

# Review (shows what it runs and installs)
java -jar tools/owl.jar review . widgets/myusername/my-widget/widget.owl

# Generate preview
java -jar tools/owl.jar preview widgets/myusername/my-widget/widget.owl preview.png

# Full review of all changed files
tools/verify-pr.sh <PR_NUMBER> pr
```

#### 3.4.2 On-Device Testing

1. **Copy to device:**
   ```bash
   adb push widgets/myusername/my-widget/widget.owl /sdcard/Download/
   ```

2. **Import in Omalauncher:**
   - Long-press home screen
   - Tap "Add widget"
   - Tap "Import"
   - Select the widget file

3. **Check for errors:**
   ```bash
   adb shell "cat /sdcard/Android/data/dev.omalauncher/files/widgets/.errors/<widget>.txt"
   ```

#### 3.4.3 Generating Previews

```bash
# Generate preview for a widget
java -jar tools/owl.jar preview widgets/myusername/my-widget/widget.owl widgets/myusername/my-widget/preview.png

# Generate theme-specific previews
./scripts/store-previews.sh

# This generates previews for all themes in previews/<theme>.webp
```

### 3.5 Submitting Changes

#### 3.5.1 Widget Submission Checklist

- [ ] Widget file is at `widgets/<username>/<name>/widget.owl`
- [ ] `meta` section includes:
  - [ ] `description` (10-200 characters)
  - [ ] `version` (semantic versioning)
  - [ ] `license` (SPDX identifier)
  - [ ] `category` (one of: news, dev, productivity, time, world, sport, finance, media, games, pets, fun, home, system)
  - [ ] `owl` (language level, if > 1)
- [ ] All packages used are declared in `requires { pacman: [...] }`
- [ ] Commands are safe (no eval, base64 decode, etc.)
- [ ] Values in commands use `${sh(value)}` or `${int(n)}`
- [ ] Widget validates with `java -jar tools/owl.jar check`
- [ ] Preview image added (optional but recommended)

#### 3.5.2 Submission Process

```bash
# 1. Fork the repository
# 2. Create feature branch
git checkout -b widget/my-widget

# 3. Add widget files
mkdir -p widgets/myusername/my-widget
# ... add files

# 4. Validate
java -jar tools/owl.jar review . widgets/myusername/my-widget/widget.owl

# 5. Commit
 git add widgets/myusername/my-widget/
 git commit -m "Add my-widget: simple time display"

# 6. Push and create PR
git push origin widget/my-widget
gh pr create --fill
```

**PR Review Process:**
1. CI runs automated checks (review.yml)
2. Maintainer reviews PR
3. Maintainer merges PR
4. CI publishes to store (publish.yml)

### 3.6 Updating Existing Widgets

1. Fork the repository
2. Modify widget in `widgets/<username>/<name>/widget.owl`
3. **Increment version** in meta
4. If commands or packages change, users will need to re-approve
5. Validate and submit PR

### 3.7 Removing Widgets

Only maintainers can remove widgets. Widgets can only be removed from a user's own directory (`widgets/<your-username>/`).

---

## 4. Testing Approach

### 4.1 Automated Testing

#### 4.1.1 CI Workflows

**review.yml** - Pull Request Validation:
- Trigger: PRs targeting widgets/, faces/, or apps/
- Runs in Arch Linux container
- Checks:
  - Syntax validation for all changed OWL files
  - Package dependency verification
  - Security checks for dangerous commands
  - Generates review summary

**runtime.yml** - Runtime Conformance:
- Trigger: Changes to runtimes/ or tools/owl.jar
- Verifies Quickshell runtime matches owl.jar
- Runs Node.js conformance tests

**publish.yml** - Store Publishing:
- Trigger: Pushes to main branch
- Builds:
  - index.json (widgets catalog)
  - faces.json (faces catalog)
  - apps.json (apps catalog)
- Publishes to GitHub Pages
- Updates store ordering

#### 4.1.2 Running CI Locally

```bash
# Review workflow (needs Arch container)
docker run -it archlinux:latest bash
pacman -Syu --noconfirm git diffutils jre-openjdk-headless
# Then manually run review steps

# Runtime conformance
runtimes/quickshell/test/run.sh

# Publishing (build only)
java -jar tools/owl.jar index .
java -jar tools/owl.jar index . --faces
java -jar tools/owl.jar index . --apps
```

### 4.2 Manual Testing

#### 4.2.1 Widget Testing

**Test Cases:**
- [ ] Widget renders correctly
- [ ] Widget updates on data changes
- [ ] Widget responds to taps (if onTap defined)
- [ ] Widget respects size constraints
- [ ] Widget works with theme colors
- [ ] Widget handles errors gracefully

**Debugging:**
```bash
# Check widget errors
adb shell "cat /sdcard/Android/data/dev.omalauncher/files/widgets/.errors/<widget>.txt"

# View widget state
adb shell "cat /sdcard/Android/data/dev.omalauncher/files/widgets/<author>/<name>/*.json"

# Monitor widget updates
adb logcat | grep -i widget
```

#### 4.2.2 Face Testing

**Test Cases:**
- [ ] Face renders correctly on all screen sizes
- [ ] Multi-page faces navigate correctly
- [ ] Face respects statusBar setting
- [ ] Face works with theme colors

#### 4.2.3 App Testing

**Test Cases:**
- [ ] App launches from drawer
- [ ] App renders correctly
- [ ] App handles back button
- [ ] App works with theme colors
- [ ] App icon displays correctly

### 4.3 Security Testing

**Dangerous Patterns to Avoid:**
- `eval` - Executing dynamic code
- `base64 -d` - Decoding potentially malicious data
- `wget | sh` or `curl | bash` - Piping downloads to shell
- `rm -rf` - Recursive deletion
- Downloading and executing files
- Hardcoded tokens or credentials
- Personal data (locations, paths, etc.)

**Security Check:**
```bash
# Review what a widget runs
java -jar tools/owl.jar programs widgets/author/name/widget.owl

# Check for flagged commands
java -jar tools/owl.jar review . widgets/author/name/widget.owl
```

---

## 5. Common Troubleshooting Steps

### 5.1 Validation Errors

#### Error: Syntax Error
```
Error: Expected '}' at line 10, column 5
```
**Solution:**
- Check for missing closing braces
- Use `java -jar tools/owl.jar check` to identify exact location
- Review OWL language syntax in `docs/LANGUAGE.md`

#### Error: Missing meta
```
Error: widget "name" is missing meta
```
**Solution:**
- Add `meta { description: "...", version: "...", license: "..." }`
- All three fields are required

#### Error: Invalid category
```
Error: unknown category "custom"
```
**Solution:**
- Use one of: news, dev, productivity, time, world, sport, finance, media, games, pets, fun, home, system
- Or omit category (defaults to "other")

#### Error: Package not declared
```
Error: program 'jq' isn't declared in requires
```
**Solution:**
- Add to requires: `requires { pacman: ["jq"] }`
- Or use alternative that doesn't need the package

### 5.2 CI Errors

#### Error: Package not in Arch repositories
```
::error file=widgets/author/name/widget.owl::package mypackage isn't in the Arch repositories
```
**Solution:**
- Check if package exists: `pacman -Si mypackage`
- If not, find alternative package or command
- If package exists, CI might need update

#### Error: Security check failed
```
Error: command contains 'eval'
```
**Solution:**
- Remove eval usage
- Find alternative approach
- If absolutely necessary, provide strong justification in PR

#### Error: Value not properly escaped
```
Error: value used in command without sh() or int()
```
**Solution:**
- Use `${sh(value)}` for strings
- Use `${int(n)}` for numbers
- Never use raw `${value}` in commands

### 5.3 Preview Generation Issues

#### Error: Preview generation failed
```
Error: Cannot render widget
```
**Solution:**
- Check widget syntax
- Ensure widget doesn't use device-specific features
- Try simpler widget first

#### Error: Theme preview missing
```
Warning: No preview for theme tokyo-night
```
**Solution:**
- Generate with: `./scripts/store-previews.sh`
- Or manually: `java -jar tools/owl.jar preview --theme tokyo-night widget.owl previews/tokyo-night.webp`

### 5.4 Publishing Issues

#### Error: Widget not appearing in store
**Solution:**
- Check CI publish workflow ran successfully
- Verify widget is in correct directory structure
- Check widget has proper meta tags
- Wait for GitHub Pages deployment (can take a few minutes)

#### Error: Widget shows "needs newer launcher"
**Solution:**
- Check widget's `meta { owl: N }`
- Check launcher's supported levels in `owl.txt`
- User needs to update Omalauncher
- Or reduce widget's owl requirement

### 5.5 Common Fixes

**Problem: Widget works locally but fails in CI**
- Check Java version (CI uses 21)
- Check all dependencies are declared
- Run review locally with Arch container

**Problem: Preview image too large**
- Resize to <300KB
- Use WebP format for better compression

**Problem: Theme preview too large**
- Resize to <100KB
- Use WebP format

**Problem: Widget name conflicts**
- Widget and app cannot share the same name
- Rename one of them

**Problem: Face page numbering has gaps**
- Pages must be numbered sequentially: page-2.owl, page-3.owl, etc.
- No gaps allowed

---

## Additional Resources

- [README](README.md) - Project overview and submission guide
- [OWL Language Reference](docs/LANGUAGE.md) - Complete language documentation
- [Omalauncher Developer Guide](https://github.com/soli-rsa/omalauncher/blob/main/DEVELOPER_GUIDE.md) - Launcher development
- [Omalauncher Widget Docs](https://github.com/soli-rsa/omalauncher/blob/main/app/src/main/assets/widgets/README.md) - Widget language docs shipped with launcher

---

*Last updated: $(date +%Y-%m-%d)*
*Widget Store: https://soli-rsa.github.io/omarchy-widgets/*
