//
//  AdskRESTful+Additions.m
//  ReCap
//
//  Created by Cyrille Fauvel on 10/16/13.
//  Copyright (c) 2013 Autodesk. All rights reserved.
//

// Copied from https://github.com/seancook/TWReverseAuthExample/blob/master/Source/Vendor/ABOAuthCore/OAuth%2BAdditions.m

#import "AdskRESTful+Additions.h"

@implementation NSString (AdskRESTfulAdditions)

- (NSString *)RFC3986Encode { // UTF-8 encodes prior to URL encoding
    NSMutableString *result =[NSMutableString string] ;
    const char *p =[self UTF8String] ;
    unsigned char c ;
    for ( ; (c = *p) ; p++ ) {
        switch ( c ) {
            case '0' ... '9':
            case 'A' ... 'Z':
            case 'a' ... 'z':
            case '.':
            case '-':
            case '~':
            case '_':
                [result appendFormat:@"%c", c] ;
                break ;
            default:
                [result appendFormat:@"%%%02X", c] ;
				break ;
        }
    }
    return (result) ;
}

- (NSString *)RFC3986Decode {
    NSString *result =[(NSString *)self stringByReplacingOccurrencesOfString:@"+" withString:@" "] ;
    result =[result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] ;
    return (result) ;
}

- (NSString *)Left:(NSUInteger)x {
	NSString *substring =self ;
	if ( [self length] > x )
		substring =[self substringWithRange:NSMakeRange (0, x - 1)] ;
	return (substring) ;
}

- (NSString *)Right:(NSUInteger)x {
	NSString *substring =self ;
	if ( [self length] > x )
		substring =[self substringFromIndex:[self length] - x] ;
	return (substring) ;
}

@end
