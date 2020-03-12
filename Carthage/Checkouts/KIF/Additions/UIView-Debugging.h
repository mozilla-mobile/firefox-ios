//
//  UIView+Debugging.h
//  KIF
//
//  Created by Graeme Arthur on 02/05/15.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIView (Debugging)
/*!
 @abstract Prints the view hiererchy, starting from the top window(s), along with accessibility information, which is more related to KIF than the usual information given by the 'description' method.
 */
+(void)printViewHierarchy;

/*!
 @abstract Prints the view hiererchy, starting from this view, along with accessibility information, which is more related to KIF than the usual information given by the 'description' method.
 */
-(void)printViewHierarchy;

@end
