# Func-Start Skill

Run the macOS app.

## Usage

```
/func-start
```

## Commands

```bash
cd spotdrop-macos
open SpotDrop.xcodeproj
# Then press Cmd+R in Xcode
```

## What it does

1. Opens Xcode project
2. User can run with Cmd+R

## Alternative

```bash
xcodebuild -scheme SpotDrop -configuration Debug build
open build/Debug/SpotDrop.app
```
