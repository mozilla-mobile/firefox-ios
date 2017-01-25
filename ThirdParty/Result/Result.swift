//
//  Result.swift
//  Result
//
//  Created by John Gallagher on 9/12/14.
//  Copyright (c) 2014 Big Nerd Ranch. All rights reserved.
//

import Foundation
//import Box

public enum Maybe<T> {
    case failure(MaybeErrorType)

    // TODO: Get rid of Box hack at some point after 6.3
    case success(Box<T>)

    public init(failure: MaybeErrorType) {
        self = .failure(failure)
    }

    public init(success: T) {
        self = .success(Box(success))
    }

    public var successValue: T? {
        switch self {
        case let .success(success): return success.value
        case .failure: return nil
        }
    }

    public var failureValue: MaybeErrorType? {
        switch self {
        case .success: return nil
        case let .failure(error): return error
        }
    }

    public var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }

    public var isFailure: Bool {
        switch self {
        case .success: return false
        case .failure: return true
        }
    }

    public func map<U>(_ f: (T) -> U) -> Maybe<U> {
        switch self {
        case let .failure(error): return .failure(error)
        case let .success(value): return .success(Box(f(value.value)))
        }
    }

    public func bind<U>(_ f: (T) -> Maybe<U>) -> Maybe<U> {
        switch self {
        case let .failure(error): return .failure(error)
        case let .success(value): return f(value.value)
        }
    }
}

extension Maybe: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .failure(error): return "Result.Failure(\(error))"
        case let .success(value): return "Result.Success(\(value.value))"
        }
    }
}
