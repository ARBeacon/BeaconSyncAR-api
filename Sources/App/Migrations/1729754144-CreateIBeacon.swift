//
//  1729754144-CreateIBeacon.swift
//  BeaconSyncAR-api
//
//  Created by Maitree Hirunteeyakul on 10/24/24.
//

import Fluent

struct CreateIBeacon: AsyncMigration {
    // Prepares the database for storing iBeacon models.
    func prepare(on database: Database) async throws {
        try await database.schema("ibeacons")
            .id()
            .field("uuid", .uuid, .required)
            .field("major", .int, .required)
            .field("minor", .int, .required)
            .unique(on: "uuid", "major", "minor")
            .create()
    }
    
    // Optionally reverts the changes made in the prepare method.
    func revert(on database: Database) async throws {
        try await database.schema("ibeacons").delete()
    }
}
