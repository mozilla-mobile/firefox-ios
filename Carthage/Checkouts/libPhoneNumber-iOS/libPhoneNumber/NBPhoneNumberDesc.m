//
//  NBPhoneNumberDesc.m
//  libPhoneNumber
//
//

#import "NBPhoneNumberDesc.h"

@interface NSArray (NBAdditions)
- (id)safeObjectAtIndex:(NSUInteger)index;
@end

@implementation NSArray (NBAdditions)
- (id)safeObjectAtIndex:(NSUInteger)index {
    @synchronized(self) {
        if (index >= [self count]) return nil;
        id res = [self objectAtIndex:index];
        if (res == nil || (NSNull*)res == [NSNull null]) {
            return nil;
        }
        return res;
    }
}
@end


@implementation NBPhoneNumberDesc

- (id)initWithData:(id)data
{
    NSString *nnp = nil;
    NSString *pnp = nil;
    NSString *exp = nil;
    
    if (data != nil && [data isKindOfClass:[NSArray class]]) {
        /* 2 */ nnp = [data safeObjectAtIndex:2];
        /* 3 */ pnp = [data safeObjectAtIndex:3];
        /* 6 */ exp = [data safeObjectAtIndex:6];
    }
    
    return [self initWithNationalNumberPattern:nnp withPossibleNumberPattern:pnp withExample:exp];
}


- (id)initWithNationalNumberPattern:(NSString *)nnp withPossibleNumberPattern:(NSString *)pnp withExample:(NSString *)exp
{
    self = [self init];
    
    if (self) {
        self.nationalNumberPattern = nnp;
        self.possibleNumberPattern = pnp;
        self.exampleNumber = exp;
    }
    
    return self;

}


- (id)init
{
    self = [super init];
    
    if (self) {
    }
    
    return self;
}


- (id)initWithCoder:(NSCoder*)coder
{
    if (self = [super init]) {
        self.nationalNumberPattern = [coder decodeObjectForKey:@"nationalNumberPattern"];
        self.possibleNumberPattern = [coder decodeObjectForKey:@"possibleNumberPattern"];
        self.exampleNumber = [coder decodeObjectForKey:@"exampleNumber"];
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder*)coder
{
    [coder encodeObject:self.nationalNumberPattern forKey:@"nationalNumberPattern"];
    [coder encodeObject:self.possibleNumberPattern forKey:@"possibleNumberPattern"];
    [coder encodeObject:self.exampleNumber forKey:@"exampleNumber"];
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"nationalNumberPattern[%@] possibleNumberPattern[%@] exampleNumber[%@]",
            self.nationalNumberPattern, self.possibleNumberPattern, self.exampleNumber];
}


- (id)copyWithZone:(NSZone *)zone
{
	NBPhoneNumberDesc *phoneDescCopy = [[NBPhoneNumberDesc allocWithZone:zone] init];
    
    phoneDescCopy.nationalNumberPattern = [self.nationalNumberPattern copy];
    phoneDescCopy.possibleNumberPattern = [self.possibleNumberPattern copy];
    phoneDescCopy.exampleNumber = [self.exampleNumber copy];
    
	return phoneDescCopy;
}


- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[NBPhoneNumberDesc class]] == NO) {
        return NO;
    }
    
    NBPhoneNumberDesc *other = object;
    return [self.nationalNumberPattern isEqual:other.nationalNumberPattern] &&
        [self.possibleNumberPattern isEqual:other.possibleNumberPattern] &&
        [self.exampleNumber isEqual:other.exampleNumber];
}

@end
