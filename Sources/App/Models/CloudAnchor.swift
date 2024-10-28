//
//  CloudAnchor.swift
//  BeaconSyncAR-api
//
//  Created by Maitree Hirunteeyakul on 28/10/2024.
//
import Vapor
import Fluent
import Foundation

final class CloudAnchor: Model, @unchecked Sendable, Content {
    static let schema = "cloud_anchors"
    
    @ID(key: .id)
    var id: UUID?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?
    
    @Field(key: "hosted_anchor_id")
    var anchorId: String
    
    @Parent(key: "room_id")
    var room: Room
    
    init() { }
    
    init(id: UUID? = nil, anchorId: String, roomID: Room.IDValue) {
        self.id = id
        self.anchorId = anchorId
        self.$room.id = roomID
    }
    
    static func deleteOnMatch(
        anchorId: String,
        roomId: UUID,
        on database: Database
    )async throws{
        if let cloudAnchor = try await CloudAnchor.query(on: database)
            .filter(\.$anchorId == anchorId)
            .filter(\.$room.$id == roomId)
            .first() {try await cloudAnchor.delete(on: database)}
        else {
            throw Abort(.notFound, reason: "CloudAnchor not found.")
        }
    }
    
}

