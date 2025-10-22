# Resolving secp256k1 Dependency Conflicts

## Problem

If your app uses multiple packages that depend on different versions/forks of secp256k1, you'll encounter duplicate symbol errors during linking because secp256k1 is a C library.

## Solution

In your **app's** Package.swift (macadamia), add dependency overrides to force all packages to use the same secp256k1 implementation:

### Option 1: Use CashuSwift's secp256k1 Fork (Recommended)

Since CashuSwift already uses a specific secp256k1 fork, force Bolt11 to use the same one:

```swift
// In your macadamia app's Package.swift
let package = Package(
    name: "macadamia",
    platforms: [...],
    dependencies: [
        .package(url: "https://github.com/yourusername/CashuSwift.git", ...),
        .package(url: "https://github.com/zeugmaster/Bolt11.git", from: "0.1.0"),
        // Add other dependencies
    ],
    targets: [
        .target(
            name: "macadamia",
            dependencies: [
                "CashuSwift",
                "Bolt11",
            ]
        ),
    ]
)
```

Then in your app, you need to tell SPM to resolve the conflict by using the same secp256k1 for both. Add this at the package level:

```swift
let package = Package(
    name: "macadamia",
    platforms: [...],
    dependencies: [
        // Use CashuSwift's secp256k1 fork (update URL to match yours)
        .package(url: "https://github.com/your-fork/secp256k1.swift.git", from: "0.x.x"),
        .package(url: "https://github.com/zeugmaster/Bolt11.git", from: "0.1.0"),
        .package(url: "https://github.com/yourusername/CashuSwift.git", ...),
    ],
    targets: [
        .target(
            name: "macadamia",
            dependencies: [
                "CashuSwift",
                "Bolt11",
                .product(name: "libsecp256k1", package: "secp256k1.swift"),
            ]
        ),
    ]
)
```

### Option 2: Xcode Project Override

If you're using an Xcode project (not SPM), you can:

1. Go to your app target's Build Settings
2. Add `-Wl,-no_warn_duplicate_libraries` to **Other Linker Flags**
3. This suppresses warnings but doesn't solve the underlying issue

### Option 3: Remove Bolt11's secp256k1 Dependency

Modify Bolt11's Package.swift to not include secp256k1, and instead expect it from the parent:

```swift
// In Bolt11's Package.swift
dependencies: [
    // Remove secp256k1 entirely - let the app provide it
],
```

Then ensure your app provides the secp256k1 dependency that Bolt11 needs.

## Recommended Approach for Your App

1. **Identify which secp256k1 fork CashuSwift uses**
2. **Update Bolt11 to use that same fork** by modifying its Package.swift dependencies
3. **Or make Bolt11 not declare secp256k1 as a dependency** (peer dependency pattern)

## Technical Details

The issue occurs because:
- secp256k1 is a C library wrapped by Swift
- Swift Package Manager links C libraries statically
- Having two copies of the same C library symbols causes linker errors
- The symbols are global and can't be namespaced in C

## For Bolt11 v0.2.0

I'll update Bolt11 to make secp256k1 a peer dependency, meaning your app must provide it explicitly. This gives you full control over which version is used.

