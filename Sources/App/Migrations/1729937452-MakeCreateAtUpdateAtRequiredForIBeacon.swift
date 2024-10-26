//
//  1729937452-MakeCreateAtUpdateAtRequiredForIBeacon.swift
//  BeaconSyncAR-api
//
//  Created by Maitree Hirunteeyakul on 10/26/24.
//
import Fluent
import SQLKit

struct MakeCreateAtUpdateAtRequiredForIBeacon: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await (database as! SQLDatabase)
            .raw("""
            ALTER TABLE ibeacons
            ALTER COLUMN created_at SET NOT NULL,
            ALTER COLUMN updated_at SET NOT NULL
            """)
            .run()
    }
    
    func revert(on database: Database) async throws {
        try await (database as! SQLDatabase)
            .raw("""
            ALTER TABLE ibeacons
            ALTER COLUMN created_at DROP NOT NULL,
            ALTER COLUMN updated_at DROP NOT NULL
            """)
            .run()
    }
}
