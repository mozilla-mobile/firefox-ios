 //
//  ADJTrademob.h
//  Adjust
//
//  Created by Davit Ohanyan on 9/14/15.
//  Copyright © 2015 adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ADJEvent.h"

@interface ADJTrademobItem : NSObject

@property (nonatomic, assign) float price;

@property (nonatomic, assign) NSUInteger quantity;

@property (nonatomic, copy, nullable) NSString *itemId;

- (nullable instancetype)initWithId:(nullable NSString *)itemId price:(float)price quantity:(NSUInteger)quantity;

@end

@interface ADJTrademob : NSObject

+ (void)injectViewListingIntoEvent:(nullable ADJEvent *)event
                           itemIds:(nullable NSArray *)itemIds
                          metadata:(nullable NSDictionary *)metadata;

+ (void)injectViewItemIntoEvent:(nullable ADJEvent *)event
                         itemId:(nullable NSString *)itemId
                       metadata:(nullable NSDictionary *)metadata;


+ (void)injectAddToBasketIntoEvent:(nullable ADJEvent *)event
                             items:(nullable NSArray *)items
                          metadata:(nullable NSDictionary *)metadata;

+ (void)injectCheckoutIntoEvent:(nullable ADJEvent *)event
                          items:(nullable NSArray *)items
                       metadata:(nullable NSDictionary *)metadata;

@end
