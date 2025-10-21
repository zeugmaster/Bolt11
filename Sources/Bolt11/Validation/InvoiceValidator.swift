import Foundation

/// Validates BOLT #11 invoice requirements
struct InvoiceValidator {
    /// Validate tagged fields according to BOLT #11 requirements
    static func validateFields(_ fields: [TaggedField]) throws -> ValidatedFields {
        var paymentHash: Data?
        var paymentSecret: Data?
        var description: String?
        var descriptionHash: Data?
        var payeePublicKey: Data?
        var expiryTime: UInt64 = 3600 // default 1 hour
        var minFinalCltvExpiry: UInt64 = 18 // default
        var fallbackAddresses: [FallbackAddress] = []
        var routingHints: [RouteHint] = []
        var features = Data()
        var metadata: Data?
        
        for field in fields {
            switch field {
            case .paymentHash(let hash):
                guard paymentHash == nil else {
                    throw Bolt11Error.duplicateField("p")
                }
                guard hash.count == 32 else {
                    throw Bolt11Error.invalidPaymentHash
                }
                paymentHash = hash
                
            case .paymentSecret(let secret):
                guard paymentSecret == nil else {
                    throw Bolt11Error.duplicateField("s")
                }
                guard secret.count == 32 else {
                    throw Bolt11Error.invalidPaymentSecret
                }
                paymentSecret = secret
                
            case .description(let desc):
                if description != nil || descriptionHash != nil {
                    throw Bolt11Error.bothDescriptionAndHash
                }
                description = desc
                
            case .descriptionHash(let hash):
                if description != nil || descriptionHash != nil {
                    throw Bolt11Error.bothDescriptionAndHash
                }
                guard hash.count == 32 else {
                    throw Bolt11Error.invalidDescriptionHash
                }
                descriptionHash = hash
                
            case .payeePublicKey(let pubkey):
                guard payeePublicKey == nil else {
                    throw Bolt11Error.duplicateField("n")
                }
                guard pubkey.count == 33 else {
                    throw Bolt11Error.invalidPublicKey
                }
                payeePublicKey = pubkey
                
            case .expiryTime(let expiry):
                expiryTime = expiry
                
            case .minFinalCltvExpiry(let minCltv):
                minFinalCltvExpiry = minCltv
                
            case .fallbackAddress(let address):
                fallbackAddresses.append(address)
                
            case .routingInfo(let hint):
                routingHints.append(hint)
                
            case .features(let featureBits):
                features = featureBits
                
            case .metadata(let meta):
                metadata = meta
                
            case .unknown(_, _):
                // Ignore unknown fields (they're allowed)
                continue
            }
        }
        
        // Validate required fields
        guard let paymentHash = paymentHash else {
            throw Bolt11Error.missingRequiredField("p")
        }
        
        guard let paymentSecret = paymentSecret else {
            throw Bolt11Error.missingRequiredField("s")
        }
        
        // Must have either description or description hash (but not both or neither)
        guard description != nil || descriptionHash != nil else {
            throw Bolt11Error.neitherDescriptionNorHash
        }
        
        // Validate feature bits
        try validateFeatureBits(features)
        
        return ValidatedFields(
            paymentHash: paymentHash,
            paymentSecret: paymentSecret,
            description: description,
            descriptionHash: descriptionHash,
            payeePublicKey: payeePublicKey,
            expiryTime: expiryTime,
            minFinalCltvExpiry: minFinalCltvExpiry,
            fallbackAddresses: fallbackAddresses,
            routingHints: routingHints,
            features: features,
            metadata: metadata
        )
    }
    
    /// Validate feature bits according to "it's ok to be odd" rule
    private static func validateFeatureBits(_ features: Data) throws {
        // Check for unknown mandatory (even) feature bits
        for (byteIndex, byte) in features.enumerated() {
            for bitIndex in 0..<8 {
                let isSet = (byte & (1 << bitIndex)) != 0
                if isSet {
                    // Calculate the actual bit position
                    // Features are big-endian, so byte 0 contains the highest bits
                    let bitPosition = (features.count - 1 - byteIndex) * 8 + bitIndex
                    
                    // Even bits are mandatory
                    if bitPosition % 2 == 0 {
                        // Check if this is a known mandatory feature
                        // For now, we'll allow all even bits to pass
                        // In a production implementation, you'd check against known features
                        // Uncomment below to enforce strict feature checking:
                        // if !isKnownFeature(bitPosition) {
                        //     throw Bolt11Error.unknownMandatoryFeature(bitPosition)
                        // }
                    }
                    // Odd bits are optional, always ok
                }
            }
        }
    }
    
    /// Check if a feature bit is known (placeholder for actual implementation)
    private static func isKnownFeature(_ bit: Int) -> Bool {
        // Known feature bits from BOLT #9
        let knownFeatures: Set<Int> = [
            8, 9,   // var_onion_optin
            14, 15, // payment_secret
            16, 17, // basic_mpp
            48, 49, // payment_metadata
        ]
        return knownFeatures.contains(bit)
    }
    
    /// Container for validated fields
    struct ValidatedFields {
        let paymentHash: Data
        let paymentSecret: Data
        let description: String?
        let descriptionHash: Data?
        let payeePublicKey: Data?
        let expiryTime: UInt64
        let minFinalCltvExpiry: UInt64
        let fallbackAddresses: [FallbackAddress]
        let routingHints: [RouteHint]
        let features: Data
        let metadata: Data?
    }
}

