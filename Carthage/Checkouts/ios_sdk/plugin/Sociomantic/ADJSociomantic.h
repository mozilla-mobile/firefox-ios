/**
 * ADJSociomantic.m
 * Adjust
 *
 * Created by Nicolas Brugneaux on 17/02/15.
 * Copyright (c) 2015 Sociomantic Labs. All rights reserved.
 */
#import <Foundation/Foundation.h>
#import "Adjust.h"

///----------------------------
/// @name Sociomantic Aliases
///----------------------------

extern NSString *const SCMCategory;
extern NSString *const SCMProductName;
extern NSString *const SCMSalePrice;
extern NSString *const SCMAmount;
extern NSString *const SCMCurrency;
extern NSString *const SCMProductURL;
extern NSString *const SCMProductImageURL;
extern NSString *const SCMBrand;
extern NSString *const SCMDescription;
extern NSString *const SCMTimestamp;
extern NSString *const SCMValidityTimestamp;
extern NSString *const SCMQuantity;
extern NSString *const SCMScore;
extern NSString *const SCMProductID;
extern NSString *const SCMAmount;
extern NSString *const SCMCurrency;
extern NSString *const SCMQuantity;
extern NSString *const SCMAmount;
extern NSString *const SCMCurrency;
extern NSString *const SCMActionConfirmed;
extern NSString *const SCMActionConfirmed;
extern NSString *const SCMCustomerAgeGroup;
extern NSString *const SCMCustomerEducation;
extern NSString *const SCMCustomerGender;
extern NSString *const SCMCustomerID;
extern NSString *const SCMCustomerMHash;
extern NSString *const SCMCustomerSegment;
extern NSString *const SCMCustomerTargeting;

///--------------------------------
/// @name Adjust Sociomantic Events
///--------------------------------

/**
 * Object exposing the different methods of the Sociomantic plugin for Adjust.
 */
@interface ADJSociomantic : NSObject

/**
 * Methods uses the given string, stores it into a singleton, it'll be injected into every
 * further sociomantic event.
 *
 * @param   event           `NSString`
 *
 * @return  `void`
 */
+ (void)injectPartnerIdIntoSociomanticEvents:(NSString *)adpanId;

/**
 * Methods uses the given dictionary, filters it and injects it into the event.
 *
 * @param   event           `ADJEvent`
 * @param   data            `NSDictionary`
 *
 * @return  `void`
 */
+ (void)injectCustomerDataIntoEvent:(ADJEvent *)event
                           withData:(NSDictionary *)data;


/**
 * Method makes sure the event has the adpanId into the event.
 *
 * @param   event           `ADJEvent`
 *
 * @return  `void`
 */
+ (void)addPartnerParameter:(ADJEvent *)event;


/**
 * Method makes sure the event has the adpanId into the event and injects the json 
 * value into the partner parameter.
 *
 * @param   event           `ADJEvent`
 *
 * @return  `void`
 */
+ (void)addPartnerParameter:(ADJEvent *)event
                  parameter:(NSString *)parameterName
                      value:(NSString *)jsonValue;

/**
 * Method injects a home page view into an Adjust event.
 *
 * @param   event           `ADJEvent`
 *
 * @return  `void`
 */
+ (void)injectHomePageIntoEvent:(ADJEvent *)event;


/**
 * Method injects a category page view into an Adjust event.
 *
 * Note: the category array will be filtered to only contain strings.
 *
 * @param   event           `ADJEvent`
 * @param   categories      `NSArray`
 *
 * @return  `void`
 */
+ (void)injectViewListingIntoEvent:(ADJEvent *)event
                    withCategories:(NSArray *)categories;

/**
 * Method injects a category page view into an Adjust event.
 *
 * Note: the category array will be filtered to only contain strings.
 *
 * @param   event           `ADJEvent`
 * @param   categories      `NSArray`
 * @param   date            `NSString`
 *
 * @return  `void`
 */
+ (void)injectViewListingIntoEvent:(ADJEvent *)event
                    withCategories:(NSArray *)categories
                          withDate:(NSString* )date;

/**
 * Method injects a product page view into an Adjust event.
 *
 * @param   event           `ADJEvent`
 * @param   productId       `NSString`
 *
 * @return  `void`
 */
+ (void)injectViewProductIntoEvent:(ADJEvent *)event
                         productId:(NSString *)productId;

/**
 * Method injects a product page view into an Adjust event.
 * Parameters dictionary will be filtered by keys and only keep the key-value
 * pairs where the key can be found in the
 * `SCMSingleton.properties[@"product"]` dictionary. These keys can be also
 * found in the file `SCMAliases.h`.
 *
 * @param   event           `ADJEvent`
 * @param   productId       `NSString`
 * @param   parameters      `NSDictionary`
 *
 * @return  `void`
 */
+ (void)injectViewProductIntoEvent:(ADJEvent *)event
                         productId:(NSString *)productId
                    withParameters:(NSDictionary *)parameters;

/**
 * Method injects a basket page view. The basket into an Adjust event.
 * used to create the request is the given array of products.
 * The array will be filtered according to the keys of
 * `SCMSingleton.properties[@"basket"]`.
 *
 * @param   event           `ADJEvent`
 * @param   products        `NSArray`
 *
 * @return  `void`
 */
+ (void)injectCartIntoEvent:(ADJEvent *)event
                       cart:(NSArray *)products;


/**
 * Method injects a confirmed sale page view into an Adjust event.
 * The array will be filtered according to the keys of
 * `SCMSingleton.properties[@"basket"]`.
 *
 * @param   event           `ADJEvent`
 * @param   transactionID   `NSString`
 * @param   products        `NSArray`
 *
 * @return  `void`
 */
+ (void)injectConfirmedTransactionIntoEvent:(ADJEvent *)event
                              transactionId:(NSString *)transactionID
                               withProducts:(NSArray *)products;

/**
 * Method injects a confirmed sale page view into an Adjust event.
 * The array will be filtered according to the keys of
 * `SCMSingleton.properties[@"basket"]`.
 * The same thing for the transaction option parameters, they are filtered
 * according to SCMSingleton.properties[@"sale"]`
 *
 * @param   event           `ADJEvent`
 * @param   transactionID   `NSString`
 * @param   products        `NSArray`
 * @param   parameters      `NSDictionary`
 *
 * @return  `void`
 */
+ (void)injectConfirmedTransactionIntoEvent:(ADJEvent *)event
                              transactionId:(NSString *)transactionID
                               withProducts:(NSArray *)products
                             withParameters:(NSDictionary *)parameters;

/**
 * Method injects a non-confirmed sale page view into an Adjust event.
 * The array will be filtered according to the keys of
 * `SCMSingleton.properties[@"basket"]`.
 * The same thing for the transaction option parameters, they are filtered
 * according to SCMSingleton.properties[@"sale"]`
 *
 * @param   event           `ADJEvent`
 * @param   transactionID   `NSString`
 * @param   products        `NSArray`
 *
 * @return  `void`
 */
+ (void)injectTransactionIntoEvent:(ADJEvent *)event
                     transactionId:(NSString *)transactionID
                      withProducts:(NSArray *)products;
/**
 * Method injects a sale page view into an Adjust event.
 * The array will be filtered according to the keys of
 * `SCMSingleton.properties[@"basket"]`.
 * The same thing for the transaction option parameters, they are filtered
 * according to SCMSingleton.properties[@"sale"]`
 *
 * @param   event           `ADJEvent`
 * @param   transactionID   `NSString`
 * @param   products        `NSArray`
 * @param   parameters      `NSDictionary`
 *
 * @return  `void`
 */
+ (void)injectTransactionIntoEvent:(ADJEvent *)event
                     transactionId:(NSString *)transactionID
                      withProducts:(NSArray *)products
                    withParameters:(NSDictionary *)parameters;

/**
 * Method injects a lead page into an Adjust event.
 *
 * @param   event           `ADJEvent`
 * @param   leadID          `NSString`
 *
 * @return  `void`
 */
+ (void)injectLeadIntoEvent:(ADJEvent *)event
                     leadID:(NSString *)transactionID;

/**
 * Method injects a lead page into an Adjust event.
 * It can be confirmed or not.
 *
 * @param   event           `ADJEvent`
 * @param   leadID          `NSString`
 *
 * @return  `void`
 */
+ (void)injectLeadIntoEvent:(ADJEvent *)event
                     leadID:(NSString *)transactionID
               andConfirmed:(BOOL)confirmed;

@end
