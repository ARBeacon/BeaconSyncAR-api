//
//  UWBAnchor.swift
//  BeaconSyncAR-api
//
//  Created by Maitree Hirunteeyakul on 05/02/2025.
//
import Vapor
import Fluent
import Foundation

final class UWBAnchor: Model, @unchecked Sendable, Content {
    static let schema = "uwb_anchors"
    
    @ID(key: .id)
    var id: UUID?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?
    
    @Field(key: "uwb_beacon_name")
    var uwbBeaconName: String
    
    @Field(key: "relative_transform")
    var relativeTransform: simd_float4x4
    
    init() { }
    
    init(id: UUID? = nil, uwbBeaconName: String, relativeTransform: simd_float4x4) {
        self.id = id
        self.uwbBeaconName = uwbBeaconName
        self.relativeTransform = relativeTransform
    }
    
    static func getUWBAnchoraFromUWBBeaconName(
        on database: Database,
        uwbBeaconName: String
    ) async throws -> [UWBAnchor] {
        return try await UWBAnchor.query(on: database)
            .filter(\.$uwbBeaconName == uwbBeaconName)
            .all()
    }
    
    static func getUWBAnchorFromId(
        on database: Database,
        id: UUID
    ) async throws -> UWBAnchor? {
        return try await UWBAnchor.query(on: database)
            .filter(\.$id == id)
            .first()
    }
}

import simd
extension simd_float4x4: Codable {
    private enum CodingKeys: String, CodingKey {
        case col0, col1, col2, col3
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(columns.0, forKey: .col0)
        try container.encode(columns.1, forKey: .col1)
        try container.encode(columns.2, forKey: .col2)
        try container.encode(columns.3, forKey: .col3)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let col0 = try container.decode(simd_float4.self, forKey: .col0)
        let col1 = try container.decode(simd_float4.self, forKey: .col1)
        let col2 = try container.decode(simd_float4.self, forKey: .col2)
        let col3 = try container.decode(simd_float4.self, forKey: .col3)
        self.init(columns: (col0, col1, col2, col3))
    }
}

