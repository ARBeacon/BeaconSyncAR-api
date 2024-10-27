//
//  ARWorldMap.swift
//  BeaconSyncAR-api
//
//  Created by Maitree Hirunteeyakul on 10/27/24.
//
import Vapor
import Fluent
import Foundation

final class ARWorldMap: Model, @unchecked Sendable, Content {
    static let schema = "ar_world_maps"
    
    @ID(key: .id)
    var id: UUID?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    @Timestamp(key: "deleted_at", on: .delete)
    var deletedAt: Date?
    
    @Field(key: "file_name")
    var fileName: String
    
    @Parent(key: "room_id")
    var room: Room
    
    @OptionalParent(key: "derived_from_id")
    var derivedFrom: ARWorldMap?
    
    init() { }
    
    init(id: UUID? = nil, fileName: String, roomID: Room.IDValue, derivedFrom: ARWorldMap.IDValue? = nil) {
        self.id = id
        self.fileName = fileName
        self.$room.id = roomID
        self.$derivedFrom.id = derivedFrom
    }
    
}

