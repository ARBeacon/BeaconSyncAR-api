# BeaconSyncAR API
A Swift Vapor backend service for the BLE & UWB Beacon-Assisted AR Synchronization project.

## 🚀 Development Setup

### Prerequisites
- Swift 6.0+
- Vapor 4.99.3+
- PostgreSQL (local or remote)
- S3-compatible storage (DigitalOcean Spaces, AWS S3, etc.)
- Running [BeaconSyncAR-namespace-functions](https://github.com/ARBeacon/BeaconSyncAR-namespace-functions) Service

### Local Development

1. Clone the repository:
```bash
git clone https://github.com/ARBeacon/BeaconSyncAR-api.git
cd BeaconSyncAR-api
```
2. Configure environment variables:
```bash
cp .env.example .env
```
Edit the .env file with your database and S3 credentials.
3. (Optional) If your PostgreSQL requires SSL, update the certificate:
```bash
nano Resources/ca-certificate.crt
```
4. Database Migrations
```bash
swift run App migrate
```
5. Run the server:
```bash
swift run
```
Or open the project in Xcode and click "Run".

## 🏗 Production Deployment
The service is Dockerized for easy deployment to any Docker-compatible hosting environment (e.g. DigitalOcean App Platform). The container includes all necessary dependencies and configurations.

## 📚 API Endpoints
The API provides endpoints for:
- Room and beacon management
- ARWorldMap storage and retrieval
- Cloud Anchor registration
- UWB anchor transformations

For detailed API documentation, refer to the [project's final report](https://github.com/ARBeacon/Docs/blob/main/Reports/Final%20Report.pdf) or examine the route definitions in `Sources/App/routes.swift`.

_Note: This README.md was refined with the assistance of [DeepSeek](https://www.deepseek.com)_
