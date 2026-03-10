//
//  DataViewModel.swift
//  NetworkManagerDemo
//
//  Created by Weerawut on 10/3/2569 BE.
//

import SwiftUI

@Observable
class DataViewModel<T: Decodable> {
    var data: T?
    var networkError: NetworkError? = nil
    var isLoading: Bool = false
    private let networkManager = NetworkManager.shared
    
    private let configureDecoder: ((JSONDecoder) -> Void)?
    
    let urlString: String
    
    init(urlString: String, configureDecoder: ((JSONDecoder) -> Void)? = nil) {
        self.urlString = urlString
        self.configureDecoder = configureDecoder
    }
    
    func fetchData() async {
        isLoading = true
        networkError = nil
        defer { isLoading = false }
        #if DEBUG
        try? await Task.sleep(for: .seconds(1))
        #endif
        do {
            data = try await networkManager.fetchAndDecodeJSON(from: urlString, configureDecoder: configureDecoder)
        } catch let error {
            networkError = error
        }
    }
}

struct Loader: ViewModifier {
    let isLoading: Bool
    let title: String
    
    func body(content: Content) -> some View {
        if isLoading {
            ProgressView("Loading \(title)...")
        } else {
            content
        }
    }
}

extension View {
    func withLoader(isLoading: Bool, title: String) -> some View {
        modifier(Loader(isLoading: isLoading, title: title))
    }
}
