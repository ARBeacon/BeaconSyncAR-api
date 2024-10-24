import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works normally!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }
    
    app.get("ibeacons") { req async throws in
        try await IBeacon.query(on: req.db).all()
    }
    
    app.post("ibeacon") { req async throws -> IBeacon in
        let iBeacon = try req.content.decode(IBeacon.self)
        try await iBeacon.create(on: req.db)
        return iBeacon
    }

}
