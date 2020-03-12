//
//  KIFUIObject.h
//  KIF
//
//  Created by Alex Odawa on 1/26/15.
//
//

#import <UIKit/UIKit.h>

@interface KIFUIObject : NSObject

@property (nonatomic, weak, readonly) UIView *view;
@property (nonatomic, weak, readonly) UIAccessibilityElement *element;

- (instancetype)initWithElement:(UIAccessibilityElement *)element view:(UIView *)view;

@end
