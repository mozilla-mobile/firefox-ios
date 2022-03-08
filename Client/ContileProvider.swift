//// This Source Code Form is subject to the terms of the Mozilla Public
//// License, v. 2.0. If a copy of the MPL was not distributed with this
//// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol ContileProviderInterface {
    func fetchContiles(completion: @escaping (Result<[Contile], Error>) -> Void)
}

/// `Contile` is short for contexual tiles. This provider returns "special" metadata and objects for use in Shortcuts (Top Sites) section.
class ContileProvider: ContileProviderInterface, Loggable {
    private let contileResourceEndpoint = "https://contile.services.mozilla.com/v1/tiles"
    
    public func fetchContiles(completion: @escaping (Result<[Contile], Error>) -> Void) {
        guard let resourceEndpoint = URL(string: contileResourceEndpoint) else {
            browserLog.error("Contile Provider - the Contile resource URL is invalid!")
            completion(.failure(ContileProviderError.invalidResourceEndpoint("Contile Provider - malformed URL.")))
            return
        }
        
        fetchContilesMeta(resourceEndpoint: resourceEndpoint, completion: completion)
    }
    
    private func fetchContilesMeta(resourceEndpoint: URL, completion: @escaping (Result<[Contile], Error>) -> Void) {
        let fetchTask = URLSession.shared.dataTask(with: resourceEndpoint) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let _ = error {
                self.browserLog.debug("Contile Provider - an unknown error occurred during the data task.")
                completion(.failure(ContileProviderError.unknownError("An unknown error occurred in data task.")))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
                self.browserLog.debug("Contile Provider - we have a bad networking response.")
                    completion(.failure(ContileProviderError.invalidHttpResponse("A bad HTTPResponse with: \(response.debugDescription)")))
                return
            }
            guard let data = data else {
                self.browserLog.debug("Contile Provider - there was an error in the data creation part of the data task.")
                completion(.failure(error as! ContileProviderError))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let contiles: [Contile] = try decoder.decode([Contile].self, from: data)
                completion(.success(contiles))
            } catch let error {
                self.browserLog.error("Unable to parse.")
                completion(.failure(ContileProviderError.unableToParse(error.localizedDescription)))
            }
        }
        
        fetchTask.resume()
    }
    
}

/// Errors specifically related to Contiles.
public enum ContileProviderError: Error {
    case invalidResourceEndpoint(String)
    case invalidHttpResponse(String)
    case unableToParse(Error)
    case unknownError(String)
}
