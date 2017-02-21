#import "BTNModelObject.h"
@class BTNCustomer;

@interface BTNSession : BTNModelObject

@property (nullable, nonatomic, copy) NSString    *sessionId;
@property (nullable, nonatomic, copy) BTNCustomer *customer;

/// An optional sourceToken returned from a session. This is transient.
@property (nullable, nonatomic, copy) NSString *sourceToken;

///---------------
/// @name Equality
///---------------

/**
 Returns a Boolean value that indicates whether a given BTNSession is equal to the receiver.
 @param session The BTNSession with which to compare to the receiver.
 @return YES if the BTNSession is equivalent to the receiver.
 */
- (BOOL)isEqualToSession:(nonnull BTNSession *)session;

@end
