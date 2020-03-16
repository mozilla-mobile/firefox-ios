//
//  LPInbox.m
//  Leanplum
//
//  Created by Aleksandar Gyorev on 05/08/15.
//  Copyright (c) 2015 Leanplum, Inc. All rights reserved.
//
//  Licensed to the Apache Software Foundation (ASF) under one
//  or more contributor license agreements.  See the NOTICE file
//  distributed with this work for additional information
//  regarding copyright ownership.  The ASF licenses this file
//  to you under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.

#import "LPInbox.h"
#import "LPConstants.h"
#import "Leanplum.h"
#import "LeanplumInternal.h"
#import "LPVarCache.h"
#import "LeanplumInternal.h"
#import "LPAES.h"
#import "LPKeychainWrapper.h"
#import "LPFileManager.h"
#import "LPUtils.h"
#import "LPRequestFactory.h"
#import "LPRequestSender.h"
#import "LPCountAggregator.h"

static NSObject *updatingLock;

@implementation LPInboxMessage

#pragma mark - LPInboxMessage private methods

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:[self messageId] forKey:LP_PARAM_MESSAGE_ID];
    [coder encodeObject:[self deliveryTimestamp] forKey:LP_KEY_DELIVERY_TIMESTAMP];
    [coder encodeObject:[self expirationTimestamp] forKey:LP_KEY_EXPIRATION_TIMESTAMP];
    [coder encodeBool:[self isRead] forKey:LP_KEY_IS_READ];
    [coder encodeObject:[[self context] args] forKey:LP_VALUE_ACTION_ARG];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        _messageId = [decoder decodeObjectForKey:LP_PARAM_MESSAGE_ID];
        _deliveryTimestamp = [decoder decodeObjectForKey:LP_KEY_DELIVERY_TIMESTAMP];
        _expirationTimestamp = [decoder decodeObjectForKey:LP_KEY_EXPIRATION_TIMESTAMP];
        _isRead = [decoder decodeBoolForKey:LP_KEY_IS_READ];
        NSDictionary *actionArgs = [decoder decodeObjectForKey:LP_VALUE_ACTION_ARG];
        NSArray *messageIdParts = [_messageId componentsSeparatedByString:@"##"];
        _context = [LPActionContext actionContextWithName:actionArgs[LP_VALUE_ACTION_ARG]
                                                     args:actionArgs
                                                messageId:messageIdParts[0]];
        _context.preventRealtimeUpdating = YES;
        [self downloadImageIfPrefetchingEnabled];
    }
    return self;
}

- (id)initWithMessageId:(NSString *)messageId
      deliveryTimestamp:(NSDate *)deliveryTimestamp
    expirationTimestamp:(NSDate *)expirationTimestamp
                 isRead:(BOOL)isRead
             actionArgs:(NSDictionary *)actionArgs
{
    if (self = [super init]) {
        _messageId = messageId;
        _deliveryTimestamp = deliveryTimestamp;
        _expirationTimestamp = expirationTimestamp;
        _isRead = isRead;

        NSArray *messageIdParts = [messageId componentsSeparatedByString:@"##"];
        if ([messageIdParts count] != 2) {
            NSLog(@"Leanplum: Malformed inbox messageId: %@", messageId);
            return nil;
        }
        _context = [LPActionContext actionContextWithName:actionArgs[LP_VALUE_ACTION_ARG]
                                                     args:actionArgs
                                                messageId:messageIdParts[0]];
        _context.preventRealtimeUpdating = YES;
        if ([LPConstantsState sharedState].isInboxImagePrefetchingEnabled) {
            [_context maybeDownloadFiles];
        }
    }
    return self;
}

- (void)setIsRead:(BOOL)isRead
{
    _isRead = isRead;
}

#pragma mark - LPInboxMessage public methods

- (NSString *)title
{
    LP_TRY
    return [_context stringNamed:LP_KEY_TITLE];
    LP_END_TRY
    return @"";
}

- (NSString *)subtitle
{
    LP_TRY
    return [_context stringNamed:LP_KEY_SUBTITLE];
    LP_END_TRY
    return @"";
}

/**
 * This is a helper method that will return the cached file path of the image URL.
 * Will return nil if there is no file.
 */
- (NSString *)filePathOfImageURL
{
    NSString *imageURLString = [_context stringNamed:LP_KEY_IMAGE];
    if (![LPUtils isNullOrEmpty:imageURLString] && [LPFileManager fileExists:imageURLString]) {
        NSString *filePath = [LPFileManager fileValue:imageURLString withDefaultValue:@""];
        if (![LPUtils isNullOrEmpty:filePath]) {
            return [LPFileManager fileValue:imageURLString withDefaultValue:@""];
        }
    }
    return nil;
}

- (NSString *)imageFilePath
{
    LP_TRY
    NSString *filePath = [self filePathOfImageURL];
    if (filePath) {
        return filePath;
    }

    if (![LPConstantsState sharedState].isInboxImagePrefetchingEnabled) {
        LPLog(LPWarning, @"Inbox Message image path is null "
              "because you're calling [Leanplum disableImagePrefetching]. "
              "Consider using imageURL method or remove disableImagePrefetching.");
    }
    LP_END_TRY

    return nil;
}

- (NSURL *)imageURL
{
    LP_TRY
    // Check if the file has been downloaded.
    // This is to prevent from sending multiple requests.
    NSString *filePath = [self filePathOfImageURL];
    if (filePath) {
        return [NSURL fileURLWithPath:filePath];
    }

    NSString *imageURLString = [_context stringNamed:LP_KEY_IMAGE];
    return [NSURL URLWithString:imageURLString];
    LP_END_TRY

    return nil;
}

- (NSDictionary *)data
{
    LP_TRY
    return [_context dictionaryNamed:LP_KEY_DATA];
    LP_END_TRY
    return nil;
}

- (void)read
{
    if (![self isRead]) {
        [self setIsRead:YES];
        
        NSUInteger unreadCount = [[LPInbox sharedState] unreadCount] - 1;
        [[LPInbox sharedState] updateUnreadCount:unreadCount];
        
        RETURN_IF_NOOP;
        LP_TRY
        NSDictionary *params = @{LP_PARAM_INBOX_MESSAGE_ID: [self messageId]};
        LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                        initWithFeatureFlagManager:[LPFeatureFlagManager sharedManager]];
        id<LPRequesting> request = [reqFactory markNewsfeedMessageAsReadWithParams:params];
        [[LPRequestSender sharedInstance] send:request];
        LP_END_TRY
    }
    
    LP_TRY
    [[self context] runTrackedActionNamed:LP_VALUE_DEFAULT_PUSH_ACTION];
    LP_END_TRY
}

- (BOOL)isActive
{
    if (![self expirationTimestamp]) {
        return YES;
    }
    NSDate *now = [NSDate date];
    return [now compare:[self expirationTimestamp]] == NSOrderedAscending;
}

- (void)remove
{
    LP_TRY
    [[LPInbox sharedState] removeMessageForId:[self messageId]];
    LP_END_TRY
}

#pragma mark - LPInboxMessage private implementation

/**
 * Download image if prefetching is enabled.
 * Returns YES if the image will be downloaded, otherwise NO.
 * Uses LPInbox.downloadedImageUrls to make sure we don't call fileExist method
 * multiple times for same URLs.
 */
- (BOOL)downloadImageIfPrefetchingEnabled
{
    if (![LPConstantsState sharedState].isInboxImagePrefetchingEnabled) {
        return NO;
    }

    NSString *imageURLString = [_context stringNamed:LP_KEY_IMAGE];
    if ([LPUtils isNullOrEmpty:imageURLString] ||
        [[Leanplum inbox].downloadedImageUrls containsObject:imageURLString]) {
        return NO;
    }

    [[Leanplum inbox].downloadedImageUrls addObject:imageURLString];
    BOOL willDownloadFile = [LPFileManager maybeDownloadFile:imageURLString
                                                defaultValue:nil
                                                  onComplete:nil];
    return willDownloadFile;
}

@end

@implementation LPInbox

+ (LPInbox *)sharedState {
    static LPInbox *sharedInbox = nil;
    static dispatch_once_t onceInboxToken;
    dispatch_once(&onceInboxToken, ^{
        sharedInbox = [self new];
    });
    return sharedInbox;
}

- (id)init {
    if (self = [super init]) {
        [self reset];
        _countAggregator = [LPCountAggregator sharedAggregator];
    }
    return self;
}

#pragma mark - LPInbox private methods

- (void)load
{
    RETURN_IF_NOOP;
    @try {
        NSData *encryptedData = [[NSUserDefaults standardUserDefaults]
                                 dataForKey:LEANPLUM_DEFAULTS_INBOX_KEY];
        NSUInteger unreadCount = 0;
        NSMutableDictionary *messages;
        if (encryptedData) {
            NSData *decryptedData = [LPAES decryptedDataFromData:encryptedData];
            if (!decryptedData) {
                return;
            }
            
            NSKeyedUnarchiver *archiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:decryptedData];
            messages = (NSMutableDictionary *)[archiver decodeObjectForKey:LP_PARAM_INBOX_MESSAGES];
            if (!messages) {
                messages = [NSMutableDictionary dictionary];
            }
            
            // We remove a message from the cached ones if it has expired, and update the unreadCount accordingly.
            for (NSString *messageId in messages.allKeys) {
                if (![messages[messageId] isActive]) {
                    [messages removeObjectForKey:messageId];
                } else if(![messages[messageId] isRead]) {
                    unreadCount++;
                }
            }
            
            // Download images.
            BOOL willDownloadImages = NO;
            for (NSString *messageId in messages) {
                LPInboxMessage *inboxMessage = [self messageForId:messageId];
                willDownloadImages |= [inboxMessage downloadImageIfPrefetchingEnabled];
            }

            // Trigger inbox changed when all images are downloaded.
            if (willDownloadImages) {
                [Leanplum onceVariablesChangedAndNoDownloadsPending:^{
                    LP_END_USER_CODE
                    [self updateMessages:messages unreadCount:unreadCount];
                    LP_BEGIN_USER_CODE
                }];
            } else {
                [self updateMessages:messages unreadCount:unreadCount];
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"Leanplum: Could not load the Inbox data: %@", exception);
    }
}

- (void)save
{
    RETURN_IF_NOOP;
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:[self messages] forKey:LP_PARAM_INBOX_MESSAGES];
    [archiver finishEncoding];
    
    NSData *encryptedData = [LPAES encryptedDataFromData:data];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:encryptedData forKey:LEANPLUM_DEFAULTS_INBOX_KEY];
    [Leanplum synchronizeDefaults];
}

- (void)updateUnreadCount:(NSUInteger)unreadCount
{
    _unreadCount = unreadCount;
    [self save];
    [self triggerInboxChanged];
}

- (void)updateMessages:(NSMutableDictionary *)messages unreadCount:(NSUInteger)unreadCount
{
    @synchronized (updatingLock) {
        _unreadCount = unreadCount;
        
        if (messages) {
            _messages = messages;
        }
    }
    
    _didLoad = YES;
    [self save];
    [self triggerInboxChanged];
}

- (void)removeMessageForId:(NSString *)messageId
{
    NSUInteger unreadCount = [[LPInbox sharedState] unreadCount];
    if (![[self messageForId:messageId] isRead]) {
        unreadCount--;
    }
    
    RETURN_IF_NOOP;
    LP_TRY
    [_messages removeObjectForKey:messageId];
    [[LPInbox sharedState] updateMessages:_messages unreadCount:unreadCount];
    
    NSDictionary *params = @{LP_PARAM_INBOX_MESSAGE_ID:messageId};
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:[LPFeatureFlagManager sharedManager]];
    id<LPRequesting> request = [reqFactory deleteNewsfeedMessageWithParams:params];
    [[LPRequestSender sharedInstance] send:request];
    LP_END_TRY
}

- (void)reset
{
    _unreadCount = 0;
    _messages = [[NSMutableDictionary alloc] init];
    _didLoad = NO;
    _inboxChangedBlocks = nil;
    _inboxChangedResponders = nil;
    _inboxSyncedBlocks = nil;
    updatingLock = [[NSObject alloc] init];
    _downloadedImageUrls = [NSMutableSet new];
}

- (void)triggerInboxChanged
{
    LP_BEGIN_USER_CODE
    for (NSInvocation *invocation in _inboxChangedResponders.copy) {
        [invocation invoke];
    }

    for (LeanplumInboxChangedBlock block in _inboxChangedBlocks.copy) {
        block();
    }
    LP_END_USER_CODE
}

- (void)triggerInboxSyncedWithStatus:(BOOL)success
{
    LP_BEGIN_USER_CODE
    for (LeanplumInboxSyncedBlock block in _inboxSyncedBlocks.copy) {
        block(success);
    }
    LP_END_USER_CODE
}

#pragma mark - LPInbox methods

- (void)downloadMessages
{
    RETURN_IF_NOOP;
    LP_TRY
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:[LPFeatureFlagManager sharedManager]];
    id<LPRequesting> request = [reqFactory getNewsfeedMessagesWithParams:nil];
    [request onResponse:^(id<LPNetworkOperationProtocol> operation, NSDictionary *response) {
        LP_TRY
        NSDictionary *messagesDict = response[LP_KEY_INBOX_MESSAGES];
        NSUInteger unreadCount = 0;
        NSMutableDictionary *messages = [[NSMutableDictionary alloc] init];
        BOOL willDownloadImage = NO;
        
        for (NSString *messageId in messagesDict) {
            NSDictionary *messageDict = messagesDict[messageId];
            NSDictionary *actionArgs = messageDict[LP_KEY_MESSAGE_DATA][LP_KEY_VARS];
            NSDate *deliveryTimestamp = [NSDate dateWithTimeIntervalSince1970:
                                [messageDict[LP_KEY_DELIVERY_TIMESTAMP] doubleValue] / 1000.0];
            NSDate *expirationTimestamp = nil;
            if (messageDict[LP_KEY_EXPIRATION_TIMESTAMP]) {
                expirationTimestamp = [NSDate dateWithTimeIntervalSince1970:
                                [messageDict[LP_KEY_EXPIRATION_TIMESTAMP] doubleValue] / 1000.0];
            }
            BOOL isRead = [messageDict[LP_KEY_IS_READ] boolValue];
            
            LPInboxMessage *message = [[LPInboxMessage alloc] initWithMessageId:messageId
                                                              deliveryTimestamp:deliveryTimestamp
                                                            expirationTimestamp:expirationTimestamp
                                                                         isRead:isRead
                                                                     actionArgs:actionArgs];
            if (!message) {
                continue;
            }

            if (!isRead) {
                unreadCount++;
            }
            willDownloadImage |= [message downloadImageIfPrefetchingEnabled];
            messages[messageId] = message;
        }

        // Trigger inbox changed when all images are downloaded.
        if (willDownloadImage) {
            [Leanplum onceVariablesChangedAndNoDownloadsPending:^{
                LP_END_USER_CODE
                [self updateMessages:messages unreadCount:unreadCount];
                [self triggerInboxSyncedWithStatus:YES];
                LP_BEGIN_USER_CODE
            }];
        } else {
            [self updateMessages:messages unreadCount:unreadCount];
            [self triggerInboxSyncedWithStatus:YES];
        }
        LP_END_TRY
    }];
    [request onError:^(NSError *error) {
        [self triggerInboxSyncedWithStatus:NO];
    }];
    [[LPRequestSender sharedInstance] sendIfConnected:request];
    LP_END_TRY
}

- (NSUInteger)count
{
    LP_TRY
    return [[self messages] count];
    LP_END_TRY

    return 0;
}

- (NSArray *)messagesIds
{
    LP_TRY
    NSMutableArray *messagesIds = [[[self messages] allKeys] mutableCopy];
    [messagesIds sortUsingComparator:^(NSString *firstId, NSString *secondId) {
        NSDate *firstDate = [[self messageForId:firstId] deliveryTimestamp];
        NSDate *secondDate = [[self messageForId:secondId] deliveryTimestamp];
        return [firstDate compare:secondDate];
    }];
    return messagesIds;
    LP_END_TRY

    return @[];
}

- (NSArray *)allMessages
{
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    LP_TRY
    NSArray *messagesIds = [self messagesIds];
    for (NSString *messageId in messagesIds) {
        [messages addObject:[self messageForId:messageId]];
    }
    LP_END_TRY
    
    [self.countAggregator incrementCount:@"all_messages_inbox"];
    
    return messages;
}

- (NSArray *)unreadMessages
{
    NSMutableArray *unreadMessages = [[NSMutableArray alloc] init];
    LP_TRY
    for (LPInboxMessage *message in [self allMessages]) {
        if (![message isRead]) {
            [unreadMessages addObject:message];
        }
    }
    LP_END_TRY
    return unreadMessages;
}

- (LPInboxMessage *)messageForId:(NSString *)messageId
{
    LP_TRY
    return self.messages[messageId];
    LP_END_TRY

    return nil;
}

- (void)onChanged:(LeanplumInboxChangedBlock)block
{
    if (!block) {
        return;
    }
    
    LP_TRY
    if (!_inboxChangedBlocks) {
        _inboxChangedBlocks = [NSMutableArray array];
    }
    [_inboxChangedBlocks addObject:[block copy]];
    LP_END_TRY
    if (_didLoad) {
        block();
    }
}

- (void)onForceContentUpdate:(LeanplumInboxSyncedBlock)block
{
    if (!block) {
        return;
    }
    
    LP_TRY
    if (!_inboxSyncedBlocks) {
        _inboxSyncedBlocks = [NSMutableArray array];
    }
    [_inboxSyncedBlocks addObject:[block copy]];
    LP_END_TRY
}

- (void)addInboxChangedResponder:(id)responder withSelector:(SEL)selector
{
    if (!_inboxChangedResponders) {
        _inboxChangedResponders = [NSMutableSet set];
    }
    NSInvocation *invocation = [Leanplum createInvocationWithResponder:responder selector:selector];
    [Leanplum addInvocation:invocation toSet:_inboxChangedResponders];
    if (_didLoad) {
        [invocation invoke];
    }
}

- (void)removeInboxChangedResponder:(id)responder withSelector:(SEL)selector
{
    LP_TRY
    [Leanplum removeResponder:responder withSelector:selector fromSet:_inboxChangedResponders];
    LP_END_TRY
}

- (void)disableImagePrefetching
{
    LP_TRY
    [LPConstantsState sharedState].isInboxImagePrefetchingEnabled = NO;
    LP_END_TRY
}

@end

#pragma mark - LPNewsfeed implementation for backwards compatibility

@implementation LPNewsfeedMessage

- (id)init
{
    return [super init];
}

@end

@implementation LPNewsfeed

+ (LPNewsfeed *)sharedState {
    static LPNewsfeed *sharedNewsfeed = nil;
    static dispatch_once_t onceNewsfeedToken;
    dispatch_once(&onceNewsfeedToken, ^{
        sharedNewsfeed = [self new];
    });
    return sharedNewsfeed;
}

- (id)init {
    return [super init];
}

- (NSUInteger)count {
    return [[LPInbox sharedState] count];
}

- (NSUInteger)unreadCount {
    return [[LPInbox sharedState] unreadCount];
}

- (NSArray *)messagesIds {
    return [[LPInbox sharedState] messagesIds];
}

- (NSArray *)allMessages {
    return [[LPInbox sharedState] allMessages];
}

- (NSArray *)unreadMessages {
    return [[LPInbox sharedState] unreadMessages];
}

- (void)onChanged:(LeanplumNewsfeedChangedBlock)block {
    [[LPInbox sharedState] onChanged:block];
}

- (LPNewsfeedMessage *)messageForId:(NSString *)messageId {
    return (LPNewsfeedMessage *)[[LPInbox sharedState] messageForId:messageId];
}

- (void)addNewsfeedChangedResponder:(id)responder withSelector:(SEL)selector {
    [[LPInbox sharedState]  addInboxChangedResponder:responder withSelector:selector];
}

- (void)removeNewsfeedChangedResponder:(id)responder withSelector:(SEL)selector {
    [[LPInbox sharedState]  removeInboxChangedResponder:responder withSelector:selector];
}

@end
