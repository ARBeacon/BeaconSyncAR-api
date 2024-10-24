//
//  1729757215-CreateRoom.swift
//  BeaconSyncAR-api
//
//  Created by Maitree Hirunteeyakul on 10/24/24.
//
import Fluent

struct CreateRoom: AsyncMigration {
    // Prepares the database for storing Room models.
    func prepare(on database: Database) async throws {
        try await database.schema("rooms")
            .id()
            .field("name", .string, .required)
            .create()
    }
    
    // Optionally reverts the changes made in the prepare method.
    func revert(on database: Database) async throws {
        try await database.schema("rooms").delete()
    }
}
