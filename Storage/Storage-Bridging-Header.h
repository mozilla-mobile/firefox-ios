#ifndef Client_Storage_Bridging_Header_h
#define Client_Storage_Bridging_Header_h

#define SQLITE_HAS_CODEC 1

#import "Shared-Bridging-Header.h"
#import <Foundation/Foundation.h>

// We do not need to import SQLCipher explicitly here; we put ThirdParty/sqlcipher at the front of our
// search path instead.
//#import "ThirdParty/sqlcipher/sqlite3.h"
#import "sqlite3.h"

#endif
