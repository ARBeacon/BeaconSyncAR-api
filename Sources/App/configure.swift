import Vapor
import Fluent
import FluentPostgresDriver

// configures your application
public func configure(_ app: Application) async throws {
    
    // Load the SSL certificate
    let certificatePath = app.directory.resourcesDirectory + "ca-certificate.crt"
    let certificate = try NIOSSLCertificate(file: certificatePath, format: .pem)
    
    // Create an SSL context configuration
    var sslContextConfig = TLSConfiguration.makeClientConfiguration()
    sslContextConfig.certificateVerification = .fullVerification
    sslContextConfig.trustRoots = .certificates([certificate])
    
    // Create SSL context
    let sslContext = try NIOSSLContext(configuration: sslContextConfig)
    
    app.databases.use(
        .postgres(
            configuration: .init(
                hostname: Environment.get("PG_DB_HOSTNAME")!,
                port: Int(Environment.get("PG_DB_PORT")!) ?? 25060,
                username: Environment.get("PG_DB_USERNAME")!,
                password: Environment.get("PG_DB_PASSWORD")!,
                database: Environment.get("PG_DB_DATABASE")!,
                tls: .require(sslContext)
            )
        ),
        as: .psql
    )
    
    app.migrations.add(CreateGalaxy())
    
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    // register routes
    try routes(app)
}
