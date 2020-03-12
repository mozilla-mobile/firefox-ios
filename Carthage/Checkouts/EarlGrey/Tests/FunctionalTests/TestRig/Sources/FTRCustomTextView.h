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

// Contains classes that are used for testing typing actions with views that conforms to UITextInput
// protocol other than UITextField and UITextView.

#import <UIKit/UIKit.h>

/**
 *  TextPosition to be used by CustomTextView.
 */
@interface CustomTextPosition : UITextPosition

@property(nonatomic, assign) NSUInteger position;

- (instancetype)initWithPosition:(NSUInteger)aPosition;

@end

/**
 *  TextRange to be used by CustomTextView.
 */
@interface CustomTextRange : UITextRange<NSCopying>

+ (id)rangeWithStartPosition:(CustomTextPosition *)startPosition
                 endPosition:(CustomTextPosition *)endPosition;
- (void)setStartPostion:(CustomTextPosition *)position;
- (void)setEndPostion:(CustomTextPosition *)position;
- (NSInteger)length;

@end

/*
 * A simple custom text view that conforms to UITextInput protocol. This class cannot be used in
 * applications. This is just a text view in which simple type actions can be performed. To do
 * complex operations, as in UITextField or UITextView, this class cannot be used. The sole purpose
 * of this class is to be used for testing text typing operations in UITextInput conforming views.
 * The accessibility label of this class is always the text in it.
 */
@interface FTRCustomTextView : UIView<UITextInput>

@property(nonatomic, readonly) UITextRange *markedTextRange;
@property(nonatomic, readonly) UITextPosition *beginningOfDocument;
@property(nonatomic, readonly) UITextPosition *endOfDocument;
@property(nonatomic, readonly) id <UITextInputTokenizer> tokenizer;
@property(nonatomic, copy) NSDictionary *markedTextStyle;
@property(readwrite, copy) UITextRange *selectedTextRange;
@property(nonatomic, weak) id <UITextInputDelegate> inputDelegate;

@end
