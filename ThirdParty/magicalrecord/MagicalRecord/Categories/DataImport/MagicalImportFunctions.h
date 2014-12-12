//
//  MagicalImportFunctions.h
//  Magical Record
//
//  Created by Saul Mora on 3/7/12.
//  Copyright (c) 2012 Magical Panda Software LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


NSDate * MR_adjustDateForDST(NSDate *date);
NSDate * MR_dateFromString(NSString *value, NSString *format);
NSDate * MR_dateFromNumber(NSNumber *value, BOOL milliseconds);
NSNumber * MR_numberFromString(NSString *value);
NSString * MR_attributeNameFromString(NSString *value);
NSString * MR_primaryKeyNameFromString(NSString *value);

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
UIColor * MR_colorFromString(NSString *serializedColor);
#else
#import <AppKit/AppKit.h>
NSColor * MR_colorFromString(NSString *serializedColor);
#endif

NSInteger* MR_newColorComponentsFromString(NSString *serializedColor);
extern id (*colorFromString)(NSString *);
