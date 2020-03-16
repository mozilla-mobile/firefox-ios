/*
 Copyright (c) 2011, Tony Million.
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 */

#import <SystemConfiguration/SystemConfiguration.h>
#import <UIKit/UIKit.h>

#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <netdb.h>

extern NSString *const kLeanplumReachabilityChangedNotification;

typedef enum
{
	// Apple NetworkStatus Compatible Names.
	NotReachable     = 0,
	ReachableViaWiFi = 2,
	ReachableViaWWAN = 1
} Leanplum_NetworkStatus;

@class Leanplum_Reachability;

typedef void (^Leanplum_NetworkReachable)(Leanplum_Reachability * reachability);
typedef void (^Leanplum_NetworkUnreachable)(Leanplum_Reachability * reachability);

@interface Leanplum_Reachability : NSObject

@property (nonatomic, copy) Leanplum_NetworkReachable    reachableBlock;
@property (nonatomic, copy) Leanplum_NetworkUnreachable  unreachableBlock;

@property SCNetworkReachabilityRef  reachabilityRef;
#if OS_OBJECT_HAVE_OBJC_SUPPORT == 1
@property dispatch_queue_t          reachabilitySerialQueue;
#else
@property dispatch_queue_t          reachabilitySerialQueue;
#endif

@property (nonatomic, assign) BOOL reachableOnWWAN;

@property (nonatomic, strong) id reachabilityObject;

+(Leanplum_Reachability*)reachabilityWithHostname:(NSString*)hostname;
+(Leanplum_Reachability*)reachabilityForInternetConnection;
+(Leanplum_Reachability*)reachabilityWithAddress:(const struct sockaddr_in*)hostAddress;
+(Leanplum_Reachability*)reachabilityForLocalWiFi;

-(Leanplum_Reachability *)initWithReachabilityRef:(SCNetworkReachabilityRef)ref;

-(BOOL)startNotifier;
-(void)stopNotifier;

-(BOOL)isReachable;
-(BOOL)isReachableViaWWAN;
-(BOOL)isReachableViaWiFi;

// WWAN may be available, but not active until a connection has been established.
// WiFi may require a connection for VPN on Demand.
-(BOOL)isConnectionRequired; // Identical DDG variant.
-(BOOL)connectionRequired; // Apple's routine.
// Dynamic, on demand connection?
-(BOOL)isConnectionOnDemand;
// Is user intervention required?
-(BOOL)isInterventionRequired;

-(Leanplum_NetworkStatus)currentReachabilityStatus;
-(SCNetworkReachabilityFlags)reachabilityFlags;
-(NSString*)currentReachabilityString;
-(NSString*)currentReachabilityFlags;

@end
