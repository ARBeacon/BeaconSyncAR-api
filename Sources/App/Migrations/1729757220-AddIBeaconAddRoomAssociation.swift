//
//  1729757220-AddIBeaconAddRoomAssociation.swift
//  BeaconSyncAR-api
//
//  Created by Maitree Hirunteeyakul on 10/24/24.
//
import Fluent

struct AddIBeaconAddRoomAssociation: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("ibeacons")
            .field("room_id", .uuid, .references("rooms", .id))
            .update()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("ibeacons")
            .deleteField("room_id")
            .update()
    }
}
