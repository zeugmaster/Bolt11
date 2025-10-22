# Updating Bolt11 in Your Xcode Project

## Issue: Xcode Showing Old Version

If Xcode shows version 0.1.0 but you want 0.1.1, it's due to Xcode's aggressive package caching.

## Solution

### Quick Fix (Run these commands)

```bash
# 1. Navigate to your app directory
cd /Users/dariolass/Developer/macadamia

# 2. Clear Xcode caches
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Caches/org.swift.swiftpm/*

# 3. Clear local package resolution
rm -rf .build
rm Package.resolved

# 4. Force SPM to resolve to latest
swift package resolve

# 5. Verify the version
swift package show-dependencies | grep Bolt11
```

### Expected Output

You should see:
```
└── bolt11<https://github.com/zeugmaster/Bolt11.git@0.1.1>
```

## In Xcode

After running the commands above:

1. **Close Xcode** completely (⌘Q)
2. **Reopen your project**
3. **File → Packages → Reset Package Caches**
4. **File → Packages → Update to Latest Package Versions**
5. **Product → Clean Build Folder** (⇧⌘K)
6. **Build** (⌘B)

## Verify Version

To check which version Xcode resolved:

1. In Project Navigator, expand **Swift Package Dependencies**
2. Find **Bolt11**
3. Right-click → **Show in Finder**
4. Check the folder name - should include the commit hash from v0.1.1

## If Still Showing 0.1.0

### Update Package.swift Explicitly

In your app's Package.swift, change:

```swift
.package(url: "https://github.com/zeugmaster/Bolt11.git", from: "0.1.0")
```

To:

```swift
.package(url: "https://github.com/zeugmaster/Bolt11.git", exact: "0.1.1")
```

Or:

```swift
.package(url: "https://github.com/zeugmaster/Bolt11.git", .upToNextMinor(from: "0.1.1"))
```

## Why No Version in Package.swift?

Swift Package Manager doesn't use a version field in `Package.swift`. Versions are determined by:
- **Git tags** (like `v0.1.1`)
- **Git commits**
- **Branches**

The `Package.swift` only defines the package structure, not its version.

## Troubleshooting

### Check Git Tags Remotely

```bash
git ls-remote --tags https://github.com/zeugmaster/Bolt11.git
```

Should show both `v0.1.0` and `v0.1.1`.

### Check GitHub Releases

Visit: https://github.com/zeugmaster/Bolt11/releases

Should show v0.1.1 as "Latest".

### Nuclear Option

If nothing works:

```bash
# Remove ALL Xcode caches
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/Caches/com.apple.dt.Xcode

# Remove project-specific files
cd /Users/dariolass/Developer/macadamia
rm -rf .build
rm -rf .swiftpm
rm Package.resolved
rm -rf ~/Library/Developer/Xcode/UserData/IDEEditorInteractivityHistory

# Restart Mac (optional but sometimes necessary)
```

Then open Xcode and let it re-index everything.

