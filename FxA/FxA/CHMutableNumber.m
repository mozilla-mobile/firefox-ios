/*
 CHMath.framework -- CHMutableNumber.m

 Copyright (c) 2008-2009, Dave DeLong <http://www.davedelong.com>

 Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

 The software is  provided "as is", without warranty of any kind, including all implied warranties of merchantability and fitness. In no event shall the authors or copyright holders be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with the software or the use or other dealings in the software.
 */


#import "CHMutableNumber.h"
#import "CHNumber_Private.h"

@implementation CHNumber (CHMutableAdditions)

- (CHMutableNumber *) mutableCopyWithZone:(NSZone *)zone {
	return [[CHMutableNumber alloc] initWithString:[self stringValue]];
}

@end

@implementation CHMutableNumber

- (void) setIntegerValue:(int)newValue {
	if (newValue < 0) {
		newValue *= -1;
		//set the initial value to the positive value
		BN_set_word([self bigNumber], newValue);
		[self negate];
	} else {
		BN_set_word([self bigNumber], newValue);
	}
}

- (void)setStringValue:(NSString *)newValue {
	NSCharacterSet * decSet = [NSCharacterSet characterSetWithCharactersInString:@"-0123456789"];
	NSRange nonDecChar = [newValue rangeOfCharacterFromSet:[decSet invertedSet]];
	if (nonDecChar.location != NSNotFound) { return; }
	BN_dec2bn(&bigNumber, [newValue cStringUsingEncoding:NSASCIIStringEncoding]);
}

- (void)setHexStringValue:(NSString *)newValue {
	NSCharacterSet * hexSet = [NSCharacterSet characterSetWithCharactersInString:@"-0123456789abcdefABCDEF"];
	NSRange nonHexChar = [newValue rangeOfCharacterFromSet:[hexSet invertedSet]];
	if (nonHexChar.location != NSNotFound) { return; }
	BN_hex2bn(&bigNumber, [newValue cStringUsingEncoding:NSASCIIStringEncoding]);
}

- (void)clear {
	BN_clear([self bigNumber]);
}

- (void)modByInteger:(int)mod {
	if (mod != 0) {
		if (mod < 0) { mod *= -1; }
		int result = BN_mod_word([self bigNumber], mod);
		[self setIntegerValue:result];
	}
}

- (void)modByNumber:(CHNumber *)mod {
	if ([mod isZero] == NO) {
		BN_mod([self bigNumber], [self bigNumber], [mod bigNumber], context);
	}
}

- (void)addInteger:(int)addend {
	if (addend > 0) {
		BN_add_word([self bigNumber], addend);
	} else {
		addend *= -1;
		[self subtractInteger:addend];
	}
}

- (void)addNumber:(CHNumber *)addend {
	BN_add([self bigNumber], [self bigNumber], [addend bigNumber]);
}

- (void)addNumber:(CHNumber *)addend mod:(CHNumber *)mod {
	BN_mod_add([self bigNumber], [self bigNumber], [addend bigNumber], [mod bigNumber], context);
}

- (void)subtractInteger:(int)subtrahend {
	if (subtrahend > 0) {
		BN_sub_word([self bigNumber], subtrahend);
	} else {
		subtrahend *= -1;
		[self addInteger:subtrahend];
	}
}

- (void)subtractNumber:(CHNumber *)subtrahend {
	BN_sub([self bigNumber], [self bigNumber], [subtrahend bigNumber]);
}

- (void)subtractNumber:(CHNumber *)subtrahend mod:(CHNumber *)mod {
	BN_mod_sub([self bigNumber], [self bigNumber], [subtrahend bigNumber], [mod bigNumber], context);
}

- (void)multiplyByInteger:(int)multiplicand {
	if (multiplicand > 0) {
		BN_mul_word([self bigNumber], multiplicand);
	} else {
		multiplicand *= -1;
		BN_mul_word([self bigNumber], multiplicand);
		[self negate];
	}
}

- (void)multiplyByNumber:(CHNumber *)multiplicand {
	BN_mul([self bigNumber], [self bigNumber], [multiplicand bigNumber], context);
}

- (void)multiplyByNumber:(CHNumber *)multiplicand mod:(CHNumber *)mod {
	BN_mod_mul([self bigNumber], [self bigNumber], [multiplicand bigNumber], [mod bigNumber], context);
}

- (void)divideByInteger:(int)divisor {
	if (divisor == 0) { return; }
	if (divisor > 0) {
		BN_div_word([self bigNumber], divisor);
	} else {
		divisor *= -1;
		BN_div_word([self bigNumber], divisor);
		[self negate];
	}
}

- (void)divideByNumber:(CHNumber *)divisor {
	if ([divisor isZero]) { return; }
	BN_div([self bigNumber], NULL, [self bigNumber], [divisor bigNumber], context);
}

- (void)raiseToInteger:(int)exponent {
	CHNumber * exp = [CHNumber numberWithInt:exponent];
	[self raiseToNumber:exp];
}

- (void)raiseToNumber:(CHNumber *)exponent {
	BN_exp([self bigNumber], [self bigNumber], [exponent bigNumber], context);
}

- (void)raiseToNumber:(CHNumber *)exponent mod:(CHNumber *)mod {
	BN_mod_exp([self bigNumber], [self bigNumber], [exponent bigNumber], [mod bigNumber], context);
}

- (void)square {
	BN_sqr([self bigNumber], [self bigNumber], context);
}

- (void)squareMod:(CHNumber *)mod {
	BN_mod_sqr([self bigNumber], [self bigNumber], [mod bigNumber], context);
}

- (void)negate {
	BN_set_negative([self bigNumber], ![self isNegative]);
}

- (void)setBit:(int)bit {
	BN_set_bit([self bigNumber], bit);
}

- (void)clearBit:(int)bit {
	BN_clear_bit([self bigNumber], bit);
}

- (void)flipBit:(int)bit {
	if ([self isBitSet:bit]) {
		[self clearBit:bit];
	} else {
		[self setBit:bit];
	}
}

- (void)shiftLeftOnce {
	BN_lshift1([self bigNumber], [self bigNumber]);
}

- (void)shiftLeft:(int)leftShift {
	BN_lshift([self bigNumber], [self bigNumber], leftShift);
}

- (void)shiftRightOnce {
	BN_rshift1([self bigNumber], [self bigNumber]);
}

- (void)shiftRight:(int)rightShift {
	BN_rshift([self bigNumber], [self bigNumber], rightShift);
}

- (void)maskWithInt:(int)mask {
	BN_mask_bits([self bigNumber], mask);
}

@end
