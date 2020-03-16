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

#import "FTRScrollViewController.h"

// A custom, square UIView that contains accessibility elements.
// For testing scrolling to AX elements.
@interface SquareAccessibleView : UIView
@end

@implementation SquareAccessibleView {
  UIAccessibilityElement *_squareElement;
  CGRect _squareFrameRect;
  NSArray *_accessibilityElements;
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self initialize];
  }
  return self;
}

- (void)initialize {
  _squareFrameRect = CGRectMake(0, 0, 20, 20);

  UIAccessibilityTraits elementTraits =
      UIAccessibilityTraitButton | UIAccessibilityTraitStaticText;
  _squareElement = [[UIAccessibilityElement alloc] initWithAccessibilityContainer:self];
  [_squareElement setAccessibilityTraits:elementTraits];
  [_squareElement setAccessibilityLabel:@"SquareElementLabel"];
  [_squareElement setAccessibilityIdentifier:@"SquareElementIdentifier"];

  _accessibilityElements = @[ _squareElement, ];
}

- (CGPoint)accessibilityActivationPoint {
  CGRect frameInScreenCoordinates = UIAccessibilityConvertFrameToScreenCoordinates(self.frame,
                                                                                   self);
  return CGPointMake(CGRectGetMidX(frameInScreenCoordinates),
                     CGRectGetMidY(frameInScreenCoordinates));
}

- (void)layoutSubviews {
  [super layoutSubviews];

  CGRect squareElementOnScreenRect =
      UIAccessibilityConvertFrameToScreenCoordinates(_squareFrameRect, self);
  [_squareElement setAccessibilityFrame:squareElementOnScreenRect];
}

- (void)drawRect:(CGRect)rect {
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSaveGState(context);

  CGContextSetRGBFillColor(context, 1, 0, 0, 1);
  CGContextFillRect(context, _squareFrameRect);

  CGContextRestoreGState(context);
  [super drawRect:rect];
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

@implementation FTRScrollViewController {
  SquareAccessibleView *_squareView;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.title = @"Scroll View Test";
  }
  return self;
}

- (instancetype)init {
  NSAssert(NO, @"Invalid Initializer");
  return nil;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.scrollview.isAccessibilityElement = YES;
  self.scrollview.accessibilityLabel = @"Upper Scroll View";

  self.bottomScrollView.isAccessibilityElement = YES;
  self.bottomScrollView.accessibilityLabel = @"Bottom Scroll View";
  self.bottomScrollView.backgroundColor = [UIColor lightGrayColor];

  // Named infinite scroll because this scroll view verifies a bug in scroll algorithm that causes
  // infinite scrolling.
  self.infiniteScrollView.isAccessibilityElement = YES;
  self.infiniteScrollView.accessibilityLabel = @"Infinite Scroll View";
  self.infiniteScrollView.backgroundColor = [UIColor lightGrayColor];
  self.infiniteScrollView.delegate = self;

  _squareView = [[SquareAccessibleView alloc] initWithFrame:CGRectMake(10, 160, 20, 20)];
  [self.scrollview addSubview:_squareView];
  self.scrollview.delegate = self;
  self.topTextbox.delegate = self;

  // Required to disable the swipe from edge to go back gesture as it can interfere with tests.
  [self.navigationItem setHidesBackButton:YES animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  // Enable the swipe from edge to go back gesture.
  [self.navigationItem setHidesBackButton:NO animated:NO];
}

- (IBAction)insetsOverrideToggled:(UISwitch *)sender {
  if ([sender isOn]) {
    [self.scrollview setContentInset:UIEdgeInsetsFromString(self.topTextbox.text)];
  } else {
    [self.scrollview setContentInset:UIEdgeInsetsZero];
  }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  self.topTextbox.text = NSStringFromCGPoint(scrollView.contentOffset);
  [_squareView setNeedsLayout];
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return NO;
}

@end
