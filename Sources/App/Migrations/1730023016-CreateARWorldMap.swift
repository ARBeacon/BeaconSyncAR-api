//
//  1730023016-CreateARWorldMap.swift
//  BeaconSyncAR-api
//
//  Created by Maitree Hirunteeyakul on 10/27/24.
//
import Fluent

struct CreateARWorldMap: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("ar_world_maps")
            .id()
            .field("created_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .field("deleted_at", .datetime)
            .field("file_name", .string, .required)
            .field("room_id", .uuid, .references("rooms", .id), .required)
            .field("derived_from_id", .uuid, .references("ar_world_maps", .id))
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("ar_world_maps").delete()
    }
}
