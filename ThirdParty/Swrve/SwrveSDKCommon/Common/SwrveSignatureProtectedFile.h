@protocol SwrveSignatureErrorListener <NSObject>
@required
- (void)signatureError:(NSURL*)file;
@end

/*! Used internally to protect the data written to the disk */
@interface SwrveSignatureProtectedFile : NSObject<SwrveSignatureErrorListener>

@property (atomic, retain)   NSURL* filename;
@property (atomic, retain)   NSURL* signatureFilename;
@property (atomic, readonly) NSString* key;
@property (atomic, retain)   id<SwrveSignatureErrorListener> signatureErrorListener;

- (id) initFile:(NSURL*)file signatureFilename:(NSURL*)signatureFile usingKey:(NSString*)signatureKey;
- (id) initFile:(NSURL*)file signatureFilename:(NSURL*)signatureFile usingKey:(NSString*)signatureKey signatureErrorListener:(id<SwrveSignatureErrorListener>)listener;

/*! Write the data specified into the file and create a signature file for verification. */
- (void) writeToFile:(NSData*)content;

/*! Read from the file, returning an error if file does not exist or signature is invalid. */
- (NSData*) readFromFile;

@end
