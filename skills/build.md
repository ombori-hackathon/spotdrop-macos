# Build Skill

Build the macOS app.

## Usage

```
/build
```

## Commands

```bash
cd spotdrop-macos
xcodebuild -scheme SpotDrop -configuration Debug build
```

## What it does

1. Compiles Swift code
2. Links frameworks
3. Creates app bundle
