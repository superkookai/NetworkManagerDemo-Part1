//
//  NetworkManager.swift
//  NetworkManagerDemo
//
//  Created by Weerawut on 2/3/2569 BE.
//

import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    
    private init() { print("DEBUG: NetworkManager init") }
    
    func fetchAndDecodeJSON<T: Decodable>(from urlString: String, configureDecoder: ((JSONDecoder) -> Void)? = nil) async -> T? {
        guard let url = URL(string: urlString) else {
            print("DEBUG: URL error")
            return nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard
                let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode)
            else {
                print("DEBUG: Response error")
                return nil
            }
            
            do {
                let decoder = JSONDecoder()
                configureDecoder?(decoder)
                return try decoder.decode(T.self, from: data)
            } catch let error as DecodingError {
                print(decodingError(error: error))
                return nil
            } catch {
                print("DEBUG: Decoding error: \(error.localizedDescription)")
                print("Data as string: \(String(data: data, encoding: .utf8) ?? "Unable to convert data to string")")
                return nil
            }
        } catch {
            print("DEBUG: Request error: \(error.localizedDescription)")
            return nil
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
