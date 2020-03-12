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

#import "FTRSliderViewController.h"

#import <tgmath.h>

@implementation FTRSliderViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.title = @"Slider View Test";
  }
  return self;
}

- (instancetype)init {
  NSAssert(NO, @"Invalid Initializer");
  return nil;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.slider1.isAccessibilityElement = YES;
  self.slider1.accessibilityIdentifier = @"slider1";
  self.slider1.minimumValue = 0.0f;
  self.slider1.maximumValue = 1.0f;
  self.slider1.value = 0.7f;

  self.slider2.isAccessibilityElement = YES;
  self.slider2.accessibilityIdentifier = @"slider2";
  self.slider2.minimumValue = 3.3f;
  self.slider2.maximumValue = 27.25f;
  self.slider2.value = 10.2f;

  self.slider3.isAccessibilityElement = YES;
  self.slider3.accessibilityIdentifier = @"slider3";
  self.slider3.minimumValue = 0.0f;
  self.slider3.maximumValue = 3600.0f;
  self.slider3.value = 0.0f;

  self.slider4.isAccessibilityElement = YES;
  self.slider4.accessibilityIdentifier = @"slider4";
  self.slider4.minimumValue = 0.0f;
  self.slider4.maximumValue = 1000000.0f;
  self.slider4.value = 1.125f;

  self.slider5.isAccessibilityElement = YES;
  self.slider5.accessibilityIdentifier = @"slider5";
  self.slider5.minimumValue = 0.0f;
  self.slider5.maximumValue = 100.0f;
  self.slider5.value = 13.3f;

  self.slider6.isAccessibilityElement = YES;
  self.slider6.accessibilityIdentifier = @"slider6";
  self.slider6.minimumValue = 0.0f;
  self.slider6.maximumValue = 100.0f;
  self.slider6.value = 20.2f;

  self.sliderSnap.isAccessibilityElement = YES;
  self.sliderSnap.accessibilityIdentifier = @"sliderSnap";
  self.sliderSnap.minimumValue = 0;
  self.sliderSnap.maximumValue = 10.0f;
  self.sliderSnap.value = 0;
}

- (void)adjustSlider5Value {
  NSArray *steps = @[@0.0f, @10.4f, @25.6f, @60.3f, @100.0f];
  CGFloat currentValue = self.slider5.value;
  CGFloat valueToMoveTo = -1;
  CGFloat smallestDifference = 1000000.0f;
  for (NSNumber *number in steps) {
    CGFloat difference = (CGFloat)fabs([number floatValue] - currentValue);
    if (difference < smallestDifference) {
      smallestDifference = difference;
      valueToMoveTo = [number floatValue];
    }
  }
  self.slider5.value = (float)valueToMoveTo;
}

// IBAction for slider 5
- (IBAction)touchUpInside:(UISlider *)sender {
  [self adjustSlider5Value];
}

// IBAction for slider 5
- (IBAction)touchUpOutside:(UISlider *)sender {
  [self adjustSlider5Value];
}

- (IBAction)valueChanged:(UISlider *)sender {
  if (self.slider6 == sender) {
    float stepValue = 25.0f;
    float newStep = (float)round(self.slider6.value / stepValue);
    self.slider6.value = newStep * stepValue;
  } else if (self.sliderSnap == sender) {
    self.sliderSnap.value = (float)round(sender.value);
  }

  // For debugging purposes leaving it in.
  NSLog(@"Slider value changed to: %f", sender.value);
}

@end
