import Foundation
import CryptoKit

/// Utilities for hashing operations
struct HashUtilities {
    /// Compute SHA-256 hash of data
    static func sha256(_ data: Data) -> Data {
        let hash = SHA256.hash(data: data)
        return Data(hash)
    }
}

