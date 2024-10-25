//
//  S3Adapter.swift
//  BeaconSyncAR-api
//
//  Created by Maitree Hirunteeyakul on 10/26/24.
//

import Vapor
import SotoS3

final class S3Adapter: @unchecked Sendable {
    
    enum S3Bucket {
        case fyp_bucket
        
        var baseURL: URL {
            switch self {
            case .fyp_bucket:
                return URL(string: Environment.get("AWS_S3_FYP_BUCKET_URL")!)!
            }
        }
    }
    
    private let s3Client: S3
    private let bucketBaseURL: URL
    
    init(awsClient: AWSClient, region: Region, bucket: S3Bucket) {
        self.s3Client = S3(client: awsClient, region: region)
        self.bucketBaseURL = bucket.baseURL
    }
    
    deinit {
        try? self.s3Client.client.syncShutdown()
    }
    
    private func generateURL(filePath: String, httpMethod: HTTPMethod, expiration: TimeAmount) async throws -> URL {
        let url = bucketBaseURL.appendingPathComponent(filePath)
        return try await s3Client.signURL(url: url, httpMethod: httpMethod, expires: expiration)
    }
    
    func generateUploadURL(filePath: String, expiration: TimeAmount) async throws -> URL {
        return try await generateURL(filePath: filePath, httpMethod: .PUT, expiration: expiration)
    }
    
    func generateDownloadURL(filePath: String, expiration: TimeAmount) async throws -> URL {
        return try await generateURL(filePath: filePath, httpMethod: .GET, expiration: expiration)
    }
}

public extension Application {
    var aws: AWS {
        .init(application: self)
    }

    struct AWS {
        struct ClientKey: StorageKey {
            typealias Value = AWSClient
        }

        public var client: AWSClient {
            get {
                guard let client = self.application.storage[ClientKey.self] else {
                    fatalError("AWSClient not setup. Use application.aws.client = ...")
                }
                return client
            }
            nonmutating set {
                self.application.storage.set(ClientKey.self, to: newValue) {
                    try $0.syncShutdown()
                }
            }
        }

        let application: Application
    }
}

public extension Request {
    var aws: AWS {
        .init(request: self)
    }

    struct AWS {
        var client: AWSClient {
            return request.application.aws.client
        }

        let request: Request
    }
}
