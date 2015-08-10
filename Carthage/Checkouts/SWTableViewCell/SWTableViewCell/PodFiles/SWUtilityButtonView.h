//
//  SWUtilityButtonView.h
//  SWTableViewCell
//
//  Created by Matt Bowman on 11/27/13.
//  Copyright (c) 2013 Chris Wendel. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SWTableViewCell;

#define kUtilityButtonWidthDefault 90

@interface SWUtilityButtonView : UIView

- (id)initWithUtilityButtons:(NSArray *)utilityButtons parentCell:(SWTableViewCell *)parentCell utilityButtonSelector:(SEL)utilityButtonSelector;
- (id)initWithFrame:(CGRect)frame utilityButtons:(NSArray *)utilityButtons parentCell:(SWTableViewCell *)parentCell utilityButtonSelector:(SEL)utilityButtonSelector;

@property (nonatomic, weak, readonly) SWTableViewCell *parentCell;
@property (nonatomic, copy) NSArray *utilityButtons;
@property (nonatomic, assign) SEL utilityButtonSelector;

- (void)setUtilityButtons:(NSArray *)utilityButtons WithButtonWidth:(CGFloat)width;
- (void)pushBackgroundColors;
- (void)popBackgroundColors;

@end
