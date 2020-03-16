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

#import "MainViewController.h"
#import "BasicViewController.h"

static NSString *gTableViewIdentifier = @"EarlGreyContribsMainVCTableViewID";

@interface MainViewController () <UITableViewDataSource,
                                  UITableViewDelegate,
                                  UIActionSheetDelegate>
@end

@implementation MainViewController {
  NSDictionary *_nameToControllerMap;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.tableview.delegate = self;
  self.tableview.dataSource = self;
  // Making the nav bar not translucent so it won't cover UI elements.
  [self.navigationController.navigationBar setTranslucent:NO];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.title = @"EarlGreyContribTestApp";
    _nameToControllerMap = @{
      @"Accessibility Views" : [NSNull null],
      @"Action Sheets" : [NSNull null],
      @"Activity Indicator Views" : [NSNull null],
      @"Alert Views" : [NSNull null],
      @"Animations" : [NSNull null],
      @"Basic Views" : [BasicViewController class],
      @"Collection Views": [NSNull null],
      @"Gesture Tests" : [NSNull null],
      @"Pinch Tests" : [NSNull null],
      @"Network Test" : [NSNull null],
      @"Picker Views" : [NSNull null],
      @"Presented Views" : [NSNull null],
      @"Rotated Views" : [NSNull null],
      @"Scroll Views" : [NSNull null],
      @"Slider Views" : [NSNull null],
      @"Table Views" : [NSNull null],
      @"Typing Views" : [NSNull null],
      @"Visibility Tests" : [NSNull null],
      @"Web Views" : [NSNull null],
    };
  }
  return self;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
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

  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
  [UIView setAnimationDuration:0.2];
  [self.navigationController pushViewController:vc animated:NO];
  [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight
                         forView:self.navigationController.view
                           cache:NO];
  [UIView commitAnimations];
}

@end
