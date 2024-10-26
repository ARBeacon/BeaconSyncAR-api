//
//  1729937460-MakeCreateAtUpdateAtRequiredForRoom.swift
//  BeaconSyncAR-api
//
//  Created by Maitree Hirunteeyakul on 10/26/24.
//
import Fluent
import SQLKit

struct MakeCreateAtUpdateAtRequiredForRoom: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await (database as! SQLDatabase)
            .raw("""
            ALTER TABLE rooms
            ALTER COLUMN created_at SET NOT NULL,
            ALTER COLUMN updated_at SET NOT NULL
            """)
            .run()
    }
    
    func revert(on database: Database) async throws {
        try await (database as! SQLDatabase)
            .raw("""
            ALTER TABLE rooms
            ALTER COLUMN created_at DROP NOT NULL,
            ALTER COLUMN updated_at DROP NOT NULL
            """)
            .run()
    }
}
