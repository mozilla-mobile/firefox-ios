//
//  File.swift
//  
//
//  Created by Orla Mitchell on 2022-11-22.
//

import Foundation

enum URLError: Error {
    case invalidHTML
    case noFaviconFound

    var description: String {
        switch self {
        case .invalidHTML: return "No HTML data is invalid"
        case .noFaviconFound: return "Could not find a favicon url"
        }
    }
}
