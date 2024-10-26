//
//  Room.swift
//  BeaconSyncAR-api
//
//  Created by Maitree Hirunteeyakul on 10/24/24.
//
import Vapor
import Fluent
import Foundation

final class Room: Model, @unchecked Sendable, Content {
    // Name of the table or collection.
    static let schema = "rooms"
    
    @ID(key: .id)
    var id: UUID?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?
    
    @Field(key: "name")
    var name: String
    
    @Children(for: \.$room)
    var iBeacons: [IBeacon]
    
    init() { }
    
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
    
    func countIBeacons(on database: Database) throws -> EventLoopFuture<Int> {
        return IBeacon.query(on: database)
            .filter(\.$room.$id == self.id!)
            .count()
    }
    
    static func getRoomFromIdWithIBeacons(
        on database: Database,
        id: UUID
    ) async throws -> Room? {
        return try await Room.query(on: database)
            .filter(\.$id == id)
            .with(\.$iBeacons)
            .first()
    }
}
