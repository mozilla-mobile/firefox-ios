@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@protocol BTNSubscriptable <NSObject>

///--------------------------
/// @name Object Subscripting
///--------------------------


/**
 Add key-value pairs with subscripting syntax:
 @code object[key] = value; @endcode
 */
- (void)setObject:(nullable id)obj forKeyedSubscript:(NSString *)key;


/**
 Retrieve previously stored values with subscripting syntax:
 @code id value = object[key]; @endcode
 */
- (nullable id)objectForKeyedSubscript:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
