// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Redux

@MainActor
class FakeReduxMiddleware {
    var generateInitialCountValue: (() -> Int)?

    lazy var fakeProvider: Middleware<FakeReduxState> = (legacyFakeProvider, modernFakeProvider)

    lazy var modernFakeProvider: MiddlewareMethod<FakeReduxState> = { [self] state, action, windowUUID in
        // Handles one type of action
        guard let action = action as? FakeReduxModernAction else { return }

        switch action {
        case .requestInitialValue:
            let initialValue = self.generateInitialCountValue?() ?? 0
            store.dispatch(
                FakeReduxModernAction.initialValueLoaded(initialValue: initialValue),
                forWindowUUID: windowUUID
            )

        case .increaseCounter:
            let existingValue = state.counter
            let newValue = self.increaseCounter(currentValue: existingValue)
            store.dispatch(
                FakeReduxModernAction.counterIncreased(counterValue: newValue),
                forWindowUUID: windowUUID
            )

        case .decreaseCounter:
            let existingValue = state.counter
            let newValue = self.decreaseCounter(currentValue: existingValue)
            store.dispatch(
                FakeReduxModernAction.counterDecreased(counterValue: newValue),
                forWindowUUID: windowUUID
            )

        default:
            break
        }
    }

    lazy var legacyFakeProvider: LegacyMiddlewareMethod<FakeReduxState> = { [self] state, action in
        // Handles one type of action
        guard let actionType = action.actionType as? FakeReduxActionType else { return }

        switch actionType {
        case .requestInitialValue:
            let initialValue = self.generateInitialCountValue?() ?? 0
            let action = FakeReduxAction(counterValue: initialValue,
                                         windowUUID: windowUUID,
                                         actionType: FakeReduxActionType.initialValueLoaded)
            store.dispatch(action)

        case .increaseCounter:
            let existingValue = state.counter
            let newValue = self.increaseCounter(currentValue: existingValue)
            let action = FakeReduxAction(counterValue: newValue,
                                         windowUUID: windowUUID,
                                         actionType: FakeReduxActionType.counterIncreased)
            store.dispatch(action)

        case .decreaseCounter:
            let existingValue = state.counter
            let newValue = self.decreaseCounter(currentValue: existingValue)
            let action = FakeReduxAction(counterValue: newValue,
                                         windowUUID: windowUUID,
                                         actionType: FakeReduxActionType.counterDecreased)
            store.dispatch(action)

        default:
           break
        }
    }

    private func increaseCounter(currentValue: Int) -> Int {
        return currentValue + 1
    }

    private func decreaseCounter(currentValue: Int) -> Int {
        return currentValue - 1
    }
}
