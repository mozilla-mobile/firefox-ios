#import "BTNModelObject.h"

/**
 This class represents an order's individual line items. This is used for order attribution in
 `-[Button reportOrderWithValue:orderId:currencyCode:lineItems]`. 
 You can use these items to e.g. represent a cart of items, their ID, value and quantity 
 or to break down the order total to vat, discount etc.
 */

__attribute__((deprecated("Please use our order API - https://www.usebutton.com/developers/api-reference/#create-order")))
@interface BTNLineItem : BTNModelObject 

/// The identifier/sku for this line item (e.g. ‘sku-1234’). Must be unique from other line items.
@property (nullable, nonatomic, copy, readonly) NSString *identifier;


/// Per item cost in the smallest decimal unit for this currency (e.g. 199 for $1.99).
@property (nonatomic, assign, readonly) NSInteger amount;


/// The number of items of this type.
@property (nonatomic, assign, readonly) NSInteger quantity;


/// A name or description for this line item.
@property (nullable, nonatomic, copy, readonly) NSString *itemDescription;


/**
 Creates a line item with the specified identifier and amount with a quantity of 1.
 @param identifier The identifier/sku for this line item (e.g. ‘sku-1234’).
 @param amount Per item cost in the smallest decimal unit for this currency (e.g. 199 for $1.99).
 */
+ (nonnull instancetype)lineItemWithId:(nonnull NSString *)identifier
                                amount:(NSInteger)amount;


/**
 Creates a line item with the specified identifier, amount, and quantity.
 @param identifier The identifier/sku for this line item (e.g. ‘sku-1234’).
 @param amount Per item cost in the smallest decimal unit for this currency (e.g. 199 for $1.99).
 @param quantity The number of items of this type.
 */
+ (nonnull instancetype)lineItemWithId:(nonnull NSString *)identifier
                                amount:(NSInteger)amount
                              quantity:(NSInteger)quantity;


/**
 Creates a line item with the specified identifier, amount, quantity, and description.
 Examples:
 @code
 // 3 bottles of wine at 15.99 each
 BTNLineItem *lineItem = [BTNLineItem lineItemWithId:@"abc123"
                                              amount:1599 
                                            quantity:3
                                         description:@"Las Rocas"];
 
 @endcode
 @param identifier The identifier/sku for this line item (e.g. ‘sku-1234’).
 @param amount Per item cost in the smallest decimal unit for this currency (e.g. 199 for $1.99).
 @param quantity The number of items of this type.
 @param description A name or description for this item (optional).
 */
+ (nonnull instancetype)lineItemWithId:(nonnull NSString *)identifier
                                amount:(NSInteger)amount
                              quantity:(NSInteger)quantity
                           description:(nullable NSString *)description;


/**
 Each line item can have optional free form attributes associated with them.
 @param attribute The attribute value.
 @param key The key representing the attribute.
 */
- (void)addAttribute:(nonnull NSString *)attribute forKey:(nonnull NSString *)key;


/**
 The attributes associated with this line item.
 @return an NSDictionary of attributes.
 */
- (nullable NSDictionary *)attributes;

@end
