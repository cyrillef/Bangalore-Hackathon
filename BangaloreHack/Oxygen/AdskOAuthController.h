//
//  AdskViewController.h
//  ReCap
//
//  Created by Cyrille Fauvel on 10/15/13.
//  Copyright (c) 2013 Autodesk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AdskOAuthController : UIViewController<UIWebViewDelegate> {
	UIWebView *_webView ;
	UIButton *_login ;
}

- (BOOL)RequestToken ;
- (void)Authorize ;
- (BOOL)AccessToken:(BOOL)refresh PIN:(NSString *)PIN ;

@end
