// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import XCTest
import ModifiedCopy
import Redux
import Common

@testable import Client

/// These are technically integration tests and shouldn't be needed, but since we had integration issues with a different
/// macro in the past, these seem like a reasonable thing to include now.
@MainActor
final class ModifiedCopyMacroTests: XCTestCase {
    func testMacroIntegration_settingNonOptionalProperties() {
        let testWindowUUID = UUID()
        let testFirstName = "Haley"
        let testLastName = "Emmett"
        let testAge = 25
        let testFavoriteColor: String? = nil

        let state = PersonReduxState(
            windowUUID: testWindowUUID,
            firstName: testFirstName,
            lastName: testLastName,
            age: testAge,
            favoriteColor: testFavoriteColor
        )

        let action = PersonReduxAction(
            windowUUID: testWindowUUID,
            actionType: PersonReduxActionType.didSetName,
            firstName: "Bob",
            lastName: "Jones"
        )

        let newState = PersonReduxState.reducer(state, action)

        XCTAssertEqual(newState.windowUUID, testWindowUUID)
        XCTAssertEqual(newState.firstName, "Bob")
        XCTAssertEqual(newState.lastName, "Jones")
        XCTAssertEqual(newState.age, testAge)
        XCTAssertEqual(newState.favoriteColor, testFavoriteColor)
    }

    func testMacroIntegration_settingOptionalNilProperties_toValue() {
        let testWindowUUID = UUID()
        let testFirstName = "Haley"
        let testLastName = "Emmett"
        let testAge = 25
        let testFavoriteColor: String? = nil

        let state = PersonReduxState(
            windowUUID: testWindowUUID,
            firstName: testFirstName,
            lastName: testLastName,
            age: testAge,
            favoriteColor: testFavoriteColor
        )

        let action = PersonReduxAction(
            windowUUID: testWindowUUID,
            actionType: PersonReduxActionType.didSetFavoriteColor,
            favoriteColor: "green"
        )

        let newState = PersonReduxState.reducer(state, action)

        XCTAssertEqual(newState.windowUUID, testWindowUUID)
        XCTAssertEqual(newState.firstName, testFirstName)
        XCTAssertEqual(newState.lastName, testLastName)
        XCTAssertEqual(newState.age, testAge)
        XCTAssertEqual(newState.favoriteColor, "green")
    }

    func testMacroIntegration_settingOptionalValueProperties_toNil() {
        let testWindowUUID = UUID()
        let testFirstName = "Haley"
        let testLastName = "Emmett"
        let testAge = 25
        let testFavoriteColor: String? = "green"

        let state = PersonReduxState(
            windowUUID: testWindowUUID,
            firstName: testFirstName,
            lastName: testLastName,
            age: testAge,
            favoriteColor: testFavoriteColor
        )

        let action = PersonReduxAction(
            windowUUID: testWindowUUID,
            actionType: PersonReduxActionType.didSetFavoriteColor,
            favoriteColor: nil
        )

        let newState = PersonReduxState.reducer(state, action)

        XCTAssertEqual(newState.windowUUID, testWindowUUID)
        XCTAssertEqual(newState.firstName, testFirstName)
        XCTAssertEqual(newState.lastName, testLastName)
        XCTAssertEqual(newState.age, testAge)
        XCTAssertEqual(newState.favoriteColor, nil)
    }
}

// MARK: Fileprivate mock Redux state type and associated update actions for `@Copyable` macro integration tests.
fileprivate extension ModifiedCopyMacroTests {
    // Fake Redux state reducer under test
    @Copyable
    struct PersonReduxState: ScreenState {
        var windowUUID: WindowUUID

        let firstName: String
        let lastName: String
        let age: Int
        var favoriteColor: String?

        static let genus = "Homo Sapien"

        var fullName: String {
            "\(firstName) \(lastName)"
        }

        init(appState: AppState, uuid: WindowUUID) {
            self.init(windowUUID: UUID())
        }

        init(windowUUID: WindowUUID) {
            self.init(
                windowUUID: windowUUID,
                firstName: "Jane",
                lastName: "Doe",
                age: 33,
                favoriteColor: nil
            )
        }

        init(
            windowUUID: WindowUUID,
            firstName: String,
            lastName: String,
            age: Int,
            favoriteColor: String?
        ) {
            self.windowUUID = windowUUID
            self.firstName = firstName
            self.lastName = lastName
            self.age = age
            self.favoriteColor = favoriteColor
        }

        static let reducer: Reducer<Self> = { state, action in
            // Handles only PersonReduxActions
            guard let action = action as? PersonReduxAction,
                  let actionType = action.actionType as? PersonReduxActionType else {
                return defaultState(from: state)
            }

            switch actionType {
            case .didSetName:
                guard let firstName = action.firstName,
                      let lastName = action.lastName
                else {
                    return defaultState(from: state)
                }

                return state
                    .copy(firstName: firstName)
                    .copy(lastName: lastName)

            case .didSetFavoriteColor:
                return state
                    .copy(favoriteColor: action.favoriteColor)
            }
        }

        static func defaultState(from state: PersonReduxState) -> PersonReduxState {
            return PersonReduxState(
                windowUUID: state.windowUUID,
                firstName: state.firstName,
                lastName: state.lastName,
                age: state.age,
                favoriteColor: state.favoriteColor
            )
        }
    }

    // Test actions
    enum PersonReduxActionType: ActionType {
        case didSetName
        case didSetFavoriteColor
    }

    // Test action payload
    struct PersonReduxAction: Action {
        let windowUUID: WindowUUID
        let actionType: ActionType

        let firstName: String?
        let lastName: String?
        let age: Int?
        let favoriteColor: String?

        init(
            windowUUID: WindowUUID,
            actionType: ActionType,
            firstName: String? = nil,
            lastName: String? = nil,
            age: Int? = nil,
            favoriteColor: String? = nil
        ) {
            self.windowUUID = windowUUID
            self.actionType = actionType
            self.firstName = firstName
            self.lastName = lastName
            self.age = age
            self.favoriteColor = favoriteColor
        }
    }
}
