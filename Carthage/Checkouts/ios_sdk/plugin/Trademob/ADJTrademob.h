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
@property (nonatomic, copy) NSString *itemId;

- (instancetype) initWithId:(NSString *)itemId
            price:(float)price
         quantity:(NSUInteger)quantity;

@end

@interface ADJTrademob : NSObject

+ (void)injectViewListingIntoEvent:(ADJEvent *)event
                          itemIds:(NSArray *)itemIds
                          metadata:(NSDictionary *)metadata;

+ (void)injectViewItemIntoEvent:(ADJEvent *)event
                        itemId:(NSString *)itemId
                       metadata:(NSDictionary *)metadata;


+ (void)injectAddToBasketIntoEvent:(ADJEvent *)event
                         items:(NSArray *)items
                          metadata:(NSDictionary *)metadata;

+ (void)injectCheckoutIntoEvent:(ADJEvent *)event
                            items:(NSArray *)items
                       metadata:(NSDictionary *)metadata;

@end
