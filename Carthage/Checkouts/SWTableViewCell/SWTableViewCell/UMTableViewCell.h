//
//  UMTableViewCell.h
//  SWTableViewCell
//
//  Created by Matt Bowman on 12/2/13.
//  Copyright (c) 2013 Chris Wendel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWTableViewCell.h"

/*
 *  Example of a custom cell built in Storyboard
 */
@interface UMTableViewCell : SWTableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UILabel *label;

@end
