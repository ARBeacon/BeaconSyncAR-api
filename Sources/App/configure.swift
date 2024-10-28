//
//  configure.swift
//  BeaconSyncAR-api
//
//  Created by Maitree Hirunteeyakul on 10/24/24.
//
import Vapor
import Fluent
import FluentPostgresDriver
import SotoS3

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
    
    app.migrations.add(CreateIBeacon())
    app.migrations.add(CreateRoom())
    app.migrations.add(AddIBeaconAddRoomAssociation())
    app.migrations.add(AddCreateAtUpdateAtDeleteAtForIBeacon())
    app.migrations.add(AddCreateAtUpdateAtDeleteAtForRoom())
    app.migrations.add(MakeCreateAtUpdateAtRequiredForIBeacon())
    app.migrations.add(MakeCreateAtUpdateAtRequiredForRoom())
    app.migrations.add(CreateARWorldMap())
    app.migrations.add(CreateCloudAnchor())
    
    app.aws.client = AWSClient(
        credentialProvider:
                .static(
                    accessKeyId: Environment.get("AWS_S3_ACCESS_KEY_ID")!,
                    secretAccessKey: Environment.get("AWS_S3_SECRETE_ACCESS_KEY")!
                ),
        httpClientProvider: .shared(app.http.client.shared))
    
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    // register routes
    try routes(app)
}
