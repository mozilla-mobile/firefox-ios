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

#import <UIKit/UIKit.h>

// Empty AppDelegate for hosting unit tests.
@interface GREYUTAppDelegate : NSObject<UIApplicationDelegate>

@property(strong, nonatomic) UIWindow *window;

@end

@implementation GREYUTAppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  self.window = [[UIWindow alloc] init];

  UILabel *runningTestsLabel = [[UILabel alloc] initWithFrame:self.window.frame];
  runningTestsLabel.backgroundColor = [UIColor whiteColor];
  runningTestsLabel.textColor = [UIColor blackColor];
  runningTestsLabel.text = @"Running unit tests...";

  UIViewController *rootVC = [[UIViewController alloc] init];
  rootVC.view = runningTestsLabel;
  self.window.rootViewController = rootVC;
  [self.window makeKeyAndVisible];

  return YES;
}

@end

int main(int argc, char *argv[]) {
  @autoreleasepool {
    return UIApplicationMain(argc, argv, nil, NSStringFromClass([GREYUTAppDelegate class]));
  }
}

