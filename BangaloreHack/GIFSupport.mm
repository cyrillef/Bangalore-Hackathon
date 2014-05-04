//
//  GIFSupport.h
//
//  Created by Cyrille Fauvel on 05/05/14.
//  (C) Copyright 2014 by Autodesk, Inc.
//
// Permission to use, copy, modify, and distribute this software in object code
// form for any purpose and without fee is hereby granted, provided that the above
// copyright notice appears in all copies and that both that copyright notice and
// the limited warranty and restricted rights notice below appear in all supporting
// documentation.
//
// AUTODESK PROVIDES THIS PROGRAM "AS IS" AND WITH ALL FAULTS. AUTODESK SPECIFICALLY
// DISCLAIMS ANY IMPLIED WARRANTY OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR USE.
// AUTODESK, INC. DOES NOT WARRANT THAT THE OPERATION OF THE PROGRAM WILL BE UNINTERRUPTED
// OR ERROR FREE.
//

@implementation GIFSupport

static UIImage *frameImage (CGSize size, CGFloat radians) {
    UIGraphicsBeginImageContextWithOptions (size, YES, 1) ;
	{
        [[UIColor whiteColor] setFill] ;
        UIRectFill (CGRectInfinite) ;
        CGContextRef gc =UIGraphicsGetCurrentContext () ;
        CGContextTranslateCTM (gc, size.width / 2, size.height / 2) ;
        CGContextRotateCTM (gc, radians) ;
        CGContextTranslateCTM (gc, size.width / 4, 0) ;
        [[UIColor redColor] setFill] ;
        CGFloat w =size.width / 10 ;
        CGContextFillEllipseInRect (gc, CGRectMake (-w / 2, -w / 2, w, w)) ;
    }
    UIImage *image =UIGraphicsGetImageFromCurrentImageContext () ;
    UIGraphicsEndImageContext () ;
    return (image) ;
}

static void makeAnimatedGif(void) {
    static NSUInteger const kFrameCount =16 ;
    NSDictionary *fileProperties =@{
									 (__bridge id)kCGImagePropertyGIFDictionary: @{
											 (__bridge id)kCGImagePropertyGIFLoopCount: @0, // 0 means loop forever
											 }
									 } ;
    NSDictionary *frameProperties =@{
									  (__bridge id)kCGImagePropertyGIFDictionary: @{
											  (__bridge id)kCGImagePropertyGIFDelayTime: @0.02f, // a float (not double!) in seconds, rounded to centiseconds in the GIF data
											  }
									  } ;
    NSURL *documentsDirectoryURL =[[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil] ;
    NSURL *fileURL =[documentsDirectoryURL URLByAppendingPathComponent:@"animated.gif"] ;
	
    CGImageDestinationRef destination =CGImageDestinationCreateWithURL((__bridge CFURLRef)fileURL, kUTTypeGIF, kFrameCount, NULL) ;
    CGImageDestinationSetProperties (destination, (__bridge CFDictionaryRef)fileProperties) ;
	for ( NSUInteger i =0 ; i < kFrameCount ; i++ ) {
        @autoreleasepool {
            UIImage *image =frameImage (CGSizeMake(300, 300), M_PI * 2 * i / kFrameCount) ;
            CGImageDestinationAddImage (destination, image.CGImage, (__bridge CFDictionaryRef)frameProperties) ;
        }
    }
    if ( !CGImageDestinationFinalize (destination) )
        NSLog(@"failed to finalize image destination") ;
    CFRelease (destination) ;
	
    NSLog(@"url=%@", fileURL) ;
}

@end
