//
//  AdskRESTful+Additions.h
//  ReCap
//
//  Created by Cyrille Fauvel on 10/16/13.
//  Copyright (c) 2013 Autodesk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (AdskRESTfulAdditions)

- (NSString *)RFC3986Encode ;
- (NSString *)RFC3986Decode ;
- (NSString *)Left:(NSUInteger)x ;
- (NSString *)Right:(NSUInteger)x ;

@end
