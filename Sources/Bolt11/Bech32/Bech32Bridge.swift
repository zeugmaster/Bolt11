import Foundation
import Bech32Swift

/// Bridge to convert Bech32Swift utilities and handle error conversion
enum Bech32Bridge {
    /// Convert Bech32 5-bit data to 8-bit bytes
    static func dataToBytes(_ data: [UInt8]) throws -> Data {
        do {
            return try Bech32Utilities.dataToBytes(data)
        } catch let error as Bech32Error {
            throw Bolt11Error.from(bech32Error: error)
        }
    }
    
    /// Extract exact number of bytes from 5-bit data
    static func extractBytes(from data: [UInt8], byteCount: Int) throws -> Data {
        do {
            return try Bech32Utilities.extractBytes(from: data, byteCount: byteCount)
        } catch let error as Bech32Error {
            throw Bolt11Error.from(bech32Error: error)
        }
    }
    
    /// Parse a big-endian integer from 5-bit data
    static func parseBigEndianInt<T: FixedWidthInteger>(from data: [UInt8], bitCount: Int) -> T? {
        return Bech32Utilities.parseBigEndianInt(from: data, bitCount: bitCount)
    }
    
    /// Convert between different bit sizes
    static func convertBits(data: [UInt8], fromBits: Int, toBits: Int, pad: Bool) throws -> [UInt8] {
        do {
            return try Bech32Utilities.convertBits(data: data, fromBits: fromBits, toBits: toBits, pad: pad)
        } catch let error as Bech32Error {
            throw Bolt11Error.from(bech32Error: error)
        }
    }
}

