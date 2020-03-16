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

#import "FTRGestureViewController.h"

@implementation FTRGestureViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.greyBox.isAccessibilityElement = YES;
  self.greyBox.accessibilityLabel = @"Grey Box";
  self.detectedGestureCoordinate.text = nil;

  // Tap gesture recognizers.
  for (NSUInteger touches = 1; touches < 5; ++touches) {
    UIGestureRecognizer *previousRecognizer = nil;
    for (NSUInteger taps = 1; taps < 5; ++taps) {
      UITapGestureRecognizer *tapRecognizer =
          [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(recognizeTap:)];
      tapRecognizer.numberOfTapsRequired = taps;
      tapRecognizer.numberOfTouchesRequired = touches;
      [self.greyBox addGestureRecognizer:tapRecognizer];

      // We should only recognize a single tap if the double tap recognizer fails, we should only
      // recognize a double tap if the triple tap recognizer fails, etc.
      if (previousRecognizer) {
        [previousRecognizer requireGestureRecognizerToFail:tapRecognizer];
      }
      previousRecognizer = tapRecognizer;
    }
  }

  // Long press gesture recognizers.
  for (NSUInteger touches = 1; touches < 5; ++touches) {
    for (NSUInteger taps = 0; taps < 4; ++taps) {
      UILongPressGestureRecognizer *longPressRecognizer =
          [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                        action:@selector(recognizeLongPress:)];
      longPressRecognizer.numberOfTapsRequired = taps;
      longPressRecognizer.numberOfTouchesRequired = touches;
      [self.greyBox addGestureRecognizer:longPressRecognizer];
    }
  }

  // Swipe gesture recognizers.
  UISwipeGestureRecognizerDirection swipeDirections[4] = {
    UISwipeGestureRecognizerDirectionLeft,
    UISwipeGestureRecognizerDirectionRight,
    UISwipeGestureRecognizerDirectionUp,
    UISwipeGestureRecognizerDirectionDown
  };
  for (NSUInteger touches = 1; touches < 5; ++touches) {
    for (NSUInteger direction = 0; direction < 4; ++direction) {
      UISwipeGestureRecognizer *swipeRecognizer =
          [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(recognizeSwipe:)];
      swipeRecognizer.numberOfTouchesRequired = touches;
      swipeRecognizer.direction = swipeDirections[direction];
      [self.greyBox addGestureRecognizer:swipeRecognizer];

      UISwipeGestureRecognizer *windowSwipeRecognizer =
          [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                    action:@selector(recognizeWindowSwipe:)];
      windowSwipeRecognizer.numberOfTouchesRequired = touches;
      windowSwipeRecognizer.direction = swipeDirections[direction];
      UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
      [window addGestureRecognizer:windowSwipeRecognizer];
    }
  }

  // Pan gesture recognizer.
  UIPanGestureRecognizer *panRecognizer =
      [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(recognizePan:)];
  panRecognizer.minimumNumberOfTouches = 2;
  [self.greyBox addGestureRecognizer:panRecognizer];

  // Rotation gesture recognizer.
  UIRotationGestureRecognizer *rotationRecognizer =
      [[UIRotationGestureRecognizer alloc] initWithTarget:self
                                                   action:@selector(recognizeRotation:)];
  [self.greyBox addGestureRecognizer:rotationRecognizer];

  // Pinch gesture recognizer.
  UIPinchGestureRecognizer *pinchRecognizer =
      [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(recognizePinch:)];
  [self.greyBox addGestureRecognizer:pinchRecognizer];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
}

- (IBAction)recognizeSwipe:(UISwipeGestureRecognizer *)recognizer {
  self.detectedGesture.text = [NSString stringWithFormat:@"%@swipe %@",
      [FTRGestureViewController stringForFingerCount:recognizer.numberOfTouchesRequired],
      [FTRGestureViewController stringFromSwipeDirection:recognizer.direction]];
  self.detectedGestureCoordinate.text =
      [FTRGestureViewController stringForPoint:[recognizer locationInView:self.greyBox]];
}

- (IBAction)recognizeWindowSwipe:(UISwipeGestureRecognizer *)recognizer {
  NSString *directionString =
      [FTRGestureViewController stringFromSwipeDirection:recognizer.direction];

  self.detectedWindowGesture.text =
      [NSString stringWithFormat:@"swipe %@ on window", directionString];
}

- (IBAction)recognizeTap:(UITapGestureRecognizer *)recognizer {
  self.detectedGesture.text = [NSString stringWithFormat:@"%@%@ tap",
      [FTRGestureViewController stringForFingerCount:recognizer.numberOfTouchesRequired],
      [FTRGestureViewController stringForRepetitionCount:recognizer.numberOfTapsRequired]];

  CGPoint tapPoint = [recognizer locationInView:self.greyBox];
  self.detectedGestureCoordinate.text = [FTRGestureViewController stringForPoint:tapPoint];
}

- (IBAction)recognizeLongPress:(UILongPressGestureRecognizer *)recognizer {
  // numberOfTapsRequired means the number of taps before the long press itself.
  self.detectedGesture.text = [NSString stringWithFormat:@"%@%@ long press",
      [FTRGestureViewController stringForFingerCount:recognizer.numberOfTouchesRequired],
      [FTRGestureViewController stringForRepetitionCount:recognizer.numberOfTapsRequired + 1]];
}

- (IBAction)recognizePan:(UIPanGestureRecognizer *)recognizer {
  if (recognizer.numberOfTouches >= recognizer.minimumNumberOfTouches) {
    self.detectedGesture.text = [NSString stringWithFormat:@"%@pan",
        [FTRGestureViewController stringForFingerCount:recognizer.numberOfTouches]];
  }
  if ([recognizer state] == UIGestureRecognizerStateBegan
      || [recognizer state] == UIGestureRecognizerStateChanged) {
    [recognizer view].transform = CGAffineTransformTranslate([recognizer view].transform,
        [recognizer translationInView:[recognizer view]].x,
        [recognizer translationInView:[recognizer view]].y);
    [recognizer setTranslation:CGPointZero inView:[recognizer view]];
  }
}

- (IBAction)recognizeRotation:(UIRotationGestureRecognizer *)recognizer {
  [self adjustAnchorPointForGestureRecognizer:recognizer];

  if (recognizer.rotation > 0) {
    self.detectedGesture.text = @"rotate clockwise";
  } else if (recognizer.rotation < 0) {
    self.detectedGesture.text = @"rotate counterclockwise";
  }

  if ([recognizer state] == UIGestureRecognizerStateBegan
      || [recognizer state] == UIGestureRecognizerStateChanged) {
    [recognizer view].transform = CGAffineTransformRotate([[recognizer view] transform],
                                                          [recognizer rotation]);
    [recognizer setRotation:0];
  }
}

- (IBAction)recognizePinch:(UIPinchGestureRecognizer *)recognizer {
  [self adjustAnchorPointForGestureRecognizer:recognizer];

  if (recognizer.scale < 1.0) {
    self.detectedGesture.text = @"pinch in";
  } else if (recognizer.scale > 1.0) {
    self.detectedGesture.text = @"pinch out";
  }

  if ([recognizer state] == UIGestureRecognizerStateBegan
      || [recognizer state] == UIGestureRecognizerStateChanged) {
    [recognizer view].transform = CGAffineTransformScale([[recognizer view] transform],
                                                         [recognizer scale],
                                                         [recognizer scale]);
    [recognizer setScale:1];
  }
}

- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)recognizer {
  if (recognizer.state == UIGestureRecognizerStateBegan) {
    UIView *piece = recognizer.view;
    CGPoint locationInView = [recognizer locationInView:piece];
    CGPoint locationInSuperview = [recognizer locationInView:piece.superview];
    piece.layer.anchorPoint = CGPointMake(locationInView.x / piece.bounds.size.width,
                                          locationInView.y / piece.bounds.size.height);
    piece.center = locationInSuperview;
  }
}

+ (NSString *)stringForFingerCount:(NSUInteger)fingers {
  switch (fingers) {
    case 1:
      return @"";
    case 2:
      return @"two finger ";
    case 3:
      return @"three finger ";
    case 4:
      return @"four finger ";
  }
  NSAssert(NO, @"Invalid number of fingers");
  return @"invalid finger count ";
}

+ (NSString *)stringForRepetitionCount:(NSUInteger)repetitions {
  switch (repetitions) {
    case 1:
      return @"single";
    case 2:
      return @"double";
    case 3:
      return @"triple";
    case 4:
      return @"quadruple";
  }
  NSAssert(NO, @"Invalid number of repetitions");
  return @"invalid repetition count ";
}

+ (NSString *)stringFromSwipeDirection:(UISwipeGestureRecognizerDirection)direction {
  switch (direction) {
    case UISwipeGestureRecognizerDirectionLeft:
      return @"left";
    case UISwipeGestureRecognizerDirectionRight:
      return @"right";
    case UISwipeGestureRecognizerDirectionUp:
      return @"up";
    case UISwipeGestureRecognizerDirectionDown:
      return @"down";
  }
}

+ (NSString *)stringForPoint:(CGPoint)point {
  return [NSString stringWithFormat:@"x:%.1f - y:%.1f", point.x, point.y];
}

@end
