# Changelog

## [0.1.1] - 2025-10-21

### Fixed
- Updated secp256k1 dependency to use zeugmaster/swift-secp256k1 fork
- Resolves duplicate symbol errors when used alongside CashuSwift or other packages using the same secp256k1 fork
- Changed import from `libsecp256k1` to `secp256k1` to match fork's module structure

## [0.1.0] - 2025-10-21

### Added
- Complete BOLT #11 Lightning invoice decoder implementation
- Full Bech32 decoding with checksum verification (BIP-0173)
- Support for all networks: mainnet, testnet, signet, regtest
- Amount parsing with all multipliers: milli (m), micro (u), nano (n), pico (p)
- All tagged field types supported:
  - Payment hash (p) - required
  - Payment secret (s) - required  
  - Description (d) and description hash (h)
  - Payee public key (n)
  - Expiry time (x)
  - Min final CLTV expiry (c)
  - Fallback addresses (f) - P2PKH, P2SH, P2WPKH, P2WSH, P2TR
  - Routing hints (r) with multi-hop support
  - Feature bits (9) with "it's ok to be odd" validation
  - Payment metadata (m)
- Cryptographic validation:
  - ECDSA signature verification using secp256k1
  - Public key recovery from signatures
  - SHA-256 hashing
- Comprehensive validation rules per BOLT #11 spec
- Pretty-print functionality with `CustomStringConvertible` conformance
- Hex string utilities for Data fields
- String extension for convenient decoding: `"lnbc...".decodeBolt11()`
- 18 comprehensive tests covering valid and invalid invoices
- Detailed error types for all failure cases
- Full documentation with README and implementation guide

### Technical Details
- Pure Swift implementation
- Minimal dependencies (libsecp256k1 via secp256k1.swift, CryptoKit)
- Platform support: macOS 13.0+, iOS 16.0+
- Swift 6.1+ compatible
- 100% test coverage of spec examples
- Performance: O(n) decoding complexity

### Documentation
- Complete API documentation
- Usage examples for all features
- Pretty-print output examples
- Error handling guide
- BOLT #11 compliance checklist

