import Foundation

/// Utilities for converting Bech32 5-bit groups to/from 8-bit bytes
struct Bech32Utilities {
    /// Convert from 5-bit groups to 8-bit bytes
    /// - Parameters:
    ///   - data: Array of 5-bit values
    ///   - pad: Whether to pad the result
    /// - Returns: Array of 8-bit bytes
    static func convertBits(data: [UInt8], fromBits: Int, toBits: Int, pad: Bool) throws -> [UInt8] {
        var accumulator: UInt32 = 0
        var bits: Int = 0
        var result: [UInt8] = []
        let maxValue = (1 << toBits) - 1
        
        for value in data {
            guard value < (1 << fromBits) else {
                throw Bolt11Error.invalidBech32Encoding
            }
            
            accumulator = (accumulator << fromBits) | UInt32(value)
            bits += fromBits
            
            while bits >= toBits {
                bits -= toBits
                result.append(UInt8((accumulator >> bits) & UInt32(maxValue)))
            }
        }
        
        if pad {
            if bits > 0 {
                result.append(UInt8((accumulator << (toBits - bits)) & UInt32(maxValue)))
            }
        } else {
            // Verify padding is all zeros (leftover bits should be zero)
            if bits > 0 {
                let paddingMask = UInt32((1 << bits) - 1)
                if (accumulator & paddingMask) != 0 {
                    throw Bolt11Error.invalidBech32Encoding
                }
            }
        }
        
        return result
    }
    
    /// Parse a big-endian integer from data
    static func parseBigEndianInt<T: FixedWidthInteger>(from data: [UInt8], bitCount: Int) -> T? {
        guard bitCount <= data.count * 5 else {
            return nil
        }
        
        var result: T = 0
        var accumulator: UInt64 = 0
        var bitsAccumulated: Int = 0
        
        for value in data {
            accumulator = (accumulator << 5) | UInt64(value)
            bitsAccumulated += 5
        }
        
        // Extract exactly bitCount bits from the accumulator
        let excessBits = (data.count * 5) - bitCount
        accumulator >>= excessBits
        
        result = T(accumulator & ((1 << bitCount) - 1))
        
        return result
    }
    
    /// Extract bytes from 5-bit data
    static func extractBytes(from data: [UInt8], byteCount: Int) throws -> Data {
        let bytes = try convertBits(data: data, fromBits: 5, toBits: 8, pad: false)
        guard bytes.count >= byteCount else {
            throw Bolt11Error.invalidBech32Encoding
        }
        return Data(bytes.prefix(byteCount))
    }
    
    /// Convert 5-bit data to bytes without strict length requirement
    static func dataToBytes(_ data: [UInt8]) throws -> Data {
        let bytes = try convertBits(data: data, fromBits: 5, toBits: 8, pad: false)
        return Data(bytes)
    }
}

