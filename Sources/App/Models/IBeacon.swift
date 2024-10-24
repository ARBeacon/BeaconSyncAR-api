//
//  IBeacon.swift
//  BeaconSyncAR-api
//
//  Created by Maitree Hirunteeyakul on 10/24/24.
//
import Vapor
import Fluent
import Foundation

struct IBeaconData: Content {
    let uuid: UUID
    let major: Int
    let minor: Int
}

final class IBeacon: Model, @unchecked Sendable, Content {
    // Name of the table or collection.
    static let schema = "ibeacons"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "uuid")
    var uuid: UUID
    
    @Field(key: "major")
    var major: Int
    
    @Field(key: "minor")
    var minor: Int
    
    @OptionalParent(key: "room_id")
    var room: Room?
    
    init() { }
    
    // Creates a new iBeacon with all properties set.
    init(id: UUID? = nil, uuid: UUID, major: Int, minor: Int) {
        self.id = id
        self.uuid = uuid
        self.major = major
        self.minor = minor
    }
    
    static func getOneBeacon(
        iBeaconData: IBeaconData,
        on db: Database
    ) async throws -> IBeacon? {
        try await IBeacon.query(on: db)
            .filter(\.$uuid == iBeaconData.uuid)
            .filter(\.$major == iBeaconData.major)
            .filter(\.$minor == iBeaconData.minor)
            .first()
    }
    
}

