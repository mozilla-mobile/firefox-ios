#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

/*! Used internally to obtain the receipt from a purchase
 * in the different iOS versions.
 */
@interface SwrveReceiptProviderResult : NSObject

@property (nonatomic, retain) NSString * encodedReceipt;        /*!< Base64 encoded receipt from Apple */
@property (nonatomic, retain) NSString * transactionId;         /*!< Transaction ID (must ONLY be populated for iOS7+) */

@end

/*! Used internally to take a transaction and return a base-64 encoded
 * version of the receipt for that transaction.
 *
 * The location of the receipt data and how to base-64 encode this data differs
 * between different versions of iOS.
 */
@interface SwrveReceiptProvider : NSObject

- (SwrveReceiptProviderResult*)obtainReceiptForTransaction:(SKPaymentTransaction*)transaction;
- (NSString*)base64encode:(NSData*)receipt;

@end
