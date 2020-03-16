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

#import "FTRCustomTextView.h"

@implementation CustomTextPosition

- (instancetype)initWithPosition:(NSUInteger)aPosition {
  self = [super init];
  if (self) {
    _position = aPosition;
  }
  return self;
}

@end

@implementation CustomTextRange {
  CustomTextPosition *_start;
  CustomTextPosition *_end;
}

+ (id)rangeWithStartPosition:(CustomTextPosition *)startPosition
                 endPosition:(CustomTextPosition *)endPosition {
  CustomTextRange *range = [[CustomTextRange alloc] init];
  [range setStartPostion:startPosition];
  [range setEndPostion:endPosition];
  return range;
}

- (BOOL)isEmpty {
  return (_end.position - _start.position) == 0;
}

- (NSInteger)length {
  return ((NSInteger)_end.position - (NSInteger)_start.position);
}

- (UITextPosition *)start {
  return _start;
}

- (void)setStartPostion:(CustomTextPosition *)position {
  _start = position;
}

- (UITextPosition *)end {
  return _end;
}

- (void)setEndPostion:(CustomTextPosition *)position {
  _end = position;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
  CustomTextRange *copiedRange = [[[self class] allocWithZone: zone] init];
  [copiedRange setEndPostion:(CustomTextPosition *)[self end]];
  [copiedRange setStartPostion:(CustomTextPosition *)[self start]];
  return copiedRange;
}

@end

@implementation FTRCustomTextView {
  NSMutableString *_textStore;
  UITextInputStringTokenizer *_tokenizer;
}

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self doInit];
  }
  return self;
}

- (void)doInit {
  self.backgroundColor = [UIColor whiteColor];
  _textStore = [NSMutableString string];
  CustomTextPosition *start = [[CustomTextPosition alloc] initWithPosition:0];
  UITextRange *range = [CustomTextRange rangeWithStartPosition:start endPosition:start];
  [self setSelectedTextRange:range];
}

- (void)awakeFromNib {
  [super awakeFromNib];
  [self doInit];
}

- (void)dealloc {
  _textStore = nil;
}

- (CGRect)rectForTextWithInset:(CGFloat)inset {
  return CGRectInset(self.bounds, inset, inset);
}

- (void)drawRect:(CGRect)rect {
  UIColor *color = [UIColor blackColor];
  UIFont *font = [UIFont systemFontOfSize:12.0f];
  CGRect rectForText = [self rectForTextWithInset:8.0f];
  UIRectFrame(rect);

  [_textStore drawInRect:rectForText withAttributes:@{ NSFontAttributeName : font,
                                                       NSForegroundColorAttributeName : color }];
}

- (BOOL)canBecomeFirstResponder {
  return YES;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  if (![self isFirstResponder]) {
    [self becomeFirstResponder];
  }
}

#pragma mark - UIKeyInput protocol

- (BOOL)hasText {
  return _textStore.length > 0;
}

- (void)insertText:(NSString *)text {
  UIMenuController *menuController = [UIMenuController sharedMenuController];
  [menuController setMenuVisible:NO animated:YES];
  [self.inputDelegate textWillChange:self];
  [_textStore appendString:text];
  [self.inputDelegate textDidChange:self];
  [self setNeedsDisplay];
}

- (void)deleteBackward {
  if (_textStore.length == 0) {
    return;
  }
  NSRange theRange = NSMakeRange(_textStore.length - 1, 1);
  [_textStore deleteCharactersInRange:theRange];
  CustomTextPosition *position = [[CustomTextPosition alloc] initWithPosition:theRange.location];
  CustomTextRange *newRange = [CustomTextRange rangeWithStartPosition:position
                                                          endPosition:position];
  [self setSelectedTextRange:newRange];
  [self setNeedsDisplay];
}

#pragma mark - UITextInput protocol

- (NSString *)textInRange:(UITextRange *)range {
  NSUInteger startPosition = [(CustomTextPosition *)range.start position];
  NSUInteger endPosition = [(CustomTextPosition *)range.end position];
  NSUInteger length = endPosition - startPosition + 1;
  NSRange substringRange = NSMakeRange(startPosition, length);
  if (endPosition != NSUIntegerMax && startPosition != NSUIntegerMax
      && _textStore.length >= NSMaxRange(substringRange)) {
    return [_textStore substringWithRange:substringRange];
  }
  return nil;
}

- (void)replaceRange:(UITextRange *)range withText:(NSString *)text {
  [self.inputDelegate textWillChange:self];
  NSUInteger start = [(CustomTextPosition *)range.start position];
  NSUInteger length = [(CustomTextPosition *)range.end position] - start;
  [_textStore replaceCharactersInRange:NSMakeRange(start, length) withString:text];
  CustomTextPosition *position =
      [[CustomTextPosition alloc] initWithPosition:start + text.length];
  UITextRange *newRange = [CustomTextRange rangeWithStartPosition:position endPosition:position];
  [self setSelectedTextRange:newRange];
  [self.inputDelegate textDidChange:self];
  [self setNeedsDisplay];
}

- (NSArray *)selectionRectsForRange:(UITextRange *)range {
  // Required method that expect non-null value. Returning empty array by default.
  return @[];
}

- (UITextRange *)markedTextRange {
  // Required method. Returns nil. Add code if needed
  return nil;
}

- (void)setMarkedTextStyle:(NSDictionary *)style {
  // Required method. Does nothing. Add code if needed
}

- (NSDictionary *)markedTextStyle {
  return nil;
}

- (void)setMarkedText:(NSString *)markedText selectedRange:(NSRange)selectedRange {
  // Required method. Does nothing. Add code if needed
}

- (void)unmarkText {
  // Required method. Does nothing. Add code if needed
}

- (UITextPosition *)beginningOfDocument {
  return [[CustomTextPosition alloc] initWithPosition:0];
}
- (UITextPosition *)endOfDocument {
  return [[CustomTextPosition alloc] initWithPosition:_textStore.length - 1];
}

- (UITextRange *)textRangeFromPosition:(UITextPosition *)fromPosition
                            toPosition:(UITextPosition *)toPosition {
  return [CustomTextRange rangeWithStartPosition:(CustomTextPosition *)fromPosition
                                     endPosition:(CustomTextPosition *)toPosition];
}

- (UITextPosition *)positionFromPosition:(UITextPosition *)position offset:(NSInteger)offset {
  CustomTextPosition *p = (CustomTextPosition *)position;
  return [[CustomTextPosition alloc] initWithPosition:[p position] + (NSUInteger)offset];
}

- (UITextPosition *)positionFromPosition:(UITextPosition *)position
                             inDirection:(UITextLayoutDirection)direction
                                  offset:(NSInteger)offset {
  NSUInteger pos;
  switch (direction) {
    case UITextLayoutDirectionUp:
    {
      CGRect caretRect = [self caretRectForPosition:position];
      CGPoint target = caretRect.origin;
      target.y =
          target.y - (caretRect.size.height * (offset - 1)) - (caretRect.size.height * 0.5f);
      pos = [(CustomTextPosition *)[self closestPositionToPoint:target] position];
      break;
    }
    case UITextLayoutDirectionDown:
    {
      CGRect caretRect = [self caretRectForPosition:position];
      CGPoint target = caretRect.origin;
      target.y =
          target.y + (caretRect.size.height * (offset - 1)) + (caretRect.size.height * 1.5f);
      pos = [(CustomTextPosition *)[self closestPositionToPoint:target] position];
      break;
    }
    case UITextLayoutDirectionLeft:
    {
      pos = [(CustomTextPosition *)position position] - (NSUInteger)offset;
      break;
    }
    case UITextLayoutDirectionRight:
    {
      pos = [(CustomTextPosition *)position position] + (NSUInteger)offset;
      break;
    }
    default:
    {
      pos = [(CustomTextPosition *)position position];
      break;
    }
  }
  CustomTextPosition *newPosition = [[CustomTextPosition alloc] initWithPosition:pos];
  UITextRange *newRange = [CustomTextRange rangeWithStartPosition:newPosition
                                                      endPosition:newPosition];
  [self setSelectedTextRange:newRange];

  return [[CustomTextPosition alloc] initWithPosition:pos];
}

- (NSComparisonResult)comparePosition:(UITextPosition *)position
                           toPosition:(UITextPosition *)other {
  NSUInteger first = [(CustomTextPosition *)position position];
  NSUInteger second = [(CustomTextPosition *)other position];

  NSComparisonResult result;
  if (first < second) {
    result = NSOrderedAscending;
  } else if (first > second) {
    result = NSOrderedDescending;
  } else {
    result = NSOrderedSame;
  }
  return result;
}

- (NSInteger)offsetFromPosition:(UITextPosition *)from toPosition:(UITextPosition *)toPosition {
  NSUInteger start = [(CustomTextPosition *)from position];
  NSUInteger end = [(CustomTextPosition *)toPosition position];
  NSInteger result = (NSInteger)(end - start);
  return result;
}

- (id<UITextInputTokenizer>)tokenizer {
  if (!_tokenizer) {
    _tokenizer = [[UITextInputStringTokenizer alloc] initWithTextInput:self];
  }
  return _tokenizer;
}

- (UITextPosition *)positionWithinRange:(UITextRange *)range
                    farthestInDirection:(UITextLayoutDirection)direction {
  // Required method. Returns nil. Add code if needed
  return nil;
}

- (UITextRange *)characterRangeByExtendingPosition:(UITextPosition *)position
                                       inDirection:(UITextLayoutDirection)direction {
  // Required method. Returns nil. Add code if needed
  return nil;
}

- (UITextWritingDirection)baseWritingDirectionForPosition:(UITextPosition *)position
                                              inDirection:(UITextStorageDirection)direction {
  return UITextWritingDirectionLeftToRight;
}

- (void)setBaseWritingDirection:(UITextWritingDirection)writingDirection
                       forRange:(UITextRange *)range {
  // Required method. Does nothing. Add code if needed
}

- (CGRect)firstRectForRange:(UITextRange *)range {
  // Required method. Returns CGRectNull. Add code if needed
  return CGRectNull;
}

- (CGRect)caretRectForPosition:(UITextPosition *)position {
  // Required method. Returns CGRectNull. Add code if needed
  return CGRectNull;
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point {
  return [[CustomTextPosition alloc] initWithPosition:0];
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point withinRange:(UITextRange *)range {
  return range.start;
}

- (UITextRange *)characterRangeAtPoint:(CGPoint)point {
  CustomTextPosition *pos = (CustomTextPosition *)[self closestPositionToPoint:point];
  return [CustomTextRange rangeWithStartPosition:pos endPosition:pos];
}

#pragma mark - Accessibility

- (NSString *)accessibilityLabel {
  return _textStore;
}

@end
