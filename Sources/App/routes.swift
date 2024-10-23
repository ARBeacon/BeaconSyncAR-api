import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works normally!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }
    
    app.get("planet") { req async throws in
        try await Planet.query(on: req.db).all()
    }
    
    app.post("planet") { req async throws -> Planet in
        let galaxy = try req.content.decode(Planet.self)
        try await galaxy.create(on: req.db)
        return galaxy
    }

}
