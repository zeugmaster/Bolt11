import Foundation
import Bech32Swift

/// Errors that can occur during BOLT #11 invoice decoding
public enum Bolt11Error: Error, LocalizedError, Equatable {
    // Bech32 errors
    case invalidBech32Encoding
    case invalidChecksum
    case mixedCase
    case noSeparator
    case invalidCharacter(Character)
    case emptyHRP
    case emptyData
    
    // Network and amount errors
    case unsupportedNetwork(String)
    case invalidAmount
    case invalidMultiplier(Character)
    case invalidPicoAmount // Last decimal must be 0 for pico multiplier
    case amountLeadingZeros
    
    // Data part errors
    case dataTooShort
    case invalidTimestamp
    case invalidSignature
    case signatureNotRecoverable
    
    // Tagged field errors
    case missingRequiredField(String)
    case duplicateField(String)
    case invalidFieldLength(field: String, expected: Int, got: Int)
    case bothDescriptionAndHash
    case neitherDescriptionNorHash
    case nonMinimalEncoding(String)
    case invalidUTF8
    
    // Feature bits errors
    case unknownMandatoryFeature(Int)
    
    // Fallback address errors
    case invalidFallbackAddress
    case unsupportedFallbackVersion(Int)
    
    // Routing errors
    case invalidRoutingInfo
    
    // Validation errors
    case invalidPaymentHash
    case invalidPaymentSecret
    case invalidPublicKey
    case invalidDescriptionHash
    
    public var errorDescription: String? {
        switch self {
        case .invalidBech32Encoding:
            return "Invalid Bech32 encoding"
        case .invalidChecksum:
            return "Bech32 checksum verification failed"
        case .mixedCase:
            return "Bech32 string contains mixed case characters"
        case .noSeparator:
            return "Bech32 string missing '1' separator"
        case .invalidCharacter(let char):
            return "Invalid Bech32 character: '\(char)'"
        case .emptyHRP:
            return "Empty human-readable part"
        case .emptyData:
            return "Empty data part"
        case .unsupportedNetwork(let prefix):
            return "Unsupported network prefix: \(prefix)"
        case .invalidAmount:
            return "Invalid amount format"
        case .invalidMultiplier(let char):
            return "Invalid multiplier: '\(char)'"
        case .invalidPicoAmount:
            return "Pico-bitcoin amount must end with 0"
        case .amountLeadingZeros:
            return "Amount cannot have leading zeros"
        case .dataTooShort:
            return "Data part is too short"
        case .invalidTimestamp:
            return "Invalid timestamp"
        case .invalidSignature:
            return "Signature verification failed"
        case .signatureNotRecoverable:
            return "Cannot recover public key from signature"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        case .duplicateField(let field):
            return "Duplicate field not allowed: \(field)"
        case .invalidFieldLength(let field, let expected, let got):
            return "Invalid length for field '\(field)': expected \(expected), got \(got)"
        case .bothDescriptionAndHash:
            return "Invoice cannot have both description and description hash"
        case .neitherDescriptionNorHash:
            return "Invoice must have either description or description hash"
        case .nonMinimalEncoding(let field):
            return "Field '\(field)' uses non-minimal encoding"
        case .invalidUTF8:
            return "Invalid UTF-8 encoding in description"
        case .unknownMandatoryFeature(let bit):
            return "Unknown mandatory feature bit: \(bit)"
        case .invalidFallbackAddress:
            return "Invalid fallback address"
        case .unsupportedFallbackVersion(let version):
            return "Unsupported fallback address version: \(version)"
        case .invalidRoutingInfo:
            return "Invalid routing information"
        case .invalidPaymentHash:
            return "Invalid payment hash"
        case .invalidPaymentSecret:
            return "Invalid payment secret"
        case .invalidPublicKey:
            return "Invalid public key"
        case .invalidDescriptionHash:
            return "Invalid description hash"
        }
    }
    
    /// Map a Bech32Error to a Bolt11Error
    static func from(bech32Error: Bech32Error) -> Bolt11Error {
        switch bech32Error {
        case .invalidBech32Encoding:
            return .invalidBech32Encoding
        case .invalidChecksum:
            return .invalidChecksum
        case .mixedCase:
            return .mixedCase
        case .noSeparator:
            return .noSeparator
        case .invalidCharacter(let char):
            return .invalidCharacter(char)
        case .emptyHRP:
            return .emptyHRP
        case .emptyData:
            return .emptyData
        }
    }
}

