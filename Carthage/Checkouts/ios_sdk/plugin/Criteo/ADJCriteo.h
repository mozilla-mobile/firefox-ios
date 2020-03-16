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

@property (nonatomic, copy, nullable) NSString *criteoProductID;

- (nullable id)initWithId:(nullable NSString *)productId price:(float)price quantity:(NSUInteger)quantity;

+ (nullable ADJCriteoProduct *)productWithId:(nullable NSString *)productId price:(float)price quantity:(NSUInteger)quantity;

@end

@interface ADJCriteo : NSObject

+ (void)injectPartnerIdIntoCriteoEvents:(nullable NSString *)partnerId;

+ (void)injectCustomerIdIntoCriteoEvents:(nullable NSString *)customerId;

+ (void)injectHashedEmailIntoCriteoEvents:(nullable NSString *)hashEmail;

+ (void)injectUserSegmentIntoCriteoEvents:(nullable NSString *)userSegment;

+ (void)injectDeeplinkIntoEvent:(nullable ADJEvent *)event url:(nullable NSURL *)url;

+ (void)injectCartIntoEvent:(nullable ADJEvent *)event products:(nullable NSArray *)products;

+ (void)injectUserLevelIntoEvent:(nullable ADJEvent *)event uiLevel:(NSUInteger)uiLevel;

+ (void)injectCustomEventIntoEvent:(nullable ADJEvent *)event uiData:(nullable NSString *)uiData;

+ (void)injectUserStatusIntoEvent:(nullable ADJEvent *)event uiStatus:(nullable NSString *)uiStatus;

+ (void)injectViewProductIntoEvent:(nullable ADJEvent *)event productId:(nullable NSString *)productId;

+ (void)injectViewListingIntoEvent:(nullable ADJEvent *)event productIds:(nullable NSArray *)productIds;

+ (void)injectAchievementUnlockedIntoEvent:(nullable ADJEvent *)event uiAchievement:(nullable NSString *)uiAchievement;

+ (void)injectViewSearchDatesIntoCriteoEvents:(nullable NSString *)checkInDate checkOutDate:(nullable NSString *)checkOutDate;

+ (void)injectCustomEvent2IntoEvent:(nullable ADJEvent *)event uiData2:(nullable NSString *)uiData2 uiData3:(NSUInteger)uiData3;

+ (void)injectTransactionConfirmedIntoEvent:(nullable ADJEvent *)event
                                   products:(nullable NSArray *)products
                              transactionId:(nullable NSString *)transactionId
                                newCustomer:(nullable NSString *)newCustomer;

@end
