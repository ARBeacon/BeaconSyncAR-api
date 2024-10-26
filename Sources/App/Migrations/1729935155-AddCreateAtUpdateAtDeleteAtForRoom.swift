//
//  1729935155-AddCreateAtUpdateAtDeleteAtForRoom.swift
//  BeaconSyncAR-api
//
//  Created by Maitree Hirunteeyakul on 10/26/24.
//
import Fluent

struct AddCreateAtUpdateAtDeleteAtForRoom: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("rooms")
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .field("deleted_at", .datetime)
            .update()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("rooms")
            .deleteField("created_at")
            .deleteField("updated_at")
            .deleteField("deleted_at")
            .update()
    }
}
