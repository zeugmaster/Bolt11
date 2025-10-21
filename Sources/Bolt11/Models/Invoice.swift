import Foundation

/// A decoded BOLT #11 Lightning invoice
public struct Invoice: Equatable, CustomStringConvertible {
    // Human-readable part
    /// The network this invoice is for
    public let network: Network
    
    /// The amount to be paid (optional, nil means any amount)
    public let amount: Amount?
    
    // Data part
    /// Timestamp when the invoice was created (seconds since Unix epoch)
    public let timestamp: UInt64
    
    /// Payment hash (required)
    public let paymentHash: Data
    
    /// Payment secret (required)
    public let paymentSecret: Data
    
    /// Short description of the payment purpose (mutually exclusive with descriptionHash)
    public let invoiceDescription: String?
    
    /// Hash of a longer description (mutually exclusive with description)
    public let descriptionHash: Data?
    
    /// Public key of the payee (if not provided, recovered from signature)
    public let payeePublicKey: Data?
    
    /// Expiry time in seconds (default 3600 if not specified)
    public let expiryTime: UInt64
    
    /// Minimum final CLTV expiry delta (default 18 if not specified)
    public let minFinalCltvExpiry: UInt64
    
    /// Fallback on-chain addresses
    public let fallbackAddresses: [FallbackAddress]
    
    /// Routing hints for private channels
    public let routingHints: [RouteHint]
    
    /// Feature bits
    public let features: Data
    
    /// Payment metadata
    public let metadata: Data?
    
    /// The signature
    public let signature: Data
    
    /// The recovery ID for signature verification (0-3)
    public let recoveryId: UInt8
    
    /// The original invoice string
    public let originalString: String
    
    public init(network: Network,
                amount: Amount?,
                timestamp: UInt64,
                paymentHash: Data,
                paymentSecret: Data,
                invoiceDescription: String?,
                descriptionHash: Data?,
                payeePublicKey: Data?,
                expiryTime: UInt64,
                minFinalCltvExpiry: UInt64,
                fallbackAddresses: [FallbackAddress],
                routingHints: [RouteHint],
                features: Data,
                metadata: Data?,
                signature: Data,
                recoveryId: UInt8,
                originalString: String) {
        self.network = network
        self.amount = amount
        self.timestamp = timestamp
        self.paymentHash = paymentHash
        self.paymentSecret = paymentSecret
        self.invoiceDescription = invoiceDescription
        self.descriptionHash = descriptionHash
        self.payeePublicKey = payeePublicKey
        self.expiryTime = expiryTime
        self.minFinalCltvExpiry = minFinalCltvExpiry
        self.fallbackAddresses = fallbackAddresses
        self.routingHints = routingHints
        self.features = features
        self.metadata = metadata
        self.signature = signature
        self.recoveryId = recoveryId
        self.originalString = originalString
    }
    
    /// Check if the invoice has expired
    public func isExpired(at date: Date = Date()) -> Bool {
        let expiryDate = Date(timeIntervalSince1970: TimeInterval(timestamp + expiryTime))
        return date > expiryDate
    }
    
    /// Get the amount in millisatoshis (if specified)
    public var amountMillisatoshis: UInt64? {
        return amount?.millisatoshis
    }
    
    // MARK: - Pretty Printing
    
    /// Pretty-printed description of the invoice
    public var prettyPrint: String {
        var lines: [String] = []
        
        lines.append("═══════════════════════════════════════════════════════")
        lines.append("              LIGHTNING INVOICE (BOLT #11)")
        lines.append("═══════════════════════════════════════════════════════")
        lines.append("")
        
        // Network
        lines.append("Network: \(network.rawValue.uppercased()) (\(network.prefix))")
        
        // Amount
        if let amount = amount {
            if let msat = amountMillisatoshis {
                let btc = Double(msat) / 100_000_000_000.0
                let multiplierStr = amount.multiplier.map { String($0.rawValue) } ?? ""
                lines.append("Amount: \(amount.value)\(multiplierStr) BTC")
                lines.append("        = \(msat) millisatoshis")
                lines.append("        = \(String(format: "%.8f", btc)) BTC")
            } else {
                let multiplierStr = amount.multiplier.map { String($0.rawValue) } ?? ""
                lines.append("Amount: \(amount.value)\(multiplierStr) BTC (sub-millisatoshi)")
            }
        } else {
            lines.append("Amount: (unspecified - any amount)")
        }
        
        lines.append("")
        lines.append("─────────────────────────────────────────────────────")
        lines.append("PAYMENT DETAILS")
        lines.append("─────────────────────────────────────────────────────")
        
        // Payment Hash
        lines.append("Payment Hash:")
        lines.append("  \(paymentHash.hexString)")
        
        // Payment Secret
        lines.append("Payment Secret:")
        lines.append("  \(paymentSecret.hexString)")
        
        // Description
        if let desc = invoiceDescription {
            lines.append("Description:")
            lines.append("  \"\(desc)\"")
        } else if let descHash = descriptionHash {
            lines.append("Description Hash:")
            lines.append("  \(descHash.hexString)")
        }
        
        lines.append("")
        lines.append("─────────────────────────────────────────────────────")
        lines.append("PAYEE & TIMING")
        lines.append("─────────────────────────────────────────────────────")
        
        // Payee Public Key
        if let pubkey = payeePublicKey {
            lines.append("Payee Public Key:")
            lines.append("  \(pubkey.hexString)")
        }
        
        // Timestamp
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        lines.append("Created: \(formatter.string(from: date))")
        lines.append("         (timestamp: \(timestamp))")
        
        // Expiry
        let expiryDate = Date(timeIntervalSince1970: TimeInterval(timestamp + expiryTime))
        let expired = isExpired()
        lines.append("Expires: \(formatter.string(from: expiryDate))")
        lines.append("         (\(expiryTime) seconds from creation)")
        lines.append("Status: \(expired ? "⚠️  EXPIRED" : "✓ Valid")")
        
        // Min Final CLTV Expiry
        lines.append("Min Final CLTV Expiry: \(minFinalCltvExpiry) blocks")
        
        // Metadata
        if let meta = metadata {
            lines.append("")
            lines.append("─────────────────────────────────────────────────────")
            lines.append("METADATA")
            lines.append("─────────────────────────────────────────────────────")
            lines.append("Payment Metadata:")
            lines.append("  \(meta.hexString)")
        }
        
        // Feature Bits
        if !features.isEmpty {
            lines.append("")
            lines.append("─────────────────────────────────────────────────────")
            lines.append("FEATURES")
            lines.append("─────────────────────────────────────────────────────")
            lines.append("Feature Bits:")
            lines.append("  \(features.hexString)")
            
            // Decode feature bits
            var featureBits: [Int] = []
            for (byteIndex, byte) in features.enumerated() {
                for bitIndex in 0..<8 {
                    if (byte & (1 << bitIndex)) != 0 {
                        let bitPosition = (features.count - 1 - byteIndex) * 8 + bitIndex
                        featureBits.append(bitPosition)
                    }
                }
            }
            if !featureBits.isEmpty {
                lines.append("  Active bits: \(featureBits.sorted().map(String.init).joined(separator: ", "))")
            }
        }
        
        // Routing Hints
        if !routingHints.isEmpty {
            lines.append("")
            lines.append("─────────────────────────────────────────────────────")
            lines.append("ROUTING HINTS (\(routingHints.count) route\(routingHints.count == 1 ? "" : "s"))")
            lines.append("─────────────────────────────────────────────────────")
            
            for (routeIndex, route) in routingHints.enumerated() {
                lines.append("Route #\(routeIndex + 1): \(route.hops.count) hop\(route.hops.count == 1 ? "" : "s")")
                for (hopIndex, hop) in route.hops.enumerated() {
                    lines.append("  Hop #\(hopIndex + 1):")
                    lines.append("    Node: \(hop.publicKey.hexString)")
                    
                    // Decode short channel ID
                    let blockHeight = (hop.shortChannelId >> 40) & 0xFFFFFF
                    let txIndex = (hop.shortChannelId >> 16) & 0xFFFFFF
                    let outputIndex = hop.shortChannelId & 0xFFFF
                    lines.append("    Channel: \(blockHeight)x\(txIndex)x\(outputIndex)")
                    lines.append("             (short_channel_id: \(hop.shortChannelId))")
                    
                    lines.append("    Base Fee: \(hop.feeBaseMsat) msat")
                    lines.append("    Fee Rate: \(hop.feeProportionalMillionths) ppm")
                    lines.append("    CLTV Delta: \(hop.cltvExpiryDelta) blocks")
                }
            }
        }
        
        // Fallback Addresses
        if !fallbackAddresses.isEmpty {
            lines.append("")
            lines.append("─────────────────────────────────────────────────────")
            lines.append("FALLBACK ADDRESSES (\(fallbackAddresses.count))")
            lines.append("─────────────────────────────────────────────────────")
            
            for (index, address) in fallbackAddresses.enumerated() {
                let typeStr: String
                switch address {
                case .p2pkh: typeStr = "P2PKH (version 17)"
                case .p2sh: typeStr = "P2SH (version 18)"
                case .witnessV0(let data):
                    if data.count == 20 {
                        typeStr = "P2WPKH (witness v0, 20 bytes)"
                    } else if data.count == 32 {
                        typeStr = "P2WSH (witness v0, 32 bytes)"
                    } else {
                        typeStr = "Witness v0 (\(data.count) bytes)"
                    }
                case .witnessV1Taproot: typeStr = "P2TR (witness v1 / Taproot)"
                case .unknown(let version, _): typeStr = "Unknown (version \(version))"
                }
                
                lines.append("Address #\(index + 1): \(typeStr)")
                lines.append("  \(address.data.hexString)")
            }
        }
        
        // Signature
        lines.append("")
        lines.append("─────────────────────────────────────────────────────")
        lines.append("SIGNATURE")
        lines.append("─────────────────────────────────────────────────────")
        lines.append("Signature (r,s):")
        lines.append("  \(signature.hexString)")
        lines.append("Recovery ID: \(recoveryId)")
        
        lines.append("")
        lines.append("─────────────────────────────────────────────────────")
        lines.append("ORIGINAL INVOICE")
        lines.append("─────────────────────────────────────────────────────")
        
        // Break up long invoice string for readability
        let chunkSize = 64
        var remaining = originalString
        while !remaining.isEmpty {
            let end = remaining.index(remaining.startIndex, offsetBy: min(chunkSize, remaining.count))
            lines.append(String(remaining[..<end]))
            remaining = String(remaining[end...])
        }
        
        lines.append("")
        lines.append("═══════════════════════════════════════════════════════")
        
        return lines.joined(separator: "\n")
    }
    
    // MARK: - CustomStringConvertible
    
    /// String representation for print() - uses pretty print format
    public var description: String {
        return prettyPrint
    }
}

