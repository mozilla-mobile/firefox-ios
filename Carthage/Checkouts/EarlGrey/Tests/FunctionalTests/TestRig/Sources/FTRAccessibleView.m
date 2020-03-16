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

#import "FTRAccessibleView.h"

@implementation FTRAccessibleView {
  UIAccessibilityElement *_squareElement;
  UIAccessibilityElement *_partialOffScreenRectangleElement;
  UIAccessibilityElement *_onScreenRectangleElement;
  UIAccessibilityElement *_circleElement;
  UIAccessibilityElement *_offScreenElement;
  UIAccessibilityElement *_elementWithZeroWidth;
  UIAccessibilityElement *_elementWithZeroHeight;
  UIAccessibilityElement *_elementPartiallyOutsideScreen;
  CGRect _squareFrameRect;
  CGRect _partialOffScreenRectangleFrameRect;
  CGRect _onScreenRectangleFrameRect;
  CGRect _circleFrameRect;
  CGRect _partiallyOutsideRect;
  UILabel *_label;
  NSArray *_accessibilityElements;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    [self initialize];
  }
  return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self initialize];
  }
  return self;
}

- (void)initialize {
  _label = [[UILabel alloc] initWithFrame:CGRectMake(20, 120, 300, 30)];
  [_label setAccessibilityLabel:@"AccessibilityElementStatus"];
  [_label setText:@"No elements were clicked."];
  [self addSubview:_label];

  UIAccessibilityTraits elementTraits = UIAccessibilityTraitButton | UIAccessibilityTraitStaticText;

  _squareElement = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:self];
  [_squareElement setAccessibilityTraits:elementTraits];
  [_squareElement setAccessibilityLabel:@"SquareElementLabel"];
  [_squareElement setAccessibilityIdentifier:@"SquareElementIdentifier"];
  [_squareElement setAccessibilityValue:@"SquareElementValue"];

  _partialOffScreenRectangleElement =
      [[UIAccessibilityElement alloc] initWithAccessibilityContainer:self];
  [_partialOffScreenRectangleElement setAccessibilityTraits:elementTraits];
  [_partialOffScreenRectangleElement
      setAccessibilityLabel:@"PartialOffScreenRectangleElementLabel"];
  [_partialOffScreenRectangleElement
      setAccessibilityIdentifier:@"PartialOffScreenRectangleElementIdentifier"];
  [_partialOffScreenRectangleElement
      setAccessibilityValue:@"PartialOffScreenRectangleElementValue"];

  _onScreenRectangleElement = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:self];
  [_onScreenRectangleElement setAccessibilityTraits:elementTraits];
  [_onScreenRectangleElement setAccessibilityLabel:@"OnScreenRectangleElementLabel"];
  [_onScreenRectangleElement setAccessibilityIdentifier:@"OnScreenRectangleElementIdentifier"];
  [_onScreenRectangleElement setAccessibilityValue:@"OnScreenRectangleElementValue"];

  _circleElement = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:self];
  [_circleElement setAccessibilityTraits:elementTraits];
  [_circleElement setAccessibilityLabel:@"CircleElementLabel"];
  [_circleElement setAccessibilityIdentifier:@"CircleElementIdentifier"];
  [_circleElement setAccessibilityValue:@"CircleElementValue"];

  _elementPartiallyOutsideScreen =
      [[UIAccessibilityElement alloc] initWithAccessibilityContainer:self];
  [_elementPartiallyOutsideScreen setAccessibilityTraits:elementTraits];
  [_elementPartiallyOutsideScreen setAccessibilityLabel:@"PartiallyOutsideElementLabel"];
  [_elementPartiallyOutsideScreen setAccessibilityIdentifier:@"PartiallyOutsideElementIdentifier"];
  [_elementPartiallyOutsideScreen setAccessibilityValue:@"PartiallyOutsideElemenValue"];

  _offScreenElement = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:self];
  [_offScreenElement setAccessibilityIdentifier:@"OffScreenElementIdentifier"];

  _elementWithZeroHeight = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:self];
  [_elementWithZeroHeight setAccessibilityIdentifier:@"ElementWithZeroHeight"];

  _elementWithZeroWidth = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:self];
  [_elementWithZeroWidth setAccessibilityIdentifier:@"ElementWithZeroWidth"];

  _accessibilityElements = @[ _squareElement,
                              _partialOffScreenRectangleElement,
                              _onScreenRectangleElement,
                              _circleElement,
                              _offScreenElement,
                              _elementWithZeroHeight,
                              _elementWithZeroWidth,
                              _elementPartiallyOutsideScreen ];
}

- (void)layoutSubviews {
  [super layoutSubviews];

  _squareFrameRect =
      UIAccessibilityConvertFrameToScreenCoordinates(CGRectMake(50, 150, 100, 100), self);
  // We test that rectangle is not fully visible; make it big enough to not fit on iPad screen.
  _partialOffScreenRectangleFrameRect =
      UIAccessibilityConvertFrameToScreenCoordinates(CGRectMake(200, 200, 800, 800), self);
  _onScreenRectangleFrameRect =
      UIAccessibilityConvertFrameToScreenCoordinates(CGRectMake(250, 50, 64, 128), self);
  _circleFrameRect =
      UIAccessibilityConvertFrameToScreenCoordinates(CGRectMake(50, 260, 50, 50), self);
  _partiallyOutsideRect =
      UIAccessibilityConvertFrameToScreenCoordinates(CGRectMake(-75, 64, 100, 50), self);

  [_squareElement setAccessibilityFrame:_squareFrameRect];
  [_partialOffScreenRectangleElement setAccessibilityFrame:_partialOffScreenRectangleFrameRect];
  [_onScreenRectangleElement setAccessibilityFrame:_onScreenRectangleFrameRect];
  [_circleElement setAccessibilityFrame:_circleFrameRect];
  [_elementPartiallyOutsideScreen setAccessibilityFrame:_partiallyOutsideRect];

  [_offScreenElement setAccessibilityFrame:CGRectMake(-100, -100, 100, 100)];
  [_elementWithZeroHeight setAccessibilityFrame:CGRectMake(100, 100, 100, 0)];
  [_elementWithZeroWidth setAccessibilityFrame:CGRectMake(100, 100, 0, 100)];
}

- (void)drawRect:(CGRect)rect {
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSaveGState(context);

  // UIAccessibilityElements contained in this view must be drawn in this view's frame co-ordinate
  // system, since accessibilityFrames are in screen coordinates we have to translate them
  // accordingly.
  CGContextTranslateCTM(context, -self.frame.origin.x, -self.frame.origin.y);

  CGContextSetRGBFillColor(context, 1, 0, 0, 1);
  CGContextFillRect(context, _squareFrameRect);

  CGContextSetRGBFillColor(context, 0, 1, 0, 1);
  CGContextFillRect(context, _partialOffScreenRectangleFrameRect);

  CGContextSetRGBFillColor(context, 1, 1, 0, 1);
  CGContextFillRect(context, _onScreenRectangleFrameRect);

  CGContextSetRGBFillColor(context, 0, 0, 1, 1);
  CGContextFillEllipseInRect(context, _circleFrameRect);

  CGContextSetRGBFillColor(context, 0, 1, 1, 1);
  CGContextFillRect(context, _partiallyOutsideRect);

  CGContextRestoreGState(context);
  [super drawRect:rect];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  if (event.type == UIEventTypeTouches && touches.count == 1) {
    UITouch *touch = [touches anyObject];
    if (touch.tapCount == 1) {
      CGPoint locationOnScreen = [touch locationInView:self];
      locationOnScreen = [self convertPoint:locationOnScreen toView:nil];
      locationOnScreen = [self.window convertPoint:locationOnScreen toWindow:nil];

      if (CGRectContainsPoint(_squareFrameRect, locationOnScreen)) {
        _label.text = @"Square Tapped";
      } else if (CGRectContainsPoint(_partialOffScreenRectangleFrameRect, locationOnScreen)) {
        _label.text = @"Rectangle Tapped";
      } else if (CGRectContainsPoint(_circleFrameRect, locationOnScreen)) {
        _label.text = @"Circle Tapped";
      } else if (CGRectContainsPoint(_partiallyOutsideRect, locationOnScreen)) {
        _label.text = @"Partially Outside Tapped";
      } else {
        _label.text = @"Unrecognized Tap";
      }
    }
  }
  [super touchesEnded:touches withEvent:event];
}

#pragma mark - UIAccessibilityContainer

- (BOOL)isAccessibilityElement {
  return NO;
}

- (NSInteger)accessibilityElementCount {
  return (NSInteger)_accessibilityElements.count;
}

- (id)accessibilityElementAtIndex:(NSInteger)index {
  return [_accessibilityElements objectAtIndex:(NSUInteger)index];
}

- (NSInteger)indexOfAccessibilityElement:(id)element {
  return (NSInteger)[_accessibilityElements indexOfObject:element];
}

@end
