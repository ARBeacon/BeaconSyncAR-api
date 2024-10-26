//
//  1729935112-AddCreateAtUpdateAtDeleteAtForIBeaconswift
//  BeaconSyncAR-api
//
//  Created by Maitree Hirunteeyakul on 10/26/24.
//
import Fluent

struct AddCreateAtUpdateAtDeleteAtForIBeacon: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("ibeacons")
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .field("deleted_at", .datetime)
            .update()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("ibeacons")
            .deleteField("created_at")
            .deleteField("updated_at")
            .deleteField("deleted_at")
            .update()
    }
}
