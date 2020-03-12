//
// Copyright 2017 Google Inc.
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

#import "FTRMultiFingerSwipeGestureRecognizerViewController.h"

@interface FTRMultiFingerSwipeGestureRecognizerViewController ()

@property(weak, nonatomic) IBOutlet UILabel *gestureRecognizedLabel;

@end

@implementation FTRMultiFingerSwipeGestureRecognizerViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.view.subviews[1].accessibilityIdentifier = @"gestureRecognizerBox";

  NSMutableArray *swipeGestureRecognizers = [[NSMutableArray alloc] init];

  NSArray *directions = @[
                          @(UISwipeGestureRecognizerDirectionRight),
                          @(UISwipeGestureRecognizerDirectionLeft),
                          @(UISwipeGestureRecognizerDirectionUp),
                          @(UISwipeGestureRecognizerDirectionDown),
                         ];
  for (NSNumber *direction in directions) {
    for (NSUInteger fingers = 1; fingers <= 4; fingers++) {
      UISwipeGestureRecognizer *swipeGesture =
          [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                    action:@selector(gestureRecognizedAction:)];
      swipeGesture.direction = (UISwipeGestureRecognizerDirection)direction.integerValue;
      swipeGesture.numberOfTouchesRequired = fingers;
      [swipeGestureRecognizers addObject:swipeGesture];

      [self.view.subviews[1] addGestureRecognizer:swipeGesture];
    }
  }
}

- (IBAction)gestureRecognizedAction:(UISwipeGestureRecognizer *)sender {
  NSString *direction;
  switch (sender.direction) {
    case UISwipeGestureRecognizerDirectionLeft:
      direction = @"Left";
      break;
    case UISwipeGestureRecognizerDirectionRight:
      direction = @"Right";
      break;
    case UISwipeGestureRecognizerDirectionUp:
      direction = @"Up";
      break;
    case UISwipeGestureRecognizerDirectionDown:
      direction = @"Down";
      break;
  }

  NSString *recognizerText =
      [NSString stringWithFormat:@"Swiped with %lu fingers %@",
                                 (unsigned long)sender.numberOfTouches, direction];
  self.gestureRecognizedLabel.text = recognizerText;
}

@end
