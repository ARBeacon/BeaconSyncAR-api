//
//  1737206618-CreateUWBAnchor.swift
//  BeaconSyncAR-api
//
//  Created by Maitree Hirunteeyakul on 05/02/2025.
//
import Fluent
import SQLKit

struct CreateUWBAnchor: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("uwb_anchors")
            .id()
            .field("created_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .field("deleted_at", .datetime)
            .field("uwb_beacon_name", .string, .required)
            .field("relative_transform", .json, .required)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("uwb_anchors").delete()
    }
}
