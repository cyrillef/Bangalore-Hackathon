//
//  AdskViewController.m
//
//  Created by Cyrille Fauvel on 10/15/13.
//  Copyright (c) 2013 Autodesk. All rights reserved.
//

#import "UserSettings.h"
#import "AdskOAuthController.h"

#import "AdskRESTful.h"
#import "DDXML.h"

@interface AdskOAuthController ()
@end

@implementation AdskOAuthController

NSMutableDictionary *requestToken ;
NSMutableDictionary *accessToken ;
NSString *photosceneid ;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if ( (self =[super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) ) {
		// Custom initialization
		NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults] ;
		if (   [defaults objectForKey:@"oauth_token"]
			&& [defaults objectForKey:@"oauth_token_secret"]
			&& [defaults objectForKey:@"oauth_session_handle"]
		) {
			accessToken =[[NSMutableDictionary alloc] init] ;
			[accessToken setObject:[defaults objectForKey:@"oauth_token"] forKey:@"oauth_token"] ;
			[accessToken setObject:[defaults objectForKey:@"oauth_token_secret"] forKey:@"oauth_token_secret"] ;
			[accessToken setObject:[defaults objectForKey:@"oauth_session_handle"] forKey:@"oauth_session_handle"] ;
		}
	}
	return (self) ;
}

- (void)viewDidLoad {
	_webView =[[UIWebView alloc] initWithFrame:CGRectMake(0, 0, [[self view] frame].size.width, [[self view] frame].size.height - 20)] ;
	_webView.delegate =self ;
	[self.view addSubview:_webView] ;
	
	_login =[UIButton buttonWithType:UIButtonTypeRoundedRect] ;
	[_login setTitle:@"Login" forState:UIControlStateNormal] ;
	_login.frame =CGRectMake (0, [[self view] frame].size.height - 20, [[self view] frame].size.width, 20) ;
	[self.view addSubview:_login] ;
	[_login addTarget:self action:@selector(startLogin:) forControlEvents:UIControlEventTouchDown] ;
	
	[super viewDidLoad] ;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning] ;
    // Dispose of any resources that can be recreated.
}

- (IBAction)startLogin:(id)sender {
	if ( [self RequestToken] ) // Leg 1
		[self Authorize] ; // Leg 2
}

//- First Leg: The first step of authentication is to request a token
- (BOOL)RequestToken {
	NSMutableDictionary *tokens =[[NSMutableDictionary alloc]
								  initWithObjectsAndKeys:CONSUMER_KEY, @"oauth_consumer_key", CONSUMER_SECRET, @"oauth_consumer_secret", nil] ;
	// In case of out-of-band authorization we also need to add the below parameter to
	// the "Authorization" header value
	if ( [self isOOB] )
		[tokens setObject:@"oob" forKey:@"oauth_callback"] ;
	
	AdskOauthPlugin *oauthClient =[[AdskOauthPlugin alloc] initWithTokens:tokens] ;
	AdskRESTful *client =[[AdskRESTful alloc] initWithBaseURL:O2_HOST options:nil] ;
	[client addSubscriber:oauthClient] ;
	
	NSURLRequest *req =[client post:O2_REQUESTTOKEN headers:nil] ;
	AdskRESTfulResponse *response =[client send:req] ;
	requestToken =[AdskRESTful ParseQueryString:[response string]] ; // [@"oauth_token"] [@"oauth_token_secret"]
	// If we did not get those params then something went wrong
	if ( [requestToken count] < 2 ) {
		[self showErrorMessage:@"Failure!<br />Could not get request token!<br />Maybe the credentials are incorrect?"] ;
		return (NO) ;
	}
	accessToken =[[NSMutableDictionary alloc] init] ;
	return (YES) ;
}

//- Second Leg: The second step is to authorize the user using the Autodesk login server
- (void)Authorize {
	NSString *path =[NSString stringWithFormat:@"%@%@?oauth_token=%@&viewmode=mobile", O2_HOST, O2_AUTHORIZE, requestToken [@"oauth_token"]] ;
	
	// In case of out-of-band authorization, let's show the authorization page which will provide the user with a PIN
	// in the default browser. Then here in our app request the user to type in that PIN.
	if ( [self isOOB] ) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:path]] ;
		UIAlertView *alert =[[UIAlertView alloc]
							 initWithTitle:@"Authorization PIN"
							 message:@"Please type here the authorization PIN!"
							 delegate:self
							 cancelButtonTitle:@"Done"
							 otherButtonTitles:nil] ;
		alert.alertViewStyle =UIAlertViewStylePlainTextInput ;
		[alert show] ;
	} else {
		// Otherwise let's load the page in our web viewer so that
		// we can catch the URL that it gets redirected to
		NSURLRequest *req =[NSURLRequest
							requestWithURL:[NSURL URLWithString:path]
							cachePolicy:NSURLRequestUseProtocolCachePolicy
							timeoutInterval:100] ;
		[self->_webView loadRequest:req] ;
	}
}

//- Third leg: The third step is to authenticate using the request tokens
//- Once you get the access token and access token secret you need to use those to make your further REST calls
//- Same in case of refreshing the access tokens or invalidating the current session. To do that we need to pass
//- in the acccess token and access token secret as the accessToken and tokenSecret parameter of the
//- [AdskRESTful URLRequestForPath] function
- (BOOL)AccessToken:(BOOL)refresh PIN:(NSString *)PIN {
	NSMutableDictionary *tokens =[[NSMutableDictionary alloc]
								  initWithObjectsAndKeys:CONSUMER_KEY, @"oauth_consumer_key", CONSUMER_SECRET, @"oauth_consumer_secret", nil] ;
	// If we already got access tokens and now just try to refresh
	// them then we need to provide the session handle
	if ( refresh ) {
		if ( !accessToken )
			return (NO) ;
		[tokens addEntriesFromDictionary:accessToken] ;
	} else {
		if ( !requestToken )
			return (NO) ;
		[tokens addEntriesFromDictionary:requestToken] ;
	}
	// If we used out-of-band authorization then we got a PIN that we need now
	if ( PIN != nil )
		[tokens setObject:PIN forKey:@"oauth_verifier"] ;

	AdskOauthPlugin *oauthClient =[[AdskOauthPlugin alloc] initWithTokens:tokens] ;
	AdskRESTful *client =[[AdskRESTful alloc] initWithBaseURL:O2_HOST options:nil] ;
	[client addSubscriber:oauthClient] ;
	
	NSURLRequest *req =[client post:O2_ACCESSTOKEN headers:nil] ;
	AdskRESTfulResponse *response =[client send:req] ;
	accessToken =[AdskRESTful ParseQueryString:[response string]] ;
	// [@"oauth_token"] [@"oauth_token_secret"] [@"oauth_session_handle"] [@"oauth_expires_in"] [@"oauth_authorization_expires_in"]
	// If session handle is not null then we got the tokens
	if ( accessToken [@"oauth_session_handle"] != nil ) {
		if ( refresh )
			[self showOAuthMessage:@"Success!<br />Managed to refresh token!"] ;
		else
			[self showOAuthMessage:@"Success!<br />Managed to log in and get access token!"] ;

		NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults] ;
		[defaults setObject:[accessToken objectForKey:@"oauth_token"] forKey:@"oauth_token"] ;
		[defaults setObject:[accessToken objectForKey:@"oauth_token_secret"] forKey:@"oauth_token_secret"] ;
		[defaults setObject:[accessToken objectForKey:@"oauth_session_handle"] forKey:@"oauth_session_handle"] ;
		[defaults synchronize] ;
		NSLog(@"Data saved") ;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"A360ConnectionStatusChanged" object:self] ;
		[self dismissViewControllerAnimated:YES completion:nil] ;
		return (YES) ;
	} else {
		//self.RefreshButton.enabled =NO ;
		//self.LogInButton.title = LOGIN ;
		if ( refresh )
			[self showErrorMessage:@"Failure!<br />Could not refresh token!"] ;
		else
			[self showErrorMessage:@"Failure!<br />Could not get access token!"] ;
		
		NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults] ;
		[defaults setObject:@"" forKey:@"oauth_token"] ;
		[defaults setObject:@"" forKey:@"oauth_token_secret"] ;
		[defaults setObject:@"" forKey:@"oauth_session_handle"] ;
		[defaults synchronize] ;
		NSLog(@"Data cleared") ;

		[[NSNotificationCenter defaultCenter] postNotificationName:@"A360ConnectionStatusChanged" object:self] ;
		[self dismissViewControllerAnimated:YES completion:nil] ;
		return (NO) ;
	}
	return (YES) ;
}

//- If we do not want to use the service anymore then
//- the best thing is to log out, i.e. invalidate the tokens we got
- (void)InvalidateToken {
	NSMutableDictionary *tokens =[[NSMutableDictionary alloc]
								  initWithObjectsAndKeys:CONSUMER_KEY, @"oauth_consumer_key", CONSUMER_SECRET, @"oauth_consumer_secret", nil] ;
	[tokens addEntriesFromDictionary:accessToken] ;
	
	AdskOauthPlugin *oauthClient =[[AdskOauthPlugin alloc] initWithTokens:tokens] ;
	AdskRESTful *client =[[AdskRESTful alloc] initWithBaseURL:O2_HOST options:nil] ;
	[client addSubscriber:oauthClient] ;
	
	NSURLRequest *req =[client post:O2_INVALIDATETOKEN headers:nil] ;
	AdskRESTfulResponse *response =[client send:req] ;
	
	// If Invalidate was successful, we will not get back any data
	if ( [[response string] isEqual:@""] ) {
		// Set the buttons' state
		//self.RefreshButton.enabled =NO ;
		//self.LogInButton.title =LOGIN ;
		// Clear the various tokens
		[requestToken removeAllObjects] ;
		[accessToken removeAllObjects] ;
		[self showMessage:@"Success!<br />Managed to log out!"] ;
	} else {
		[self showErrorMessage:@"Failure!<br />Could not log out!"] ;
	}
}

//- When a new URL is being shown in the browser then we can check the URL
//- This is needed in case of in-band authorization which will redirect us to a given
//- URL (O2_ALLOW) in case of success
- (void)webViewDidFinishLoad:(UIWebView *)aWebView {
	// In case of out-of-band login we do not need to check the callback URL
	// Instead we'll need the PIN that the webpage will provide for the user
	if ( [self isOOB] )
		return ;
	// Let's check if we got redirected to the correct page
	if ( [self isAuthorizeCallBack] )
		[self AccessToken:NO PIN:nil] ;
}

//- Check if the URL is O2_ALLOW, which means that the user could log in successfully
- (BOOL)isAuthorizeCallBack {
	NSString *fullUrlString =self->_webView.request.URL.absoluteString ;
	if ( !fullUrlString )
		return (NO) ;
	NSArray *arr =[fullUrlString componentsSeparatedByString:@"?"] ;
	if ( !arr || arr.count != 2 )
		return (NO) ;
	// If we were redirected to the O2_ALLOW URL then the user could log in successfully
	if ( [arr [0] isEqualToString:O2_ALLOW] )
		return (YES) ;
	// If we got to this page then probably there is an issue
	if ( [arr [0] isEqualToString:O2_AUTHORIZE] ) {
		// If the page contains the word "oauth_problem" then there is clearly a problem
		NSString *content =[self->_webView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML"] ;
		if ( [content rangeOfString:@"oauth_problem"].location != NSNotFound )
			[self showErrorMessage:@"Failure!<br />Could not log in!<br />Try again!"] ;
	}
	return (NO) ;
}

//- In case of out-of-band authorization this is where we continue once the user got the PIN
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	[self AccessToken:NO PIN:[[alertView textFieldAtIndex:0] text]] ;
}

/*- (IBAction)LogInClick:(id)sender {
	UIBarButtonItem *button =(UIBarButtonItem *)sender ;
	if ( [button.title isEqualToString:LOGIN] ) {
		if ( [self RequestToken] ) // Leg 1
			[self Authorize] ; // Leg 2

		// Leg 3
		// If Authorize succeeds, then in case of
		//   out-of-band authorization the /OAuth/AccessToken will be called from UIAlertView:didDismissWithButtonIndex,
		//   in-band authorization it will be called from UIWebView:webViewDidFinishLoad
	} else {
		[self InvalidateToken] ;
	}
}*/

//- Checks if we should use out-of-band authorization
- (BOOL)isOOB {
	//return (self.OobButton.style == UIBarButtonItemStyleDone) ;
    // Return false always in this example
    return (NO) ;
}

//- WARNING: Out-of-band authorization is shown here only for educational purposes and should only be used
//- if for some reason you cannot use in-band authorization.
//- In case of out-of-band authorization the web page will provide a PIN that the user will need to paste in
//- the message box of the iOS app
/*- (IBAction)OobClick:(id)sender {
	if ( [self isOOB] )
		self.OobButton.style =UIBarButtonItemStyleBordered ;
	else
		self.OobButton.style =UIBarButtonItemStyleDone ;
}*/

/*- (IBAction)RefreshClick:(id)sender {
	[self AccessToken:YES PIN:nil] ;
}*/

//- Utility function to show information to the user
- (void)showMessage:(NSString *)text {
	NSString *html =[NSString
					 stringWithFormat:@"<div style=\"font-size:24px; margin:10%%; text-align:center;\">%@</div>",
					 text] ;
	[self->_webView loadHTMLString:html baseURL:nil] ;
}

- (void)showErrorMessage:(NSString *)text {
	NSString *html =[NSString
					 stringWithFormat:@"<div style=\"font-size:24px; margin:10%%; text-align:center; color: red;\">%@</div>",
					 text] ;
	[self->_webView loadHTMLString:html baseURL:nil] ;
}

- (void)showOAuthMessage:(NSString *)text {
	NSString *html =[NSString
					 stringWithFormat:@"<div style=\"font-size:24px; margin:10%%; text-align:center;\">%@<br />&nbsp;<div style=\"text-align:left; font-size:18px;\">requestToken = %@ <br />requestTokenSecret = %@ <br />accessToken = %@<br />accessTokenSecret = %@<br />sessionHandle = %@<br />accessTokenExpires = %@<br />authorizationExpires = %@</div></div>",
					 text,
					 [requestToken [@"oauth_token"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
					 [requestToken [@"oauth_token_secret"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
					 [accessToken [@"oauth_token"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
					 [accessToken [@"oauth_token_secret"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
					 [accessToken [@"oauth_session_handle"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
					 accessToken [@"oauth_expires_in"],
					 accessToken [@"oauth_authorization_expires_in"]] ;
	[self->_webView loadHTMLString:html baseURL:nil] ;
}

@end
