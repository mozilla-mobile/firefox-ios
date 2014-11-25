//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import <libxml/HTMLtree.h>
#import <libxml/HTMLparser.h>
#import <libxml/xpath.h>
#import <libxml/xpathInternals.h>
#import <libxml/xmlerror.h>

static inline UInt32 xmlElementTypeToInt(xmlElementType type) {
    return (UInt32) type;
}