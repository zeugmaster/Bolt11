import Foundation

/// A single hop in a routing hint
public struct RouteHintHop: Equatable {
    /// The public key of the node at the start of this channel
    public let publicKey: Data
    
    /// The short channel ID
    public let shortChannelId: UInt64
    
    /// Base fee in millisatoshi
    public let feeBaseMsat: UInt32
    
    /// Proportional fee in millionths
    public let feeProportionalMillionths: UInt32
    
    /// CLTV expiry delta
    public let cltvExpiryDelta: UInt16
    
    public init(publicKey: Data, shortChannelId: UInt64, feeBaseMsat: UInt32, feeProportionalMillionths: UInt32, cltvExpiryDelta: UInt16) {
        self.publicKey = publicKey
        self.shortChannelId = shortChannelId
        self.feeBaseMsat = feeBaseMsat
        self.feeProportionalMillionths = feeProportionalMillionths
        self.cltvExpiryDelta = cltvExpiryDelta
    }
}

/// Complete routing hint (one or more hops)
public struct RouteHint: Equatable {
    /// The hops in this route
    public let hops: [RouteHintHop]
    
    public init(hops: [RouteHintHop]) {
        self.hops = hops
    }
}

