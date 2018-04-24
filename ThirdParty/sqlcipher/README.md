## SQLCipher

SQLCipher extends the [SQLite](https://www.sqlite.org) database library to add security enhancements that make it more suitable for encrypted local data storage such as on-the-fly encryption, tamper evidence, and key derivation. Based on SQLite, SQLCipher closely tracks SQLite and periodically integrates stable SQLite release features.

SQLCipher is maintained by Zetetic, LLC, the official site can be found [here](https://www.zetetic.net/sqlcipher/).

## Features

- Fast performance with as little as 5-15% overhead for encryption on many operations
- 100% of data in the database file is encrypted
- Good security practices (CBC mode, HMAC, key derivation)
- Zero-configuration and application level cryptography
- Algorithms provided by the peer reviewed OpenSSL crypto library.
- Configurable crypto providers

## Contributions

We welcome contributions, to contribute to SQLCipher, a [contributor agreement](https://www.zetetic.net/contributions/) needs to be submitted.  All submissions should be based on the `prerelease` branch.

## Compiling

Building SQLCipher is almost the same as compiling a regular version of 
SQLite with two small exceptions: 

 1. You *must* define `SQLITE_HAS_CODEC` and `SQLITE_TEMP_STORE=2` when building sqlcipher. 
 2. If compiling against the default OpenSSL crypto provider, you will need to link libcrypto
 
Example Static linking (replace /opt/local/lib with the path to libcrypto.a). Note in this 
example, `--enable-tempstore=yes` is setting `SQLITE_TEMP_STORE=2` for the build.

	$ ./configure --enable-tempstore=yes CFLAGS="-DSQLITE_HAS_CODEC" \
		LDFLAGS="/opt/local/lib/libcrypto.a"
	$ make

Example Dynamic linking

	$ ./configure --enable-tempstore=yes CFLAGS="-DSQLITE_HAS_CODEC" \
		LDFLAGS="-lcrypto"
	$ make

## Encrypting a database

To specify an encryption passphrase for the database via the SQL interface you 
use a pragma. The passphrase you enter is passed through PBKDF2 key derivation to
obtain the encryption key for the database 

	PRAGMA key = 'passphrase';

Alternately, you can specify an exact byte sequence using a blob literal. If you
use this method it is your responsibility to ensure that the data you provide is a
64 character hex string, which will be converted directly to 32 bytes (256 bits) of 
key data without key derivation.

	PRAGMA key = "x'2DD29CA851E7B56E4697B0E1F08507293D761A05CE4D1B628663F411A8086D99'";

To encrypt a database programatically you can use the `sqlite3_key` function. 
The data provided in `pKey` is converted to an encryption key according to the 
same rules as `PRAGMA key`. 

	int sqlite3_key(sqlite3 *db, const void *pKey, int nKey);

`PRAGMA key` or `sqlite3_key` should be called as the first operation when a database is open.

## Changing a database key

To change the encryption passphrase for an existing database you may use the rekey pragma
after you've supplied the correct database password;

	PRAGMA key = 'passphrase'; -- start with the existing database passphrase
	PRAGMA rekey = 'new-passphrase'; -- rekey will reencrypt with the new passphrase

The hex rekey pragma may be used to rekey to a specific binary value

	PRAGMA rekey = "x'2DD29CA851E7B56E4697B0E1F08507293D761A05CE4D1B628663F411A8086D99'";

This can be accomplished programtically by using sqlite3_rekey;
  
	sqlite3_rekey(sqlite3 *db, const void *pKey, int nKey)

## Support

The primary avenue for support and discussions is the SQLCipher discuss site:

https://discuss.zetetic.net/c/sqlcipher

Issues or support questions on using SQLCipher should be entered into the 
GitHub Issue tracker:

https://github.com/sqlcipher/sqlcipher/issues

Please DO NOT post issues, support questions, or other problems to blog 
posts about SQLCipher as we do not monitor them frequently.

If you are using SQLCipher in your own software please let us know at 
support@zetetic.net!

## License

Copyright (c) 2016, ZETETIC LLC
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the ZETETIC LLC nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY ZETETIC LLC ''AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL ZETETIC LLC BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
