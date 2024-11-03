//
//  1730623498-AddExpireAtForCloudAnchor.swift
//  BeaconSyncAR-api
//
//  Created by Maitree Hirunteeyakul on 11/3/24.
//
import Fluent

struct AddExpireAtForCloudAnchor: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("cloud_anchors")
            .field("expire_at", .datetime)
            .update()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("cloud_anchors")
            .deleteField("expire_at")
            .update()
    }
}

