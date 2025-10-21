import Foundation

/// Parser for tagged fields in BOLT #11 invoices
struct TaggedFieldParser {
    /// Parse all tagged fields from 5-bit data
    static func parse(_ data: [UInt8]) throws -> [TaggedField] {
        var fields: [TaggedField] = []
        var index = 0
        
        while index < data.count {
            // Need at least type (1) + length (2) = 3 5-bit groups
            guard index + 3 <= data.count else {
                break
            }
            
            // Parse type (5 bits)
            let type = data[index]
            index += 1
            
            // Parse data_length (10 bits = 2 5-bit groups)
            let lengthHigh = UInt16(data[index]) << 5
            let lengthLow = UInt16(data[index + 1])
            let dataLength = Int(lengthHigh | lengthLow)
            index += 2
            
            // Extract field data
            guard index + dataLength <= data.count else {
                throw Bolt11Error.invalidBech32Encoding
            }
            
            let fieldData = Array(data[index..<(index + dataLength)])
            index += dataLength
            
            // Parse the field based on type
            let field = try parseField(type: type, data: fieldData)
            fields.append(field)
        }
        
        return fields
    }
    
    /// Parse a single field based on type
    private static func parseField(type: UInt8, data: [UInt8]) throws -> TaggedField {
        switch type {
        case 1: // Payment hash
            guard data.count == 52 else {
                throw Bolt11Error.invalidFieldLength(field: "p", expected: 52, got: data.count)
            }
            let bytes = try Bech32Utilities.extractBytes(from: data, byteCount: 32)
            return .paymentHash(bytes)
            
        case 16: // Payment secret
            guard data.count == 52 else {
                throw Bolt11Error.invalidFieldLength(field: "s", expected: 52, got: data.count)
            }
            let bytes = try Bech32Utilities.extractBytes(from: data, byteCount: 32)
            return .paymentSecret(bytes)
            
        case 13: // Description
            let bytes = try Bech32Utilities.dataToBytes(data)
            guard let description = String(data: bytes, encoding: .utf8) else {
                throw Bolt11Error.invalidUTF8
            }
            return .description(description)
            
        case 19: // Payee public key
            guard data.count == 53 else {
                throw Bolt11Error.invalidFieldLength(field: "n", expected: 53, got: data.count)
            }
            let bytes = try Bech32Utilities.extractBytes(from: data, byteCount: 33)
            return .payeePublicKey(bytes)
            
        case 23: // Description hash
            guard data.count == 52 else {
                throw Bolt11Error.invalidFieldLength(field: "h", expected: 52, got: data.count)
            }
            let bytes = try Bech32Utilities.extractBytes(from: data, byteCount: 32)
            return .descriptionHash(bytes)
            
        case 6: // Expiry time
            // Check for non-minimal encoding (leading zero field-elements)
            if data.first == 0 {
                throw Bolt11Error.nonMinimalEncoding("x")
            }
            guard let expiry: UInt64 = Bech32Utilities.parseBigEndianInt(from: data, bitCount: data.count * 5) else {
                throw Bolt11Error.invalidBech32Encoding
            }
            return .expiryTime(expiry)
            
        case 24: // Min final CLTV expiry
            // Check for non-minimal encoding
            if data.first == 0 {
                throw Bolt11Error.nonMinimalEncoding("c")
            }
            guard let minCltv: UInt64 = Bech32Utilities.parseBigEndianInt(from: data, bitCount: data.count * 5) else {
                throw Bolt11Error.invalidBech32Encoding
            }
            return .minFinalCltvExpiry(minCltv)
            
        case 9: // Fallback address
            return try parseFallbackAddress(data)
            
        case 3: // Routing info
            return try parseRoutingInfo(data)
            
        case 5: // Features
            // Check for non-minimal encoding
            if data.first == 0 {
                throw Bolt11Error.nonMinimalEncoding("9")
            }
            let bytes = try Bech32Utilities.dataToBytes(data)
            return .features(bytes)
            
        case 27: // Metadata
            let bytes = try Bech32Utilities.dataToBytes(data)
            return .metadata(bytes)
            
        default:
            // Unknown field - store as-is
            let bytes = try Bech32Utilities.dataToBytes(data)
            return .unknown(type: type, data: bytes)
        }
    }
    
    /// Parse fallback address field
    private static func parseFallbackAddress(_ data: [UInt8]) throws -> TaggedField {
        guard !data.isEmpty else {
            throw Bolt11Error.invalidFallbackAddress
        }
        
        let version = data[0]
        let addressData = Array(data.dropFirst())
        
        let bytes = try Bech32Utilities.dataToBytes(addressData)
        let address = FallbackAddress(version: version, data: bytes)
        
        return .fallbackAddress(address)
    }
    
    /// Parse routing information field
    private static func parseRoutingInfo(_ data: [UInt8]) throws -> TaggedField {
        // Each hop is: pubkey (264 bits) + short_channel_id (64 bits) + fee_base_msat (32 bits) +
        // fee_proportional_millionths (32 bits) + cltv_expiry_delta (16 bits) = 408 bits = 51 bytes
        // In 5-bit encoding: 408 bits / 5 = 81.6, so we need 82 5-bit groups per hop
        
        let hopSize = 82 // 5-bit groups per hop
        guard data.count % hopSize == 0 else {
            throw Bolt11Error.invalidRoutingInfo
        }
        
        var hops: [RouteHintHop] = []
        var index = 0
        
        while index < data.count {
            let hopData = Array(data[index..<(index + hopSize)])
            
            // Convert to bytes
            let hopBytes = try Bech32Utilities.dataToBytes(hopData)
            guard hopBytes.count >= 51 else {
                throw Bolt11Error.invalidRoutingInfo
            }
            
            // Parse hop fields
            let publicKey = hopBytes.prefix(33)
            
            var shortChannelId: UInt64 = 0
            shortChannelId |= UInt64(hopBytes[33]) << 56
            shortChannelId |= UInt64(hopBytes[34]) << 48
            shortChannelId |= UInt64(hopBytes[35]) << 40
            shortChannelId |= UInt64(hopBytes[36]) << 32
            shortChannelId |= UInt64(hopBytes[37]) << 24
            shortChannelId |= UInt64(hopBytes[38]) << 16
            shortChannelId |= UInt64(hopBytes[39]) << 8
            shortChannelId |= UInt64(hopBytes[40])
            
            var feeBaseMsat: UInt32 = 0
            feeBaseMsat |= UInt32(hopBytes[41]) << 24
            feeBaseMsat |= UInt32(hopBytes[42]) << 16
            feeBaseMsat |= UInt32(hopBytes[43]) << 8
            feeBaseMsat |= UInt32(hopBytes[44])
            
            var feeProportionalMillionths: UInt32 = 0
            feeProportionalMillionths |= UInt32(hopBytes[45]) << 24
            feeProportionalMillionths |= UInt32(hopBytes[46]) << 16
            feeProportionalMillionths |= UInt32(hopBytes[47]) << 8
            feeProportionalMillionths |= UInt32(hopBytes[48])
            
            var cltvExpiryDelta: UInt16 = 0
            cltvExpiryDelta |= UInt16(hopBytes[49]) << 8
            cltvExpiryDelta |= UInt16(hopBytes[50])
            
            let hop = RouteHintHop(
                publicKey: Data(publicKey),
                shortChannelId: shortChannelId,
                feeBaseMsat: feeBaseMsat,
                feeProportionalMillionths: feeProportionalMillionths,
                cltvExpiryDelta: cltvExpiryDelta
            )
            
            hops.append(hop)
            index += hopSize
        }
        
        return .routingInfo(RouteHint(hops: hops))
    }
}

