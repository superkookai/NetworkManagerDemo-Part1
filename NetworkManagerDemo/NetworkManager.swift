//
//  NetworkManager.swift
//  NetworkManagerDemo
//
//  Created by Weerawut on 2/3/2569 BE.
//

import Foundation

enum NetworkError: Error {
    case badURL
    case transport(TransportError)
    case httpResponse
    case httpStatusCode(Int)
    case decoding
    
    var userMessage: String {
        switch self {
        case .transport(let transportError):
            transportError.userMessage
        case .httpStatusCode(let code):
            switch code {
            case 401: "Your session has expired.  Please sign in again."
            case 403: "You don't have permission to do that."
            case 404: "We coudn't find what you were looking for."
            case 429: "Too many requests.  Please wait a moment and try again."
            case 500...599: "The server is having trouble, please try again later."
            default: "Something went wrong.  Please try again"
            }
        default: "Something went wrong.  Please try again"
        }
    }
}

enum TransportError: Error {
    case offline, timedOut, dnsFailure, cannotConnect, cancelled, tlsFailure, unknown
    init(urlError: URLError) {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            self = .offline
        case .timedOut:
            self = .timedOut
        case .dnsLookupFailed, .cannotFindHost:
            self = .dnsFailure
        case .cannotConnectToHost:
            self = .cannotConnect
        case .cancelled:
            self = .cancelled
        case .secureConnectionFailed, .serverCertificateHasBadDate, .serverCertificateUntrusted, .serverCertificateHasUnknownRoot, .serverCertificateNotYetValid:
            self = .tlsFailure
        default:
            self = .unknown
        }
    }
    
    var userMessage: String {
        switch self {
        case .offline:
            "You appear to be offline. Check your internet connection and try again."
        case .timedOut:
            "The request timed out.  Try again."
        case .dnsFailure, .cannotConnect:
            "We can't reach the server right now.  Please try again later."
        case .cancelled:
            "The request was cancelled."
        case .tlsFailure:
            "A secure connection could not be established."
        case .unknown:
            "A network error occurred.  Please try again."
        }
    }
}

class NetworkManager {
    static let shared = NetworkManager()
    
    private init() { print("DEBUG: NetworkManager init") }
    
    func fetchAndDecodeJSON<T: Decodable>(from urlString: String, configureDecoder: ((JSONDecoder) -> Void)? = nil) async throws(NetworkError) -> T {
        guard let url = URL(string: urlString) else {
            print("DEBUG: URL error")
            throw NetworkError.badURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse
            else {
                print("DEBUG: Response error")
                throw NetworkError.httpResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("DEBUG: Reponse error with code: \(httpResponse.statusCode)")
                throw NetworkError.httpStatusCode(httpResponse.statusCode)
            }
            
            do {
                let decoder = JSONDecoder()
                configureDecoder?(decoder)
                return try decoder.decode(T.self, from: data)
            } catch let error as DecodingError {
                print(decodingError(error: error))
                throw NetworkError.decoding
            } catch {
                print("DEBUG: Decoding error: \(error.localizedDescription)")
                print("Data as string: \(String(data: data, encoding: .utf8) ?? "Unable to convert data to string")")
                throw NetworkError.decoding
            }
        } catch let networkError as NetworkError {
            throw networkError
        } catch let urlError as URLError {
            throw NetworkError.transport(TransportError(urlError: urlError))
        } catch {
            print("DEBUG: Request error: \(error.localizedDescription)")
            throw NetworkError.transport(TransportError(urlError: .init(.unknown)))
        }
    }
    
    func decodingError(error: DecodingError) -> String {
        switch error {
        case .typeMismatch(let type, let context):
            """
            Decoding error: Type mismatch for \(type)
            Context: \(context.debugDescription)
            Coding path: \(context.codingPath.map {$0.stringValue}.joined(separator: " -> "))
            """
        case .valueNotFound(let type, let context):
            """
            Decoding error: Value of \(type) not found
            Context: \(context.debugDescription)
            Coding path: \(context.codingPath.map {$0.stringValue}.joined(separator: " -> "))
            """
        case .keyNotFound(let codingKey, let context):
            """
            Decoding error: Key '\(codingKey.stringValue)' not found
            Context: \(context.debugDescription)
            Coding path: \(context.codingPath.map {$0.stringValue}.joined(separator: " -> "))
            """
        case .dataCorrupted(let context):
            """
            Decoding error: Data corrupted
            Context: \(context.debugDescription)
            Coding path: \(context.codingPath.map {$0.stringValue}.joined(separator: " -> "))
            """
        @unknown default:
            """
            Unknown error: \(error.localizedDescription)
            """
        }
    }
}
