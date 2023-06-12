// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct Thunk<State>: Action {
    let body: (_ dispatch: @escaping DispatchFunction,
               _ getState: @escaping () -> State?) -> Void

    public init(body: @escaping (_ dispatch: @escaping DispatchFunction,
                                 _ getState: @escaping () -> State?) -> Void) {
        self.body = body
    }

    public func createThunkMiddleware<State>() -> Middleware<State> {
        return { dispatch, getState in
            return { next in
                return { action in
                    switch action {
                    case let thunk as Thunk<State>:
                        thunk.body(dispatch, getState)
                    default:
                        next(action)
                    }
                }
            }
        }
    }
}


