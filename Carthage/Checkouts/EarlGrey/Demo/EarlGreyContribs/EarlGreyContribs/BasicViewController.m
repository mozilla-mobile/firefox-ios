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

#import "BasicViewController.h"

@interface BasicViewController ()

@property(unsafe_unretained, nonatomic) IBOutlet UILabel *titleLabel;
@property(unsafe_unretained, nonatomic) IBOutlet UITextField *textField;
@property(unsafe_unretained, nonatomic) IBOutlet UIButton *button;
@property(unsafe_unretained, nonatomic) IBOutlet UILabel *textLabel;

@end

@implementation BasicViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self.button addTarget:self
                  action:@selector(changeTextLabel:)
        forControlEvents:UIControlEventTouchUpInside];
}

- (void)changeTextLabel:(UIButton*)button {
  self.textLabel.text = self.textField.text;
  self.textField.text = @"";
}


@end
