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

#import "FTRSplashViewController.h"

@implementation FTRSplashViewController

- (void)loadView {
  UIImage *splashImage;
  CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
      splashImage = [UIImage imageNamed:@"Default-Landscape.png"];
    } else {
      splashImage = [UIImage imageNamed:@"Default-Portrait.png"];
    }
  } else if (screenHeight == 736.0) {
    splashImage = [UIImage imageNamed:@"Default-736h.png"];
  } else if (screenHeight == 667.0) {
    splashImage = [UIImage imageNamed:@"Default-667h.png"];
  } else if (screenHeight == 568.0) {
    splashImage = [UIImage imageNamed:@"Default-568h.png"];
  } else {
    splashImage = [UIImage imageNamed:@"Default.png"];
  }

  UIImageView *imageView = [[UIImageView alloc] initWithImage:splashImage];
  [imageView setUserInteractionEnabled:YES];
  self.view = imageView;
}

@end
