/*
 CHMath.framework -- CHNumber.m

 Copyright (c) 2008-2009, Dave DeLong <http://www.davedelong.com>

 Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

 The software is  provided "as is", without warranty of any kind, including all implied warranties of merchantability and fitness. In no event shall the authors or copyright holders be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with the software or the use or other dealings in the software.
 */


#import "CHNumber.h"
#import "CHNumber_Private.h"

#define CH_ASCII_ZERO 48

@interface CHNumber ()

@property (readonly) BIGNUM * bigNumber;

@end


@implementation CHNumber

@synthesize bigNumber;

+ (BOOL) isIntegerPrime:(int)integer {
	CHNumber * num = [[CHNumber alloc] initWithInt:integer];
	return [num isPrime];
}

+ (id)numberWithInt:(int)integer {
	//in class methods, self always refers to the Class object
	return [[self alloc] initWithInt:integer];
}

+ (id)numberWithUnsignedInt:(unsigned int)integer {
	return [[self alloc] initWithUnsignedInt:integer];
}

+ (id)numberWithString:(NSString *)string {
	return [[self alloc] initWithString:string];
}

+ (id)numberWithHexString:(NSString *)string {
	return [[self alloc] initWithHexString:string];
}

+ (id)numberWithData:(NSData *)data
{
    return [[self alloc] initWithData: data];
}

+ (id) numberWithOpenSSLNumber: (BIGNUM*) bn
{
    return [[self alloc] initWithOpenSSLNumber: bn];
}

+ (id)numberWithNumber:(NSNumber *)number {
	return [[self alloc] initWithNumber:number];
}

+ (id)number {
	return [[self alloc] initWithInt:0];
}

- (id) init {
	if (self = [super init]) {
		bigNumber = BN_new();
		if (bigNumber == NULL) {
			//[self release];
			return nil;
		}
		BN_zero(bigNumber);
		context = BN_CTX_new();
		if(context == NULL) {
			BN_free(bigNumber);
			//[self release];
			return nil;
		}
	}
	return self;
}

- (id)initWithInt:(int)integer {
	if(self = [self init]) {
		if (integer < 0) {
			integer *= -1;
			//set the initial value to the positive value
			BN_set_word([self bigNumber], integer);
			//subtract the value twice to get the negative value
			BN_sub_word([self bigNumber], integer);
			BN_sub_word([self bigNumber], integer);
		} else {
			BN_set_word([self bigNumber], integer);
		}
    }
	return self;
}

- (id)initWithUnsignedInt:(unsigned int)integer {
	if (self = [self init]) {
		BN_set_word(bigNumber, integer);
	}
	return self;
}

- (id)initWithString:(NSString *)string {
	NSCharacterSet * decSet = [NSCharacterSet characterSetWithCharactersInString:@"-0123456789"];
	NSRange nonDecChar = [string rangeOfCharacterFromSet:[decSet invertedSet]];
	if (nonDecChar.location != NSNotFound) { return nil; }
	if (self = [self init]) {
		BN_dec2bn(&bigNumber, [string cStringUsingEncoding:NSASCIIStringEncoding]);
	}
	return self;
}

- (id)initWithHexString:(NSString *)string {
	NSCharacterSet * hexSet = [NSCharacterSet characterSetWithCharactersInString:@"-0123456789abcdefABCDEF"];
	NSRange nonHexChar = [string rangeOfCharacterFromSet:[hexSet invertedSet]];
	if (nonHexChar.location != NSNotFound) { return nil; }
	if (self = [self init]) {
		BN_hex2bn(&bigNumber, [string cStringUsingEncoding:NSASCIIStringEncoding]);
	}
	return self;
}

- (id)initWithData:(NSData*)data
{
    if (self = [self init]) {
        if (data == nil) {
            return nil;
        }
        if ([data length] == 0) {
            return nil;
        }
        (void) BN_bin2bn([data bytes], (int) [data length], bigNumber);
    }
    return self;
}

- (id)initWithOpenSSLNumber:(BIGNUM*)bn
{
    if ((self = [self init]) != nil) {
        BN_copy(bigNumber, bn);
    }
    return self;
}

- (id)initWithNumber:(NSNumber *)number {
	return [self initWithString:[number descriptionWithLocale:[NSLocale currentLocale]]];
}

- (void) dealloc {
	BN_clear_free(bigNumber), bigNumber = NULL;
	BN_CTX_free(context), context = NULL;
}

- (void) finalize {
	BN_clear_free(bigNumber), bigNumber = NULL;
	BN_CTX_free(context), context = NULL;
	[super finalize];
}

#pragma mark -
#pragma mark NSCopying compliance

- (id) copyWithZone:(NSZone *)zone {
	id copy = [[[self class] alloc] init];
	BN_copy([copy bigNumber], [self bigNumber]);
	return copy;
}

#pragma mark -
#pragma mark NSCoding compliance

- (id) initWithCoder:(NSCoder *)decoder {
	return [self initWithString:[decoder decodeObjectForKey:@"num"]];
}

- (void) encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:[self stringValue] forKey:@"num"];
}

#pragma mark -
#pragma mark Getters and Setters

- (NSString *)stringValue {
	return [NSString stringWithCString:BN_bn2dec([self bigNumber]) encoding:NSASCIIStringEncoding];
}

- (NSString *)hexStringValue {
	return [[NSString stringWithCString:BN_bn2hex([self bigNumber]) encoding:NSASCIIStringEncoding] lowercaseString];
}

- (NSData *)dataValue
{
	NSData* result = nil;

	void* buffer = malloc(BN_num_bytes([self bigNumber]));
	if (buffer != NULL) {
		BN_bn2bin([self bigNumber], buffer);
		result = [NSData dataWithBytesNoCopy: buffer length: BN_num_bytes([self bigNumber]) freeWhenDone: YES];
	}

	return result;
}

- (NSString *)binaryStringValue {
	int numBits = BN_num_bits([self bigNumber]);
	BOOL isNegative = [self isNegative];
	BOOL shouldFlip = NO;
	int totalBufferSize = numBits + 1;
	unsigned char * string = malloc(totalBufferSize * sizeof(unsigned char));
	string[totalBufferSize] = '\0';
	for (int i = 0; i < numBits; ++i) {
		int idx = totalBufferSize - i - 1;
		int bit = BN_is_bit_set([self bigNumber], i);
		if (isNegative) {
			if (shouldFlip == YES) {
				bit = !bit;
			} else if (bit == 1) {
				shouldFlip = YES;
			}
		}
		string[idx] = bit + CH_ASCII_ZERO;
	}
	string[0] = (int)isNegative + CH_ASCII_ZERO;
	NSString * binaryString = [[NSString alloc] initWithBytesNoCopy:string length:totalBufferSize encoding:NSASCIIStringEncoding freeWhenDone:YES];
	return binaryString;
}

- (NSInteger)integerValue {
	NSInteger value = BN_get_word([self bigNumber]);
	if ([self isNegative]) { value *= -1; }
	return value;
}

- (NSUInteger)unsignedIntegerValue {
	return (NSUInteger)BN_get_word([self bigNumber]);
}

- (BIGNUM*) bigNumValue
{
    return BN_dup([self bigNumber]);
}

- (NSString *)description {
	return [self stringValue];
}

- (NSString *)debugDescription {
	return [NSString stringWithFormat:@"<%@ %p> - %@", NSStringFromClass([self class]), self, [self stringValue]];
}

#pragma mark Comparisons

- (BOOL)isZero {
	return BN_is_zero([self bigNumber]);
}

- (BOOL)isOne {
	return BN_is_one([self bigNumber]);
}

- (BOOL)isNegative {
	return [self isLessThanNumber:[CHNumber number]];
}

- (BOOL)isPositive {
	return ![self isNegative];
}

- (BOOL)isPrime {
	return BN_is_prime_ex([self bigNumber], BN_prime_checks, context, NULL);
}

- (BOOL)isOdd {
	return BN_is_odd([self bigNumber]);
}

- (BOOL)isEven {
	return ![self isOdd];
}

- (BOOL)isGreaterThanNumber:(CHNumber *)number {
	return (BN_cmp([self bigNumber], [number bigNumber]) == NSOrderedDescending);
}

- (BOOL)isGreaterThanOrEqualToNumber:(CHNumber *)number {
	return ([self isGreaterThanNumber:number] || [self isEqualToNumber:number]);
}

- (NSComparisonResult) compare:(id)object {
	if ([object isKindOfClass:[CHNumber class]]) {
		CHNumber * other = (CHNumber *)object;
		return (NSComparisonResult)BN_cmp([self bigNumber], [other bigNumber]);
	}
	return NSOrderedDescending;
}

- (BOOL)isEqualToNumber:(CHNumber *)number {
	return (BN_cmp([self bigNumber], [number bigNumber]) == NSOrderedSame);
}

- (BOOL)isLessThanNumber:(CHNumber *)number {
	return (BN_cmp([self bigNumber], [number bigNumber]) == NSOrderedAscending);
}

- (BOOL)isLessThanOrEqualToNumber:(CHNumber *)number {
	return ([self isLessThanNumber:number] || [self isEqualToNumber:number]);
}

- (BOOL) isEqualTo:(id)object {
	if ([object isKindOfClass:[self class]]) {
		return [self isEqualToNumber:(CHNumber *)object];
	} else {
		return NO;
	}
}

- (BOOL) isEqual:(id)object {
	return [self isEqualTo:object];
}

#pragma mark -
#pragma mark Mathematical Operations

- (CHNumber *)numberByModding:(CHNumber *)mod {
	CHNumber * result = [CHNumber number];
	BN_mod([result bigNumber], [self bigNumber], [mod bigNumber], context);
	return result;
}

- (CHNumber *)numberByInverseModding:(CHNumber *)mod {
	CHNumber * result = [CHNumber number];
	BN_mod_inverse([result bigNumber], [self bigNumber], [mod bigNumber], context);
	return result;
}

- (CHNumber *)numberByAdding:(CHNumber *)addend {
	CHNumber * result = [CHNumber number];
	BN_add([result bigNumber], [self bigNumber], [addend bigNumber]);
	return result;
}

- (CHNumber *)numberByAdding:(CHNumber *)addend mod:(CHNumber *)mod {
	CHNumber * result = [CHNumber number];
	BN_mod_add([result bigNumber], [self bigNumber], [addend bigNumber], [mod bigNumber], context);
	return result;
}

- (CHNumber *)numberBySubtracting:(CHNumber *)subtrahend {
	CHNumber * result = [CHNumber number];
	BN_sub([result bigNumber], [self bigNumber], [subtrahend bigNumber]);
	return result;
}

- (CHNumber *)numberBySubtracting:(CHNumber *)subtrahend mod:(CHNumber *)mod {
	CHNumber * result = [CHNumber number];
	BN_mod_sub([result bigNumber], [self bigNumber], [subtrahend bigNumber], [mod bigNumber], context);
	return result;
}

- (CHNumber *)numberByMultiplyingBy:(CHNumber *)multiplicand {
	CHNumber * result = [CHNumber number];
	BN_mul([result bigNumber], [self bigNumber], [multiplicand bigNumber], context);
	return result;
}

- (CHNumber *)numberByMultiplyingBy:(CHNumber *)multiplicand mod:(CHNumber *)mod {
	CHNumber * result = [CHNumber number];
	BN_mod_mul([result bigNumber], [self bigNumber], [multiplicand bigNumber], [mod bigNumber], context);
	return result;
}

- (CHNumber *)numberByDividingBy:(CHNumber *)divisor {
	CHNumber * result = [CHNumber number];
	BN_div([result bigNumber], NULL, [self bigNumber], [divisor bigNumber], context);
	return result;
}

- (CHNumber *)squaredNumber {
	CHNumber * result = [CHNumber number];
	BN_sqr([result bigNumber], [self bigNumber], context);
	return result;
}

- (CHNumber *)squaredNumberMod:(CHNumber *)mod {
	CHNumber * result = [CHNumber number];
	BN_mod_sqr([result bigNumber], [self bigNumber], [mod bigNumber], context);
	return result;
}

- (CHNumber *)numberByRaisingToPower:(CHNumber *)exponent {
	CHNumber * result = [CHNumber number];
	BN_exp([result bigNumber], [self bigNumber], [exponent bigNumber], context);
	return result;
}

- (CHNumber *)numberByRaisingToPower:(CHNumber *)exponent mod:(CHNumber *)mod {
	CHNumber * result = [CHNumber number];
	BN_mod_exp([result bigNumber], [self bigNumber], [exponent bigNumber], [mod bigNumber], context);
	return result;
}

- (CHNumber *)negatedNumber {
	CHNumber * result = [self copy];
	BN_set_negative([result bigNumber], ![self isNegative]);
	return result;
}

#pragma mark Bitfield Operations

- (BOOL)isBitSet:(int)bit {
	return BN_is_bit_set([self bigNumber], bit);
}

- (CHNumber *)numberByShiftingLeftOnce {
	CHNumber * result = [CHNumber number];
	BN_lshift1([result bigNumber], [self bigNumber]);
	return result;
}

- (CHNumber *)numberByShiftingLeft:(int)leftShift {
	CHNumber * result = [CHNumber number];
	BN_lshift([result bigNumber], [self bigNumber], leftShift);
	return result;
}

- (CHNumber *)numberByShiftingRightOnce {
	CHNumber * result = [CHNumber number];
	BN_rshift1([result bigNumber], [self bigNumber]);
	return result;
}

- (CHNumber *)numberByShiftingRight:(int)rightShift {
	CHNumber * result = [CHNumber number];
	BN_rshift([result bigNumber], [self bigNumber], rightShift);
	return result;
}

- (CHNumber *)numberByMaskingWithInt:(int)mask {
	CHNumber * result = [self copy];
	BN_mask_bits([result bigNumber], mask);
	return result;
}

@end
