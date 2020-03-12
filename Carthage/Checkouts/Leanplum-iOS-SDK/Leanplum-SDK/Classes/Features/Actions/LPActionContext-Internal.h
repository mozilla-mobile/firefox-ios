//
//  LPActionContext.h
//  Leanplum-iOS-SDK-source
//
//  Created by Mayank Sanganeria on 4/24/18.
//

#import "LeanplumInternal.h"

@class LPContextualValues;

@interface LPActionContext ()

+ (LPActionContext *)actionContextWithName:(NSString *)name
                                      args:(NSDictionary *)args
                                 messageId:(NSString *)messageId;

+ (LPActionContext *)actionContextWithName:(NSString *)name
                                      args:(NSDictionary *)args
                                 messageId:(NSString *)messageId
                         originalMessageId:(NSString *)originalMessageId
                                  priority:(NSNumber *)priority;

@property (readonly, strong) NSString *name;
@property (readonly, strong) NSString *messageId;
@property (readonly, strong) NSString *originalMessageId;
@property (readonly, strong) NSNumber *priority;
@property (readonly, strong) NSDictionary *args;
@property (readonly, strong) LPActionContext *parentContext;
@property (readonly) int contentVersion;
@property (readonly, strong) NSString *key;
@property (assign) BOOL preventRealtimeUpdating;
@property (nonatomic, assign) BOOL isRooted;
@property (nonatomic, assign) BOOL isPreview;
@property (nonatomic, strong) LPContextualValues *contextualValues;

- (void)maybeDownloadFiles;
- (id)objectNamed:(NSString *)name;
- (void)preventRealtimeUpdating;
+ (void)sortByPriority:(NSMutableArray *)actionContexts;

@end
