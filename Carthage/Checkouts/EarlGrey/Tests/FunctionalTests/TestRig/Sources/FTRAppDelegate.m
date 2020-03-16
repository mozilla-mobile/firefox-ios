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

#import "FTRAppDelegate.h"

#import "FTRMainViewController.h"
#import "FTRSplashViewController.h"

// This class was created to override UINavigationController's default orientation mask
// to allow TestApp interface to rotate to all orientations including upside down.
@interface FTRAllOrientationsNavigationController : UINavigationController
@end

@implementation FTRAllOrientationsNavigationController

#if defined(__IPHONE_9_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0)
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskAll;
}
#else
- (NSUInteger)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskAll;
}
#endif // defined(__IPHONE_9_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0)

@end

@implementation FTRAppDelegate

- (void)resetRootNavigationController {
  UIViewController *vc = [[FTRMainViewController alloc] initWithNibName:@"FTRMainViewController"
                                                                 bundle:nil];
  UINavigationController *nav = (UINavigationController *)self.window.rootViewController;
  nav.viewControllers = @[ vc ];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)opt {
  // Shows a custom splash screen.
  FTRSplashViewController *splashVC = [[FTRSplashViewController alloc] init];
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  self.window.rootViewController = splashVC;
  [self.window makeKeyAndVisible];

  NSTimeInterval splashScreenDuration = 0.5;
  NSLog(@"Scheduling timer to fire in %g seconds.", splashScreenDuration);
  [NSTimer scheduledTimerWithTimeInterval:splashScreenDuration
                                   target:self
                                 selector:@selector(hideSpashScreenAndDisplayMainViewController)
                                 userInfo:nil
                                  repeats:NO];
  return YES;
}

- (void)hideSpashScreenAndDisplayMainViewController {
  NSLog(@"Timer fired! Removing splash screen.");
  UIViewController *vc = [[FTRMainViewController alloc] initWithNibName:@"FTRMainViewController"
                                                                 bundle:nil];
  UINavigationController *nav =
      [[FTRAllOrientationsNavigationController alloc] initWithRootViewController:vc];
  [UIView transitionWithView:self.window
                    duration:0.2
                     options:UIViewAnimationOptionTransitionFlipFromLeft
                  animations:^{
                    self.window.rootViewController = nav;
                  }
                  completion:nil];
}

@end
