//
//  1730094868-CreateCloudAnchor.swift
//  BeaconSyncAR-api
//
//  Created by Maitree Hirunteeyakul on 28/10/2024.
//
import Fluent

struct CreateCloudAnchor: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("cloud_anchors")
            .id()
            .field("created_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .field("deleted_at", .datetime)
            .field("hosted_anchor_id", .string, .required)
            .field("room_id", .uuid, .references("rooms", .id), .required)
            .unique(on: "hosted_anchor_id", "room_id")
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("cloud_anchors").delete()
    }
}
