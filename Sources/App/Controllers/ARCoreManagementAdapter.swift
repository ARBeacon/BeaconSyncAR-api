//
//  ARCoreManagementAdapter.swift
//  BeaconSyncAR-api
//
//  Created by Maitree Hirunteeyakul on 11/3/24.
//
import Vapor

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class ARCoreManagementAdapter: @unchecked Sendable {
    
    private static func getARCoreManagementAPIToken() async throws -> String {
        let url = URL(string: Environment.get("ARCORE_API_OAUTH2_GENERATOR_URL")!)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return String(decoding: data, as: UTF8.self)
    }
    
    private static func getAnchorDetails(cloudId: String, token: String) async throws -> [String: Any] {
        let url = URL(string: "https://arcore.googleapis.com/v1beta2/management/anchors/\(cloudId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }
        
        return jsonObject
    }
    
    private static func updateAnchorExpireTime(cloudId: String, token: String, newExpireTime: String) async throws {
        let url = URL(string: "https://arcore.googleapis.com/v1beta2/management/anchors/\(cloudId)?updateMask=expire_time")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["expireTime": newExpireTime]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
    }
    
    public static func maximizeCloudAnchorTTL(_ cloudId: String) async throws -> Date {
        let token = try await getARCoreManagementAPIToken()
        
        // Retrieve the current anchor details
        let anchorDetails = try await getAnchorDetails(cloudId: cloudId, token: token)
        
        // Get the maximumExpireTime
        guard let maximumExpireTime = anchorDetails["maximumExpireTime"] as? String else {
            throw URLError(.cannotParseResponse)
        }
        
        // Update the expireTime to maximumExpireTime
        try await updateAnchorExpireTime(cloudId: cloudId, token: token, newExpireTime: maximumExpireTime)
        
        let formatter = ISO8601DateFormatter()
        guard let expireDate = formatter.date(from: maximumExpireTime) else {
            throw URLError(.cannotParseResponse)
        }
        return expireDate
    }
}
