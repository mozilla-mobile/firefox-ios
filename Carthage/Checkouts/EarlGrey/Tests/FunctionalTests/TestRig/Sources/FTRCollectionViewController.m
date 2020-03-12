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

#import "FTRCollectionViewController.h"

#import "FTRCollectionViewCell.h"
#import "FTRCollectionViewLayout.h"

@interface FTRCollectionViewController ()

@property(nonatomic, strong) NSDictionary *layouts;
@property(nonatomic, strong) NSArray *incrementValues;
@end

@implementation FTRCollectionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    CGSize itemSize = CGSizeMake(70, 70);
    UIEdgeInsets insets = UIEdgeInsetsMake(5, 5, 5, 5);
    UICollectionViewFlowLayout *vertical = [[UICollectionViewFlowLayout alloc] init];
    [vertical setScrollDirection:UICollectionViewScrollDirectionVertical];
    [vertical setItemSize:itemSize];
    [vertical setSectionInset:insets];

    UICollectionViewFlowLayout *horizontal = [[UICollectionViewFlowLayout alloc] init];
    [horizontal setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    [horizontal setItemSize:itemSize];
    [horizontal setSectionInset:insets];

    FTRCollectionViewLayout *custom = [[FTRCollectionViewLayout alloc] init];
    [custom setGreyItemSize:itemSize];
    [custom setGreyItemMargin:5.0];
    _layouts = @{@"Custom Layout": custom,
                 @"Horizontal Layout": horizontal,
                 @"Vertical Layout": vertical};
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self.collectionView setDataSource:self];
  UINib *cellNib = [UINib nibWithNibName:@"FTRCollectionViewCell" bundle:nil];
  [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"FTRCollectionViewCell"];
  [self.collectionView setCollectionViewLayout:[self.layouts objectForKey:@"Horizontal Layout"]];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  // Prevent the pop gesture recognizer from triggering when collection view (that is very close to
  // the edge of the screen) is scrolled.
  for (UIGestureRecognizer *recognizer in self.collectionView.gestureRecognizers) {
    UIGestureRecognizer *navGestureRecognizer =
        self.navigationController.interactivePopGestureRecognizer;
    [navGestureRecognizer requireGestureRecognizerToFail:recognizer];
  }
}

#pragma mark - UICollectionViewDataSource Protocol

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
  // 26 is the total number of english characters, from A to Z.
  return (section == 0 ? 26 : 0);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  FTRCollectionViewCell *cell = [collectionView
      dequeueReusableCellWithReuseIdentifier:@"FTRCollectionViewCell" forIndexPath:indexPath];
  cell.backgroundColor = [UIColor whiteColor];
  [cell.alphaButton setTitle:[NSString stringWithFormat:@"%c", 'A' + (char)indexPath.row]
                    forState:UIControlStateNormal];
  return cell;
}

#pragma mark - UIPickerViewDataSource Protocol

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
  return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent :(NSInteger)component {
  if (component == 0) {
    return (NSInteger)[[self.layouts allKeys] count];
  }
  NSAssert(NO, @"invalid component number");
  return 0;
}

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component {
  if (component == 0) {
    return [[self.layouts allKeys] objectAtIndex:(NSUInteger)row];
  }
  NSAssert(NO, @"invalid component number");
  return nil;
}

#pragma mark - UIPickerViewDelegate Protocol

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
  return 30;
}

- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component {
  NSDictionary *layouts = self.layouts;
  NSAssert(0 <= row && row < (NSInteger)[[layouts allKeys] count], @"invalid row");
  id key = [[layouts allKeys] objectAtIndex:(NSUInteger)row];
  [self.collectionView setCollectionViewLayout:[layouts objectForKey:key] animated:YES];
}

@end
