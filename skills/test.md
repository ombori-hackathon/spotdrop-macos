# Test Skill

Run macOS tests.

## Usage

```
/test
```

## Commands

```bash
cd spotdrop-macos
xcodebuild test -scheme SpotDrop -destination 'platform=macOS'
```

## Options

```bash
# Run specific test
xcodebuild test -scheme SpotDrop -destination 'platform=macOS' -only-testing:SpotDropTests/AuthViewModelTests

# Run with coverage
xcodebuild test -scheme SpotDrop -destination 'platform=macOS' -enableCodeCoverage YES
```
