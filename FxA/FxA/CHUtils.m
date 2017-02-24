/*
 CHMath.framework -- CHUtils.m

 Copyright (c) 2008-2009, Dave DeLong <http://www.davedelong.com>

 Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

 The software is  provided "as is", without warranty of any kind, including all implied warranties of merchantability and fitness. In no event shall the authors or copyright holders be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with the software or the use or other dealings in the software.
 */


#import "CHUtils.h"
#import "CHNumber.h"
#import "CHNumber_Private.h"
#import <openssl/bn.h>
#import <openssl/rand.h>

static NSMutableSet * cachedPrimes;


@implementation CHUtils

+ (void)initialize {
	@synchronized(self) {
		cachedPrimes = [[NSMutableSet alloc] init];
		NSFileHandle * random = [NSFileHandle fileHandleForReadingAtPath:@"/dev/urandom"];
		NSData * buffer = [random readDataOfLength:512];
		RAND_seed([buffer bytes], 512);
	}
}

+ (CHNumber *)generatePrimeOfLength:(int)numBits safe:(BOOL)safe add:(CHNumber *)add remainder:(CHNumber *)rem {
	CHNumber * result = [CHNumber number];
	BN_generate_prime_ex([result bigNumber], numBits, safe, [add bigNumber], [rem bigNumber], NULL);
	return result;
}

+ (CHNumber *)generatePrimeOfLength:(int)numBits {
	return [CHUtils generatePrimeOfLength:numBits safe:NO add:nil remainder:nil];
}

+ (CHNumber *)generateSafePrimeOfLength:(int)numBits {
	return [CHUtils generatePrimeOfLength:numBits safe:YES add:nil remainder:nil];
}

+ (CHNumber *)generatePrimeOfLength:(int)numBits add:(CHNumber *)add remainder:(CHNumber *)rem {
	return [CHUtils generatePrimeOfLength:numBits safe:NO add:add remainder:rem];
}

+ (CHNumber *)generateSafePrimeOfLength:(int)numBits add:(CHNumber *)add remainder:(CHNumber *)rem {
	return [CHUtils generatePrimeOfLength:numBits safe:YES add:add remainder:rem];
}

+ (CHNumber *)greatestCommonDivisorOf:(CHNumber *)first and:(CHNumber *)second {
	CHNumber * result = [CHNumber number];
	BN_CTX * ctx = BN_CTX_new();
	BN_gcd([result bigNumber], [first bigNumber], [second bigNumber], ctx);
	BN_CTX_free(ctx);
	return result;
}

+ (NSArray *)primesUpTo:(CHNumber *)number {
	CHNumber * two = [CHNumber numberWithInt:2];
	if ([number isLessThanNumber:two]) { return [NSArray array]; }

	NSMutableArray * primes = [NSMutableArray arrayWithObject:two];
	//NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	CHNumber * potentialPrime = [CHNumber numberWithInt:3];
	while ([potentialPrime isLessThanNumber:number]) {
		if ([cachedPrimes containsObject:potentialPrime] == YES) {
			[primes addObject:potentialPrime];
		} else if ([potentialPrime isPrime]) {
			[cachedPrimes addObject:potentialPrime];
			[primes addObject:potentialPrime];
		}
		potentialPrime = [potentialPrime numberByAdding:two];
	}
	//[pool release];
	return primes;
}

@end
