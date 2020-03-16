//
//  AsyncSocket.m
//
//  This class is in the public domain.
//  Originally created by Dustin Voss on Wed Jan 29 2003.
//  Updated and maintained by Deusty Designs and the Mac development community.
//
//  http://code.google.com/p/cocoaasyncsocket/
//

#import "Leanplum_AsyncSocket.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <netdb.h>

#if TARGET_OS_IPHONE
// Note: You may need to add the CFNetwork Framework to your project
#import <CFNetwork/CFNetwork.h>
#endif

#pragma mark Declarations

#define DEFAULT_PREBUFFERING YES        // Whether pre-buffering is enabled by default

#define READQUEUE_CAPACITY	5           // Initial capacity
#define WRITEQUEUE_CAPACITY 5           // Initial capacity
#define READALL_CHUNKSIZE	256         // Incremental increase in buffer size
#define WRITE_CHUNKSIZE    (1024 * 4)   // Limit on size of each write pass

NSString *const Leanplum_AsyncSocketException = @"AsyncSocketException";
NSString *const Leanplum_AsyncSocketErrorDomain = @"AsyncSocketErrorDomain";

#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5
// Mutex lock used by all instances of AsyncSocket, to protect getaddrinfo.
// Prior to Mac OS X 10.5 this method was not thread-safe.
static NSString *getaddrinfoLock = @"lock";
#endif

enum AsyncSocketFlags
{
	kEnablePreBuffering      = 1 <<  0,  // If set, pre-buffering is enabled
	kDidPassConnectMethod    = 1 <<  1,  // If set, disconnection results in delegate call
	kDidCompleteOpenForRead  = 1 <<  2,  // If set, open callback has been called for read stream
	kDidCompleteOpenForWrite = 1 <<  3,  // If set, open callback has been called for write stream
	kStartingReadTLS         = 1 <<  4,  // If set, we're waiting for TLS negotiation to complete
	kStartingWriteTLS        = 1 <<  5,  // If set, we're waiting for TLS negotiation to complete
	kForbidReadsWrites       = 1 <<  6,  // If set, no new reads or writes are allowed
	kDisconnectAfterReads    = 1 <<  7,  // If set, disconnect after no more reads are queued
	kDisconnectAfterWrites   = 1 <<  8,  // If set, disconnect after no more writes are queued
	kClosingWithError        = 1 <<  9,  // If set, the socket is being closed due to an error
	kDequeueReadScheduled    = 1 << 10,  // If set, a maybeDequeueRead operation is already scheduled
	kDequeueWriteScheduled   = 1 << 11,  // If set, a maybeDequeueWrite operation is already scheduled
	kSocketCanAcceptBytes    = 1 << 12,  // If set, we know socket can accept bytes. If unset, it's unknown.
	kSocketHasBytesAvailable = 1 << 13,  // If set, we know socket has bytes available. If unset, it's unknown.
};

@interface Leanplum_AsyncSocket (Private)

// Connecting
- (void)startConnectTimeout:(NSTimeInterval)timeout;
- (void)endConnectTimeout;

// Socket Implementation
- (CFSocketRef)newAcceptSocketForAddress:(NSData *)addr error:(NSError **)errPtr;
- (BOOL)createSocketForAddress:(NSData *)remoteAddr error:(NSError **)errPtr;
- (BOOL)attachSocketsToRunLoop:(NSRunLoop *)runLoop error:(NSError **)errPtr;
- (BOOL)configureSocketAndReturnError:(NSError **)errPtr;
- (BOOL)connectSocketToAddress:(NSData *)remoteAddr error:(NSError **)errPtr;
- (void)doAcceptWithSocket:(CFSocketNativeHandle)newSocket;
- (void)doSocketOpen:(CFSocketRef)sock withCFSocketError:(CFSocketError)err;

// Stream Implementation
- (BOOL)createStreamsFromNative:(CFSocketNativeHandle)native error:(NSError **)errPtr;
- (BOOL)createStreamsToHost:(NSString *)hostname onPort:(UInt16)port error:(NSError **)errPtr;
- (BOOL)attachStreamsToRunLoop:(NSRunLoop *)runLoop error:(NSError **)errPtr;
- (BOOL)configureStreamsAndReturnError:(NSError **)errPtr;
- (BOOL)openStreamsAndReturnError:(NSError **)errPtr;
- (void)doStreamOpen;
- (BOOL)setSocketFromStreamsAndReturnError:(NSError **)errPtr;

// Disconnect Implementation
- (void)closeWithError:(NSError *)err;
- (void)recoverUnreadData;
- (void)emptyQueues;
- (void)close;

// Errors
- (NSError *)getErrnoError;
- (NSError *)getAbortError;
- (NSError *)getStreamError;
- (NSError *)getSocketError;
- (NSError *)getConnectTimeoutError;
- (NSError *)getReadMaxedOutError;
- (NSError *)getReadTimeoutError;
- (NSError *)getWriteTimeoutError;
- (NSError *)errorFromCFStreamError:(CFStreamError)err;

// Diagnostics
- (BOOL)isSocketConnected;
- (BOOL)areStreamsConnected;
- (NSString *)connectedHost:(CFSocketRef)socket;
- (UInt16)connectedPort:(CFSocketRef)socket;
- (NSString *)localHost:(CFSocketRef)socket;
- (UInt16)localPort:(CFSocketRef)socket;
- (NSString *)addressHost:(CFDataRef)cfaddr;
- (UInt16)addressPort:(CFDataRef)cfaddr;

// Reading
- (void)doBytesAvailable;
- (void)completeCurrentRead;
- (void)endCurrentRead;
- (void)scheduleDequeueRead;
- (void)maybeDequeueRead;
- (void)doReadTimeout:(NSTimer *)timer;

// Writing
- (void)doSendBytes;
- (void)completeCurrentWrite;
- (void)endCurrentWrite;
- (void)scheduleDequeueWrite;
- (void)maybeDequeueWrite;
- (void)maybeScheduleDisconnect;
- (void)doWriteTimeout:(NSTimer *)timer;

// Run Loop
- (void)runLoopAddSource:(CFRunLoopSourceRef)source;
- (void)runLoopRemoveSource:(CFRunLoopSourceRef)source;
- (void)runLoopAddTimer:(NSTimer *)timer;
- (void)runLoopRemoveTimer:(NSTimer *)timer;
- (void)runLoopUnscheduleReadStream;
- (void)runLoopUnscheduleWriteStream;

// Security
- (void)maybeStartTLS;
- (void)onTLSHandshakeSuccessful;

// Callbacks
- (void)doCFCallback:(CFSocketCallBackType)type forSocket:(CFSocketRef)sock withAddress:(NSData *)address withData:(const void *)pData;
- (void)doCFReadStreamCallback:(CFStreamEventType)type forStream:(CFReadStreamRef)stream;
- (void)doCFWriteStreamCallback:(CFStreamEventType)type forStream:(CFWriteStreamRef)stream;

@end

static void MyCFSocketCallback(CFSocketRef, CFSocketCallBackType, CFDataRef, const void *, void *);
static void MyCFReadStreamCallback(CFReadStreamRef stream, CFStreamEventType type, void *pInfo);
static void MyCFWriteStreamCallback(CFWriteStreamRef stream, CFStreamEventType type, void *pInfo);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * The AsyncReadPacket encompasses the instructions for any given read.
 * The content of a read packet allows the code to determine if we're:
 *  - reading to a certain length
 *  - reading to a certain separator
 *  - or simply reading the first chunk of available data
 **/
@interface Leanplum_AsyncReadPacket : NSObject
{
@public
	NSMutableData *buffer;
	CFIndex bytesDone;
	NSTimeInterval timeout;
	CFIndex maxLength;
	long tag;
	NSData *term;
	BOOL readAllAvailableData;
}
- (id)initWithData:(NSMutableData *)d
		   timeout:(NSTimeInterval)t
			   tag:(long)i
  readAllAvailable:(BOOL)a
		terminator:(NSData *)e
	  	 maxLength:(CFIndex)m;

- (unsigned)readLengthForTerm;

- (unsigned)prebufferReadLengthForTerm;
- (CFIndex)searchForTermAfterPreBuffering:(CFIndex)numBytes;
@end

@implementation Leanplum_AsyncReadPacket

- (id)initWithData:(NSMutableData *)d
		   timeout:(NSTimeInterval)t
			   tag:(long)i
  readAllAvailable:(BOOL)a
		terminator:(NSData *)e
         maxLength:(CFIndex)m
{
	if((self = [super init]))
	{
		buffer = d;
		timeout = t;
		tag = i;
		readAllAvailableData = a;
		term = [e copy];
		bytesDone = 0;
		maxLength = m;
	}
	return self;
}

/**
 * For read packets with a set terminator, returns the safe length of data that can be read
 * without going over a terminator, or the maxLength.
 *
 * It is assumed the terminator has not already been read.
 **/
- (unsigned)readLengthForTerm
{
	NSAssert(term != nil, @"Searching for term in data when there is no term.");
	
	// What we're going to do is look for a partial sequence of the terminator at the end of the buffer.
	// If a partial sequence occurs, then we must assume the next bytes to arrive will be the rest of the term,
	// and we can only read that amount.
	// Otherwise, we're safe to read the entire length of the term.
	
	unsigned result = (unsigned) [term length];
	
	// Shortcut when term is a single byte
	if(result == 1) return result;
	
	// i = index within buffer at which to check data
	// j = length of term to check against
	
	// Note: Beware of implicit casting rules
	// This could give you -1: MAX(0, (0 - [term length] + 1));
	
	CFIndex i = MAX(0, (CFIndex)(bytesDone - [term length] + 1));
	CFIndex j = MIN([term length] - 1, bytesDone);
	
	while(i < bytesDone)
	{
		const void *subBuffer = [buffer bytes] + i;
		
		if(memcmp(subBuffer, [term bytes], j) == 0)
		{
			result = (unsigned)MAX(0, ([term length] - j));
			break;
		}
		
		i++;
		j--;
	}
	
	if(maxLength > 0)
		return (unsigned)MIN(result, MAX(0, (maxLength - bytesDone)));
	else
		return result;
}

/**
 * Assuming pre-buffering is enabled, returns the amount of data that can be read
 * without going over the maxLength.
 **/
- (unsigned)prebufferReadLengthForTerm
{
	if(maxLength > 0)
		return (unsigned)MIN(READALL_CHUNKSIZE, MAX(0, (maxLength - bytesDone)));
	else
		return READALL_CHUNKSIZE;
}

/**
 * For read packets with a set terminator, scans the packet buffer for the term.
 * It is assumed the terminator had not been fully read prior to the new bytes.
 *
 * If the term is found, the number of excess bytes after the term are returned.
 * If the term is not found, this method will return -1.
 *
 * Note: A return value of zero means the term was found at the very end.
 **/
- (CFIndex)searchForTermAfterPreBuffering:(CFIndex)numBytes
{
	NSAssert(term != nil, @"Searching for term in data when there is no term.");
	
	// We try to start the search such that the first new byte read matches up with the last byte of the term.
	// We continue searching forward after this until the term no longer fits into the buffer.
	
	// Note: Beware of implicit casting rules
	// This could give you -1: MAX(0, 1 - 1 - [term length] + 1);
	
	CFIndex i = MAX(0, (CFIndex)(bytesDone - numBytes - [term length] + 1));
	
	while(i + [term length] <= bytesDone)
	{
		const void *subBuffer = [buffer bytes] + i;
		
		if(memcmp(subBuffer, [term bytes], [term length]) == 0)
		{
			return bytesDone - (i + [term length]);
		}
		
		i++;
	}
	
	return -1;
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * The AsyncWritePacket encompasses the instructions for any given write.
 **/
@interface Leanplum_AsyncWritePacket : NSObject
{
@public
	NSData *buffer;
	CFIndex bytesDone;
	long tag;
	NSTimeInterval timeout;
}
- (id)initWithData:(NSData *)d timeout:(NSTimeInterval)t tag:(long)i;
@end

@implementation Leanplum_AsyncWritePacket

- (id)initWithData:(NSData *)d timeout:(NSTimeInterval)t tag:(long)i
{
	if((self = [super init]))
	{
		buffer = d;
		timeout = t;
		tag = i;
		bytesDone = 0;
	}
	return self;
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * The AsyncSpecialPacket encompasses special instructions for interruptions in the read/write queues.
 * This class my be altered to support more than just TLS in the future.
 **/
@interface Leanplum_AsyncSpecialPacket : NSObject
{
@public
	NSDictionary *tlsSettings;
}
- (id)initWithTLSSettings:(NSDictionary *)settings;
@end

@implementation Leanplum_AsyncSpecialPacket

- (id)initWithTLSSettings:(NSDictionary *)settings
{
	if((self = [super init]))
	{
		tlsSettings = [settings copy];
	}
	return self;
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation Leanplum_AsyncSocket

- (id)init
{
	return [self initWithDelegate:nil userData:0];
}

- (id)initWithDelegate:(id)delegate
{
	return [self initWithDelegate:delegate userData:0];
}

// Designated initializer.
- (id)initWithDelegate:(id)delegate userData:(long)userData
{
	if((self = [super init]))
	{
		theFlags = DEFAULT_PREBUFFERING ? kEnablePreBuffering : 0;
		theDelegate = delegate;
		theUserData = userData;
		
		theSocket4 = NULL;
		theSource4 = NULL;
		theSocket6 = NULL;
		theSource6 = NULL;
		theRunLoop = NULL;
		theReadStream = NULL;
		theWriteStream = NULL;
		
		theConnectTimer = nil;
		
		theReadQueue = [[NSMutableArray alloc] initWithCapacity:READQUEUE_CAPACITY];
		theCurrentRead = nil;
		theReadTimer = nil;
		
		partialReadBuffer = [[NSMutableData alloc] initWithCapacity:READALL_CHUNKSIZE];
		
		theWriteQueue = [[NSMutableArray alloc] initWithCapacity:WRITEQUEUE_CAPACITY];
		theCurrentWrite = nil;
		theWriteTimer = nil;
		
		// Socket context
		NSAssert(sizeof(CFSocketContext) == sizeof(CFStreamClientContext), @"CFSocketContext != CFStreamClientContext");
		theContext.version = 0;
		theContext.info = (__bridge void *)(self);
		theContext.retain = nil;
		theContext.release = nil;
		theContext.copyDescription = nil;
		
		// Default run loop modes
		theRunLoopModes = [NSArray arrayWithObject:NSDefaultRunLoopMode];
	}
	return self;
}

// The socket may been initialized in a connected state and auto-released, so this should close it down cleanly.
- (void)dealloc
{
	[self close];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (long)userData
{
	return theUserData;
}

- (void)setUserData:(long)userData
{
	theUserData = userData;
}

- (id)delegate
{
	return theDelegate;
}

- (void)setDelegate:(id)delegate
{
	theDelegate = delegate;
}

- (BOOL)canSafelySetDelegate
{
	return ([theReadQueue count] == 0 && [theWriteQueue count] == 0 && theCurrentRead == nil && theCurrentWrite == nil);
}

- (CFSocketRef)getCFSocket
{
	if(theSocket4)
		return theSocket4;
	else
		return theSocket6;
}

- (CFReadStreamRef)getCFReadStream
{
	return theReadStream;
}

- (CFWriteStreamRef)getCFWriteStream
{
	return theWriteStream;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Progress
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (float)progressOfReadReturningTag:(long *)tag bytesDone:(CFIndex *)done total:(CFIndex *)total
{
	// Check to make sure we're actually reading something right now,
	// and that the read packet isn't an AsyncSpecialPacket (upgrade to TLS).
	if (!theCurrentRead || ![theCurrentRead isKindOfClass:[Leanplum_AsyncReadPacket class]]) return NAN;
	
	// It's only possible to know the progress of our read if we're reading to a certain length
	// If we're reading to data, we of course have no idea when the data will arrive
	// If we're reading to timeout, then we have no idea when the next chunk of data will arrive.
	BOOL hasTotal = (theCurrentRead->readAllAvailableData == NO && theCurrentRead->term == nil);
	
	CFIndex d = theCurrentRead->bytesDone;
	CFIndex t = hasTotal ? [theCurrentRead->buffer length] : 0;
	if (tag != NULL)   *tag = theCurrentRead->tag;
	if (done != NULL)  *done = d;
	if (total != NULL) *total = t;
	float ratio = (float)d/(float)t;
	return isnan(ratio) ? 1.0F : ratio; // 0 of 0 bytes is 100% done.
}

- (float)progressOfWriteReturningTag:(long *)tag bytesDone:(CFIndex *)done total:(CFIndex *)total
{
	// Check to make sure we're actually writing something right now,
	// and that the write packet isn't an AsyncSpecialPacket (upgrade to TLS).
	if (!theCurrentWrite || ![theCurrentWrite isKindOfClass:[Leanplum_AsyncWritePacket class]]) return NAN;
	
	CFIndex d = theCurrentWrite->bytesDone;
	CFIndex t = [theCurrentWrite->buffer length];
	if (tag != NULL)   *tag = theCurrentWrite->tag;
	if (done != NULL)  *done = d;
	if (total != NULL) *total = t;
	return (float)d/(float)t;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Run Loop
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)runLoopAddSource:(CFRunLoopSourceRef)source
{
	unsigned i, count = (unsigned)[theRunLoopModes count];
	for(i = 0; i < count; i++)
	{
		CFStringRef runLoopMode = (__bridge CFStringRef)theRunLoopModes[i];
		CFRunLoopAddSource(theRunLoop, source, runLoopMode);
	}
}

- (void)runLoopRemoveSource:(CFRunLoopSourceRef)source
{
	unsigned i, count = (unsigned)[theRunLoopModes count];
	for(i = 0; i < count; i++)
	{
		CFStringRef runLoopMode = (__bridge CFStringRef)theRunLoopModes[i];
		CFRunLoopRemoveSource(theRunLoop, source, runLoopMode);
	}
}

- (void)runLoopAddTimer:(NSTimer *)timer
{
	unsigned i, count = (unsigned)[theRunLoopModes count];
	for(i = 0; i < count; i++)
	{
		CFStringRef runLoopMode = (__bridge CFStringRef)theRunLoopModes[i];
		CFRunLoopAddTimer(theRunLoop, (CFRunLoopTimerRef)timer, runLoopMode);
	}
}

- (void)runLoopRemoveTimer:(NSTimer *)timer
{
	unsigned i, count = (unsigned)[theRunLoopModes count];
	for(i = 0; i < count; i++)		
	{
		CFStringRef runLoopMode = (__bridge CFStringRef)theRunLoopModes[i];
		CFRunLoopRemoveTimer(theRunLoop, (CFRunLoopTimerRef)timer, runLoopMode);
	}
}

- (void)runLoopUnscheduleReadStream
{
	unsigned i, count = (unsigned)[theRunLoopModes count];
	for(i = 0; i < count; i++)
	{
		CFStringRef runLoopMode = (__bridge CFStringRef)theRunLoopModes[i];
		CFReadStreamUnscheduleFromRunLoop(theReadStream, theRunLoop, runLoopMode);
	}
	CFReadStreamSetClient(theReadStream, kCFStreamEventNone, NULL, NULL);
}

- (void)runLoopUnscheduleWriteStream
{
	unsigned i, count = (unsigned)[theRunLoopModes count];
	for(i = 0; i < count; i++)
	{
		CFStringRef runLoopMode = (__bridge CFStringRef)theRunLoopModes[i];
		CFWriteStreamUnscheduleFromRunLoop(theWriteStream, theRunLoop, runLoopMode);
	}
	CFWriteStreamSetClient(theWriteStream, kCFStreamEventNone, NULL, NULL);
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Configuration
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * See the header file for a full explanation of pre-buffering.
 **/
- (void)enablePreBuffering
{
	theFlags |= kEnablePreBuffering;
}

/**
 * See the header file for a full explanation of this method.
 **/
- (BOOL)moveToRunLoop:(NSRunLoop *)runLoop
{
	NSAssert((theRunLoop == NULL) || (theRunLoop == CFRunLoopGetCurrent()),
			 @"moveToRunLoop must be called from within the current RunLoop!");
	
	if(runLoop == nil)
	{
		return NO;
	}
	if(theRunLoop == [runLoop getCFRunLoop])
	{
		return YES;
	}
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	theFlags &= ~kDequeueReadScheduled;
	theFlags &= ~kDequeueWriteScheduled;
	
	if(theReadStream && theWriteStream)
    {
        [self runLoopUnscheduleReadStream];
        [self runLoopUnscheduleWriteStream];
    }

	if(theSource4) [self runLoopRemoveSource:theSource4];
	if(theSource6) [self runLoopRemoveSource:theSource6];

	if(theReadTimer) [self runLoopRemoveTimer:theReadTimer];
	if(theWriteTimer) [self runLoopRemoveTimer:theWriteTimer];
	
	theRunLoop = [runLoop getCFRunLoop];
	
	if(theReadTimer) [self runLoopAddTimer:theReadTimer];
	if(theWriteTimer) [self runLoopAddTimer:theWriteTimer];

	if(theSource4) [self runLoopAddSource:theSource4];
	if(theSource6) [self runLoopAddSource:theSource6];

    if(theReadStream && theWriteStream)
	{
		if(![self attachStreamsToRunLoop:runLoop error:nil])
		{
			return NO;
		}
	}
	
	[runLoop performSelector:@selector(maybeDequeueRead) target:self argument:nil order:0 modes:theRunLoopModes];
	[runLoop performSelector:@selector(maybeDequeueWrite) target:self argument:nil order:0 modes:theRunLoopModes];
	[runLoop performSelector:@selector(maybeScheduleDisconnect) target:self argument:nil order:0 modes:theRunLoopModes];
	
	return YES;
}

/**
 * See the header file for a full explanation of this method.
 **/
- (BOOL)setRunLoopModes:(NSArray *)runLoopModes
{
	NSAssert((theRunLoop == NULL) || (theRunLoop == CFRunLoopGetCurrent()),
			 @"setRunLoopModes must be called from within the current RunLoop!");
	
	if([runLoopModes count] == 0)
	{
		return NO;
	}
	if([theRunLoopModes isEqualToArray:runLoopModes])
	{
		return YES;
	}
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	theFlags &= ~kDequeueReadScheduled;
	theFlags &= ~kDequeueWriteScheduled;
	
	if(theReadStream && theWriteStream)
    {
        [self runLoopUnscheduleReadStream];
        [self runLoopUnscheduleWriteStream];
    }

	if(theSource4) [self runLoopRemoveSource:theSource4];
	if(theSource6) [self runLoopRemoveSource:theSource6];

	if(theReadTimer) [self runLoopRemoveTimer:theReadTimer];
	if(theWriteTimer) [self runLoopRemoveTimer:theWriteTimer];
	
	theRunLoopModes = [runLoopModes copy];
	
	if(theReadTimer) [self runLoopAddTimer:theReadTimer];
	if(theWriteTimer) [self runLoopAddTimer:theWriteTimer];

	if(theSource4) [self runLoopAddSource:theSource4];
	if(theSource6) [self runLoopAddSource:theSource6];

	if(theReadStream && theWriteStream)
	{
		// Note: theRunLoop variable is a CFRunLoop, and NSRunLoop is NOT toll-free bridged with CFRunLoop.
		// So we cannot pass theRunLoop to the method below, which is expecting a NSRunLoop parameter.
		// Instead we pass nil, which will result in the method properly using the current run loop.
		
		if(![self attachStreamsToRunLoop:nil error:nil])
		{
			return NO;
		}
	}
	
	[self performSelector:@selector(maybeDequeueRead) withObject:nil afterDelay:0 inModes:theRunLoopModes];
	[self performSelector:@selector(maybeDequeueWrite) withObject:nil afterDelay:0 inModes:theRunLoopModes];
	[self performSelector:@selector(maybeScheduleDisconnect) withObject:nil afterDelay:0 inModes:theRunLoopModes];
	
	return YES;
}

- (NSArray *)runLoopModes
{
	return theRunLoopModes;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accepting
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)acceptOnPort:(UInt16)port error:(NSError **)errPtr
{
	return [self acceptOnInterface:nil port:port error:errPtr];
}

/**
 * To accept on a certain interface, pass the address to accept on.
 * To accept on any interface, pass nil or an empty string.
 * To accept only connections from localhost pass "localhost" or "loopback".
 **/
- (BOOL)acceptOnInterface:(NSString *)interface port:(UInt16)port error:(NSError **)errPtr
{
	if (theDelegate == NULL)
    {
		[NSException raise:Leanplum_AsyncSocketException
		            format:@"Attempting to accept without a delegate. Set a delegate first."];
    }
	
	if (theSocket4 != NULL || theSocket6 != NULL)
    {
		[NSException raise:Leanplum_AsyncSocketException
		            format:@"Attempting to accept while connected or accepting connections. Disconnect first."];
    }

	// Set up the listen sockaddr structs if needed.
	
	NSData *address4 = nil, *address6 = nil;
	if(interface == nil || ([interface length] == 0))
	{
		// Accept on ANY address
		struct sockaddr_in nativeAddr4;
		nativeAddr4.sin_len         = sizeof(struct sockaddr_in);
		nativeAddr4.sin_family      = AF_INET;
		nativeAddr4.sin_port        = htons(port);
		nativeAddr4.sin_addr.s_addr = htonl(INADDR_ANY);
		memset(&(nativeAddr4.sin_zero), 0, sizeof(nativeAddr4.sin_zero));
		
		struct sockaddr_in6 nativeAddr6;
		nativeAddr6.sin6_len       = sizeof(struct sockaddr_in6);
		nativeAddr6.sin6_family    = AF_INET6;
		nativeAddr6.sin6_port      = htons(port);
		nativeAddr6.sin6_flowinfo  = 0;
		nativeAddr6.sin6_addr      = in6addr_any;
		nativeAddr6.sin6_scope_id  = 0;
		
		// Wrap the native address structures for CFSocketSetAddress.
		address4 = [NSData dataWithBytes:&nativeAddr4 length:sizeof(nativeAddr4)];
		address6 = [NSData dataWithBytes:&nativeAddr6 length:sizeof(nativeAddr6)];
	}
	else if([interface isEqualToString:@"localhost"] || [interface isEqualToString:@"loopback"])
	{
		// Accept only on LOOPBACK address
		struct sockaddr_in nativeAddr4;
		nativeAddr4.sin_len         = sizeof(struct sockaddr_in);
		nativeAddr4.sin_family      = AF_INET;
		nativeAddr4.sin_port        = htons(port);
		nativeAddr4.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
		memset(&(nativeAddr4.sin_zero), 0, sizeof(nativeAddr4.sin_zero));

		struct sockaddr_in6 nativeAddr6;
		nativeAddr6.sin6_len       = sizeof(struct sockaddr_in6);
		nativeAddr6.sin6_family    = AF_INET6;
		nativeAddr6.sin6_port      = htons(port);
		nativeAddr6.sin6_flowinfo  = 0;
		nativeAddr6.sin6_addr      = in6addr_loopback;
		nativeAddr6.sin6_scope_id  = 0;
		
		// Wrap the native address structures for CFSocketSetAddress.
		address4 = [NSData dataWithBytes:&nativeAddr4 length:sizeof(nativeAddr4)];
		address6 = [NSData dataWithBytes:&nativeAddr6 length:sizeof(nativeAddr6)];
	}
	else
	{
		NSString *portStr = [NSString stringWithFormat:@"%hu", port];

#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5
		@synchronized (getaddrinfoLock)
#endif
		{
			struct addrinfo hints, *res, *res0;
			
			memset(&hints, 0, sizeof(hints));
			hints.ai_family   = PF_UNSPEC;
			hints.ai_socktype = SOCK_STREAM;
			hints.ai_protocol = IPPROTO_TCP;
			hints.ai_flags    = AI_PASSIVE;
			
			int error = getaddrinfo([interface UTF8String], [portStr UTF8String], &hints, &res0);
			
			if(error)
			{
				if(errPtr)
				{
					NSString *errMsg = [NSString stringWithCString:gai_strerror(error) encoding:NSASCIIStringEncoding];
					NSDictionary *info = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
					
					*errPtr = [NSError errorWithDomain:@"kCFStreamErrorDomainNetDB" code:error userInfo:info];
				}
			}
			
			for(res = res0; res; res = res->ai_next)
			{
				if(!address4 && (res->ai_family == AF_INET))
				{
					// Found IPv4 address
					// Wrap the native address structures for CFSocketSetAddress.
					address4 = [NSData dataWithBytes:res->ai_addr length:res->ai_addrlen];
				}
				else if(!address6 && (res->ai_family == AF_INET6))
				{
					// Found IPv6 address
					// Wrap the native address structures for CFSocketSetAddress.
					address6 = [NSData dataWithBytes:res->ai_addr length:res->ai_addrlen];
				}
			}
			freeaddrinfo(res0);
		}
		
		if(!address4 && !address6) return NO;
	}

	// Create the sockets.

	if (address4)
	{
		theSocket4 = [self newAcceptSocketForAddress:address4 error:errPtr];
		if (theSocket4 == NULL) goto Failed;
	}
	
	if (address6)
	{
		theSocket6 = [self newAcceptSocketForAddress:address6 error:errPtr];
		
		// Note: The iPhone doesn't currently support IPv6
		
#if !TARGET_OS_IPHONE
		if (theSocket6 == NULL) goto Failed;
#endif
	}
	
	// Attach the sockets to the run loop so that callback methods work
	
	[self attachSocketsToRunLoop:nil error:nil];
	
	// Set the SO_REUSEADDR flags.

	int reuseOn = 1;
	if (theSocket4)	setsockopt(CFSocketGetNative(theSocket4), SOL_SOCKET, SO_REUSEADDR, &reuseOn, sizeof(reuseOn));
	if (theSocket6)	setsockopt(CFSocketGetNative(theSocket6), SOL_SOCKET, SO_REUSEADDR, &reuseOn, sizeof(reuseOn));

	// Set the local bindings which causes the sockets to start listening.

	CFSocketError err;
	if (theSocket4)
	{
		err = CFSocketSetAddress (theSocket4, (CFDataRef)address4);
		if (err != kCFSocketSuccess) goto Failed;
		
		//NSLog(@"Leanplum: theSocket4: %hu", [self localPort:theSocket4]);
	}
	
	if(port == 0 && theSocket4 && theSocket6 && address6)
	{
		// The user has passed in port 0, which means he wants to allow the kernel to choose the port for them
		// However, the kernel will choose a different port for both theSocket4 and theSocket6
		// So we grab the port the kernel choose for theSocket4, and set it as the port for theSocket6
		UInt16 chosenPort = [self localPort:theSocket4];
		
		struct sockaddr_in6 *pSockAddr6 = (struct sockaddr_in6 *)[address6 bytes];
		pSockAddr6->sin6_port = htons(chosenPort);
    }
	
	if (theSocket6)
	{
		err = CFSocketSetAddress (theSocket6, (CFDataRef)address6);
		if (err != kCFSocketSuccess) goto Failed;
		
		//NSLog(@"Leanplum: theSocket6: %hu", [self localPort:theSocket6]);
	}

	theFlags |= kDidPassConnectMethod;
	return YES;
	
Failed:
	if(errPtr) *errPtr = [self getSocketError];
	if(theSocket4 != NULL)
	{
		CFSocketInvalidate(theSocket4);
		CFRelease(theSocket4);
		theSocket4 = NULL;
	}
	if(theSocket6 != NULL)
	{
		CFSocketInvalidate(theSocket6);
		CFRelease(theSocket6);
		theSocket6 = NULL;
	}
	return NO;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Connecting
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)connectToHost:(NSString*)hostname onPort:(UInt16)port error:(NSError **)errPtr
{
	return [self connectToHost:hostname onPort:port withTimeout:-1 error:errPtr];
}

/**
 * This method creates an initial CFReadStream and CFWriteStream to the given host on the given port.
 * The connection is then opened, and the corresponding CFSocket will be extracted after the connection succeeds.
 *
 * Thus the delegate will have access to the CFReadStream and CFWriteStream prior to connection,
 * specifically in the onSocketWillConnect: method.
 **/
- (BOOL)connectToHost:(NSString *)hostname
			   onPort:(UInt16)port
		  withTimeout:(NSTimeInterval)timeout
				error:(NSError **)errPtr
{
	if(theDelegate == NULL)
	{
		[NSException raise:Leanplum_AsyncSocketException
		            format:@"Attempting to connect without a delegate. Set a delegate first."];
	}

	if(theSocket4 != NULL || theSocket6 != NULL)
	{
		[NSException raise:Leanplum_AsyncSocketException
		            format:@"Attempting to connect while connected or accepting connections. Disconnect first."];
	}
	
	if(![self createStreamsToHost:hostname onPort:port error:errPtr]) goto Failed;
	if(![self attachStreamsToRunLoop:nil error:errPtr])               goto Failed;
	if(![self configureStreamsAndReturnError:errPtr])                 goto Failed;
	if(![self openStreamsAndReturnError:errPtr])                      goto Failed;
	
	[self startConnectTimeout:timeout];
	theFlags |= kDidPassConnectMethod;
	
	return YES;
	
Failed:
	[self close];
	return NO;
}

- (BOOL)connectToAddress:(NSData *)remoteAddr error:(NSError **)errPtr
{
	return [self connectToAddress:remoteAddr withTimeout:-1 error:errPtr];
}

/**
 * This method creates an initial CFSocket to the given address.
 * The connection is then opened, and the corresponding CFReadStream and CFWriteStream will be
 * created from the low-level sockets after the connection succeeds.
 *
 * Thus the delegate will have access to the CFSocket and CFSocketNativeHandle (BSD socket) prior to connection,
 * specifically in the onSocketWillConnect: method.
 *
 * Note: The NSData parameter is expected to be a sockaddr structure. For example, an NSData object returned from
 * NSNetservice addresses method.
 * If you have an existing struct sockaddr you can convert it to an NSData object like so:
 * struct sockaddr sa  -> NSData *dsa = [NSData dataWithBytes:&remoteAddr length:remoteAddr.sa_len];
 * struct sockaddr *sa -> NSData *dsa = [NSData dataWithBytes:remoteAddr length:remoteAddr->sa_len];
 **/
- (BOOL)connectToAddress:(NSData *)remoteAddr withTimeout:(NSTimeInterval)timeout error:(NSError **)errPtr
{
	if (theDelegate == NULL)
	{
		[NSException raise:Leanplum_AsyncSocketException
		            format:@"Attempting to connect without a delegate. Set a delegate first."];
	}
	
	if (theSocket4 != NULL || theSocket6 != NULL)
	{
		[NSException raise:Leanplum_AsyncSocketException
		            format:@"Attempting to connect while connected or accepting connections. Disconnect first."];
	}
	
	if(![self createSocketForAddress:remoteAddr error:errPtr])   goto Failed;
	if(![self attachSocketsToRunLoop:nil error:errPtr])          goto Failed;
	if(![self configureSocketAndReturnError:errPtr])             goto Failed;
	if(![self connectSocketToAddress:remoteAddr error:errPtr])   goto Failed;
	
	[self startConnectTimeout:timeout];
	theFlags |= kDidPassConnectMethod;
	
	return YES;
	
Failed:
	[self close];
	return NO;
}

- (void)startConnectTimeout:(NSTimeInterval)timeout
{
	if(timeout >= 0.0)
	{
		theConnectTimer = [NSTimer timerWithTimeInterval:timeout
											      target:self
											    selector:@selector(doConnectTimeout:)
											    userInfo:nil
											     repeats:NO];
		[self runLoopAddTimer:theConnectTimer];
	}
}

- (void)endConnectTimeout
{
	[theConnectTimer invalidate];
	theConnectTimer = nil;
}

- (void)doConnectTimeout:(NSTimer *)timer
{
	[self endConnectTimeout];
	[self closeWithError:[self getConnectTimeoutError]];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Socket Implementation
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Creates the accept sockets.
 * Returns true if either IPv4 or IPv6 is created.
 * If either is missing, an error is returned (even though the method may return true).
 **/
- (CFSocketRef)newAcceptSocketForAddress:(NSData *)addr error:(NSError **)errPtr
{
	struct sockaddr *pSockAddr = (struct sockaddr *)[addr bytes];
	int addressFamily = pSockAddr->sa_family;
	
	CFSocketRef theSocket = CFSocketCreate(kCFAllocatorDefault,
	                                       addressFamily,
	                                       SOCK_STREAM,
	                                       0,
	                                       kCFSocketAcceptCallBack,                // Callback flags
	                                       (CFSocketCallBack)&MyCFSocketCallback,  // Callback method
	                                       &theContext);

	if(theSocket == NULL)
	{
		if(errPtr) *errPtr = [self getSocketError];
	}
	
	return theSocket;
}

- (BOOL)createSocketForAddress:(NSData *)remoteAddr error:(NSError **)errPtr
{
	struct sockaddr *pSockAddr = (struct sockaddr *)[remoteAddr bytes];
	
	if(pSockAddr->sa_family == AF_INET)
	{
		theSocket4 = CFSocketCreate(NULL,                                   // Default allocator
		                            PF_INET,                                // Protocol Family
		                            SOCK_STREAM,                            // Socket Type
		                            IPPROTO_TCP,                            // Protocol
		                            kCFSocketConnectCallBack,               // Callback flags
		                            (CFSocketCallBack)&MyCFSocketCallback,  // Callback method
		                            &theContext);                           // Socket Context
		
		if(theSocket4 == NULL)
		{
			if (errPtr) *errPtr = [self getSocketError];
			return NO;
		}
	}
	else if(pSockAddr->sa_family == AF_INET6)
	{
		theSocket6 = CFSocketCreate(NULL,                                   // Default allocator
								    PF_INET6,                               // Protocol Family
								    SOCK_STREAM,                            // Socket Type
								    IPPROTO_TCP,                            // Protocol
								    kCFSocketConnectCallBack,               // Callback flags
								    (CFSocketCallBack)&MyCFSocketCallback,  // Callback method
								    &theContext);                           // Socket Context
		
		if(theSocket6 == NULL)
		{
			if (errPtr) *errPtr = [self getSocketError];
			return NO;
		}
	}
	else
	{
		if (errPtr) *errPtr = [self getSocketError];
		return NO;
	}
	
	return YES;
}

/**
 * Adds the CFSocket's to the run-loop so that callbacks will work properly.
 **/
- (BOOL)attachSocketsToRunLoop:(NSRunLoop *)runLoop error:(NSError **)errPtr
{	
	// Get the CFRunLoop to which the socket should be attached.
	theRunLoop = (runLoop == nil) ? CFRunLoopGetCurrent() : [runLoop getCFRunLoop];
	
	if(theSocket4)
	{
		theSource4 = CFSocketCreateRunLoopSource (kCFAllocatorDefault, theSocket4, 0);
        [self runLoopAddSource:theSource4];
	}
	
	if(theSocket6)
	{
		theSource6 = CFSocketCreateRunLoopSource (kCFAllocatorDefault, theSocket6, 0);
        [self runLoopAddSource:theSource6];
	}
	
	return YES;
}

/**
 * Allows the delegate method to configure the CFSocket or CFNativeSocket as desired before we connect.
 * Note that the CFReadStream and CFWriteStream will not be available until after the connection is opened.
 **/
- (BOOL)configureSocketAndReturnError:(NSError **)errPtr
{
	// Call the delegate method for further configuration.
	if([theDelegate respondsToSelector:@selector(onSocketWillConnect:)])
	{
		if([theDelegate onSocketWillConnect:self] == NO)
		{
			if (errPtr) *errPtr = [self getAbortError];
			return NO;
		}
	}
	return YES;
}

- (BOOL)connectSocketToAddress:(NSData *)remoteAddr error:(NSError **)errPtr
{
	// Start connecting to the given address in the background
	// The MyCFSocketCallback method will be called when the connection succeeds or fails
	if(theSocket4)
	{
		CFSocketError err = CFSocketConnectToAddress(theSocket4, (CFDataRef)remoteAddr, -1);
		if(err != kCFSocketSuccess)
		{
			if (errPtr) *errPtr = [self getSocketError];
			return NO;
		}
	}
	else if(theSocket6)
	{
		CFSocketError err = CFSocketConnectToAddress(theSocket6, (CFDataRef)remoteAddr, -1);
		if(err != kCFSocketSuccess)
		{
			if (errPtr) *errPtr = [self getSocketError];
			return NO;
		}
	}
	
	return YES;
}

/**
 * Attempt to make the new socket.
 * If an error occurs, ignore this event.
 **/
- (void)doAcceptWithSocket:(CFSocketNativeHandle)newNative
{
	// New socket inherits same delegate and run loop modes.
	// Note: We use [self class] to support subclassing AsyncSocket.
	Leanplum_AsyncSocket *newSocket = [[[self class] alloc] initWithDelegate:theDelegate];
	[newSocket setRunLoopModes:theRunLoopModes];
	
	if(newSocket)
	{
		if ([theDelegate respondsToSelector:@selector(onSocket:didAcceptNewSocket:)])
			[theDelegate onSocket:self didAcceptNewSocket:newSocket];
		
		NSRunLoop *runLoop = nil;
		if ([theDelegate respondsToSelector:@selector(onSocket:wantsRunLoopForNewSocket:)])
			runLoop = [theDelegate onSocket:self wantsRunLoopForNewSocket:newSocket];
		
		BOOL pass = YES;
		
		if(pass && ![newSocket createStreamsFromNative:newNative error:nil]) pass = NO;
		if(pass && ![newSocket attachStreamsToRunLoop:runLoop error:nil])    pass = NO;
		if(pass && ![newSocket configureStreamsAndReturnError:nil])          pass = NO;
		if(pass && ![newSocket openStreamsAndReturnError:nil])               pass = NO;
		
		if(pass)
			newSocket->theFlags |= kDidPassConnectMethod;
		else {
			// No NSError, but errors will still get logged from the above functions.
			[newSocket close];
		}
		
	}
}

/**
 * Description forthcoming...
 **/
- (void)doSocketOpen:(CFSocketRef)sock withCFSocketError:(CFSocketError)socketError
{
	NSParameterAssert ((sock == theSocket4) || (sock == theSocket6));
	
	if(socketError == kCFSocketTimeout || socketError == kCFSocketError)
	{
		[self closeWithError:[self getSocketError]];
		return;
	}
	
	// Get the underlying native (BSD) socket
	CFSocketNativeHandle nativeSocket = CFSocketGetNative(sock);
	
	// Setup the socket so that invalidating the socket will not close the native socket
	CFSocketSetSocketFlags(sock, 0);
	
	// Invalidate and release the CFSocket - All we need from here on out is the nativeSocket
	// Note: If we don't invalidate the socket (leaving the native socket open)
	// then theReadStream and theWriteStream won't function properly.
	// Specifically, their callbacks won't work, with the exception of kCFStreamEventOpenCompleted.
	// I'm not entirely sure why this is, but I'm guessing that events on the socket fire to the CFSocket we created,
	// as opposed to the CFReadStream/CFWriteStream.
	
	CFSocketInvalidate(sock);
	CFRelease(sock);
	theSocket4 = NULL;
	theSocket6 = NULL;
	
	NSError *err;
	BOOL pass = YES;
	
	if(pass && ![self createStreamsFromNative:nativeSocket error:&err]) pass = NO;
	if(pass && ![self attachStreamsToRunLoop:nil error:&err])           pass = NO;
	if(pass && ![self openStreamsAndReturnError:&err])                  pass = NO;
	
	if(!pass)
	{
		[self closeWithError:err];
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Stream Implementation
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Creates the CFReadStream and CFWriteStream from the given native socket.
 * The CFSocket may be extracted from either stream after the streams have been opened.
 *
 * Note: The given native socket must already be connected!
 **/
- (BOOL)createStreamsFromNative:(CFSocketNativeHandle)native error:(NSError **)errPtr
{
	// Create the socket & streams.
	CFStreamCreatePairWithSocket(kCFAllocatorDefault, native, &theReadStream, &theWriteStream);
	if (theReadStream == NULL || theWriteStream == NULL)
	{
		NSError *err = [self getStreamError];
		
		NSLog (@"Leanplum: AsyncSocket %p couldn't create streams from accepted socket: %@", self, err);
		
		if (errPtr) *errPtr = err;
		return NO;
	}
	
	// Ensure the CF & BSD socket is closed when the streams are closed.
	CFReadStreamSetProperty(theReadStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
	CFWriteStreamSetProperty(theWriteStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
	
	return YES;
}

/**
 * Creates the CFReadStream and CFWriteStream from the given hostname and port number.
 * The CFSocket may be extracted from either stream after the streams have been opened.
 **/
- (BOOL)createStreamsToHost:(NSString *)hostname onPort:(UInt16)port error:(NSError **)errPtr
{
	// Create the socket & streams.
	CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (__bridge CFStringRef)hostname, port, &theReadStream, &theWriteStream);
	if (theReadStream == NULL || theWriteStream == NULL)
	{
		if (errPtr) *errPtr = [self getStreamError];
		return NO;
	}
	
	// Ensure the CF & BSD socket is closed when the streams are closed.
	CFReadStreamSetProperty(theReadStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
	CFWriteStreamSetProperty(theWriteStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
	
	return YES;
}

- (BOOL)attachStreamsToRunLoop:(NSRunLoop *)runLoop error:(NSError **)errPtr
{
	// Get the CFRunLoop to which the socket should be attached.
	theRunLoop = (runLoop == nil) ? CFRunLoopGetCurrent() : [runLoop getCFRunLoop];

	// Setup read stream callbacks
	
	CFOptionFlags readStreamEvents = kCFStreamEventHasBytesAvailable |
    kCFStreamEventErrorOccurred     |
    kCFStreamEventEndEncountered    |
    kCFStreamEventOpenCompleted;
	
	if (!CFReadStreamSetClient(theReadStream,
							   readStreamEvents,
							   (CFReadStreamClientCallBack)&MyCFReadStreamCallback,
							   (CFStreamClientContext *)(&theContext)))
	{
		NSError *err = [self getStreamError];
		
		NSLog (@"Leanplum: AsyncSocket %p couldn't attach read stream to run-loop,", self);
		NSLog (@"Leanplum: Error: %@", err);
		
		if (errPtr) *errPtr = err;
		return NO;
	}

	// Setup write stream callbacks
	
	CFOptionFlags writeStreamEvents = kCFStreamEventCanAcceptBytes |
    kCFStreamEventErrorOccurred  |
    kCFStreamEventEndEncountered |
    kCFStreamEventOpenCompleted;
	
	if (!CFWriteStreamSetClient (theWriteStream,
								 writeStreamEvents,
								 (CFWriteStreamClientCallBack)&MyCFWriteStreamCallback,
								 (CFStreamClientContext *)(&theContext)))
	{
		NSError *err = [self getStreamError];
		
		NSLog (@"Leanplum: AsyncSocket %p couldn't attach write stream to run-loop,", self);
		NSLog (@"Leanplum: Error: %@", err);
		
		if (errPtr) *errPtr = err;
		return NO;
	}
	
	// Add read and write streams to run loop
	
	unsigned i, count = (unsigned)[theRunLoopModes count];
	for(i = 0; i < count; i++)
	{
		CFStringRef runLoopMode = (__bridge CFStringRef)theRunLoopModes[i];
		CFReadStreamScheduleWithRunLoop(theReadStream, theRunLoop, runLoopMode);
		CFWriteStreamScheduleWithRunLoop(theWriteStream, theRunLoop, runLoopMode);
	}
	
	return YES;
}

/**
 * Allows the delegate method to configure the CFReadStream and/or CFWriteStream as desired before we connect.
 * Note that the CFSocket and CFNativeSocket will not be available until after the connection is opened.
 **/
- (BOOL)configureStreamsAndReturnError:(NSError **)errPtr
{
	// Call the delegate method for further configuration.
	if([theDelegate respondsToSelector:@selector(onSocketWillConnect:)])
	{
		if([theDelegate onSocketWillConnect:self] == NO)
		{
			if (errPtr) *errPtr = [self getAbortError];
			return NO;
		}
	}
	return YES;
}

- (BOOL)openStreamsAndReturnError:(NSError **)errPtr
{
	BOOL pass = YES;
	
	if(pass && !CFReadStreamOpen (theReadStream))
	{
		NSLog (@"Leanplum: AsyncSocket %p couldn't open read stream,", self);
		pass = NO;
	}
	
	if(pass && !CFWriteStreamOpen (theWriteStream))
	{
		NSLog (@"Leanplum: AsyncSocket %p couldn't open write stream,", self);
		pass = NO;
	}
	
	if(!pass)
	{
		if (errPtr) *errPtr = [self getStreamError];
	}
	
	return pass;
}

/**
 * Called when read or write streams open.
 * When the socket is connected and both streams are open, consider the AsyncSocket instance to be ready.
 **/
- (void)doStreamOpen
{
	NSError *err = nil;
	if ((theFlags & kDidCompleteOpenForRead) && (theFlags & kDidCompleteOpenForWrite))
	{
		// Get the socket.
		if (![self setSocketFromStreamsAndReturnError: &err])
		{
			NSLog (@"Leanplum: AsyncSocket %p couldn't get socket from streams, %@. Disconnecting.", self, err);
			[self closeWithError:err];
			return;
		}
		
        // Stop the connection attempt timeout timer
		[self endConnectTimeout];

		if ([theDelegate respondsToSelector:@selector(onSocket:didConnectToHost:port:)])
		{
			[theDelegate onSocket:self didConnectToHost:[self connectedHost] port:[self connectedPort]];
		}
		
		// Immediately deal with any already-queued requests.
		[self maybeDequeueRead];
		[self maybeDequeueWrite];
	}
}

- (BOOL)setSocketFromStreamsAndReturnError:(NSError **)errPtr
{
	// Get the CFSocketNativeHandle from theReadStream
	CFSocketNativeHandle native;
	CFDataRef nativeProp = CFReadStreamCopyProperty(theReadStream, kCFStreamPropertySocketNativeHandle);
	if(nativeProp == NULL)
	{
		if (errPtr) *errPtr = [self getStreamError];
		return NO;
	}
	
	CFDataGetBytes(nativeProp, CFRangeMake(0, CFDataGetLength(nativeProp)), (UInt8 *)&native);
	CFRelease(nativeProp);
	
	CFSocketRef theSocket = CFSocketCreateWithNative(kCFAllocatorDefault, native, 0, NULL, NULL);
	if(theSocket == NULL)
	{
		if (errPtr) *errPtr = [self getSocketError];
		return NO;
	}
	
	// Determine whether the connection was IPv4 or IPv6
	CFDataRef peeraddr = CFSocketCopyPeerAddress(theSocket);
	if(peeraddr == NULL)
	{
		NSLog(@"Leanplum: AsyncSocket couldn't determine IP version of socket");
		
		CFRelease(theSocket);
		
		if (errPtr) *errPtr = [self getSocketError];
		return NO;
	}
	struct sockaddr *sa = (struct sockaddr *)CFDataGetBytePtr(peeraddr);
	
	if(sa->sa_family == AF_INET)
	{
		theSocket4 = theSocket;
	}
	else
	{
		theSocket6 = theSocket;
	}
	
	CFRelease(peeraddr);

	return YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Disconnect Implementation
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Sends error message and disconnects
- (void)closeWithError:(NSError *)err
{
	theFlags |= kClosingWithError;
	
	if (theFlags & kDidPassConnectMethod)
	{
		// Try to salvage what data we can.
		[self recoverUnreadData];
		
		// Let the delegate know, so it can try to recover if it likes.
		if ([theDelegate respondsToSelector:@selector(onSocket:willDisconnectWithError:)])
		{
			[theDelegate onSocket:self willDisconnectWithError:err];
		}
	}
	[self close];
}

// Prepare partially read data for recovery.
- (void)recoverUnreadData
{
	if(theCurrentRead != nil)
	{
		// We never finished the current read.
		// Check to see if it's a normal read packet (not AsyncSpecialPacket) and if it had read anything yet.
		
		if(([theCurrentRead isKindOfClass:[Leanplum_AsyncReadPacket class]]) && (theCurrentRead->bytesDone > 0))
		{
			// We need to move its data into the front of the partial read buffer.
			
			[partialReadBuffer replaceBytesInRange:NSMakeRange(0, 0)
										 withBytes:[theCurrentRead->buffer bytes]
											length:theCurrentRead->bytesDone];
		}
	}
	
	[self emptyQueues];
}

- (void)emptyQueues
{
	if (theCurrentRead != nil)	[self endCurrentRead];
	if (theCurrentWrite != nil)	[self endCurrentWrite];
	
	[theReadQueue removeAllObjects];
	[theWriteQueue removeAllObjects];
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(maybeDequeueRead) object:nil];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(maybeDequeueWrite) object:nil];
	
	theFlags &= ~kDequeueReadScheduled;
	theFlags &= ~kDequeueWriteScheduled;
}

/**
 * Disconnects. This is called for both error and clean disconnections.
 **/
- (void)close
{
	// Empty queues
	[self emptyQueues];
	
	// Clear partialReadBuffer (pre-buffer and also unreadData buffer in case of error)
	[partialReadBuffer replaceBytesInRange:NSMakeRange(0, [partialReadBuffer length]) withBytes:NULL length:0];
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(disconnect) object:nil];
	
	// Stop the connection attempt timeout timer
	if (theConnectTimer != nil)
	{
		[self endConnectTimeout];
	}
	
	// Close streams.
	if (theReadStream != NULL)
	{
        [self runLoopUnscheduleReadStream];
		CFReadStreamClose(theReadStream);
		CFRelease(theReadStream);
		theReadStream = NULL;
	}
	if (theWriteStream != NULL)
	{
        [self runLoopUnscheduleWriteStream];
		CFWriteStreamClose(theWriteStream);
		CFRelease(theWriteStream);
		theWriteStream = NULL;
	}
	
	// Close sockets.
	if (theSocket4 != NULL)
	{
		CFSocketInvalidate (theSocket4);
		CFRelease (theSocket4);
		theSocket4 = NULL;
	}
	if (theSocket6 != NULL)
	{
		CFSocketInvalidate (theSocket6);
		CFRelease (theSocket6);
		theSocket6 = NULL;
	}
    if (theSource4 != NULL)
    {
        [self runLoopRemoveSource:theSource4];
		CFRelease (theSource4);
		theSource4 = NULL;
	}
	if (theSource6 != NULL)
	{
        [self runLoopRemoveSource:theSource6];
		CFRelease (theSource6);
		theSource6 = NULL;
	}
	theRunLoop = NULL;
	
	// If the client has passed the connect/accept method, then the connection has at least begun.
	// Notify delegate that it is now ending.
	BOOL shouldCallDelegate = (theFlags & kDidPassConnectMethod);
	
	// Clear all flags (except the pre-buffering flag, which should remain as is)
	theFlags &= kEnablePreBuffering;
	
	if (shouldCallDelegate)
	{
		if ([theDelegate respondsToSelector: @selector(onSocketDidDisconnect:)])
		{
			[theDelegate onSocketDidDisconnect:self];
		}
	}
	
	// Do not access any instance variables after calling onSocketDidDisconnect.
	// This gives the delegate freedom to release us without returning here and crashing.
}

/**
 * Disconnects immediately. Any pending reads or writes are dropped.
 **/
- (void)disconnect
{
	[self close];
}

/**
 * Diconnects after all pending reads have completed.
 **/
- (void)disconnectAfterReading
{
	theFlags |= (kForbidReadsWrites | kDisconnectAfterReads);
	
	[self maybeScheduleDisconnect];
}

/**
 * Disconnects after all pending writes have completed.
 **/
- (void)disconnectAfterWriting
{
	theFlags |= (kForbidReadsWrites | kDisconnectAfterWrites);
	
	[self maybeScheduleDisconnect];
}

/**
 * Disconnects after all pending reads and writes have completed.
 **/
- (void)disconnectAfterReadingAndWriting
{
	theFlags |= (kForbidReadsWrites | kDisconnectAfterReads | kDisconnectAfterWrites);
	
	[self maybeScheduleDisconnect];
}

/**
 * Schedules a call to disconnect if possible.
 * That is, if all writes have completed, and we're set to disconnect after writing,
 * or if all reads have completed, and we're set to disconnect after reading.
 **/
- (void)maybeScheduleDisconnect
{
	BOOL shouldDisconnect = NO;
	
	if(theFlags & kDisconnectAfterReads)
	{
		if(([theReadQueue count] == 0) && (theCurrentRead == nil))
		{
			if(theFlags & kDisconnectAfterWrites)
			{
				if(([theWriteQueue count] == 0) && (theCurrentWrite == nil))
				{
					shouldDisconnect = YES;
				}
			}
			else
			{
				shouldDisconnect = YES;
			}
		}
	}
	else if(theFlags & kDisconnectAfterWrites)
	{
		if(([theWriteQueue count] == 0) && (theCurrentWrite == nil))
		{
			shouldDisconnect = YES;
		}
	}
	
	if(shouldDisconnect)
	{
		[self performSelector:@selector(disconnect) withObject:nil afterDelay:0 inModes:theRunLoopModes];
	}
}

/**
 * In the event of an error, this method may be called during onSocket:willDisconnectWithError: to read
 * any data that's left on the socket.
 **/
- (NSData *)unreadData
{
	// Ensure this method will only return data in the event of an error
	if(!(theFlags & kClosingWithError)) return nil;
	
	if(theReadStream == NULL) return nil;
	
	CFIndex totalBytesRead = [partialReadBuffer length];
	BOOL error = NO;
	while(!error && CFReadStreamHasBytesAvailable(theReadStream))
	{
		[partialReadBuffer increaseLengthBy:READALL_CHUNKSIZE];
		
		// Number of bytes to read is space left in packet buffer.
		CFIndex bytesToRead = [partialReadBuffer length] - totalBytesRead;
		
		// Read data into packet buffer
		UInt8 *packetbuf = (UInt8 *)( [partialReadBuffer mutableBytes] + totalBytesRead );
		CFIndex bytesRead = CFReadStreamRead(theReadStream, packetbuf, bytesToRead);
		
		// Check results
		if(bytesRead < 0)
		{
			error = YES;
		}
		else
		{
			totalBytesRead += bytesRead;
		}
	}
	
	[partialReadBuffer setLength:totalBytesRead];
	
	return partialReadBuffer;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Errors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Returns a standard error object for the current errno value.
 * Errno is used for low-level BSD socket errors.
 **/
- (NSError *)getErrnoError
{
	NSString *errorMsg = [NSString stringWithUTF8String:strerror(errno)];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errorMsg forKey:NSLocalizedDescriptionKey];
	
	return [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:userInfo];
}

/**
 * Returns a standard error message for a CFSocket error.
 * Unfortunately, CFSocket offers no feedback on its errors.
 **/
- (NSError *)getSocketError
{
	NSString *errMsg = NSLocalizedStringWithDefaultValue(@"AsyncSocketCFSocketError",
														 @"AsyncSocket", [NSBundle mainBundle],
														 @"General CFSocket error", nil);
	
	NSDictionary *info = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
	
	return [NSError errorWithDomain:Leanplum_AsyncSocketErrorDomain code:AsyncSocketCFSocketError userInfo:info];
}

- (NSError *)getStreamError
{
	CFStreamError err;
	if (theReadStream != NULL)
	{
		err = CFReadStreamGetError (theReadStream);
		if (err.error != 0) return [self errorFromCFStreamError: err];
	}
	
	if (theWriteStream != NULL)
	{
		err = CFWriteStreamGetError (theWriteStream);
		if (err.error != 0) return [self errorFromCFStreamError: err];
	}
	
	return nil;
}

/**
 * Returns a standard AsyncSocket abort error.
 **/
- (NSError *)getAbortError
{
	NSString *errMsg = NSLocalizedStringWithDefaultValue(@"AsyncSocketCanceledError",
														 @"AsyncSocket", [NSBundle mainBundle],
														 @"Connection canceled", nil);
	
	NSDictionary *info = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
	
	return [NSError errorWithDomain:Leanplum_AsyncSocketErrorDomain code:AsyncSocketCanceledError userInfo:info];
}

/**
 * Returns a standard AsyncSocket connect timeout error.
 **/
- (NSError *)getConnectTimeoutError
{
	NSString *errMsg = NSLocalizedStringWithDefaultValue(@"AsyncSocketConnectTimeoutError",
														 @"AsyncSocket", [NSBundle mainBundle],
														 @"Attempt to connect to host timed out", nil);
	
	NSDictionary *info = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
	
	return [NSError errorWithDomain:Leanplum_AsyncSocketErrorDomain code:AsyncSocketConnectTimeoutError userInfo:info];
}

/**
 * Returns a standard AsyncSocket maxed out error.
 **/
- (NSError *)getReadMaxedOutError
{
	NSString *errMsg = NSLocalizedStringWithDefaultValue(@"AsyncSocketReadMaxedOutError",
														 @"AsyncSocket", [NSBundle mainBundle],
														 @"Read operation reached set maximum length", nil);
	
	NSDictionary *info = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
	
	return [NSError errorWithDomain:Leanplum_AsyncSocketErrorDomain code:AsyncSocketReadMaxedOutError userInfo:info];
}

/**
 * Returns a standard AsyncSocket read timeout error.
 **/
- (NSError *)getReadTimeoutError
{
	NSString *errMsg = NSLocalizedStringWithDefaultValue(@"AsyncSocketReadTimeoutError",
														 @"AsyncSocket", [NSBundle mainBundle],
														 @"Read operation timed out", nil);
	
	NSDictionary *info = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
	
	return [NSError errorWithDomain:Leanplum_AsyncSocketErrorDomain code:AsyncSocketReadTimeoutError userInfo:info];
}

/**
 * Returns a standard AsyncSocket write timeout error.
 **/
- (NSError *)getWriteTimeoutError
{
	NSString *errMsg = NSLocalizedStringWithDefaultValue(@"AsyncSocketWriteTimeoutError",
														 @"AsyncSocket", [NSBundle mainBundle],
														 @"Write operation timed out", nil);
	
	NSDictionary *info = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
	
	return [NSError errorWithDomain:Leanplum_AsyncSocketErrorDomain code:AsyncSocketWriteTimeoutError userInfo:info];
}

- (NSError *)errorFromCFStreamError:(CFStreamError)err
{
	if (err.domain == 0 && err.error == 0) return nil;
	
	// Can't use switch; these constants aren't int literals.
	NSString *domain = @"CFStreamError (unlisted domain)";
	NSString *message = nil;
	
	if(err.domain == kCFStreamErrorDomainPOSIX) {
		domain = NSPOSIXErrorDomain;
	}
	else if(err.domain == kCFStreamErrorDomainMacOSStatus) {
		domain = NSOSStatusErrorDomain;
	}
	else if(err.domain == kCFStreamErrorDomainMach) {
		domain = NSMachErrorDomain;
	}
	else if(err.domain == kCFStreamErrorDomainNetDB)
	{
		domain = @"kCFStreamErrorDomainNetDB";
		message = [NSString stringWithCString:gai_strerror(err.error) encoding:NSASCIIStringEncoding];
	}
	else if(err.domain == kCFStreamErrorDomainNetServices) {
		domain = @"kCFStreamErrorDomainNetServices";
	}
	else if(err.domain == kCFStreamErrorDomainSOCKS) {
		domain = @"kCFStreamErrorDomainSOCKS";
	}
	else if(err.domain == kCFStreamErrorDomainSystemConfiguration) {
		domain = @"kCFStreamErrorDomainSystemConfiguration";
	}
	else if(err.domain == kCFStreamErrorDomainSSL) {
		domain = @"kCFStreamErrorDomainSSL";
	}
	
	NSDictionary *info = nil;
	if(message != nil)
	{
		info = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
	}
	return [NSError errorWithDomain:domain code:err.error userInfo:info];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Diagnostics
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)isConnected
{
	return [self isSocketConnected] && [self areStreamsConnected];
}

- (NSString *)connectedHost
{
	if(theSocket4)
		return [self connectedHost:theSocket4];
	else
		return [self connectedHost:theSocket6];
}

- (UInt16)connectedPort
{
	if(theSocket4)
		return [self connectedPort:theSocket4];
	else
		return [self connectedPort:theSocket6];
}

- (NSString *)localHost
{
	if(theSocket4)
		return [self localHost:theSocket4];
	else
		return [self localHost:theSocket6];
}

- (UInt16)localPort
{
	if(theSocket4)
		return [self localPort:theSocket4];
	else
		return [self localPort:theSocket6];
}

- (NSString *)connectedHost:(CFSocketRef)theSocket
{
	if (theSocket == NULL) return nil;
	
	CFDataRef peeraddr;
	NSString *peerstr = nil;

	if((peeraddr = CFSocketCopyPeerAddress(theSocket)))
	{
		peerstr = [self addressHost:peeraddr];
		CFRelease (peeraddr);
	}

	return peerstr;
}

- (UInt16)connectedPort:(CFSocketRef)theSocket
{
	if (theSocket == NULL) return 0;
	
	CFDataRef peeraddr;
	UInt16 peerport = 0;

	if((peeraddr = CFSocketCopyPeerAddress(theSocket)))
	{
		peerport = [self addressPort:peeraddr];
		CFRelease (peeraddr);
	}

	return peerport;
}

- (NSString *)localHost:(CFSocketRef)theSocket
{
	if (theSocket == NULL) return nil;
	
	CFDataRef selfaddr;
	NSString *selfstr = nil;

	if((selfaddr = CFSocketCopyAddress(theSocket)))
	{
		selfstr = [self addressHost:selfaddr];
		CFRelease (selfaddr);
	}

	return selfstr;
}

- (UInt16)localPort:(CFSocketRef)theSocket
{
	if (theSocket == NULL) return 0;
	
	CFDataRef selfaddr;
	UInt16 selfport = 0;

	if ((selfaddr = CFSocketCopyAddress(theSocket)))
	{
		selfport = [self addressPort:selfaddr];
		CFRelease (selfaddr);
	}

	return selfport;
}

- (NSString *)addressHost:(CFDataRef)cfaddr
{
	if (cfaddr == NULL) return nil;
	
	char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
	struct sockaddr *pSockAddr = (struct sockaddr *) CFDataGetBytePtr (cfaddr);
	struct sockaddr_in  *pSockAddrV4 = (struct sockaddr_in  *)pSockAddr;
	struct sockaddr_in6 *pSockAddrV6 = (struct sockaddr_in6 *)pSockAddr;

	const void *pAddr = (pSockAddr->sa_family == AF_INET) ?
    (void *)(&(pSockAddrV4->sin_addr)) :
    (void *)(&(pSockAddrV6->sin6_addr));

	const char *pStr = inet_ntop (pSockAddr->sa_family, pAddr, addrBuf, (unsigned)sizeof(addrBuf));
	if (pStr == NULL) [NSException raise: NSInternalInconsistencyException
								  format: @"Cannot convert address to string."];

	return [NSString stringWithCString:pStr encoding:NSASCIIStringEncoding];
}

- (UInt16)addressPort:(CFDataRef)cfaddr
{
	if (cfaddr == NULL) return 0;

	struct sockaddr_in *pAddr = (struct sockaddr_in *) CFDataGetBytePtr (cfaddr);
	return ntohs (pAddr->sin_port);
}

- (NSData *)connectedAddress
{
    CFSocketRef theSocket;

    if (theSocket4)
        theSocket = theSocket4;
    else
        theSocket = theSocket6;

    if (theSocket == NULL) return nil;
	
	CFDataRef peeraddr = CFSocketCopyPeerAddress(theSocket);

    if (peeraddr == NULL) return nil;

#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_5
    NSData *result = [NSData dataWithBytes:CFDataGetBytePtr(peeraddr) length:CFDataGetLength(peeraddr)];
    CFRelease(peeraddr);
    return result;
#else
    return (__bridge NSData *)peeraddr;
#endif
}

- (NSData *)localAddress
{
    CFSocketRef theSocket;

    if (theSocket4)
        theSocket = theSocket4;
    else
        theSocket = theSocket6;

    if (theSocket == NULL) return nil;

    CFDataRef selfaddr = CFSocketCopyAddress(theSocket);

    if (selfaddr == NULL) return nil;

    return CFBridgingRelease(selfaddr);
}

- (BOOL)isIPv4
{
	return (theSocket4 != NULL);
}

- (BOOL)isIPv6
{
	return (theSocket6 != NULL);
}

- (BOOL)isSocketConnected
{
	if(theSocket4 != NULL)
		return CFSocketIsValid(theSocket4);
	else if(theSocket6 != NULL)
		return CFSocketIsValid(theSocket6);
	else
		return NO;
}

- (BOOL)areStreamsConnected
{
	CFStreamStatus s;

	if (theReadStream != NULL)
	{
		s = CFReadStreamGetStatus (theReadStream);
		if ( !(s == kCFStreamStatusOpen || s == kCFStreamStatusReading || s == kCFStreamStatusError) )
			return NO;
	}
	else return NO;

	if (theWriteStream != NULL)
	{
		s = CFWriteStreamGetStatus (theWriteStream);
		if ( !(s == kCFStreamStatusOpen || s == kCFStreamStatusWriting || s == kCFStreamStatusError) )
			return NO;
	}
	else return NO;

	return YES;
}

- (NSString *)description
{
	static const char *statstr[] = {"not open","opening","open","reading","writing","at end","closed","has error"};
	CFStreamStatus rs = (theReadStream != NULL) ? CFReadStreamGetStatus(theReadStream) : 0;
	CFStreamStatus ws = (theWriteStream != NULL) ? CFWriteStreamGetStatus(theWriteStream) : 0;
	
	NSString *peerstr, *selfstr;
	CFDataRef peeraddr4 = NULL, peeraddr6 = NULL, selfaddr4 = NULL, selfaddr6 = NULL;

	if (theSocket4 || theSocket6)
	{
		if (theSocket4) peeraddr4 = CFSocketCopyPeerAddress(theSocket4);
		if (theSocket6) peeraddr6 = CFSocketCopyPeerAddress(theSocket6);

		if(theSocket4 && theSocket6)
		{
			peerstr = [NSString stringWithFormat: @"%@/%@ %u",
					   [self addressHost:peeraddr4], [self addressHost:peeraddr6], [self addressPort:peeraddr4]];
		}
		else if(theSocket4)
		{
			peerstr = [NSString stringWithFormat: @"%@ %u", [self addressHost:peeraddr4], [self addressPort:peeraddr4]];
		}
		else
		{
			peerstr = [NSString stringWithFormat: @"%@ %u", [self addressHost:peeraddr6], [self addressPort:peeraddr6]];
		}
		
		if(peeraddr4) CFRelease(peeraddr4);
		if(peeraddr6) CFRelease(peeraddr6);
		peeraddr4 = NULL;
		peeraddr6 = NULL;
	}
	else peerstr = @"nowhere";

	if (theSocket4 || theSocket6)
	{
		if (theSocket4) selfaddr4 = CFSocketCopyAddress (theSocket4);
		if (theSocket6) selfaddr6 = CFSocketCopyAddress (theSocket6);

		if (theSocket4 && theSocket6)
		{
			selfstr = [NSString stringWithFormat: @"%@/%@ %u",
					   [self addressHost:selfaddr4], [self addressHost:selfaddr6], [self addressPort:selfaddr4]];
		}
		else if (theSocket4)
		{
			selfstr = [NSString stringWithFormat: @"%@ %u", [self addressHost:selfaddr4], [self addressPort:selfaddr4]];
		}
		else
		{
			selfstr = [NSString stringWithFormat: @"%@ %u", [self addressHost:selfaddr6], [self addressPort:selfaddr6]];
		}

		if(selfaddr4) CFRelease(selfaddr4);
		if(selfaddr6) CFRelease(selfaddr6);
		selfaddr4 = NULL;
		selfaddr6 = NULL;
	}
	else selfstr = @"nowhere";
	
	NSMutableString *ms = [[NSMutableString alloc] initWithCapacity:150];
	
	[ms appendString:[NSString stringWithFormat:@"<AsyncSocket %p", self]];
	[ms appendString:[NSString stringWithFormat:@" local %@ remote %@ ", selfstr, peerstr]];
	
	unsigned readQueueCount  = (unsigned)[theReadQueue count];
	unsigned writeQueueCount = (unsigned)[theWriteQueue count];
	
	[ms appendString:[NSString stringWithFormat:@"has queued %u reads %u writes, ", readQueueCount, writeQueueCount]];

	if (theCurrentRead == nil)
		[ms appendString: @"no current read, "];
	else
	{
		int percentDone;
		if ([theCurrentRead->buffer length] != 0)
			percentDone = (float)theCurrentRead->bytesDone /
            (float)[theCurrentRead->buffer length] * 100.0F;
		else
			percentDone = 100.0F;

		[ms appendString: [NSString stringWithFormat:@"currently read %u bytes (%d%% done), ",
                           (unsigned int)[theCurrentRead->buffer length],
                           theCurrentRead->bytesDone ? percentDone : 0]];
	}

	if (theCurrentWrite == nil)
		[ms appendString: @"no current write, "];
	else
	{
		int percentDone;
		if ([theCurrentWrite->buffer length] != 0)
			percentDone = (float)theCurrentWrite->bytesDone /
            (float)[theCurrentWrite->buffer length] * 100.0F;
		else
			percentDone = 100.0F;

		[ms appendString: [NSString stringWithFormat:@"currently written %u (%d%%), ",
                           (unsigned int)[theCurrentWrite->buffer length],
                           theCurrentWrite->bytesDone ? percentDone : 0]];
	}
	
	[ms appendString:[NSString stringWithFormat:@"read stream %p %s, ", theReadStream, statstr[rs]]];
	[ms appendString:[NSString stringWithFormat:@"write stream %p %s", theWriteStream, statstr[ws]]];
	
	if(theFlags & kDisconnectAfterReads)
	{
		if(theFlags & kDisconnectAfterWrites)
			[ms appendString: @", will disconnect after reads & writes"];
		else
			[ms appendString: @", will disconnect after reads"];
	}
	else if(theFlags & kDisconnectAfterWrites)
	{
		[ms appendString: @", will disconnect after writes"];
	}
	
	if (![self isConnected]) [ms appendString: @", not connected"];

	[ms appendString:@">"];

	return ms;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Reading
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)readDataToLength:(CFIndex)length withTimeout:(NSTimeInterval)timeout tag:(long)tag
{
	if(length == 0) return;
	if(theFlags & kForbidReadsWrites) return;
	
	NSMutableData *buffer = [[NSMutableData alloc] initWithLength:length];
	Leanplum_AsyncReadPacket *packet = [[Leanplum_AsyncReadPacket alloc] initWithData:buffer
															timeout:timeout
																tag:tag
												   readAllAvailable:NO
														 terminator:nil
														  maxLength:length];

	[theReadQueue addObject:packet];
	[self scheduleDequeueRead];
}

- (void)readDataToData:(NSData *)data withTimeout:(NSTimeInterval)timeout tag:(long)tag
{
	[self readDataToData:data withTimeout:timeout maxLength:-1 tag:tag];
}

- (void)readDataToData:(NSData *)data withTimeout:(NSTimeInterval)timeout maxLength:(CFIndex)length tag:(long)tag
{
	if(data == nil || [data length] == 0) return;
	if(length >= 0 && length < [data length]) return;
	if(theFlags & kForbidReadsWrites) return;

	NSMutableData *buffer = [[NSMutableData alloc] initWithLength:0];
	Leanplum_AsyncReadPacket *packet = [[Leanplum_AsyncReadPacket alloc] initWithData:buffer
															timeout:timeout
																tag:tag
												   readAllAvailable:NO
														 terminator:data
														  maxLength:length];
	
	[theReadQueue addObject:packet];
	[self scheduleDequeueRead];
}

- (void)readDataWithTimeout:(NSTimeInterval)timeout tag:(long)tag
{
	if (theFlags & kForbidReadsWrites) return;
	
	NSMutableData *buffer = [[NSMutableData alloc] initWithLength:0];
	Leanplum_AsyncReadPacket *packet = [[Leanplum_AsyncReadPacket alloc] initWithData:buffer
															timeout:timeout
																tag:tag
												   readAllAvailable:YES
														 terminator:nil
														  maxLength:-1];
	
	[theReadQueue addObject:packet];
	[self scheduleDequeueRead];
}

/**
 * Puts a maybeDequeueRead on the run loop.
 * An assumption here is that selectors will be performed consecutively within their priority.
 **/
- (void)scheduleDequeueRead
{
	if((theFlags & kDequeueReadScheduled) == 0)
	{
		theFlags |= kDequeueReadScheduled;
		[self performSelector:@selector(maybeDequeueRead) withObject:nil afterDelay:0 inModes:theRunLoopModes];
	}
}

/**
 * This method starts a new read, if needed.
 * It is called when a user requests a read,
 * or when a stream opens that may have requested reads sitting in the queue, etc.
 **/
- (void)maybeDequeueRead
{
	// Unset the flag indicating a call to this method is scheduled
	theFlags &= ~kDequeueReadScheduled;
	
	// If we're not currently processing a read AND we have an available read stream
	if((theCurrentRead == nil) && (theReadStream != NULL))
	{
		if([theReadQueue count] > 0)
		{
			// Dequeue the next object in the write queue
			theCurrentRead = theReadQueue[0];
			[theReadQueue removeObjectAtIndex:0];
			
			if([theCurrentRead isKindOfClass:[Leanplum_AsyncSpecialPacket class]])
			{
				// Attempt to start TLS
				theFlags |= kStartingReadTLS;
				
				// This method won't do anything unless both kStartingReadTLS and kStartingWriteTLS are both set
				[self maybeStartTLS];
			}
			else
			{
				// Start time-out timer
				if(theCurrentRead->timeout >= 0.0)
				{
					theReadTimer = [NSTimer timerWithTimeInterval:theCurrentRead->timeout
														   target:self
														 selector:@selector(doReadTimeout:)
														 userInfo:nil
														  repeats:NO];
					[self runLoopAddTimer:theReadTimer];
				}
				
				// Immediately read, if possible
				[self doBytesAvailable];
			}
		}
		else if(theFlags & kDisconnectAfterReads)
		{
			if(theFlags & kDisconnectAfterWrites)
			{
				if(([theWriteQueue count] == 0) && (theCurrentWrite == nil))
				{
					[self disconnect];
				}
			}
			else
			{
				[self disconnect];
			}
		}
	}
}

/**
 * Call this method in doBytesAvailable instead of CFReadStreamHasBytesAvailable().
 * This method supports pre-buffering properly as well as the kSocketHasBytesAvailable flag.
 **/
- (BOOL)hasBytesAvailable
{
	if ((theFlags & kSocketHasBytesAvailable) || ([partialReadBuffer length] > 0))
	{
		return YES;
	}
	else
	{
		return CFReadStreamHasBytesAvailable(theReadStream);
	}
}

/**
 * Call this method in doBytesAvailable instead of CFReadStreamRead().
 * This method support pre-buffering properly.
 **/
- (CFIndex)readIntoBuffer:(UInt8 *)buffer maxLength:(CFIndex)length
{
	if([partialReadBuffer length] > 0)
	{
		// Determine the maximum amount of data to read
		CFIndex bytesToRead = MIN(length, [partialReadBuffer length]);
		
		// Copy the bytes from the buffer
		memcpy(buffer, [partialReadBuffer bytes], bytesToRead);
		
		// Remove the copied bytes from the buffer
		[partialReadBuffer replaceBytesInRange:NSMakeRange(0, bytesToRead) withBytes:NULL length:0];
		
		return bytesToRead;
	}
	else
	{
		// Unset the "has-bytes-available" flag
		theFlags &= ~kSocketHasBytesAvailable;
		
		return CFReadStreamRead(theReadStream, buffer, length);
	}
}

/**
 * This method is called when a new read is taken from the read queue or when new data becomes available on the stream.
 **/
- (void)doBytesAvailable
{
	// If data is available on the stream, but there is no read request, then we don't need to process the data yet.
	// Also, if there is a read request, but no read stream setup yet, we can't process any data yet.
	if((theCurrentRead != nil) && (theReadStream != NULL))
	{
		// Note: This method is not called if theCurrentRead is an AsyncSpecialPacket (startTLS packet)

		CFIndex totalBytesRead = 0;
		
		BOOL done = NO;
		BOOL socketError = NO;
		BOOL maxoutError = NO;
		
		while(!done && !socketError && !maxoutError && [self hasBytesAvailable])
		{
			BOOL didPreBuffer = NO;
			
			// There are 3 types of read packets:
			//
			// 1) Read a specific length of data.
			// 2) Read all available data.
			// 3) Read up to a particular terminator.
			
			if(theCurrentRead->readAllAvailableData == YES)
			{
				// We're reading all available data.
				//
				// Make sure there is at least READALL_CHUNKSIZE bytes available.
				// We don't want to increase the buffer any more than this or we'll waste space.
				// With prebuffering it's possible to read in a small chunk on the first read.
                unsigned diff = (unsigned)MAX(0, ([theCurrentRead->buffer length] - theCurrentRead->bytesDone));
				unsigned buffInc = READALL_CHUNKSIZE - diff;
				[theCurrentRead->buffer increaseLengthBy:buffInc];
			}
			else if(theCurrentRead->term != nil)
			{
				// We're reading up to a terminator.
				//
				// We may only want to read a few bytes.
				// Just enough to ensure we don't go past our term or over our max limit.
				// Unless pre-buffering is enabled, in which case we may want to read in a larger chunk.
				
				// If we already have data pre-buffered, we obviously don't want to pre-buffer it again.
				// So in this case we'll just read as usual.
				
				if(([partialReadBuffer length] > 0) || !(theFlags & kEnablePreBuffering))
				{
					unsigned maxToRead = [theCurrentRead readLengthForTerm];
					unsigned diff = (unsigned)MAX(0, ([theCurrentRead->buffer length] - theCurrentRead->bytesDone));
					unsigned bufInc = maxToRead - diff;
					[theCurrentRead->buffer increaseLengthBy:bufInc];
				}
				else
				{
					didPreBuffer = YES;
					unsigned maxToRead = [theCurrentRead prebufferReadLengthForTerm];
					unsigned diff = (unsigned)MAX(0, ([theCurrentRead->buffer length] - theCurrentRead->bytesDone));
					unsigned buffInc = maxToRead - diff;
					[theCurrentRead->buffer increaseLengthBy:buffInc];

				}
			}
			
			// Number of bytes to read is space left in packet buffer.
			CFIndex bytesToRead = [theCurrentRead->buffer length] - theCurrentRead->bytesDone;
			
			// Read data into packet buffer
			UInt8 *subBuffer = (UInt8 *)([theCurrentRead->buffer mutableBytes] + theCurrentRead->bytesDone);
			CFIndex bytesRead = [self readIntoBuffer:subBuffer maxLength:bytesToRead];
			
			// Check results
			if(bytesRead < 0)
			{
				socketError = YES;
			}
			else
			{
				// Update total amount read for the current read
				theCurrentRead->bytesDone += bytesRead;
				
				// Update total amount read in this method invocation
				totalBytesRead += bytesRead;
			}

			// Is packet done?
			if(theCurrentRead->readAllAvailableData != YES)
			{
				if(theCurrentRead->term != nil)
				{
					if(didPreBuffer)
					{
						// Search for the terminating sequence within the big chunk we just read.
						CFIndex overflow = [theCurrentRead searchForTermAfterPreBuffering:bytesRead];
						
						if(overflow > 0)
						{
							// Copy excess data into partialReadBuffer
							NSMutableData *buffer = theCurrentRead->buffer;
							const void *overflowBuffer = [buffer bytes] + theCurrentRead->bytesDone - overflow;
							
							[partialReadBuffer appendBytes:overflowBuffer length:overflow];
							
							// Update the bytesDone variable.
							// Note: The completeCurrentRead method will trim the buffer for us.
							theCurrentRead->bytesDone -= overflow;
						}
						
						done = (overflow >= 0);
					}
					else
					{
						// Search for the terminating sequence at the end of the buffer
						int termlen = (int)[theCurrentRead->term length];
						if(theCurrentRead->bytesDone >= termlen)
						{
							const void *buf = [theCurrentRead->buffer bytes] + (theCurrentRead->bytesDone - termlen);
							const void *seq = [theCurrentRead->term bytes];
							done = (memcmp (buf, seq, termlen) == 0);
						}
					}
					
					if(!done && theCurrentRead->maxLength >= 0 && theCurrentRead->bytesDone >= theCurrentRead->maxLength)
					{
						// There's a set maxLength, and we've reached that maxLength without completing the read
						maxoutError = YES;
					}
				}
				else
				{
					// Done when (sized) buffer is full.
					done = ([theCurrentRead->buffer length] == theCurrentRead->bytesDone);
				}
			}
			// else readAllAvailable doesn't end until all readable is read.
		}
		
		if(theCurrentRead->readAllAvailableData && theCurrentRead->bytesDone > 0)
		{
			// Ran out of bytes, so the "read-all-available-data" type packet is done
			done = YES;
		}

		if(done)
		{
			[self completeCurrentRead];
			if (!socketError) [self scheduleDequeueRead];
		}
		else if(totalBytesRead > 0)
		{
			// We're not done with the readToLength or readToData yet, but we have read in some bytes
			if ([theDelegate respondsToSelector:@selector(onSocket:didReadPartialDataOfLength:tag:)])
			{
				[theDelegate onSocket:self didReadPartialDataOfLength:totalBytesRead tag:theCurrentRead->tag];
			}
		}

		if(socketError)
		{
			CFStreamError err = CFReadStreamGetError(theReadStream);
			[self closeWithError:[self errorFromCFStreamError:err]];
			return;
		}
		if(maxoutError)
		{
			[self closeWithError:[self getReadMaxedOutError]];
			return;
		}
	}
}

// Ends current read and calls delegate.
- (void)completeCurrentRead
{
	NSAssert(theCurrentRead, @"Trying to complete current read when there is no current read.");
	
	[theCurrentRead->buffer setLength:theCurrentRead->bytesDone];
	if([theDelegate respondsToSelector:@selector(onSocket:didReadData:withTag:)])
	{
		[theDelegate onSocket:self didReadData:theCurrentRead->buffer withTag:theCurrentRead->tag];
	}
	
	if (theCurrentRead != nil) [self endCurrentRead]; // Caller may have disconnected.
}

// Ends current read.
- (void)endCurrentRead
{
	NSAssert(theCurrentRead, @"Trying to end current read when there is no current read.");
	
	[theReadTimer invalidate];
	theReadTimer = nil;
	
	theCurrentRead = nil;
}

- (void)doReadTimeout:(NSTimer *)timer
{
	NSTimeInterval timeoutExtension = 0.0;
	
	if([theDelegate respondsToSelector:@selector(onSocket:shouldTimeoutReadWithTag:elapsed:bytesDone:)])
	{
		timeoutExtension = [theDelegate onSocket:self shouldTimeoutReadWithTag:theCurrentRead->tag
                                         elapsed:theCurrentRead->timeout
                                       bytesDone:theCurrentRead->bytesDone];
	}
	
	if(timeoutExtension > 0.0)
	{
		theCurrentRead->timeout += timeoutExtension;
		
		theReadTimer = [NSTimer timerWithTimeInterval:timeoutExtension
											   target:self
											 selector:@selector(doReadTimeout:)
											 userInfo:nil
											  repeats:NO];
		[self runLoopAddTimer:theReadTimer];
	}
	else
	{
		// Do not call endCurrentRead here.
		// We must allow the delegate access to any partial read in the unreadData method.
		
		[self closeWithError:[self getReadTimeoutError]];
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Writing
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)writeData:(NSData *)data withTimeout:(NSTimeInterval)timeout tag:(long)tag
{
	if (data == nil || [data length] == 0) return;
	if (theFlags & kForbidReadsWrites) return;
	
	Leanplum_AsyncWritePacket *packet = [[Leanplum_AsyncWritePacket alloc] initWithData:data timeout:timeout tag:tag];
	
	[theWriteQueue addObject:packet];
	[self scheduleDequeueWrite];
}

- (void)scheduleDequeueWrite
{
	if((theFlags & kDequeueWriteScheduled) == 0)
	{
		theFlags |= kDequeueWriteScheduled;
		[self performSelector:@selector(maybeDequeueWrite) withObject:nil afterDelay:0 inModes:theRunLoopModes];
	}
}

/**
 * Conditionally starts a new write.
 *
 * IF there is not another write in process
 * AND there is a write queued
 * AND we have a write stream available
 *
 * This method also handles auto-disconnect post read/write completion.
 **/
- (void)maybeDequeueWrite
{
	// Unset the flag indicating a call to this method is scheduled
	theFlags &= ~kDequeueWriteScheduled;
	
	// If we're not currently processing a write AND we have an available write stream
	if((theCurrentWrite == nil) && (theWriteStream != NULL))
	{
		if([theWriteQueue count] > 0)
		{
			// Dequeue the next object in the write queue
			theCurrentWrite = theWriteQueue[0];
			[theWriteQueue removeObjectAtIndex:0];
			
			if([theCurrentWrite isKindOfClass:[Leanplum_AsyncSpecialPacket class]])
			{
				// Attempt to start TLS
				theFlags |= kStartingWriteTLS;
				
				// This method won't do anything unless both kStartingReadTLS and kStartingWriteTLS are both set
				[self maybeStartTLS];
			}
			else
			{
				// Start time-out timer
				if(theCurrentWrite->timeout >= 0.0)
				{
					theWriteTimer = [NSTimer timerWithTimeInterval:theCurrentWrite->timeout
															target:self
														  selector:@selector(doWriteTimeout:)
														  userInfo:nil
														   repeats:NO];
					[self runLoopAddTimer:theWriteTimer];
				}
				
				// Immediately write, if possible
				[self doSendBytes];
			}
		}
		else if(theFlags & kDisconnectAfterWrites)
		{
			if(theFlags & kDisconnectAfterReads)
			{
				if(([theReadQueue count] == 0) && (theCurrentRead == nil))
				{
					[self disconnect];
				}
			}
			else
			{
				[self disconnect];
			}
		}
	}
}

/**
 * Call this method in doSendBytes instead of CFWriteStreamCanAcceptBytes().
 * This method supports the kSocketCanAcceptBytes flag.
 **/
- (BOOL)canAcceptBytes
{
	if (theFlags & kSocketCanAcceptBytes)
	{
		return YES;
	}
	else
	{
		return CFWriteStreamCanAcceptBytes(theWriteStream);
	}
}

- (void)doSendBytes
{
	if((theCurrentWrite != nil) && (theWriteStream != NULL))
	{
		// Note: This method is not called if theCurrentWrite is an AsyncSpecialPacket (startTLS packet)
		
		CFIndex totalBytesWritten = 0;
		
		BOOL done = NO;
		BOOL error = NO;
		
		while (!done && !error && [self canAcceptBytes])
		{
			// Figure out what to write.
			CFIndex bytesRemaining = [theCurrentWrite->buffer length] - theCurrentWrite->bytesDone;
			CFIndex bytesToWrite = (bytesRemaining < WRITE_CHUNKSIZE) ? bytesRemaining : WRITE_CHUNKSIZE;
			UInt8 *writestart = (UInt8 *)([theCurrentWrite->buffer bytes] + theCurrentWrite->bytesDone);

			// Write.
			CFIndex bytesWritten = CFWriteStreamWrite(theWriteStream, writestart, bytesToWrite);

			// Unset the "can accept bytes" flag
			theFlags &= ~kSocketCanAcceptBytes;
			
			// Check results
			if (bytesWritten < 0)
			{
				error = YES;
			}
			else
			{
				// Update total amount read for the current write
				theCurrentWrite->bytesDone += bytesWritten;
				
				// Update total amount written in this method invocation
				totalBytesWritten += bytesWritten;
				
				// Is packet done?
				done = ([theCurrentWrite->buffer length] == theCurrentWrite->bytesDone);
			}
		}

		if(done)
		{
			[self completeCurrentWrite];
			[self scheduleDequeueWrite];
		}
		else if(error)
		{
			CFStreamError err = CFWriteStreamGetError(theWriteStream);
			[self closeWithError:[self errorFromCFStreamError:err]];
			return;
		}
		else
		{
			// We're not done with the entire write, but we have written some bytes
			if ([theDelegate respondsToSelector:@selector(onSocket:didWritePartialDataOfLength:tag:)])
			{
				[theDelegate onSocket:self didWritePartialDataOfLength:totalBytesWritten tag:theCurrentWrite->tag];
			}
		}
	}
}

// Ends current write and calls delegate.
- (void)completeCurrentWrite
{
	NSAssert(theCurrentWrite, @"Trying to complete current write when there is no current write.");
	
	if ([theDelegate respondsToSelector:@selector(onSocket:didWriteDataWithTag:)])
	{
		[theDelegate onSocket:self didWriteDataWithTag:theCurrentWrite->tag];
	}
	
	if (theCurrentWrite != nil) [self endCurrentWrite]; // Caller may have disconnected.
}

// Ends current write.
- (void)endCurrentWrite
{
	NSAssert(theCurrentWrite, @"Trying to complete current write when there is no current write.");
	
	[theWriteTimer invalidate];
	theWriteTimer = nil;

    theCurrentWrite = nil;
}

- (void)doWriteTimeout:(NSTimer *)timer
{
	NSTimeInterval timeoutExtension = 0.0;
	
	if([theDelegate respondsToSelector:@selector(onSocket:shouldTimeoutWriteWithTag:elapsed:bytesDone:)])
	{
		timeoutExtension = [theDelegate onSocket:self shouldTimeoutWriteWithTag:theCurrentWrite->tag
                                         elapsed:theCurrentWrite->timeout
                                       bytesDone:theCurrentWrite->bytesDone];
	}
	
	if(timeoutExtension > 0.0)
	{
		theCurrentWrite->timeout += timeoutExtension;
		
		theWriteTimer = [NSTimer timerWithTimeInterval:timeoutExtension
		                                        target:self
		                                      selector:@selector(doWriteTimeout:)
		                                      userInfo:nil
		                                       repeats:NO];
		[self runLoopAddTimer:theWriteTimer];
	}
	else
	{
		[self closeWithError:[self getWriteTimeoutError]];
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Security
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)startTLS:(NSDictionary *)tlsSettings
{
	if(tlsSettings == nil)
    {
        // Passing nil/NULL to CFReadStreamSetProperty will appear to work the same as passing an empty dictionary,
        // but causes problems if we later try to fetch the remote host's certificate.
        //
        // To be exact, it causes the following to return NULL instead of the normal result:
        // CFReadStreamCopyProperty(readStream, kCFStreamPropertySSLPeerCertificates)
        //
        // So we use an empty dictionary instead, which works perfectly.

        tlsSettings = [NSDictionary dictionary];
    }
	
	Leanplum_AsyncSpecialPacket *packet = [[Leanplum_AsyncSpecialPacket alloc] initWithTLSSettings:tlsSettings];
	
	[theReadQueue addObject:packet];
	[self scheduleDequeueRead];
	
	[theWriteQueue addObject:packet];
	[self scheduleDequeueWrite];
}

- (void)maybeStartTLS
{
	// We can't start TLS until:
	// - All queued reads prior to the user calling StartTLS are complete
	// - All queued writes prior to the user calling StartTLS are complete
	//
	// We'll know these conditions are met when both kStartingReadTLS and kStartingWriteTLS are set
	
	if((theFlags & kStartingReadTLS) && (theFlags & kStartingWriteTLS))
	{
		Leanplum_AsyncSpecialPacket *tlsPacket = (Leanplum_AsyncSpecialPacket *)theCurrentRead;
		
		BOOL didStartOnReadStream = CFReadStreamSetProperty(theReadStream, kCFStreamPropertySSLSettings,
                                                            (CFDictionaryRef)tlsPacket->tlsSettings);
		BOOL didStartOnWriteStream = CFWriteStreamSetProperty(theWriteStream, kCFStreamPropertySSLSettings,
                                                              (CFDictionaryRef)tlsPacket->tlsSettings);
		
		if(!didStartOnReadStream || !didStartOnWriteStream)
		{
            [self closeWithError:[self getSocketError]];
		}
	}
}

- (void)onTLSHandshakeSuccessful
{
	if((theFlags & kStartingReadTLS) && (theFlags & kStartingWriteTLS))
	{
		theFlags &= ~kStartingReadTLS;
		theFlags &= ~kStartingWriteTLS;
		
		if([theDelegate respondsToSelector:@selector(onSocketDidSecure:)])
		{
			[theDelegate onSocketDidSecure:self];
		}
		
		[self endCurrentRead];
		[self endCurrentWrite];
		
		[self scheduleDequeueRead];
		[self scheduleDequeueWrite];
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark CF Callbacks
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)doCFSocketCallback:(CFSocketCallBackType)type
				 forSocket:(CFSocketRef)sock
			   withAddress:(NSData *)address
				  withData:(const void *)pData
{
	NSParameterAssert ((sock == theSocket4) || (sock == theSocket6));
	
	switch (type)
	{
		case kCFSocketConnectCallBack:
			// The data argument is either NULL or a pointer to an SInt32 error code, if the connect failed.
			if(pData)
				[self doSocketOpen:sock withCFSocketError:kCFSocketError];
			else
				[self doSocketOpen:sock withCFSocketError:kCFSocketSuccess];
			break;
		case kCFSocketAcceptCallBack:
			[self doAcceptWithSocket: *((CFSocketNativeHandle *)pData)];
			break;
		default:
			NSLog (@"Leanplum: AsyncSocket %p received unexpected CFSocketCallBackType %lu.", self, (unsigned long) type);
			break;
	}
}

- (void)doCFReadStreamCallback:(CFStreamEventType)type forStream:(CFReadStreamRef)stream
{
	NSParameterAssert(theReadStream != NULL);
	
	CFStreamError err;
	switch (type)
	{
		case kCFStreamEventOpenCompleted:
			theFlags |= kDidCompleteOpenForRead;
			[self doStreamOpen];
			break;
		case kCFStreamEventHasBytesAvailable:
			if(theFlags & kStartingReadTLS) {
				[self onTLSHandshakeSuccessful];
			}
			else {
				theFlags |= kSocketHasBytesAvailable;
				[self doBytesAvailable];
			}
			break;
		case kCFStreamEventErrorOccurred:
		case kCFStreamEventEndEncountered:
			err = CFReadStreamGetError (theReadStream);
			[self closeWithError: [self errorFromCFStreamError:err]];
			break;
		default:
			NSLog (@"Leanplum: AsyncSocket %p received unexpected CFReadStream callback, CFStreamEventType %lu.", self, type);
	}
}

- (void)doCFWriteStreamCallback:(CFStreamEventType)type forStream:(CFWriteStreamRef)stream
{
	NSParameterAssert(theWriteStream != NULL);
	
	CFStreamError err;
	switch (type)
	{
		case kCFStreamEventOpenCompleted:
			theFlags |= kDidCompleteOpenForWrite;
			[self doStreamOpen];
			break;
		case kCFStreamEventCanAcceptBytes:
			if(theFlags & kStartingWriteTLS) {
				[self onTLSHandshakeSuccessful];
			}
			else {
				theFlags |= kSocketCanAcceptBytes;
				[self doSendBytes];
			}
			break;
		case kCFStreamEventErrorOccurred:
		case kCFStreamEventEndEncountered:
			err = CFWriteStreamGetError (theWriteStream);
			[self closeWithError: [self errorFromCFStreamError:err]];
			break;
		default:
			NSLog (@"Leanplum: AsyncSocket %p received unexpected CFWriteStream callback, CFStreamEventType %lu.", self, type);
	}
}

/**
 * This is the callback we setup for CFSocket.
 * This method does nothing but forward the call to it's Objective-C counterpart
 **/
static void MyCFSocketCallback (CFSocketRef sref, CFSocketCallBackType type, CFDataRef address, const void *pData, void *pInfo)
{
	Leanplum_AsyncSocket *theSocket = (__bridge Leanplum_AsyncSocket *)pInfo;
	[theSocket doCFSocketCallback:type forSocket:sref withAddress:(__bridge NSData *)address withData:pData];
}

/**
 * This is the callback we setup for CFReadStream.
 * This method does nothing but forward the call to it's Objective-C counterpart
 **/
static void MyCFReadStreamCallback (CFReadStreamRef stream, CFStreamEventType type, void *pInfo)
{
	Leanplum_AsyncSocket *theSocket = (__bridge Leanplum_AsyncSocket *)pInfo;
	[theSocket doCFReadStreamCallback:type forStream:stream];
}

/**
 * This is the callback we setup for CFWriteStream.
 * This method does nothing but forward the call to it's Objective-C counterpart
 **/
static void MyCFWriteStreamCallback (CFWriteStreamRef stream, CFStreamEventType type, void *pInfo)
{
	Leanplum_AsyncSocket *theSocket = (__bridge Leanplum_AsyncSocket *)pInfo;
	[theSocket doCFWriteStreamCallback:type forStream:stream];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Class Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Return line separators.
+ (NSData *)CRLFData
{
	return [NSData dataWithBytes:"\x0D\x0A" length:2];
}

+ (NSData *)CRData
{
	return [NSData dataWithBytes:"\x0D" length:1];
}

+ (NSData *)LFData
{
	return [NSData dataWithBytes:"\x0A" length:1];
}

+ (NSData *)ZeroData
{
	return [NSData dataWithBytes:"" length:1];
}

@end
