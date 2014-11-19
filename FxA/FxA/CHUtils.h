//
//  CHUtils.h
//  CHMath
//
//  Created by Dave DeLong on 9/28/09.
//  Copyright 2009 Home. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CHNumber;

/**
 @file CHUtils.h
 Provides utility methods for operating on multiple CHNumbers
 */

/**
 CHUtils is a non-instantiated class.  It provides utility methods for generating random prime numbers, finding the greatest common divisor of two \link CHNumber CHNumbers\endlink, and listing prime numbers.
 */
@interface CHUtils : NSObject

/**
 Generates a prime number.  This method uses the <a href="http://openssl.org/docs/crypto/BN_generate_prime.html">BN_generate_prime</a> function to generate a prime number of length @a numBits bits.

 @param numBits The length of the prime to be generated (in bits)

 @return a new prime \link CHNumber\endlink
*/
+ (CHNumber *)generatePrimeOfLength:(int)numBits;

/**
 Generates a safe prime number.  This method uses the <a href="http://openssl.org/docs/crypto/BN_generate_prime.html">BN_generate_prime</a> function to generate a prime number.  The generated prime @a p has the property that @c (p/2)-1 is also prime.

 @param numBits The length of the prime to be generated (in bits)

 @return a new prime \link CHNumber\endlink
 */
+ (CHNumber *)generateSafePrimeOfLength:(int)numBits;

/**
 Generates a prime number.  This method uses the <a href="http://openssl.org/docs/crypto/BN_generate_prime.html">BN_generate_prime</a> function to generate a prime number.  If @a add is not nil, then the generated prime @a p will have the property that @c (p % add == rem).  If @a rem is nil, then the prime will have the property that @c (p % add == 1).

 @param numBits The length of the prime to be generated (in bits)
 @param add
 @param rem

 @return a new prime \link CHNumber\endlink
 */
+ (CHNumber *)generatePrimeOfLength:(int)numBits add:(CHNumber *)add remainder:(CHNumber *)rem;

/**
 Generates a safe prime number.  This method uses the <a href="http://openssl.org/docs/crypto/BN_generate_prime.html">BN_generate_prime</a> function to generate a prime number.  The generated prime @a p has the property that @c (p/2)-1 is also prime.  If @a add is not nil, then the generated prime @a p will have the property that @c (p % add == rem).  If @a rem is nil, then the prime will have the property that @c (p % add == 1).

 @param numBits The length of the prime to be generated (in bits)
 @param add
 @param rem

 @return a new prime \link CHNumber\endlink
 */
+ (CHNumber *)generateSafePrimeOfLength:(int)numBits add:(CHNumber *)add remainder:(CHNumber *)rem;

/**
 Generates a prime number.  This method uses the <a href="http://openssl.org/docs/crypto/BN_generate_prime.html">BN_generate_prime</a> function to generate a prime number.  If @a safe is @c YES, then the generated prime @a p will have the property that @c (p/2)-1 is also prime.  If @a add is not nil, then the generated prime @a p will have the property that @c (p % add == rem).  If @a rem is nil, then the prime will have the property that @c (p % add == 1).

 @param numBits The length of the prime to be generated (in bits)
 @param safe
 @param add
 @param rem

 @return a new prime \link CHNumber\endlink
 */
+ (CHNumber *)generatePrimeOfLength:(int)numBits safe:(BOOL)safe add:(CHNumber *)add remainder:(CHNumber *)rem;

/**
 Finds the greatest common divisor of two \link CHNumber CHNumbers\endlink.  Uses the <a href="">BN_gcd</a> function to compute the greatest common divisor.  If the two numbers are <a href="http://en.wikipedia.org/wiki/Relatively_prime">relatively prime</a> this returns a CHNumber of 1.

 @param first
 @param second

 @return a new \link CHNumber\endlink that is the greatest common divisor of @a first and @a second
*/
+ (CHNumber *)greatestCommonDivisorOf:(CHNumber *)first and:(CHNumber *)second;

/**
 Returns a list of prime numbers.  Computes a list of prime numbers up to, but not including @a number.  If @a number is less than or equal to 2, it returns an empty array.

 @param number a non-negative CHNumber
 */
+ (NSArray *)primesUpTo:(CHNumber *)number;

@end
