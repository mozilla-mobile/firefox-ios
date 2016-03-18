@import Foundation;

FOUNDATION_EXPORT double SQLiteVersionNumber;
FOUNDATION_EXPORT const unsigned char SQLiteVersionString[];

typedef struct SQLiteHandle SQLiteHandle; // ??? - CocoaPods workaround

NS_ASSUME_NONNULL_BEGIN
typedef NSString * _Nullable (^_SQLiteTokenizerNextCallback)(const char * input, int * inputOffset, int * inputLength);
int _SQLiteRegisterTokenizer(SQLiteHandle * db, const char * module, const char * tokenizer, _Nullable _SQLiteTokenizerNextCallback callback);
NS_ASSUME_NONNULL_END