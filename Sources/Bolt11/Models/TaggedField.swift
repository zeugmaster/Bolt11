import Foundation

/// Tagged field types in BOLT #11
public enum TaggedFieldType: UInt8 {
    case paymentHash = 1            // 'p'
    case paymentSecret = 16         // 's'
    case description = 13           // 'd'
    case payeePublicKey = 19        // 'n'
    case descriptionHash = 23       // 'h'
    case expiryTime = 6             // 'x'
    case minFinalCltvExpiry = 24    // 'c'
    case fallbackAddress = 9        // 'f'
    case routingInfo = 3            // 'r'
    case features = 5               // '9'
    case metadata = 27              // 'm'
}

/// A tagged field in a BOLT #11 invoice
public enum TaggedField: Equatable {
    case paymentHash(Data)                  // 256 bits (52 * 5 bits)
    case paymentSecret(Data)                // 256 bits (52 * 5 bits)
    case description(String)                // variable UTF-8 string
    case payeePublicKey(Data)               // 264 bits (53 * 5 bits)
    case descriptionHash(Data)              // 256 bits (52 * 5 bits)
    case expiryTime(UInt64)                 // variable seconds
    case minFinalCltvExpiry(UInt64)         // variable blocks
    case fallbackAddress(FallbackAddress)   // variable
    case routingInfo(RouteHint)             // variable
    case features(Data)                     // variable feature bits
    case metadata(Data)                     // variable metadata
    case unknown(type: UInt8, data: Data)   // unknown field type
    
    /// Get the field type identifier
    public var type: UInt8 {
        switch self {
        case .paymentHash: return 1
        case .paymentSecret: return 16
        case .description: return 13
        case .payeePublicKey: return 19
        case .descriptionHash: return 23
        case .expiryTime: return 6
        case .minFinalCltvExpiry: return 24
        case .fallbackAddress: return 9
        case .routingInfo: return 3
        case .features: return 5
        case .metadata: return 27
        case .unknown(let type, _): return type
        }
    }
}

