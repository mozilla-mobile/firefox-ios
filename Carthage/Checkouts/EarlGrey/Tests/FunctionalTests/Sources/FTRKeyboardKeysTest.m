//
// Copyright 2016 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "FTRBaseIntegrationTest.h"
#import "FTRFailureHandler.h"
#import "Action/GREYActions+Internal.h"
#import "Additions/NSError+GREYAdditions.h"
#import "Core/GREYKeyboard.h"

@interface FTRKeyboardKeysTest : FTRBaseIntegrationTest
@end

@implementation FTRKeyboardKeysTest

- (void)setUp {
  [super setUp];
  [self openTestViewNamed:@"Typing Views"];
}

- (void)testTypingAtBeginning {
  [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:[GREYActions actionForTypeText:@"Foo"]]
      performAction:[self ftr_actionForTypingText:@"Bar" atPosition:0]]
      assertWithMatcher:grey_text(@"BarFoo")];
}

- (void)testTypingAtEnd {
    [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:[GREYActions actionForTypeText:@"Foo"]]
      performAction:[self ftr_actionForTypingText:@"Bar" atPosition:-1]]
      assertWithMatcher:grey_text(@"FooBar")];
}

- (void)testTypingInMiddle {
  [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:[GREYActions actionForTypeText:@"Foo"]]
      performAction:[self ftr_actionForTypingText:@"Bar" atPosition:2]]
      assertWithMatcher:grey_text(@"FoBaro")];
}

- (void)testTypingInMiddleOfBigString {
  [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:
          [GREYActions actionForTypeText:@"This string is a little too long for this text field!"]]
      performAction:[self ftr_actionForTypingText:@"Foo" atPosition:1]]
      assertWithMatcher:grey_text(@"TFoohis string is a little too long for this text field!")];
}

- (void)testTypingAfterTappingOnTextField {
  [[[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:[GREYActions actionForTap]]
      performAction:[GREYActions actionForTypeText:@"foo"]]
      performAction:[GREYActions actionForClearText]]
      assertWithMatcher:grey_text(@"")];
}

- (void)testClearAfterTyping {
  [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:[GREYActions actionForTypeText:@"Foo"]]
      performAction:[GREYActions actionForClearText]]
      assertWithMatcher:grey_text(@"")];
}

- (void)testClearAfterClearing {
  [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:[GREYActions actionForClearText]]
      performAction:[GREYActions actionForClearText]]
      assertWithMatcher:grey_text(@"")];
}

- (void)testClearAndType_TypeShort {
  [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:[GREYActions actionForClearText]]
      performAction:[GREYActions actionForTypeText:@"Foo"]]
      assertWithMatcher:grey_text(@"Foo")];
}

- (void)testTypeAfterClearing_ClearThenType {
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:[GREYActions actionForTypeText:@"f"]]
      assertWithMatcher:grey_text(@"f")];

  [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:[GREYActions actionForClearText]]
      performAction:[GREYActions actionForTypeText:@"g"]]
      assertWithMatcher:grey_text(@"g")];
}

- (void)testTypeAfterClearing_TypeLong {
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:[GREYActions actionForTypeText:@"This is a long string"]]
      assertWithMatcher:grey_text(@"This is a long string")];

  [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:[GREYActions actionForClearText]]
      performAction:[GREYActions actionForTypeText:@"short string"]]
      assertWithMatcher:grey_text(@"short string")];
}

- (void)testNonTypistKeyboardInteraction {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:[GREYActions actionForTap]];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"a")]
      performAction:[GREYActions actionForTap]];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"b")]
      performAction:[GREYActions actionForTap]];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"c")]
      performAction:[GREYActions actionForTap]];

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"return")]
      performAction:[GREYActions actionForTap]];
}

- (void)testNonTypingTextField {
  [EarlGrey setFailureHandler:[[FTRFailureHandler alloc] init]];

  @try {
    [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"NonTypingTextField")]
        performAction:[GREYActions actionForTypeText:@"Should Fail"]];
    GREYFail(@"Should throw an exception");
  } @catch (NSException *exception) {
    NSRange exceptionRange =
        [[exception reason] rangeOfString:@"\"Action Name\":  \"Type 'Should Fail'\""];
    GREYAssertTrue(exceptionRange.length > 0, @"Should throw exception indicating action failure.");
  }
}

- (void)testTypingWordsThatTriggerAutoCorrect {
  NSString *string = @"hekp";
  [self ftr_typeString:string andVerifyOutput:string];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_clearText()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextView")]
      performAction:grey_clearText()];

  string = @"helko";
  [self ftr_typeString:string andVerifyOutput:string];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_clearText()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextView")]
      performAction:grey_clearText()];

  string = @"balk";
  [self ftr_typeString:string andVerifyOutput:string];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_clearText()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextView")]
      performAction:grey_clearText()];

  string = @"surr";
  [self ftr_typeString:string andVerifyOutput:string];
}

- (void)testNumbersTyping {
  NSString *string = @"1234567890";
  [self ftr_typeString:string andVerifyOutput:string];
}

- (void)testSymbolsTyping {
  NSString *string = @"~!@#$%^&*()_+-={}:;<>?";
  [self ftr_typeString:string andVerifyOutput:string];
}

- (void)testLetterTyping {
  NSString *string = @"aBc";
  [self ftr_typeString:string andVerifyOutput:string];
}

- (void)testEmailTyping {
  NSString *string = @"donec.metus+spam@google.com";
  [self ftr_typeString:string andVerifyOutput:string];
}

- (void)testUpperCaseLettersTyping {
  NSString *string = @"VERYLONGTEXTWITHMANYLETTERS";
  [self ftr_typeString:string andVerifyOutput:string];
}

- (void)testNumbersAndSpacesTyping {
  NSString *string = @"0 1 2 3 4 5 6 7 8 9";
  [self ftr_typeString:string andVerifyOutput:string];
}

- (void)testSymbolsAndSpacesTyping {
  NSString *string = @"[ ] # + = _ < > { }";
  [self ftr_typeString:string andVerifyOutput:string];
}

- (void)testSpaceKey {
  NSString *string = @"a b";
  [self ftr_typeString:string andVerifyOutput:string];
}

- (void)testBackspaceKey {
  NSString *string = @"ab\b";
  NSString *verificationString = @"a";
  [self ftr_typeString:string andVerifyOutput:verificationString];
}

- (void)testReturnKey {
  Class kbViewClass = NSClassFromString(@"UIKeyboardImpl");
  NSString *textFieldString = @"and\n";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(textFieldString)]
      assertWithMatcher:grey_text(@"and")];

  [[EarlGrey selectElementWithMatcher:grey_kindOfClass(kbViewClass)] assertWithMatcher:grey_nil()];

  NSString *string = @"and\nand";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextView")]
      performAction:grey_typeText(string)]
      assertWithMatcher:grey_text(@"and\nand")];

  [[EarlGrey selectElementWithMatcher:grey_kindOfClass(kbViewClass)]
      assertWithMatcher:grey_notNil()];
}

- (void)testAllReturnKeyTypes {
  Class kbViewClass = NSClassFromString(@"UIKeyboardImpl");
  // There are 11 returnKeyTypes; test all of them.
  for (int i = 0; i < 11; i++) {
    [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:grey_typeText(@"a\n")]
        assertWithMatcher:grey_text(@"a")];

    [[EarlGrey selectElementWithMatcher:grey_kindOfClass(kbViewClass)]
        assertWithMatcher:grey_nil()];

    [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:grey_typeText(@"*\n")]
        assertWithMatcher:grey_text(@"a*")];

    [[EarlGrey selectElementWithMatcher:grey_kindOfClass(kbViewClass)]
        assertWithMatcher:grey_nil()];

    [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"next returnKeyType")]
        performAction:grey_tap()];
  }
}

- (void)testPanelNavigation {
  NSString *string = @"a1a%a%1%";
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)];
}

- (void)testKeyplaneIsDetectedCorrectlyWhenSwitchingTextFields {
  NSString *string = @"$";

  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)]
      assertWithMatcher:grey_text(string)];

  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextView")]
      performAction:grey_typeText(string)]
      assertWithMatcher:grey_text(string)];
}

- (void)testUIKeyboardTypeDefault {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
      performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"Default"]];

  NSString *string = @":$a8. {T<b@CC";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)]
      assertWithMatcher:grey_text(string)];
}

- (void)testUIKeyboardTypeASCIICapable {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
      performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"ASCIICapable"]];

  NSString *string = @":$a8. {T<b@CC";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)]
      assertWithMatcher:grey_text(string)];
}

- (void)testUIKeyboardTypeNumbersAndPunctuation {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
      performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"NumbersAndPunctuation"]];

  NSString *string = @":$a8. {T<b@CC";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)]
      assertWithMatcher:grey_text(string)];
}

- (void)testUIKeyboardTypeURL {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
      performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"URL"]];

  NSString *string = @"http://www.google.com/@*s$&T+t?[]#testLabel%foo;";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)]
      assertWithMatcher:grey_text(string)];
}

- (void)testUIKeyboardTypeNumberPad {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
      performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"NumberPad"]];

  NSString *string = @"\b0123456\b789\b\b";
  NSString *verificationString = @"0123457";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)]
      assertWithMatcher:grey_text(verificationString)];
}

- (void)testUIKeyboardTypePhonePad {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
      performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"PhonePad"]];

  NSString *string = @"01*23\b\b+45#67,89;";
  NSString *verificationString = @"01*+45#67,89;";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)]
      assertWithMatcher:grey_text(verificationString)];
}

- (void)testUIKeyboardTypeEmailAddress {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
      performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"EmailAddress"]];

  NSString *string = @"l0rem.ipsum+42@google.com#$_T*-";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)]
      assertWithMatcher:grey_text(string)];
}

- (void)testUIKeyboardTypeDecimalPad {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
      performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"DecimalPad"]];

  NSString *string = @"\b0123.456\b78..9\b\b";
  NSString *verificationString = @"0123.4578.";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)]
      assertWithMatcher:grey_text(verificationString)];
}

- (void)testUIKeyboardTypeTwitter {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
      performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"Twitter"]];

  NSString *string = @"@earlgrey Your framework is #awesome!!!1$:,eG%g\n";
  NSString *verificationString = @"@earlgrey Your framework is #awesome!!!1$:,eG%g";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)]
      assertWithMatcher:grey_text(verificationString)];
}

- (void)testUIKeyboardTypeWebSearch {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"KeyboardPicker")]
      performAction:[GREYActions actionForSetPickerColumn:0 toValue:@"WebSearch"]];

  NSString *string = @":$a8. {T<b@CC";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)]
      assertWithMatcher:grey_text(string)];
}

- (void)testTypingOnLandscapeLeft {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeLeft errorOrNil:nil];
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(@"Cat")]
      assertWithMatcher:grey_text(@"Cat")];
}

- (void)testTypingOnLandscapeRight {
  [EarlGrey rotateDeviceToOrientation:UIDeviceOrientationLandscapeRight errorOrNil:nil];
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(@"Cat")]
      assertWithMatcher:grey_text(@"Cat")];
}

- (void)testTogglingShiftByChangingCase {
  NSString *multiCaseString = @"aA1a1A1aA1AaAa1A1a";
  id<GREYAction> action =
      [GREYActionBlock actionWithName:@"ToggleShift"
                         performBlock:^(id element, __strong NSError **errorOrNil) {
        NSArray *shiftAXLabels =
            @[ @"shift", @"Shift", @"SHIFT", @"more, symbols", @"more, numbers", @"more", @"MORE" ];
        for (NSString *axLabel in shiftAXLabels) {
          NSError *error;
          [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(axLabel)]
                              performAction:grey_tap()
                                      error:&error];
        }
        return YES;
      }];

  for (NSUInteger i = 0; i < multiCaseString.length; i++) {
    NSString *currentCharacter = [multiCaseString substringWithRange:NSMakeRange(i, 1)];
    [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
        performAction:grey_typeText(currentCharacter)]
        performAction:action]
        assertWithMatcher:grey_text([multiCaseString substringToIndex:i + 1])];
  }

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      assertWithMatcher:grey_text(multiCaseString)];
}

- (void)testSuccessivelyTypingInTheSameTextField {
  [[[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(@"This ")]
      performAction:grey_typeText(@"Is A ")]
      performAction:grey_typeText(@"Test")]
      assertWithMatcher:grey_text(@"This Is A Test")];
}

- (void)testTypingBlankString {
  NSString *string = @"       ";
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)]
      assertWithMatcher:grey_text(string)];
}

- (void)testClearAfterTypingInCustomTextView {
  [[[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomTextView")]
      performAction:[GREYActions actionForTypeText:@"Foo"]]
      assertWithMatcher:grey_accessibilityLabel(@"Foo")]
      performAction:[GREYActions actionForClearText]]
      assertWithMatcher:grey_accessibilityLabel(@"")];
}

- (void)testClearAfterClearingInCustomTextView {
  [[[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomTextView")]
      performAction:[GREYActions actionForClearText]]
      assertWithMatcher:grey_accessibilityLabel(@"")]
      performAction:[GREYActions actionForClearText]]
      assertWithMatcher:grey_accessibilityLabel(@"")];
}

- (void)testTypeAfterClearingInCustomTextView {
  [[[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomTextView")]
      performAction:[GREYActions actionForClearText]]
      assertWithMatcher:grey_accessibilityLabel(@"")]
      performAction:[GREYActions actionForTypeText:@"Foo"]]
      assertWithMatcher:grey_accessibilityLabel(@"Foo")];
}

- (void)testTypingOnTextFieldInUIInputAccessory {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"Input Button")]
      performAction:grey_tap()];
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"InputAccessoryTextField")]
      performAction:grey_typeText(@"Test")] assertWithMatcher:grey_text(@"Test")];
}

- (void)testClearAndReplaceWorksWithUIAccessibilityTextFieldElement {
  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"Input Button")]
      performAction:grey_tap()];

  Class accessibilityTextFieldElemClass = NSClassFromString(@"UIAccessibilityTextFieldElement");
  id<GREYMatcher> elementMatcher = grey_allOf(grey_accessibilityValue(@"Text Field"),
                                              grey_kindOfClass(accessibilityTextFieldElemClass),
                                              nil);
  [[[EarlGrey selectElementWithMatcher:elementMatcher]
      performAction:grey_clearText()]
      performAction:grey_replaceText(@"foo")];

  [[EarlGrey selectElementWithMatcher:grey_textFieldValue(@"foo")]
      assertWithMatcher:grey_text(@"foo")];
}

- (void)testIsKeyboardShownWithCustomKeyboardTracker {
  GREYActionBlock *setResponderBlock =
  [GREYActionBlock actionWithName:@"Set First Responder"
      performBlock:^BOOL(id element, NSError *__strong *errorOrNil) {
          return [element becomeFirstResponder];
      }];

  GREYAssertFalse([GREYKeyboard isKeyboardShown], @"Keyboard Shouldn't be Shown");

  [[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"CustomKeyboardTracker")]
      performAction:setResponderBlock];
  GREYAssertFalse([GREYKeyboard isKeyboardShown], @"Keyboard Shouldn't be Shown");
}

- (void)testTypingAndResigningOfFirstResponder {
  GREYAssertFalse([GREYKeyboard isKeyboardShown], @"Keyboard Shouldn't be Shown");

  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:[GREYActions actionForTypeText:@"Foo"]]
      assertWithMatcher:grey_text(@"Foo")];
  GREYAssertTrue([GREYKeyboard isKeyboardShown], @"Keyboard Shouldn't be Shown");

  [EarlGrey dismissKeyboardWithError:nil];
  GREYAssertFalse([GREYKeyboard isKeyboardShown], @"Keyboard Shouldn't be Shown as it is resigned");

  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:[GREYActions actionForTypeText:@"Foo"]]
      assertWithMatcher:grey_text(@"FooFoo")];
  GREYAssertTrue([GREYKeyboard isKeyboardShown], @"Keyboard Shouldn't be Shown");
}

- (void)testTypingAndResigningWithError {
  GREYAssertFalse([GREYKeyboard isKeyboardShown], @"Keyboard Shouldn't be Shown");

  GREYActionBlock *setResponderBlock =
      [GREYActionBlock actionWithName:@"Set First Responder"
                         performBlock:^BOOL(id element, NSError *__strong *errorOrNil) {
                           [element becomeFirstResponder];
                           return YES;
                         }];
  NSError *error;
  [EarlGrey dismissKeyboardWithError:&error];
  NSString *localizedErrorDescription = [error localizedDescription];
  GREYAssertEqualObjects(localizedErrorDescription,
                         @"Failed to dismiss keyboard since it was not showing.",
                         @"Unexpected error message for initial dismiss: %@, original error: %@",
                         localizedErrorDescription, error);

  [[EarlGrey selectElementWithMatcher:grey_keyWindow()] performAction:setResponderBlock];
  [EarlGrey dismissKeyboardWithError:&error];
  localizedErrorDescription = [error localizedDescription];
  GREYAssertEqualObjects(localizedErrorDescription,
                         @"Failed to dismiss keyboard since it was not showing.",
                         @"Unexpected error message for second dismiss: %@, original error: %@",
                         localizedErrorDescription, error);
}

#pragma mark - Private

- (void)ftr_typeString:(NSString *)string andVerifyOutput:(NSString *)verificationString {
  [[[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextField")]
      performAction:grey_typeText(string)]
      performAction:grey_typeText(@"\n")]
      assertWithMatcher:grey_text(verificationString)];
  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"TypingTextView")]
      performAction:grey_typeText(string)]
      assertWithMatcher:grey_text(verificationString)];
  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"Done")]
      performAction:grey_tap()];
}

// Helper action that converts numeric position to UITextPosition.
- (id<GREYAction>)ftr_actionForTypingText:(NSString *)text atPosition:(NSInteger)position {
  NSString *actionName =
      [NSString stringWithFormat:@"Test type \"%@\" at position %ld", text, (long)position];
  return [GREYActionBlock actionWithName:actionName
                             constraints:grey_conformsToProtocol(@protocol(UITextInput))
                            performBlock:^BOOL (id element, __strong NSError **errorOrNil) {
      UITextPosition *textPosition;
      if (position >= 0) {
        textPosition = [element positionFromPosition:[element beginningOfDocument] offset:position];
        if (!textPosition) {
          // Text position will be nil if the computed text position is greater than the length
          // of the backing string or less than zero. Since position is positive, the computed value
          // was past the end of the text field.
          textPosition = [element endOfDocument];
        }
      } else {
        // Position is negative. -1 should map to the end of the text field.
        textPosition = [element positionFromPosition:[element endOfDocument] offset:position + 1];
        if (!textPosition) {
          // Since position is positive, the computed value was past beginning of the text field.
          textPosition = [element beginningOfDocument];
        }
      }
      return [[GREYActions grey_actionForTypeText:text atUITextPosition:textPosition]
                 perform:element error:errorOrNil];
  }];
}

@end
