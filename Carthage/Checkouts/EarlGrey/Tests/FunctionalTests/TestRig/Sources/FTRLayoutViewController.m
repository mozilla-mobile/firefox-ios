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

#import "FTRLayoutViewController.h"

@interface FTRLayoutViewController ()

@property(nonatomic, strong) UIView *elementView;
@property(nonatomic, strong) UIView *referenceElementView;

@property(nonatomic, assign) BOOL toggle;

@end

@implementation FTRLayoutViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  NSString *const kElementID = @"elementID";
  self.elementView = [[UIView alloc] init];
  self.elementView.accessibilityIdentifier = kElementID;
  self.elementView.backgroundColor = [UIColor colorWithRed:0 green:0.5f blue:0.8f alpha:1];

  NSString *const kReferenceElementID = @"referenceElementID";
  self.referenceElementView = [[UIView alloc] init];
  self.referenceElementView.accessibilityIdentifier = kReferenceElementID;
  self.referenceElementView.backgroundColor = [UIColor colorWithRed:0 green:0.8f blue:0.5f alpha:1];

  // Add to subview
  [self.view addSubview:self.elementView];
  [self.view addSubview:self.referenceElementView];

  // Set the accessibility identifier.
  self.topTextbox.accessibilityIdentifier = @"topTextbox";
  self.button.accessibilityIdentifier = @"button";
}

- (IBAction)clickedButton:(UIButton *)sender {
  CGRect frame = CGRectFromString(self.topTextbox.text);
  if (self.toggle) {
    [self.referenceElementView setFrame:frame];
  } else {
    [self.elementView setFrame:frame];
  }
  self.toggle = !self.toggle;
}

@end
