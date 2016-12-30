#import "SwrveCommonConnectionDelegate.h"

// This connection delegate tracks performance metrics for each request (see JIRA SWRVE-5067 for more details)
@implementation SwrveCommonConnectionDelegate

@synthesize startTime;
@synthesize metrics;
@synthesize data;
@synthesize response;
@synthesize handler;

- (id)init:(ConnectionCompletionHandler)_handler
{
    self = [super init];
    if (self) {
        [self setHandler:_handler];
        [self setData:[[NSMutableData alloc] init]];
        [self setMetrics:[[NSMutableDictionary alloc] init]];
        [self setStartTime:[NSDate date]];
        [self setResponse:nil];
    }
    return self;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSDate* finishTime = [NSDate date];
    NSString* interval = [self getTimeIntervalFromStartAsString:finishTime];
    
    NSURL* requestURL = [[connection originalRequest] URL];
    NSString* baseURL = [NSString stringWithFormat:@"%@://%@", [requestURL scheme], [requestURL host]];
    
    NSString* metricsString = [NSString stringWithFormat:@"u=%@", baseURL];
    
    NSString* failedOn = @"c";
    if ([[self metrics] objectForKey:@"sb"]) {
        failedOn = @"rh";
        metricsString = [metricsString stringByAppendingString:[NSString stringWithFormat:@",sb=%@", [[self metrics] valueForKey:@"sb"]]];
    }
    metricsString = [metricsString stringByAppendingString:[NSString stringWithFormat:@",%@=%@,%@_error=1", failedOn, interval, failedOn]];
    
    [self addHttpPerformanceMetrics:metricsString];
    
    if (self.handler) {
        self.handler([self response], [self data], error);
    }
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
#pragma unused(connection, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
    NSDate* sendBodyTime = [NSDate date];
    NSString* interval = [self getTimeIntervalFromStartAsString:sendBodyTime];
    
    [[self metrics] setValue:interval forKey:@"c"];
    [[self metrics] setValue:interval forKey:@"sh"];
    [[self metrics] setValue:interval forKey:@"sb"];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)receivedResponse
{
#pragma unused(connection)
    NSDate* responseTime = [NSDate date];
    NSString* interval = [self getTimeIntervalFromStartAsString:responseTime];
    [self setResponse:receivedResponse];
    
    if (![[self metrics] objectForKey:@"sb"]) {
        [[self metrics] setValue:interval forKey:@"c"];
        [[self metrics] setValue:interval forKey:@"sh"];
        [[self metrics] setValue:interval forKey:@"sb"];
    }
    [[self metrics] setValue:interval forKey:@"rh"];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)receivedData
{
#pragma unused(connection)
    // This might be called multiple times while data is being received
    NSDate* responseDateTime = [NSDate date];
    NSString* interval = [self getTimeIntervalFromStartAsString:responseDateTime];
    [[self data] appendData:receivedData];
    
    if (![[self metrics] objectForKey:@"sb"]) {
        [[self metrics] setValue:interval forKey:@"c"];
        [[self metrics] setValue:interval forKey:@"sh"];
        [[self metrics] setValue:interval forKey:@"sb"];
    }
    if (![[self metrics] objectForKey:@"rh"]) {
        [[self metrics] setValue:interval forKey:@"rh"];
    }
    [[self metrics] setValue:interval forKey:@"rb"];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSDate* finishTime = [NSDate date];
    NSString* interval = [self getTimeIntervalFromStartAsString:finishTime];
    
    if (![[self metrics] objectForKey:@"sb"]) {
        [[self metrics] setValue:interval forKey:@"c"];
        [[self metrics] setValue:interval forKey:@"sh"];
        [[self metrics] setValue:interval forKey:@"sb"];
    }
    if (![[self metrics] objectForKey:@"rh"]) {
        [[self metrics] setValue:interval forKey:@"rh"];
    }
    if (![[self metrics] objectForKey:@"rb"]) {
        [[self metrics] setValue:interval forKey:@"rb"];
    }
    
    NSURL* requestURL = [[connection originalRequest] URL];
    NSString* baseURL = [NSString stringWithFormat:@"%@://%@", [requestURL scheme], [requestURL host]];
    
    NSString* metricsString = [NSString stringWithFormat:@"u=%@,c=%@,sh=%@,sb=%@,rh=%@,rb=%@",
                               baseURL,
                               [[self metrics] valueForKey:@"c"],
                               [[self metrics] valueForKey:@"sh"],
                               [[self metrics] valueForKey:@"sb"],
                               [[self metrics] valueForKey:@"rh"],
                               [[self metrics] valueForKey:@"rb"]];
    
    [self addHttpPerformanceMetrics:metricsString];
    
    if (self.handler) {
        self.handler([self response], [self data], nil);
    }
}

- (NSString*) getTimeIntervalFromStartAsString:(NSDate*)date
{
    NSTimeInterval interval = [date timeIntervalSinceDate:[self startTime]];
    return [NSString stringWithFormat:@"%.0f", round(interval * 1000)];
}

- (void)addHttpPerformanceMetrics:(NSString*)metricsString {
    #pragma unused(metricsString)
}

@end
