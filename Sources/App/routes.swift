//
//  routes.swift
//  BeaconSyncAR-api
//
//  Created by Maitree Hirunteeyakul on 10/24/24.
//
import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }
    
    app.get("ibeacon", "list") { req async throws in
        try await IBeacon.query(on: req.db).all()
    }
    
    app.post("ibeacon", "new") { req async throws -> IBeacon in
        let iBeacon = try req.content.decode(IBeacon.self)
        try await iBeacon.create(on: req.db)
        return iBeacon
    }
    
    struct IBeaconAttachRoomRequestParams: Content {
        let iBeaconData: IBeaconData
        let roomId: UUID
    }
    
    app.patch("ibeacon", "attachRoom") { req async throws -> IBeacon in
        let params = try req.content.decode(IBeaconAttachRoomRequestParams.self)
        guard let iBeacon = try await IBeacon.getOneBeacon(iBeaconData: params.iBeaconData, on: req.db) else {
            throw Abort(.badRequest, reason: "iBeacon is not registered.")
        }
        
        if iBeacon.$room.id != nil {
            throw Abort(.conflict, reason: "iBeacon is already attached to a room.")
        }
        
        guard let room = try await Room.find(params.roomId, on: req.db) else {
            throw Abort(.badRequest, reason: "Room not found.")
        }
        
        iBeacon.$room.id = room.id
        try await iBeacon.update(on: req.db)
        return iBeacon
    }
    
    app.delete("ibeacon", "detachRoom") { req async throws -> IBeacon in
        let iBeaconData = try req.content.decode(IBeaconData.self)
        
        guard let iBeacon = try await IBeacon.getOneBeacon(iBeaconData: iBeaconData, on: req.db) else {
            throw Abort(.badRequest, reason: "iBeacon is not registered.")
        }
        
        guard iBeacon.$room.id != nil else {
            throw Abort(.badRequest, reason: "No room is currently associated with this iBeacon.")
        }
        
        iBeacon.$room.id = nil
        try await iBeacon.update(on: req.db)
        return iBeacon
    }
    
    struct RoomResponse: Content {
        let id: UUID?
        let name: String
        let iBeaconCount: Int
    }
    
    app.get("room", "list") { req async throws -> [RoomResponse] in
        let rooms = try await Room.query(on: req.db).all()
        var roomResponses: [RoomResponse] = []
        
        for room in rooms {
            let iBeaconCount = try await room.countIBeacons(on: req.db).get()
            let response = RoomResponse(id: room.id, name: room.name, iBeaconCount: iBeaconCount)
            roomResponses.append(response)
        }
        
        return roomResponses
    }
    
    app.get("room", ":roomID") { req async throws -> Room in
        guard let roomId = req.parameters.get("roomID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid room ID")
        }
        guard let room = try await Room.getRoomFromIdWithIBeacons(on: req.db, id: roomId) else {
            throw Abort(.badRequest, reason: "Room not found")
        }
        
        return room
    }
    
    app.delete("room", ":roomID") { req async throws in
        guard let roomId = req.parameters.get("roomID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid room ID")
        }
        
        guard let room = try await Room.getRoomFromIdWithIBeacons(on: req.db, id: roomId) else {
            throw Abort(.notFound, reason: "Room not found")
        }
        
        let iBeaconCount = try await room.countIBeacons(on: req.db).get()
        
        if iBeaconCount > 0 {
            throw Abort(.conflict, reason: "Room cannot be deleted because it has associated iBeacons")
        }
        
        try await room.delete(on: req.db)
        return HTTPStatus.ok
    }
    
    app.post("room", "new") { req async throws -> Room in
        let room = try req.content.decode(Room.self)
        try await room.create(on: req.db)
        return room
    }
    
    app.put("room", ":roomID", "name") { req async throws -> Room in
        guard let roomId = req.parameters.get("roomID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid room ID")
        }
        guard let room = try await Room.getRoomFromIdWithIBeacons(on: req.db, id: roomId) else {
            throw Abort(.badRequest, reason: "Room not found")
        }
        
        guard let newName = req.body.string, newName != "" else {
            throw Abort(.badRequest, reason: "Invalid name")
        }
        
        room.name = newName
        try await room.update(on: req.db)
        return room
    }
    
}
