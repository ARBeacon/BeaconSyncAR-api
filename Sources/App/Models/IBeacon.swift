//
//  IBeacon.swift
//  BeaconSyncAR-api
//
//  Created by Maitree Hirunteeyakul on 10/24/24.
//
import Vapor
import Fluent
import Foundation

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
    
    init() { }
    
    // Creates a new iBeacon with all properties set.
    init(id: UUID? = nil, uuid: UUID, major: Int, minor: Int) {
        self.id = id
        self.uuid = uuid
        self.major = major
        self.minor = minor
    }
}

