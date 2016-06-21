/**
 * ADJSociomantic.m
 * Adjust
 *
 * Created by Nicolas Brugneaux on 17/02/15.
 * Copyright (c) 2015 Sociomantic Labs. All rights reserved.
 */

#import "ADJSociomantic.h"
#import "Adjust.h"
#import "ADJAdjustFactory.h"
#import "ADJLogger.h"

///----------------------------
/// @name Sociomantic Aliases
///----------------------------

NSString *const SCMCategory = @"category";
NSString *const SCMProductName = @"fn";
NSString *const SCMSalePrice = @"price";
NSString *const SCMAmount = @"amount";
NSString *const SCMCurrency = @"currency";
NSString *const SCMProductURL = @"url";
NSString *const SCMProductImageURL = @"photo";
NSString *const SCMBrand = @"brand";
NSString *const SCMDescription = @"description";
NSString *const SCMTimestamp = @"date";
NSString *const SCMValidityTimestamp = @"valid";
NSString *const SCMQuantity = @"quantity";
NSString *const SCMScore = @"score";
NSString *const SCMProductID = @"identifier";
NSString *const SCMActionConfirmed = @"confirmed";
NSString *const SCMCustomerAgeGroup = @"agegroup";
NSString *const SCMCustomerEducation = @"education";
NSString *const SCMCustomerGender = @"gender";
NSString *const SCMCustomerID = @"identifier";
NSString *const SCMCustomerMHash = @"mhash";
NSString *const SCMCustomerSegment = @"segment";
NSString *const SCMCustomerTargeting = @"targeting";


///----------------------------
/// @name Sociomantic Singleton
///----------------------------

/**
 * Object storing the state of the application and aliases for the sociomantic
 * events.
 */
@interface SCMSingleton : NSObject

/**
 * Immutable `NSDictionary` storing the aliases for stringification of the
 * tracking objects (product, basket, etc..).
 */
@property (nonatomic, strong) NSDictionary *properties;

/**
 * `NSString` storing the adpanId.
 */
@property (nonatomic, strong) NSString *adpanId;

/**
 * As the purpose of a Singleton is to be stateful, there is no `init` function
 * exposed. You can only get the existing instance of it (init is implicitly
 * called if the instance wasn't created).
 *
 * @return  `SCMSingleton`
 */
+ (SCMSingleton*)sharedClient;

@end

@implementation SCMSingleton

@synthesize properties;

+ (id)sharedClient
{
    static SCMSingleton *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[self alloc] init];
    });

    return _sharedClient;
}

- (id)init
{
    if ( self = [super init] )
    {
        properties =
        @{
            @"product" :
            @[
                SCMCategory,
                SCMProductName,
                SCMSalePrice,
                SCMAmount,
                SCMCurrency,
                SCMProductURL,
                SCMProductImageURL,
                SCMBrand,
                SCMDescription,
                SCMTimestamp,
                SCMValidityTimestamp,
                SCMQuantity,
                SCMScore
            ],
            @"basket" :
            @[
                SCMProductID,
                SCMAmount,
                SCMCurrency,
                SCMQuantity
            ],
            @"sale" :
            @[
                SCMAmount,
                SCMCurrency,
                SCMActionConfirmed
            ],
            @"lead" :
            @[
                SCMActionConfirmed
            ],
            @"customer" :
            @[
                SCMCustomerAgeGroup,
                SCMCustomerEducation,
                SCMCustomerGender,
                SCMCustomerID,
                SCMCustomerMHash,
                SCMCustomerSegment,
                SCMCustomerTargeting
            ]
        };

    }
    return self;
}
@end

///--------------------------------
/// @name Adjust Sociomantic Events
///--------------------------------

@implementation ADJSociomantic

+ (void)injectPartnerIdIntoSociomanticEvents:(NSString *) adpanId
{
    [SCMSingleton sharedClient].adpanId = adpanId;
}

+ (void)injectCustomerDataIntoEvent:(ADJEvent *)event
                           withData:(NSDictionary *)data
{
    NSArray *aliases            = [SCMSingleton sharedClient].properties[@"customer"];
    NSMutableDictionary * _data  = [NSMutableDictionary dictionary];
    id<ADJLogger> logger = [ADJAdjustFactory logger];

    [data enumerateKeysAndObjectsUsingBlock:
     ^(NSString *key, id value, BOOL* stop)
     {
         if (![aliases containsObject:key]) {
             [logger error:@"Key must correspond to a Sociomantic alias => [%@] see SCMAliases.h", key];
             return;
         }
         if (![value isKindOfClass:[NSString class]]) {
             [logger error:@"Customer Data must be NSString=> [%@] [%@]", value, [value class]];
         }

         _data[key] = value;
     }];

    NSString *dob = [ADJSociomantic stringifyAndEncode:_data];
    [ADJSociomantic addPartnerParameter:event parameter:@"socio_dob" value:dob];
}

+ (void)addPartnerParameter:(ADJEvent *)event
{
    [ADJSociomantic addPartnerParameter:event parameter:nil value:nil];
}

+ (void)addPartnerParameter:(ADJEvent *)event
                  parameter:(NSString *)parameterName
                      value:(NSString *)jsonValue
{
    if (nil == [SCMSingleton sharedClient].adpanId) {
        id<ADJLogger> logger = [ADJAdjustFactory logger];
        [logger error:@"The adpanId must be set before sending any sociomantic event. No parameter has been added"];
        return;
    }

    if (nil != parameterName && nil != jsonValue) {

        [event addPartnerParameter:parameterName value:jsonValue];
    }

    [event addPartnerParameter:@"socio_aid" value:[SCMSingleton sharedClient].adpanId];
}


+ (void)injectHomePageIntoEvent:(ADJEvent *)event
{
    [ADJSociomantic addPartnerParameter:event];
}


+ (void)injectViewListingIntoEvent:(ADJEvent *)event
                    withCategories:(NSArray *)categories
{
    [ADJSociomantic injectViewListingIntoEvent:event withCategories:categories withDate:nil];
}


+ (void)injectViewListingIntoEvent:(ADJEvent *)event
                    withCategories:(NSArray *)categories
                          withDate:(NSString *)date
{
    NSMutableDictionary* co = [NSMutableDictionary dictionary];

    co[SCMCategory] = [ADJSociomantic filterCategories:categories];

    if ( nil != date )
    {
        co[SCMTimestamp] = date;
    }

    NSString *jsonCo = [ADJSociomantic stringifyAndEncode:@{@"category":co}];
    [ADJSociomantic addPartnerParameter:event parameter:@"socio_co" value:jsonCo];
}


+ (void)injectViewProductIntoEvent:(ADJEvent *)event
                         productId:(NSString *)productId
{
    [ADJSociomantic injectViewProductIntoEvent:event productId:productId withParameters:nil];
}


+ (void)injectViewProductIntoEvent:(ADJEvent *)event
                         productId:(NSString *)productId
                    withParameters:(NSDictionary *)parameters
{
    NSArray *aliases                = [SCMSingleton sharedClient].properties[@"product"];
    NSMutableDictionary *product    = [NSMutableDictionary dictionary];

    product[SCMProductID] = productId;

    if ( nil != parameters )
    {
        [ADJSociomantic filter:parameters withAliases:aliases modifies:product ];
    }

    NSString *jsonPo = [ADJSociomantic stringifyAndEncode:@{@"products": @[product]}];
    [ADJSociomantic addPartnerParameter:event parameter:@"socio_po" value:jsonPo];
}


+ (void)injectCartIntoEvent:(ADJEvent *)event
                       cart:(NSArray *)products
{
    NSArray *aliases    = [SCMSingleton sharedClient].properties[@"basket"];
    NSMutableArray *po  = [NSMutableArray array];

    [products enumerateObjectsUsingBlock:
    ^(id product, NSUInteger idx, BOOL *stop)
    {
        NSMutableDictionary *_product = [NSMutableDictionary dictionary];

        if ( [product isKindOfClass:[NSString class]] )
        {
            _product[SCMProductID] = product;
        }
        else if ( [product isKindOfClass:[NSDictionary class]] )
        {
            [ADJSociomantic filter:product withAliases:aliases modifies:_product];
        }
        if ( 0 < _product.count )
        {
            [po addObject:_product];
        }
    }];

    if ( 0 < po.count )
    {
        NSString *jsonPo = [ADJSociomantic stringifyAndEncode:@{@"products":po}];
        [ADJSociomantic addPartnerParameter:event parameter:@"socio_po" value:jsonPo];
    }
}


+ (void)injectConfirmedTransactionIntoEvent:(ADJEvent *)event
                              transactionId:(NSString *)transactionID
                               withProducts:(NSArray *)products
{
    [ADJSociomantic injectConfirmedTransactionIntoEvent:event transactionId:transactionID withProducts:products withParameters:nil];
}

+ (void)injectConfirmedTransactionIntoEvent:(ADJEvent *)event
                              transactionId:(NSString *)transactionID
                               withProducts:(NSArray *)products
                             withParameters:(NSDictionary *)parameters
{
    [ADJSociomantic injectTransactionIntoEvent:event transactionId:transactionID withProducts:products withParameters:parameters andConfirmed:YES];
}

+ (void)injectTransactionIntoEvent:(ADJEvent *)event
                     transactionId:(NSString *)transactionID
                      withProducts:(NSArray *)products
{
    [ADJSociomantic injectTransactionIntoEvent:event transactionId:transactionID withProducts:products withParameters:nil andConfirmed:NO];
}

+ (void)injectTransactionIntoEvent:(ADJEvent *)event
                     transactionId:(NSString *)transactionID
                      withProducts:(NSArray *)products
                    withParameters:(NSDictionary *)parameters
{
    [ADJSociomantic injectTransactionIntoEvent:event transactionId:transactionID withProducts:products withParameters:parameters andConfirmed:NO];
}

+ (void)injectTransactionIntoEvent:(ADJEvent *)event
                     transactionId:(NSString *)transactionID
                      withProducts:(NSArray *)products
                    withParameters:(NSDictionary *)parameters
                      andConfirmed:(BOOL)confirmed
{
    NSArray *saleAliases    = [SCMSingleton sharedClient].properties[@"sale"];
    NSArray *basketAliases  = [SCMSingleton sharedClient].properties[@"basket"];

    NSMutableArray *po          = [NSMutableArray array];
    NSMutableDictionary *to     = [NSMutableDictionary dictionary];

    if ( nil != products )
    {
        [products enumerateObjectsUsingBlock:
        ^(id product, NSUInteger idx, BOOL *stop)
        {
            NSMutableDictionary *_product = [NSMutableDictionary dictionary];

            if ( [product isKindOfClass:[NSString class]] )
            {
                _product[SCMProductID] = product;
            }
            else if ( [product isKindOfClass:[NSDictionary class]] )
            {
                [ADJSociomantic filter:product withAliases:basketAliases modifies:_product];
            }
            if ( 0 < _product.count )
            {
                 [po addObject:_product];
            }
        }];

        NSString *jsonPo = [ADJSociomantic stringifyAndEncode:@{@"products":po}];
        [ADJSociomantic addPartnerParameter:event parameter:@"socio_po" value:jsonPo];
    }

    if ( nil != parameters )
    {
        [ADJSociomantic filter:parameters withAliases:saleAliases modifies:to];
    }

    if ( YES == confirmed )
    {
        to[SCMActionConfirmed] = @"true";
    }

    to[@"transaction"]  = transactionID;
    NSString *jsonTo    = [ADJSociomantic stringifyAndEncode:@{@"transaction":to}];
    [ADJSociomantic addPartnerParameter:event parameter:@"socio_to" value:jsonTo];

}

+ (void)injectLeadIntoEvent:(ADJEvent *)event
                     leadID:(NSString *)leadId
{
    [ADJSociomantic injectLeadIntoEvent:event leadID:leadId andConfirmed:NO];
}

+ (void)injectLeadIntoEvent:(ADJEvent *)event
                     leadID:(NSString *)leadID
               andConfirmed:(BOOL)confirmed
{
    NSMutableDictionary *to = [NSMutableDictionary dictionary];

    if ( YES == confirmed )
    {
        to[SCMActionConfirmed] = @"true";
    }

    to[@"transaction"]  = leadID;
    NSString *jsonTo    = [ADJSociomantic stringifyAndEncode:@{@"transaction":to}];
    [ADJSociomantic addPartnerParameter:event parameter:@"socio_to" value:jsonTo];
}

+ (NSArray*)filterCategories:(NSArray*)categories
{
    return [categories filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:
    ^BOOL(id category, NSDictionary *bindings)
    {
        if (![category isKindOfClass:[NSString class]]) {
            id<ADJLogger> logger = [ADJAdjustFactory logger];
            [logger error:@"Categories should only contains a string, failed on: [%@] type:[%@]", category, [category class]];
            return NO;
        }

        return [category isKindOfClass:[NSString class]];
    }]];
}

+ (void)filter:(NSDictionary*)parameters withAliases:(NSArray*)aliases modifies:(inout NSMutableDictionary*)result
{
    [parameters enumerateKeysAndObjectsUsingBlock:
     ^(NSString *key, id value, BOOL* stop)
     {
         if (![aliases containsObject:key]) {
             id<ADJLogger> logger = [ADJAdjustFactory logger];
             [logger error:@"Key must correspond to a Sociomantic alias => [%@] see SCMAliases.h", key];
             return;
         }

         if ( [aliases containsObject:key])
         {
             if ( [key isEqualToString:SCMCategory] )
             {
                 if ( [value isKindOfClass:[NSString class]] )
                 {
                     result[key] = @[value];
                 }
                 else if ( [value isKindOfClass:[NSArray class]] )
                 {
                     result[key] = [ADJSociomantic filterCategories:value];
                 }
             }
             else
             {
                 result[key] = value;
             }
         }
     }];
}

#pragma mark json helper

+ (NSString*)stringify:(NSObject*)object
{
    if ( nil == object )
    {
        return nil;
    }

    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object options:0 error:&error];

    if ( !jsonData || error )
    {
        id<ADJLogger> logger = [ADJAdjustFactory logger];
        [logger error:@"%@", [error debugDescription]];
        return @"{}";
    }
    else
    {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}

+ (NSString*) encode:(NSString*) unencodedString
{
    NSString *encoded = [unencodedString stringByReplacingOccurrencesOfString:@"\\/" withString:@"/"];
    return encoded;
}

+ (NSString*) stringifyAndEncode:(NSObject*) object
{
    return [ADJSociomantic encode:[ADJSociomantic stringify:object]];
}

@end
