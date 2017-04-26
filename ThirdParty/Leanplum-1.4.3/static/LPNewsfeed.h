//
//  LPNewsfeed.h
//  Leanplum
//
//  Created by Aleksandar Gyorev on 05/08/15.
//  Copyright (c) 2015 Leanplum. All rights reserved.
//
//

#import <Foundation/Foundation.h>

#pragma mark - LPNewsfeedMessage interface

@interface LPNewsfeedMessage : NSObject <NSCoding>

#pragma mark - LPNewsfeedMessage methods

/**
 * Returns the message identifier of the newsfeed message.
 */
- (NSString *)messageId;

/**
 * Returns the title of the newsfeed message.
 */
- (NSString *)title;

/**
 * Returns the subtitle of the newsfeed message.
 */
- (NSString *)subtitle;

/**
 * Returns the delivery timestamp of the newsfeed message.
 */
- (NSDate *)deliveryTimestamp;

/**
 * Return the expiration timestamp of the newsfeed message.
 */
- (NSDate *)expirationTimestamp;

/**
 * Returns YES if the newsfeed message is read.
 */
- (BOOL)isRead;

/**
 * Read the newsfeed message, marking it as read and invoking its open action.
 */
- (void)read;

/**
 * Remove the newsfeed message from the newsfeed.
 */
- (void)remove;

@end

#pragma mark - LPNewsfeed interface

/**
 * This block is used when you define a callback.
 */
typedef void (^LeanplumNewsfeedChangedBlock)();

@interface LPNewsfeed : NSObject

#pragma mark - LPNewsfeed methods

/**
 * Returns the number of all newsfeed messages on the device.
 */
- (NSUInteger)count;

/**
 * Returns the number of the unread newsfeed messages on the device.
 */
- (NSUInteger)unreadCount;

/**
 * Returns the identifiers of all newsfeed messages on the device sorted in ascending
 * chronological order, i.e. the id of the oldest message is the first one, and the most
 * recent one is the last one in the array.
 */
- (NSArray *)messagesIds;

/**
 * Returns an array containing all of the newsfeed messages (as LPNewsfeedMessage objects)
 * on the device, sorted in ascending chronological order, i.e. the oldest message is the 
 * first one, and the most recent one is the last one in the array.
 */
- (NSArray *)allMessages;

/**
 * Returns an array containing all of the unread newsfeed messages on the device, sorted
 * in ascending chronological order, i.e. the oldest message is the first one, and the
 * most recent one is the last one in the array.
 */
- (NSArray *)unreadMessages;

/**
 * Returns the newsfeed messages associated with the given messageId identifier.
 */
- (LPNewsfeedMessage *)messageForId:(NSString *)messageId;

/**
 * Block to call when the newsfeed receive new values from the server.
 * This will be called on start, and also later on if the user is in an experiment
 * that can update in realtime.
 */
- (void)onChanged:(LeanplumNewsfeedChangedBlock)block;

/**
 @{
 * Adds a responder to be executed when an event happens.
 * Uses NSInvocation instead of blocks.
 * @see [Leanplum onStartResponse:]
 */
- (void)addNewsfeedChangedResponder:(id)responder withSelector:(SEL)selector;
- (void)removeNewsfeedChangedResponder:(id)responder withSelector:(SEL)selector;
/**@}*/

@end
