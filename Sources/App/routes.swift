//
//  routes.swift
//  BeaconSyncAR-api
//
//  Created by Maitree Hirunteeyakul on 10/24/24.
//
import Vapor

func routes(_ app: Application) throws {
    
    let s3Adapter = S3Adapter(awsClient: app.aws.client, region: .apsoutheast1, bucket: .fyp_bucket)
    
    app.get { req async in
        "It works!"
    }
    
    app.get("ibeacon", "list") { req async throws in
        try await IBeacon.query(on: req.db).all()
    }
    
    app.post("ibeacon", "new") { req async throws -> IBeacon in
        let iBeaconData = try req.content.decode(IBeaconData.self)
        let iBeacon = IBeacon(uuid: iBeaconData.uuid, major: iBeaconData.major, minor: iBeaconData.minor)
        try await iBeacon.create(on: req.db)
        return iBeacon
    }
    
    app.delete("ibeacon") { req async throws in
        let iBeaconData = try req.content.decode(IBeaconData.self)
        guard let iBeacon = try await IBeacon.getOneBeacon(iBeaconData: iBeaconData, on: req.db) else {
            throw Abort(.badRequest, reason: "iBeacon not found.")
        }
        try await iBeacon.delete(on: req.db)
        return HTTPStatus.ok
    }
    
    struct IBeaconAttachRoomRequestParams: Content {
        let iBeaconData: IBeaconData
        let roomId: UUID
    }
    
    app.post("ibeacon", "attachRoom") { req async throws -> IBeacon in
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
    
    app.post("ibeacon", "detachRoom") { req async throws -> IBeacon in
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
    
    app.post("ibeacon", "getRoom"){ req async throws -> Room in
        let iBeaconData = try req.content.decode(IBeaconData.self)
        
        guard let iBeacon = try await IBeacon.getOneBeacon(iBeaconData: iBeaconData, on: req.db) else {
            throw Abort(.badRequest, reason: "iBeacon is not registered.")
        }
        
        guard let roomId = iBeacon.$room.id else {
            throw Abort(.badRequest, reason: "No room is currently associated with this iBeacon.")
        }
        
        guard let room = try await Room.getRoomFromId(on: req.db, id: roomId) else {
            throw Abort(.badRequest, reason: "Room not found")
        }
        
        return room
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
            let iBeaconCount = try await room.countIBeacons(on: req.db)
            let response = RoomResponse(id: room.id, name: room.name, iBeaconCount: iBeaconCount)
            roomResponses.append(response)
        }
        
        return roomResponses
    }
    
    app.get("room", ":roomID") { req async throws -> Room in
        guard let roomId = req.parameters.get("roomID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid room ID")
        }
        guard let room = try await Room.getRoomFromId(on: req.db, id: roomId) else {
            throw Abort(.badRequest, reason: "Room not found")
        }
        
        return room
    }
    
    app.delete("room", ":roomID") { req async throws in
        guard let roomId = req.parameters.get("roomID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid room ID")
        }
        
        guard let room = try await Room.getRoomFromId(on: req.db, id: roomId) else {
            throw Abort(.notFound, reason: "Room not found")
        }
        
        if try await room.countIBeacons(on: req.db) > 0 {
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
        guard let room = try await Room.getRoomFromId(on: req.db, id: roomId) else {
            throw Abort(.badRequest, reason: "Room not found")
        }
        
        guard let newName = req.body.string, newName != "" else {
            throw Abort(.badRequest, reason: "Invalid name")
        }
        
        room.name = newName
        try await room.update(on: req.db)
        return room
    }
    
    app.get("room", ":roomID", "ARWorldMap", "getPresignedUploadUrl"){req async throws in
        guard let roomId = req.parameters.get("roomID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid room ID")
        }
        guard let _ = try await Room.getRoomFromId(on: req.db, id: roomId) else {
            throw Abort(.badRequest, reason: "Room not found")
        }
        
        let uuid = UUID().uuidString
        let url = try await s3Adapter.generateUploadURL(filePath: "/ar-world-maps/\(uuid).worldmap", expiration: .minutes(15))
        let responseBody = [
            "url": url.absoluteString,
            "fileName": uuid
        ]
        
        let response = Response(status: .ok)
        try response.content.encode(responseBody, as: .json)
        return response
    }
    
    struct ARWorldMapPresignedUploadConfirmationRequestParams: Content {
        let fileName: String
        let old_uuid: UUID?
    }
    
    app.post("room", ":roomID", "ARWorldMap", "presignedUploadConfirmation"){req async throws -> ARWorldMap in
        let params = try req.content.decode(ARWorldMapPresignedUploadConfirmationRequestParams.self)
        let fileName = params.fileName
        let old_UUID = params.old_uuid
        
        guard let roomId = req.parameters.get("roomID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid room ID")
        }
        guard let room = try await Room.getRoomFromId(on: req.db, id: roomId) else {
            throw Abort(.badRequest, reason: "Room not found")
        }
        
        guard let oldARWorldMap = room.arWorldMap else {
            if old_UUID != nil {
                throw Abort(.conflict, reason: "Room don't have an associated ARWorldMap, Only new ARWorldMap can be submitted")
            }
            
            let arWorldMap = ARWorldMap(fileName: fileName, roomID: roomId)
            try await arWorldMap.create(on: req.db)
            return arWorldMap
        }
        
        guard let declaredOldUUID = old_UUID else {
            throw Abort(.conflict, reason: "Room already has an associated ARWorldMap, Only inhereted on latest ARWorldMap can be submitted")
        }
        if oldARWorldMap.id! != declaredOldUUID {
            throw Abort(.conflict, reason: "The previous latest ARWorldMap for this room is not the one you are trying to reference")
        }
        
        let arWorldMap = ARWorldMap(fileName: fileName, roomID: roomId, derivedFrom: oldARWorldMap.id)
        try await oldARWorldMap.delete(force: false, on: req.db)
        try await arWorldMap.create(on: req.db)
        return arWorldMap
    }
    
    struct ARWorldMapUploadRequestParams: Content {
        let prev_uuid: UUID?
        let dataBase64Encoded: String
    }
    
    app.on(.POST,"room", ":roomID", "ARWorldMap", "upload", body: .collect(maxSize: "1gb")) { req async throws -> ARWorldMap in
        let params = try req.content.decode(ARWorldMapUploadRequestParams.self)
        let prevUUID = params.prev_uuid
        
        guard let roomId = req.parameters.get("roomID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid room ID")
        }
        guard let room = try await Room.getRoomFromId(on: req.db, id: roomId) else {
            throw Abort(.badRequest, reason: "Room not found")
        }
        
        let fileName = UUID().uuidString
        let filePath = "/ar-world-maps/\(fileName).worldmap"
        guard let data = Data(base64Encoded: params.dataBase64Encoded) else {
            throw Abort(.badRequest, reason: "dataBase64Encoded cannot be decoded")
        }
        try await s3Adapter.upload(data: data, to: filePath)
        
        guard let oldARWorldMap = room.arWorldMap else {
            if prevUUID != nil {
                throw Abort(.conflict, reason: "Room don't have an associated ARWorldMap, Only new ARWorldMap can be submitted")
            }
            
            let arWorldMap = ARWorldMap(fileName: fileName, roomID: roomId)
            try await arWorldMap.create(on: req.db)
            return arWorldMap
        }
        
        guard let declaredPrevUUID = prevUUID else {
            throw Abort(.conflict, reason: "Room already has an associated ARWorldMap, Only inhereted on latest ARWorldMap can be submitted")
        }
        if oldARWorldMap.id! != declaredPrevUUID {
            throw Abort(.conflict, reason: "The previous latest ARWorldMap for this room is not match your reference.")
        }
        
        let arWorldMap = ARWorldMap(fileName: fileName, roomID: roomId, derivedFrom: oldARWorldMap.id)
        try await oldARWorldMap.delete(force: false, on: req.db)
        try await arWorldMap.create(on: req.db)
        return arWorldMap
    }
    
    app.get("room", ":roomID", "ARWorldMap"){req async throws in
        guard let roomId = req.parameters.get("roomID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid room ID")
        }
        guard let room = try await Room.getRoomFromId(on: req.db, id: roomId) else {
            throw Abort(.badRequest, reason: "Room not found")
        }
        
        guard let arWorldMap = room.arWorldMap else {
            throw Abort(.conflict, reason: "This Room don't have an associated ARWorldMap yet")
        }
        
        let filePath = "/ar-world-maps/\(arWorldMap.fileName).worldmap"
        let data = try await s3Adapter.download(from: filePath)
        let responseBody = [
            "dataBase64Encoded": data.base64EncodedString(),
            "uuid": arWorldMap.id!.uuidString
        ]
        
        let response = Response(status: .ok)
        try response.content.encode(responseBody, as: .json)
        return response
    }
    
    app.get("room", ":roomID", "ARWorldMap", "getPresignedDownloadUrl"){req async throws in
        guard let roomId = req.parameters.get("roomID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid room ID")
        }
        guard let room = try await Room.getRoomFromId(on: req.db, id: roomId) else {
            throw Abort(.badRequest, reason: "Room not found")
        }
        
        guard let arWorldMap = room.arWorldMap else {
            throw Abort(.conflict, reason: "This Room don't have an associated ARWorldMap yet")
        }
        
        let filePath = "/ar-world-maps/\(arWorldMap.fileName).worldmap"
        let url = try await s3Adapter.generateDownloadURL(filePath: filePath, expiration: .minutes(15))
        let responseBody = [
            "url": url.absoluteString,
            "uuid": arWorldMap.id!.uuidString
        ]
        
        let response = Response(status: .ok)
        try response.content.encode(responseBody, as: .json)
        return response
    }
    
    struct CloudAnchorNewRequestParams: Content {
        let anchorId: String
    }
    
    app.post("room", ":roomID", "CloudAnchor", "new"){req async throws -> CloudAnchor in
        let params = try req.content.decode(CloudAnchorNewRequestParams.self)
        let anchorId = params.anchorId
        
        guard let roomId = req.parameters.get("roomID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid room ID")
        }
        guard let _ = try await Room.getRoomFromId(on: req.db, id: roomId) else {
            throw Abort(.badRequest, reason: "Room not found")
        }
        
        let expireDate = try await ARCoreManagementAdapter.maximizeCloudAnchorTTL(anchorId)
        
        let cloudAnchor = CloudAnchor(anchorId: anchorId, roomID: roomId, expireAt: expireDate)
        try await cloudAnchor.create(on: req.db)
        return cloudAnchor
    }
    
    app.get("room", ":roomID", "CloudAnchor", "list"){req async throws -> [CloudAnchor] in
        guard let roomId = req.parameters.get("roomID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid room ID")
        }
        guard let room = try await Room.getRoomFromId(on: req.db, id: roomId) else {
            throw Abort(.badRequest, reason: "Room not found")
        }
        
        return try await room.getAliveCloudAnchors(on: req.db)
    }
    
    app.delete("room", ":roomID", "CloudAnchor", ":anchorId"){req async throws in
        guard let roomId = req.parameters.get("roomID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid room ID")
        }
        guard let _ = try await Room.getRoomFromId(on: req.db, id: roomId) else {
            throw Abort(.badRequest, reason: "Room not found")
        }
        
        guard let anchorId = req.parameters.get("anchorId", as: String.self)else {
            throw Abort(.badRequest, reason: "anchorId are not provided")
        }
        
        try await CloudAnchor.deleteOnMatch(anchorId: anchorId, roomId: roomId, on: req.db)
        
        return HTTPStatus.ok
    }
    
}
