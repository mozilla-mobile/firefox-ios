//
//  CollectionViewController.m
//  Test Suite
//
//  Created by Tony Mann on 11/5/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

@interface CollectionViewCell : UICollectionViewCell
@property (strong, nonatomic) IBOutlet UILabel *label;
@end

@implementation CollectionViewCell
@end

@interface CollectionViewController : UICollectionViewController
@end

@implementation CollectionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self.collectionView registerClass:[CollectionViewCell class] forCellWithReuseIdentifier:@"CollectionViewCell"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 200;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"CollectionViewCell" forIndexPath:indexPath];
    
    if (indexPath.item == 0) {
        cell.accessibilityLabel = @"First Cell";
        cell.label.text = @"First";
    } else if (indexPath.item == [collectionView numberOfItemsInSection:indexPath.section] - 1) {
        cell.accessibilityLabel = @"Last Cell";
        cell.label.text = @"Last";
    } else {
        cell.accessibilityLabel = @"Filler";
        cell.label.text = @"Filler";
    }
    
    return cell;
}

@end
