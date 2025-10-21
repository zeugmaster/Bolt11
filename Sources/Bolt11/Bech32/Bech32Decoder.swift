import Foundation

/// Bech32 decoder implementing BIP-0173
struct Bech32Decoder {
    /// Bech32 character set
    private static let charset = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"
    
    /// Generator values for checksum computation
    private static let generator: [UInt32] = [0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3]
    
    /// Decoded Bech32 data
    struct DecodedBech32 {
        let hrp: String
        let data: [UInt8]
        let checksum: [UInt8]
    }
    
    /// Decode a Bech32 string
    static func decode(_ string: String) throws -> DecodedBech32 {
        // Check for mixed case
        let hasLower = string.contains(where: { $0.isLowercase })
        let hasUpper = string.contains(where: { $0.isUppercase })
        if hasLower && hasUpper {
            throw Bolt11Error.mixedCase
        }
        
        // Convert to lowercase for processing
        let str = string.lowercased()
        
        // Find the last occurrence of '1' separator
        guard let separatorIndex = str.lastIndex(of: "1") else {
            throw Bolt11Error.noSeparator
        }
        
        // Split into HRP and data
        let hrp = String(str[..<separatorIndex])
        let dataString = String(str[str.index(after: separatorIndex)...])
        
        // Validate HRP is not empty
        guard !hrp.isEmpty else {
            throw Bolt11Error.emptyHRP
        }
        
        // Validate data is not empty (must have at least 6 checksum characters)
        guard dataString.count >= 6 else {
            throw Bolt11Error.emptyData
        }
        
        // Convert characters to 5-bit values
        var data: [UInt8] = []
        for char in dataString {
            guard let index = charset.firstIndex(of: char) else {
                throw Bolt11Error.invalidCharacter(char)
            }
            let value = UInt8(charset.distance(from: charset.startIndex, to: index))
            data.append(value)
        }
        
        // Verify checksum
        guard verifyChecksum(hrp: hrp, data: data) else {
            throw Bolt11Error.invalidChecksum
        }
        
        // Split data and checksum (last 6 characters)
        let dataOnly = Array(data.dropLast(6))
        let checksumOnly = Array(data.suffix(6))
        
        return DecodedBech32(hrp: hrp, data: dataOnly, checksum: checksumOnly)
    }
    
    /// Verify the Bech32 checksum
    private static func verifyChecksum(hrp: String, data: [UInt8]) -> Bool {
        let values = expandHRP(hrp) + data
        return polymod(values) == 1
    }
    
    /// Expand the HRP for checksum computation
    private static func expandHRP(_ hrp: String) -> [UInt8] {
        var result: [UInt8] = []
        for char in hrp {
            let value = char.asciiValue ?? 0
            result.append(value >> 5)
        }
        result.append(0)
        for char in hrp {
            let value = char.asciiValue ?? 0
            result.append(value & 0x1f)
        }
        return result
    }
    
    /// Compute the Bech32 polymod
    private static func polymod(_ values: [UInt8]) -> UInt32 {
        var chk: UInt32 = 1
        for value in values {
            let top = chk >> 25
            chk = (chk & 0x1ffffff) << 5 ^ UInt32(value)
            for i in 0..<5 {
                if ((top >> i) & 1) != 0 {
                    chk ^= generator[i]
                }
            }
        }
        return chk
    }
}

