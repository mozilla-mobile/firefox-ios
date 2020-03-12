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

#import "FTRMainViewController.h"

#import "FTRAccessibilityViewController.h"
#import "FTRActionSheetViewController.h"
#import "FTRActivityIndicatorViewController.h"
#import "FTRAlertViewController.h"
#import "FTRAnimationViewController.h"
#import "FTRBasicViewController.h"
#import "FTRCollectionViewController.h"
#import "FTRGestureViewController.h"
#import "FTRImageViewController.h"
#import "FTRLayoutViewController.h"
#import "FTRMultiFingerSwipeGestureRecognizerViewController.h"
#import "FTRNetworkTestViewController.h"
#import "FTRPickerViewController.h"
#import "FTRPresentedViewController.h"
#import "FTRRotatedViewsViewController.h"
#import "FTRScrollViewController.h"
#import "FTRSliderViewController.h"
#import "FTRTableViewController.h"
#import "FTRTypingViewController.h"
#import "FTRVisibilityTestViewController.h"
#import "FTRWebViewController.h"

static NSString *gTableViewIdentifier = @"TableViewIdentifier";

@interface FTRMainViewController () <UITableViewDataSource,
                                     UITableViewDelegate,
                                     UIActionSheetDelegate>
@end

@implementation FTRMainViewController {
  NSDictionary *_nameToControllerMap;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.title = @"EarlGrey TestApp";
    // TODO: Clean this up so we have text to selector mapping instead of text to class
    // and text to [NSNull null] in some cases.
    _nameToControllerMap = @{
      @"Accessibility Views" : [FTRAccessibilityViewController class],
      @"Action Sheets" : [FTRActionSheetViewController class],
      @"Activity Indicator Views" : [FTRActivityIndicatorViewController class],
      @"Alert Views" : [FTRAlertViewController class],
      @"Animations" : [FTRAnimationViewController class],
      @"Basic Views" : [FTRBasicViewController class],
      @"Collection Views": [FTRCollectionViewController class],
      @"Gesture Tests" : [FTRGestureViewController class],
      @"Layout Tests" : [FTRLayoutViewController class],
      @"Pinch Tests" : [FTRImageViewController class],
      @"Network Test" : [FTRNetworkTestViewController class],
      @"Picker Views" : [FTRPickerViewController class],
      @"Presented Views" : [FTRPresentedViewController class],
      @"Rotated Views" : [FTRRotatedViewsViewController class],
      @"Scroll Views" : [FTRScrollViewController class],
      @"Slider Views" : [FTRSliderViewController class],
      @"Table Views" : [FTRTableViewController class],
      @"Typing Views" : [FTRTypingViewController class],
      @"Visibility Tests" : [FTRVisibilityTestViewController class],
      @"Web Views" : [FTRWebViewController class],
      @"Multi finger swipe gestures" : [FTRMultiFingerSwipeGestureRecognizerViewController class],
    };
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.tableview.delegate = self;
  self.tableview.dataSource = self;

  // Making the nav bar not translucent so it won't cover UI elements.
  [self.navigationController.navigationBar setTranslucent:NO];
}

// If we find that the orientation of the device / simulator is not
// UIDeviceOrientationPortrait, then for testing purposes, we rotate
// it to UIDeviceOrientationPortrait. However, the simulator itself
// tries to correct the orientation since we support all orientations
// in our test app. This removes the automated orientation correction.
- (BOOL)shouldAutorotate {
  return NO;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  NSAssert(section == 0, @"We have more than one section?");
  return (NSInteger)[_nameToControllerMap count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:gTableViewIdentifier];

  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:gTableViewIdentifier];
  }

  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  NSString *key = [_nameToControllerMap.allKeys objectAtIndex:(NSUInteger)indexPath.row];
  cell.textLabel.text = key;
  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  NSString *key = [_nameToControllerMap.allKeys objectAtIndex:(NSUInteger)indexPath.row];
  Class viewController = _nameToControllerMap[key];
  UIViewController *vc = [[viewController alloc] initWithNibName:NSStringFromClass(viewController)
                                                          bundle:nil];

  if ([key isEqualToString:@"Presented Views"]) {
    [self.navigationController presentViewController:vc animated:NO completion:nil];
  } else {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:0.2];
    [self.navigationController pushViewController:vc animated:NO];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight
                           forView:self.navigationController.view
                             cache:NO];
    [UIView commitAnimations];
  }
}

@end
