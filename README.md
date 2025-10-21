# Bolt11

A pure Swift implementation of BOLT #11 Lightning invoice decoder following the [Lightning Network specification](https://github.com/lightning/bolts/blob/master/11-payment-encoding.md).

## Features

- ✅ Full BOLT #11 specification compliance
- ✅ Bech32 encoding/decoding with checksum verification  
- ✅ Support for all networks (mainnet, testnet, signet, regtest)
- ✅ Amount parsing with all multipliers (m, u, n, p)
- ✅ Tagged field parsing (payment hash, payment secret, description, routing hints, etc.)
- ✅ Signature verification using secp256k1
- ✅ Public key recovery from signatures
- ✅ Feature bits validation
- ✅ Comprehensive test suite with real-world invoice examples
- ✅ Pure Swift implementation with minimal dependencies

## Requirements

- macOS 13.0+ / iOS 16.0+
- Swift 6.1+

## Installation

Add this package to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/Bolt11.git", from: "1.0.0")
]
```

## Usage

### Basic Decoding

```swift
import Bolt11

let invoiceString = "lnbc2500u1pvjluezsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdq5xysxxatsyp3k7enxv4jsxqzpu9qrsgquk0rl77nj30yxdy8j9vdx85fkpmdla2087ne0xh8nhedh8w27kyke0lp53ut353s06fv3qfegext0eh0ymjpf39tuven09sam30g4vgpfna3rh"

do {
    let invoice = try Bolt11Decoder.decode(invoiceString)
    
    print("Network: \(invoice.network)")
    print("Amount: \(invoice.amountMillisatoshis ?? 0) millisatoshis")
    print("Description: \(invoice.invoiceDescription ?? "N/A")")
    print("Payment Hash: \(invoice.paymentHash.hexString)")
    print("Payee Public Key: \(invoice.payeePublicKey?.hexString ?? "N/A")")
    print("Expires: \(invoice.isExpired() ? "Yes" : "No")")
} catch {
    print("Error decoding invoice: \(error)")
}
```

### Pretty Printing

The `Invoice` type conforms to `CustomStringConvertible`, so you can print it directly for a beautifully formatted output:

```swift
let invoice = try Bolt11Decoder.decode(invoiceString)

// Simply print the invoice
print(invoice)

// Or access the formatted string
let formatted = invoice.prettyPrint
```

This will output a formatted display with:
- Network and amount information (in multiple formats)
- All payment details with hex-encoded data
- Payee information and timestamps
- Expiry status
- Feature bits (decoded)
- Routing hints (with decoded short channel IDs)
- Fallback addresses
- Signature details
- Original invoice string (chunked for readability)

Example output:
```
═══════════════════════════════════════════════════════
              LIGHTNING INVOICE (BOLT #11)
═══════════════════════════════════════════════════════

Network: BC (lnbc)
Amount: 2500u BTC
        = 250000000 millisatoshis
        = 0.00250000 BTC

─────────────────────────────────────────────────────
PAYMENT DETAILS
─────────────────────────────────────────────────────
Payment Hash:
  0001020304050607080900010203040506070809000102030405060708090102
Payment Secret:
  1111111111111111111111111111111111111111111111111111111111111111
Description:
  "1 cup coffee"

─────────────────────────────────────────────────────
PAYEE & TIMING
─────────────────────────────────────────────────────
...
```

### String Extension

You can also use the convenience extension on String:

```swift
let invoice = try invoiceString.decodeBolt11()
```

### Accessing Invoice Fields

```swift
let invoice = try Bolt11Decoder.decode(invoiceString)

// Network information
let network = invoice.network // .mainnet, .testnet, .signet, or .regtest

// Amount (optional - can be nil for donation invoices)
if let amount = invoice.amount {
    print("Amount: \(amount.value) \(amount.multiplier?.rawValue ?? "")")
    print("Millisatoshis: \(invoice.amountMillisatoshis ?? 0)")
}

// Payment details
let paymentHash = invoice.paymentHash // 32 bytes
let paymentSecret = invoice.paymentSecret // 32 bytes

// Description
if let description = invoice.invoiceDescription {
    print("Description: \(description)")
} else if let descriptionHash = invoice.descriptionHash {
    print("Description Hash: \(descriptionHash.hexString)")
}

// Timing
let timestamp = invoice.timestamp // Unix timestamp
let expiryTime = invoice.expiryTime // seconds (default 3600)
let isExpired = invoice.isExpired()

// Routing
for route in invoice.routingHints {
    for hop in route.hops {
        print("Hop: \(hop.publicKey.hexString)")
        print("  Channel: \(hop.shortChannelId)")
        print("  Base fee: \(hop.feeBaseMsat) msat")
        print("  Fee rate: \(hop.feeProportionalMillionths) ppm")
    }
}

// Fallback addresses
for address in invoice.fallbackAddresses {
    print("Fallback: version \(address.version), data: \(address.data.hexString)")
}

// Feature bits
let features = invoice.features

// Payment metadata (if present)
if let metadata = invoice.metadata {
    print("Metadata: \(metadata.hexString)")
}
```

## Invoice Structure

A decoded `Invoice` contains:

- `network`: The Lightning network (mainnet, testnet, signet, regtest)
- `amount`: Optional amount with multiplier
- `timestamp`: Invoice creation time (Unix timestamp)
- `paymentHash`: 32-byte payment hash (required)
- `paymentSecret`: 32-byte payment secret (required)
- `invoiceDescription`: Human-readable description (optional)
- `descriptionHash`: Hash of longer description (optional)
- `payeePublicKey`: Public key of the payee (recovered from signature if not provided)
- `expiryTime`: Time until expiration in seconds (default: 3600)
- `minFinalCltvExpiry`: Minimum CLTV expiry delta (default: 18)
- `fallbackAddresses`: On-chain fallback addresses
- `routingHints`: Routing hints for private channels
- `features`: Feature bits
- `metadata`: Payment metadata (optional)
- `signature`: 64-byte ECDSA signature
- `recoveryId`: Signature recovery ID (0-3)
- `originalString`: The original invoice string

## Error Handling

The decoder throws `Bolt11Error` for various validation failures:

```swift
do {
    let invoice = try Bolt11Decoder.decode(invalidInvoice)
} catch Bolt11Error.invalidChecksum {
    print("Invalid Bech32 checksum")
} catch Bolt11Error.missingRequiredField(let field) {
    print("Missing required field: \(field)")
} catch Bolt11Error.invalidSignature {
    print("Signature verification failed")
} catch {
    print("Other error: \(error)")
}
```

Common errors include:
- `invalidBech32Encoding` - Invalid Bech32 format
- `invalidChecksum` - Checksum verification failed
- `mixedCase` - Mixed upper/lowercase characters
- `missingRequiredField` - Missing payment hash or payment secret
- `invalidSignature` - Signature verification failed
- `unsupportedNetwork` - Unknown network prefix
- `invalidAmount` - Malformed amount
- `bothDescriptionAndHash` - Both description and hash present
- And more...

## Implementation Details

### Architecture

The decoder follows a layered architecture:

1. **Bech32 Decoding**: Validates and decodes the Bech32 encoding
2. **HRP Parsing**: Extracts network and amount from human-readable part
3. **Data Part Parsing**: Parses timestamp, tagged fields, and signature
4. **Field Validation**: Validates required fields and constraints
5. **Signature Verification**: Verifies ECDSA signature and recovers public key

### Dependencies

- **libsecp256k1**: For ECDSA signature verification and public key recovery
- **CryptoKit**: For SHA-256 hashing

### Testing

The package includes a comprehensive test suite with 17 tests covering:
- Valid invoices from the BOLT #11 specification
- Invalid invoices (bad checksum, missing fields, etc.)
- Edge cases (uppercase, pico amounts, metadata, routing hints)
- Helper functions (expiry checking, string extensions)

Run tests with:

```bash
swift test
```

## Specification Compliance

This implementation follows [BOLT #11](https://github.com/lightning/bolts/blob/master/11-payment-encoding.md) and includes:

- ✅ Bech32 encoding (BIP-0173)
- ✅ All multipliers (m, u, n, p)
- ✅ All tagged fields (p, s, d, h, n, x, c, f, r, 9, m)
- ✅ Feature bits ("it's ok to be odd" rule)
- ✅ Signature verification and recovery
- ✅ Non-minimal encoding detection
- ✅ Payment secret (required)
- ✅ Payment metadata support
- ✅ Routing hints
- ✅ Fallback addresses

## Examples

See the test suite in `Tests/Bolt11Tests/Bolt11Tests.swift` for comprehensive examples using real invoices from the specification.

## License

This project is available under the MIT license.

## References

- [BOLT #11: Invoice Protocol for Lightning Payments](https://github.com/lightning/bolts/blob/master/11-payment-encoding.md)
- [BIP-0173: Bech32](https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki)
- [Lightning Network Specifications](https://github.com/lightning/bolts)

