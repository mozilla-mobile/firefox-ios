// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Redux

final class ModernActionTests: XCTestCase {
    func testActionDescription_noAssociatedValue() {
        let action = FakeReduxModernAction.requestInitialValue
        let expectedDescription = "FakeReduxModernAction.requestInitialValue"

        XCTAssertEqual(action.description, expectedDescription)
    }

    func testActionDescription_withLabelledAssociatedValue() {
        let testValue = 3
        let action = FakeReduxModernAction.initialValueLoaded(initialValue: testValue)
        let expectedDescription = """
        FakeReduxModernAction.initialValueLoaded {
           initialValue: \(testValue)
        }
        """

        XCTAssertEqual(action.description, expectedDescription)
    }

    func testActionDescription_withLabelledAssociatedValueObject() {
        let testBool = true
        let testCount = 4
        let testOptional: Int? = .some(2)
        let testOptionalAsInterpolatedString = "\(String(describing: testOptional))"
        let testPayload = FakeComplicatedPayload(someBool: testBool, someCount: testCount, someOptionalCount: testOptional)
        let action = FakeReduxModernAction.complicatedActionLabelledPayload(labelled: testPayload)
        let expectedDescription = """
        FakeReduxModernAction.complicatedActionLabelledPayload {
           labelled: FakeComplicatedPayload(someBool: \(testBool), someCount: \(testCount), someOptionalCount: \(testOptionalAsInterpolatedString))
        }
        """.trimmingCharacters(in: .whitespaces) // Trim the newlines at the end due to the """ termination

        XCTAssertEqual(action.description, expectedDescription)
    }

    func testActionDescription_withUnlabelledAssociatedValueObject() {
        let testBool = true
        let testCount = 4
        let testOptional: Int? = .some(2)
        let testOptionalAsInterpolatedString = "\(String(describing: testOptional))"
        let testPayload = FakeComplicatedPayload(someBool: testBool, someCount: testCount, someOptionalCount: testOptional)
        let action = FakeReduxModernAction.complicatedActionUnlabelledPayload(testPayload)
        let expectedDescription = """
        FakeReduxModernAction.complicatedActionUnlabelledPayload {
           someBool: \(testBool),
           someCount: \(testCount),
           someOptionalCount: \(testOptionalAsInterpolatedString)
        }
        """.trimmingCharacters(in: .whitespaces) // Trim the newlines at the end due to the """ termination

        XCTAssertEqual(action.description, expectedDescription)
    }

    func testActionDescription_withMixedLabelledValue_UnlabelledObject() {
        let testBool = true
        let testCount = 4
        let testOptional: Int? = .some(2)
        let testOptionalAsInterpolatedString = "\(String(describing: testOptional))"
        let testPayload = FakeComplicatedPayload(someBool: testBool, someCount: testCount, someOptionalCount: testOptional)
        let action = FakeReduxModernAction.mixedLabelsPayload1(isPrivate: testBool, testPayload)
        // We should never have one labelled and one unlabelled property in our action's associated value payloads like this,
        // but if we do this is what we expect:
        let expectedDescription = """
        FakeReduxModernAction.mixedLabelsPayload1 {
           isPrivate: \(testBool),
           .1: FakeComplicatedPayload(someBool: \(testBool), someCount: \(testCount), someOptionalCount: \(testOptionalAsInterpolatedString))
        }
        """.trimmingCharacters(in: .whitespaces) // Trim the newlines at the end due to the """ termination

        XCTAssertEqual(action.description, expectedDescription)
    }

    func testActionDescription_withMixedUnlabelledValue_LabelledObject() {
        let testBool = true
        let testCount = 4
        let testOptional: Int? = .some(2)
        let testOptionalAsInterpolatedString = "\(String(describing: testOptional))"
        let testPayload = FakeComplicatedPayload(someBool: testBool, someCount: testCount, someOptionalCount: testOptional)
        let action = FakeReduxModernAction.mixedLabelsPayload2(testBool, complicatedPayload: testPayload)
        // We should never have one labelled and one unlabelled property in our action's associated value payloads like this,
        // but if we do this is what we expect:
        let expectedDescription = """
        FakeReduxModernAction.mixedLabelsPayload2 {
           .0: \(testBool),
           complicatedPayload: FakeComplicatedPayload(someBool: \(testBool), someCount: \(testCount), someOptionalCount: \(testOptionalAsInterpolatedString))
        }
        """.trimmingCharacters(in: .whitespaces) // Trim the newlines at the end due to the """ termination

        XCTAssertEqual(action.description, expectedDescription)
    }

    func testActionDescription_withMixedUnlabelledValue_UnlabelledObject() {
        let testBool = true
        let testCount = 4
        let testOptional: Int? = .some(2)
        let testOptionalAsInterpolatedString = "\(String(describing: testOptional))"
        let testPayload = FakeComplicatedPayload(someBool: testBool, someCount: testCount, someOptionalCount: testOptional)
        let action = FakeReduxModernAction.mixedLabelsPayload3(testBool, testPayload)
        // We should never have two unlabelled properties in our action's associated value payloads like this, but if we do
        // this is what we expect:
        let expectedDescription = """
        FakeReduxModernAction.mixedLabelsPayload3 {
           .0: \(testBool),
           .1: FakeComplicatedPayload(someBool: \(testBool), someCount: \(testCount), someOptionalCount: \(testOptionalAsInterpolatedString))
        }
        """.trimmingCharacters(in: .whitespaces) // Trim the newlines at the end due to the """ termination

        XCTAssertEqual(action.description, expectedDescription)
    }

    func testActionDescription_withMixedLabelledValue_LabelledObject() {
        let testBool = true
        let testCount = 4
        let testOptional: Int? = .some(2)
        let testOptionalAsInterpolatedString = "\(String(describing: testOptional))"
        let testPayload = FakeComplicatedPayload(someBool: testBool, someCount: testCount, someOptionalCount: testOptional)
        let action = FakeReduxModernAction.mixedLabelsPayload4(isPrivate: testBool, complicatedPayload: testPayload)
        let expectedDescription = """
        FakeReduxModernAction.mixedLabelsPayload4 {
           isPrivate: \(testBool),
           complicatedPayload: FakeComplicatedPayload(someBool: \(testBool), someCount: \(testCount), someOptionalCount: \(testOptionalAsInterpolatedString))
        }
        """.trimmingCharacters(in: .whitespaces) // Trim the newlines at the end due to the """ termination

        XCTAssertEqual(action.description, expectedDescription)
    }

    func testActionDescription_withNestedObjects() {
        let nestedObject1 = FakeComplicatedPayload(someBool: true, someCount: 1, someOptionalCount: 2)
        let nestedObject2 = Optional.some(FakeComplicatedPayload(someBool: false, someCount: 10, someOptionalCount: 9))
        let fakePayload = FakeNestedComplicatedPayload(
            someString: "TestString",
            nestedComponent: nestedObject1,
            optionalNestedComponent: nestedObject2
        )
        let action = FakeReduxModernAction.nestedObjectPayload(nestedObject: fakePayload)
        // swiftlint:disable line_length
        let expectedDescription = """
        FakeReduxModernAction.nestedObjectPayload {
           nestedObject: FakeNestedComplicatedPayload(someString: "TestString", nestedComponent: ReduxTests.FakeComplicatedPayload(someBool: true, someCount: 1, someOptionalCount: Optional(2)), optionalNestedComponent: Optional(ReduxTests.FakeComplicatedPayload(someBool: false, someCount: 10, someOptionalCount: Optional(9))))
        }
        """.trimmingCharacters(in: .whitespaces) // Trim the newlines at the end due to the """ termination
        // swiftlint:enable line_length

        XCTAssertEqual(action.description, expectedDescription)
    }
}
