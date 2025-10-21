import Foundation

/// Fallback on-chain address
public enum FallbackAddress: Equatable {
    case p2pkh(Data)        // version 17, 160 bits
    case p2sh(Data)         // version 18, 160 bits
    case witnessV0(Data)    // version 0, witness program (160 or 260 bits)
    case witnessV1Taproot(Data) // version 1, 260 bits
    case unknown(version: UInt8, data: Data)
    
    /// Initialize from version and data
    public init(version: UInt8, data: Data) {
        switch version {
        case 17:
            self = .p2pkh(data)
        case 18:
            self = .p2sh(data)
        case 0:
            self = .witnessV0(data)
        case 1:
            self = .witnessV1Taproot(data)
        default:
            self = .unknown(version: version, data: data)
        }
    }
    
    public var version: UInt8 {
        switch self {
        case .p2pkh: return 17
        case .p2sh: return 18
        case .witnessV0: return 0
        case .witnessV1Taproot: return 1
        case .unknown(let version, _): return version
        }
    }
    
    public var data: Data {
        switch self {
        case .p2pkh(let data),
             .p2sh(let data),
             .witnessV0(let data),
             .witnessV1Taproot(let data),
             .unknown(_, let data):
            return data
        }
    }
}

