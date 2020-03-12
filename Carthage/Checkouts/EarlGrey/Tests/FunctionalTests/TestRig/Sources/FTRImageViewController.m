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

#import "FTRImageViewController.h"

@implementation FTRImageViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  UIImage *image = [UIImage imageNamed:@"Default.png"];
  UIImageView *imageView = (UIImageView *)self.view;
  // Add image from resource bundle to the image view.
  imageView.image = image;
  imageView.isAccessibilityElement = YES;
  imageView.accessibilityLabel = @"Image View";

  UIPinchGestureRecognizer *pinchRecognizer =
      [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(scaleImage:)];
  // Add pinchGestureRecognizer to the image view.
  [self.view addGestureRecognizer:pinchRecognizer];
}

#pragma mark - ImageView Handler

// Scales image relative to the touch point in the screen.
- (IBAction)scaleImage:(UIPinchGestureRecognizer *)recognizer {
  if (!CGRectIsEmpty(recognizer.view.frame)) {
    recognizer.view.transform = CGAffineTransformScale(recognizer.view.transform,
                                                       recognizer.scale,
                                                       recognizer.scale);
  } else {
    recognizer.view.transform = CGAffineTransformIdentity;
    CGRect zeroSizeFrame = recognizer.view.frame;
    zeroSizeFrame.size = CGSizeMake(0, 0);
    recognizer.view.frame = zeroSizeFrame;
  }
  recognizer.scale = 1.0;
}

@end
