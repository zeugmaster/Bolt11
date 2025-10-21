import Foundation

/// Parser for the data part of a BOLT #11 invoice
struct DataPartParser {
    struct ParsedDataPart {
        let timestamp: UInt64
        let fields: [TaggedField]
        let signature: Data
        let recoveryId: UInt8
        let signingData: Data
    }
    
    /// Parse the data part
    /// - Parameters:
    ///   - data: The 5-bit data array
    ///   - hrp: The human-readable part (needed for signature verification)
    /// - Returns: Parsed timestamp, fields, and signature
    static func parse(data: [UInt8], hrp: String) throws -> ParsedDataPart {
        // Data must be at least: 35 bits (timestamp) + 520 bits (signature) = 555 bits = 111 5-bit groups
        guard data.count >= 111 else {
            throw Bolt11Error.dataTooShort
        }
        
        // Parse timestamp (35 bits = 7 5-bit groups)
        let timestampData = Array(data.prefix(7))
        guard let timestamp: UInt64 = Bech32Utilities.parseBigEndianInt(from: timestampData, bitCount: 35) else {
            throw Bolt11Error.invalidTimestamp
        }
        
        // Signature is last 104 5-bit groups (520 bits = 65 bytes)
        let signatureData = Array(data.suffix(104))
        let signatureBytes = try Bech32Utilities.extractBytes(from: signatureData, byteCount: 65)
        
        // Last byte is recovery ID
        let recoveryId = signatureBytes[64]
        guard recoveryId < 4 else {
            throw Bolt11Error.invalidSignature
        }
        
        // First 64 bytes are the signature
        let signature = signatureBytes.prefix(64)
        
        // Parse tagged fields (everything between timestamp and signature)
        let fieldsData = Array(data.dropFirst(7).dropLast(104))
        let fields = try TaggedFieldParser.parse(fieldsData)
        
        // Construct signing data for verification
        // It's the HRP (as UTF-8) + data part without signature
        let signingData = constructSigningData(hrp: hrp, data: Array(data.dropLast(104)))
        
        return ParsedDataPart(
            timestamp: timestamp,
            fields: fields,
            signature: Data(signature),
            recoveryId: recoveryId,
            signingData: signingData
        )
    }
    
    /// Construct the data that was signed
    private static func constructSigningData(hrp: String, data: [UInt8]) -> Data {
        var result = Data()
        
        // Add HRP as UTF-8 bytes
        result.append(contentsOf: hrp.utf8)
        
        // Convert 5-bit data to 8-bit, padding with zeros at the end
        var accumulator: UInt32 = 0
        var bits: Int = 0
        
        for value in data {
            accumulator = (accumulator << 5) | UInt32(value)
            bits += 5
            
            while bits >= 8 {
                bits -= 8
                result.append(UInt8((accumulator >> bits) & 0xFF))
            }
        }
        
        // Pad remaining bits with zeros if needed
        if bits > 0 {
            result.append(UInt8((accumulator << (8 - bits)) & 0xFF))
        }
        
        return result
    }
}

