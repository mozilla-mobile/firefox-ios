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

#import "FTRTableViewController.h"

static NSString *gTableViewIdentifier = @"TableViewCellReuseIdentifier";

@implementation FTRTableViewController {
  NSMutableArray *_rowIndicesRemoved;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  _rowIndicesRemoved = [[NSMutableArray alloc] init];

  self.mainTableView.accessibilityIdentifier = @"main_table_view";
  self.mainTableView.dataSource = self;
  self.insetsValue.delegate = self;
}

- (IBAction)insetsToggled:(UISwitch *)sender {
  if ([sender isOn]) {
    [self.mainTableView setContentInset:UIEdgeInsetsFromString(self.insetsValue.text)];
  } else {
    [self.mainTableView setContentInset:UIEdgeInsetsZero];
  }
}

#pragma mark - UITableViewDataSource

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  return YES;
}

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    [_rowIndicesRemoved addObject:@(indexPath.row)];
    [tableView deleteRowsAtIndexPaths:@[ indexPath ]
                     withRowAnimation:UITableViewRowAnimationAutomatic];
  }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return 100 - (NSInteger)_rowIndicesRemoved.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
       cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:gTableViewIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:gTableViewIdentifier];
  }

  NSInteger row = indexPath.row;
  for (NSNumber *number in _rowIndicesRemoved) {
    if ([number integerValue] <= row) {
      row++;
    }
  }

  cell.textLabel.text = [NSString stringWithFormat:@"Row %zd", row];
  return cell;
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return NO;
}

@end
