@import Foundation;

@protocol ButtonDeprecated <NSObject>

///-------------------------------------------
/// @name Order Reporting - FEATURE DEPRECATED
///-------------------------------------------

/**
 Reports an order to Button with line items.
 @param orderId An order identifier (required).
 @param currencyCode The ISO 4217 currency code. (default is USD).
 @param lineItems An array of BTNLineItem objects.
 */
- (void)reportOrderWithId:(nonnull NSString *)orderId
             currencyCode:(nonnull NSString *)currencyCode
                lineItems:(nonnull NSArray <BTNLineItem *> *)lineItems DEPRECATED_MSG_ATTRIBUTE("Please use our order API - https://www.usebutton.com/developers/api-reference/#create-order");


/**
 Reports an order to Button.
 @param orderValue The total order value in the smallest decimal unit for this currency (e.g. 3999 for $39.99).
 @param orderId An order identifier (required).
 @param currencyCode The ISO 4217 currency code. (default is USD).
 */
- (void)reportOrderWithValue:(NSInteger)orderValue
                     orderId:(nonnull NSString *)orderId
                currencyCode:(nonnull NSString *)currencyCode DEPRECATED_MSG_ATTRIBUTE("Please use our order API - https://www.usebutton.com/developers/api-reference/#create-order");

@end
