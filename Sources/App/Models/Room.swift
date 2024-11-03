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
    
    @OptionalChild(for: \.$room)
    var arWorldMap: ARWorldMap?
    
    @Children(for: \.$room)
    var cloudAnchors: [CloudAnchor]
    
    init() { }
    
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
    
    func countIBeacons(on database: Database) async throws -> Int {
        let iBeacons = try await self.$iBeacons.query(on: database).all()
        return iBeacons.count
    }
    
    func isARWorldMapPresent(on database: Database) async throws -> Bool {
        let arWorldMap = try await self.$arWorldMap.query(on: database).first()
        return arWorldMap != nil
    }
    
    func getAliveCloudAnchors(on database: Database) async throws -> [CloudAnchor] {
        return try await self.$cloudAnchors
            .query(on: database)
            .filter(\.$expireAt > Date.now)
            .all()
    }
    
    func countCloudAnchors(on database: Database) async throws -> Int {
        let cloudAnchors = try await getAliveCloudAnchors(on: database)
        return cloudAnchors.count
    }
    
    static func getRoomFromId(
        on database: Database,
        id: UUID
    ) async throws -> Room? {
        return try await Room.query(on: database)
            .filter(\.$id == id)
            .with(\.$iBeacons)
            .with(\.$arWorldMap)
            .first()
    }
}
