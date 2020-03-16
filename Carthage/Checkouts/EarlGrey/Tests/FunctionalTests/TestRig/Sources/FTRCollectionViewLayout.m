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

#import "FTRCollectionViewLayout.h"

@implementation FTRCollectionViewLayout

- (NSInteger)grey_itemsPerSide {
  return (NSInteger)(1 + sqrt([self.collectionView numberOfItemsInSection:0]));
}

// Cell = Item + margins.
- (CGSize)grey_cellSize {
  return CGSizeMake(self.greyItemSize.width + self.greyItemMargin * 2,
                    self.greyItemSize.height + self.greyItemMargin * 2);
}

- (UICollectionViewLayoutAttributes *)grey_layoutAttributesForChar:(char)aChar {
  const NSInteger itemsPerSide = [self grey_itemsPerSide];
  if (itemsPerSide == 0 || toupper(aChar) < 'A' || toupper(aChar) > 'Z') {
    return nil;
  }

  NSInteger charIndex = aChar - 'A';
  // Compute the char's position from its index. The chars are laid out in a grid of size W X H
  // where W and H are itemsPerSide.
  NSInteger xIndex = charIndex % itemsPerSide;
  NSInteger yIndex = charIndex / itemsPerSide;
  CGSize cellSize = [self grey_cellSize];
  CGPoint itemPosition = CGPointMake(self.greyItemMargin + xIndex * cellSize.width,
                                     self.greyItemMargin + yIndex * cellSize.height);

  // Create and return a UICollectionViewLayoutAttributes object after filling its frame and bounds
  // attributes.
  NSIndexPath *cellIndexPath = [NSIndexPath indexPathForItem:charIndex inSection:0];
  UICollectionViewLayoutAttributes *attributes =
      [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:cellIndexPath];
  attributes.frame = CGRectMake(itemPosition.x, itemPosition.y,
                                self.greyItemSize.width, self.greyItemSize.height);
  attributes.bounds = CGRectMake(0, 0, self.greyItemSize.width, self.greyItemSize.height);
  return attributes;
}

#pragma mark - UICollectionViewLayout Methods

- (CGSize)collectionViewContentSize {
  CGSize cellSize = [self grey_cellSize];
  const NSInteger itemsPerSide = [self grey_itemsPerSide];
  return CGSizeMake(itemsPerSide * cellSize.width,
                    itemsPerSide * cellSize.height);
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
  NSMutableArray *array = [[NSMutableArray alloc] init];
  for (char aChar = 'A'; aChar <= 'Z'; aChar++) {
    UICollectionViewLayoutAttributes *attributes = [self grey_layoutAttributesForChar:aChar];
    if (CGRectIntersectsRect(attributes.frame, rect)) {
      [array addObject:attributes];
    }
  }
  return array;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
  return [self grey_layoutAttributesForChar:(char)('A' + indexPath.row)];
}

@end
