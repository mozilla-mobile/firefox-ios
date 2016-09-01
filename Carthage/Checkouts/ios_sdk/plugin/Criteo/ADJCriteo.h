//
//  ADJCriteoEvents.h
//
//
//  Created by Pedro Filipe on 06/02/15.
//
//

#import <Foundation/Foundation.h>
#import "ADJEvent.h"

@interface ADJCriteoProduct : NSObject

@property (nonatomic, assign) float criteoPrice;
@property (nonatomic, assign) NSUInteger criteoQuantity;
@property (nonatomic, copy) NSString *criteoProductID;

- (id) initWithId:(NSString*)productId
            price:(float)price
         quantity:(NSUInteger)quantity;

+ (ADJCriteoProduct *)productWithId:(NSString*)productId
                           price:(float)price
                        quantity:(NSUInteger)quantity;

@end

@interface ADJCriteo : NSObject

+ (void)injectViewListingIntoEvent:(ADJEvent *)event
                        productIds:(NSArray *)productIds
                        customerId:(NSString *)customerId;

+ (void)injectViewProductIntoEvent:(ADJEvent *)event
                         productId:(NSString *)productId
                        customerId:(NSString *)customerId;

+ (void)injectCartIntoEvent:(ADJEvent *)event
                   products:(NSArray *)products
                 customerId:(NSString *)customerId;

+ (void)injectTransactionConfirmedIntoEvent:(ADJEvent *)event
                                   products:(NSArray *)products
                              transactionId:(NSString *)transactionId
                                 customerId:(NSString *)customerId;

+ (void)injectUserLevelIntoEvent:(ADJEvent *)event
                         uiLevel:(NSUInteger)uiLevel
                      customerId:(NSString *)customerId;

+ (void)injectUserStatusIntoEvent:(ADJEvent *)event
                         uiStatus:(NSString *)uiStatus
                       customerId:(NSString *)customerId;

+ (void)injectAchievementUnlockedIntoEvent:(ADJEvent *)event
                             uiAchievement:(NSString *)uiAchievement
                                customerId:(NSString *)customerId;

+ (void)injectCustomEventIntoEvent:(ADJEvent *)event
                            uiData:(NSString *)uiData
                        customerId:(NSString *)customerId;

+ (void)injectCustomEvent2IntoEvent:(ADJEvent *)event
                            uiData2:(NSString *)uiData2
                            uiData3:(NSUInteger)uiData3
                         customerId:(NSString *)customerId;

+ (void)injectDeeplinkIntoEvent:(ADJEvent *)event
                            url:(NSURL *)url;

+ (void)injectHashedEmailIntoCriteoEvents:(NSString *)hashEmail;

+ (void)injectViewSearchDatesIntoCriteoEvents:(NSString *)checkInDate
                                checkOutDate:(NSString *)checkOutDate;

+ (void)injectPartnerIdIntoCriteoEvents:(NSString *)partnerId;

@end
