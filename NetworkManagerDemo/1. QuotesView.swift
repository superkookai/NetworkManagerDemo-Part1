//z
//----------------------------------------------
// Original project: NetworkManagerDemo
//
// Follow me on Mastodon: https://iosdev.space/@StewartLynch
// Follow me on Threads: https://www.threads.net/@stewartlynch
// Follow me on Bluesky: https://bsky.app/profile/stewartlynch.bsky.social
// Follow me on X: https://x.com/StewartLynch
// Follow me on LinkedIn: https://linkedin.com/in/StewartLynch
// Email: slynch@createchsol.com
// Subscribe on YouTube: https://youTube.com/@StewartLynch
// Buy me a ko-fi:  https://ko-fi.com/StewartLynch
//----------------------------------------------
// Copyright © 2026 CreaTECH Solutions (Stewart Lynch). All rights reserved.

enum TestURL {
    static let quotesURL = "https://stewartlynch.github.io/Samples/quotes.json"
    static let quotesURLRequestError = "https://invalid.stewartlynch.github.io/Samples/quotes.json"
    static let quotesURLResponseError = "data:text/plain,hello"
    static let quotesURLStatusError = "https://httpbin.org/status/500"
    static let quotesURLBadJSON = "https://stewartlynch.github.io/Samples/errorQuotes.json"
    
    static let jokesURL = "https://stewartlynch.github.io/Samples/jokes.json"
    
    static let quotes2URL = "https://stewartlynch.github.io/Samples/quotes2.json"
}

struct Quote: Decodable, Identifiable {
    let id: Int
    let text: String
    let author: String
    let entryDate: Date
}

import SwiftUI

struct QuotesView: View {
    @State private var quotes: [Quote]? = nil
    let networkManager = NetworkManager.shared
    
    var body: some View {
        Group {
            if let quotes {
                List(quotes.shuffled()) { quote in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(quote.text)
                            .font(.headline)
                        HStack {
                            Text(quote.author)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(quote.entryDate, format: .dateTime.month().day().year())
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            } else {
                ContentUnavailableView("No Quotes available", systemImage: "quote.closing")
            }
        }
        .task {
//            quotes = await fetchAndDecodeQuotes(from: TestURL.quotesURLBadJSON)
            quotes = await networkManager.fetchAndDecodeJSON(from: TestURL.quotesURL)
        }
    }
    
    func fetchAndDecodeQuotes(from urlString: String) async -> [Quote]? {
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
                return try JSONDecoder().decode([Quote].self, from: data)
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

#Preview {
    NavigationStack {
        QuotesView()
            .navigationTitle(ViewOption.first.title)
            .toolbarTitleDisplayMode(.inlineLarge)
    }
}
