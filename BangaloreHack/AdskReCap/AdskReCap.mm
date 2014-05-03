//
//  AdskReCap.m
//
//  Created by Cyrille Fauvel on 10/23/13.
//  (C) Copyright 2013 by Autodesk, Inc.
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

#import "AdskRESTful.h"
#import "AdskReCap.h"
#import "DDXML.h"

#import "UserSettings.h" // Modify this file before usign the API

@implementation AdskReCap

- (id)initWithTokens:(NSString *)clientID tokens:(NSDictionary *)tokens {
	if ( (self =[super init]) ) {
		_clientID =clientID ;
		// @"oauth_consumer_key" @"oauth_consumer_secret" @"oauth_token" @"oauth_token_secret"
		_tokens =[[NSDictionary alloc] initWithDictionary:tokens copyItems:YES] ;

		oauthClient =[[AdskOauthPlugin alloc] initWithTokens:_tokens] ;
		restClient =[[AdskRESTful alloc] initWithBaseURL:ReCapAPIURL options:nil] ;
		[restClient addSubscriber:oauthClient] ;
	}
	return (self) ;
}

- (id)initWithTokens:(NSString *)clientID
		 consumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret
			   oauth:(NSString *)oauth oauthSecret:(NSString *)oauthSecret
{
	if ( (self =[super init]) ) {
		_clientID =clientID ;
		// @"oauth_consumer_key" @"oauth_consumer_secret" @"oauth_token" @"oauth_token_secret"
		_tokens =[[NSDictionary alloc]
				  initWithObjectsAndKeys:consumerKey, @"oauth_consumer_key",
				  consumerSecret, @"oauth_consumer_secret",
				  oauth, @"oauth_token",
				  oauthSecret, @"oauth_token_secret",
				  nil] ;
		oauthClient =[[AdskOauthPlugin alloc] initWithTokens:_tokens] ;
		restClient =[[AdskRESTful alloc] initWithBaseURL:ReCapAPIURL options:nil] ;
		[restClient addSubscriber:oauthClient] ;
	}
	return (self) ;
}

- (BOOL)ServerTime {
	NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init] ;
	[parameters setObject:ReCapClientID forKey:@"clientID"] ;
	[restClient clearAllParameters] ;
	[restClient addParameters:parameters] ;
	
	NSURLRequest *req =[restClient get:@"service/date" headers:nil] ;
	lastResponse =[restClient send:req] ;
	NSLog(@"service/date response: %@", [lastResponse string]) ;
	return ([lastResponse isOk]) ;
}

- (BOOL)Version {
	NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init] ;
	[parameters setObject:_clientID forKey:@"clientID"] ;
	[restClient clearAllParameters] ;
	[restClient addParameters:parameters] ;
	
	NSURLRequest *req =[restClient get:@"version" headers:nil] ;
	lastResponse =[restClient send:req] ;
	NSLog(@"version response: %@", [lastResponse string]) ;
	return ([lastResponse isOk]) ;
}

- (BOOL)SetNotificationMessage:(NSString *)emailType msg:(NSString *)msg {
	NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init] ;
	[parameters setObject:_clientID forKey:@"clientID"] ;
	[parameters setObject:emailType forKey:@"emailType"] ;
	[parameters setObject:msg forKey:@"emailTxt"] ;
	[restClient clearAllParameters] ;
	[restClient addParameters:parameters] ;
	
	NSURLRequest *req =[restClient post:@"notification/template" headers:nil] ;
	lastResponse =[restClient send:req] ;
	NSLog(@"notification/template response: %@", [lastResponse string]) ;
	return ([lastResponse isOk]) ;
}

- (BOOL)CreateSimplePhotoscene:(NSString *)format meshQuality:(NSString *)meshQuality {
	NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init] ;
	[parameters setObject:_clientID forKey:@"clientID"] ;
	[parameters setObject:format forKey:@"format"] ;
	[parameters setObject:meshQuality forKey:@"meshquality"] ;
	[parameters setObject:[NSString stringWithFormat:@"MyPhotoScene%@", [AdskRESTful timestamp]] forKey:@"scenename"] ;
	[restClient clearAllParameters] ;
	[restClient addParameters:parameters] ;
	
	NSURLRequest *req =[restClient post:@"photoscene" headers:nil] ;
	lastResponse =[restClient send:req] ;
	NSLog(@"photoscene response: %@", [lastResponse string]) ;
	return ([lastResponse isOk]) ;
}

- (BOOL)SceneList:(NSString *)attributeName criteria:(NSString *)attributeValue {
	NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init] ;
	[parameters setObject:_clientID forKey:@"clientID"] ;
	[parameters setObject:attributeName forKey:@"attributeName"] ;
	[parameters setObject:attributeValue forKey:@"attributeValue"] ;
	[restClient clearAllParameters] ;
	[restClient addParameters:parameters] ;
	
	NSURLRequest *req =[restClient get:@"photoscene/properties" headers:nil] ;
	lastResponse =[restClient send:req] ;
	NSLog(@"photoscene/properties response: %@", [lastResponse string]) ;
	return ([lastResponse isOk]) ;
}

- (BOOL)SceneProperties:(NSString *)photosceneid {
	NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init] ;
	[parameters setObject:_clientID forKey:@"clientID"] ;
	[restClient clearAllParameters] ;
	[restClient addParameters:parameters] ;
	
	NSURLRequest *req =[restClient get:[NSString stringWithFormat:@"photoscene/%@/properties", photosceneid] headers:nil] ;
	lastResponse =[restClient send:req] ;
	NSLog(@"photoscene/.../properties response: %@", [lastResponse string]) ;
	return ([lastResponse isOk]) ;
}

- (BOOL)UploadFiles:(NSString *)photosceneid files:(NSDictionary *)files {
	// ReCap returns the following if no file uploaded (or referenced), setup an error instead
	//<Response>
	//	<Usage>0.81617307662964</Usage>
	//	<Resource>/file</Resource>
	//	<photosceneid>  your scene ID  </photosceneid>
	//	<Files>
	//
	//	</Files>
	//</Response>
	if ( files == nil || [files count] == 0 ) {
	 NSString *errXml =@"<Response><Usage>0.0</Usage><Resource>/file</Resource><Error><code>1</code><msg>No file to upload</msg></Error></Response>" ;
		lastResponse =[[AdskRESTfulResponse alloc] init] ;
		lastResponse->data =[NSData dataWithBytes:[errXml UTF8String] length:[errXml lengthOfBytesUsingEncoding:NSUTF8StringEncoding]] ;
		return (NO) ;
	}
	NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init] ;
	[parameters setObject:_clientID forKey:@"clientID"] ;
	[parameters setObject:photosceneid forKey:@"photosceneid"] ;
	[parameters setObject:@"image" forKey:@"type"] ;
	[restClient clearAllParameters] ;
	[restClient addParameters:parameters] ;
	[restClient addPostFiles:files] ;
	
	NSURLRequest *req =[restClient post:@"file" headers:nil] ;
	lastResponse =[restClient send:req] ;
	NSLog(@"file response: %@", [lastResponse string]) ;
	return ([lastResponse isOk]) ;
}

- (BOOL)ProcessScene:(NSString *)photosceneid {
	NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init] ;
	[parameters setObject:_clientID forKey:@"clientID"] ;
	[parameters setObject:photosceneid forKey:@"photosceneid"] ;
	[parameters setObject:@"1" forKey:@"forceReprocess"] ;
	[restClient clearAllParameters] ;
	[restClient addParameters:parameters] ;
	
	NSURLRequest *req =[restClient post:[NSString stringWithFormat:@"photoscene/%@", photosceneid] headers:nil] ;
	lastResponse =[restClient send:req] ;
	NSLog(@"(post) photoscene/... response: %@", [lastResponse string]) ;
	return ([lastResponse isOk]) ;
}

- (BOOL)SceneProgress:(NSString *)photosceneid {
	NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init] ;
	[parameters setObject:_clientID forKey:@"clientID"] ;
	[parameters setObject:photosceneid forKey:@"photosceneid"] ;
	[restClient clearAllParameters] ;
	[restClient addParameters:parameters] ;
	
	NSURLRequest *req =[restClient get:[NSString stringWithFormat:@"photoscene/%@/progress", photosceneid] headers:nil] ;
	lastResponse =[restClient send:req] ;
	NSLog(@"photoscene/.../progress response: %@", [lastResponse string]) ;
	return ([lastResponse isOk]) ;
}

- (BOOL)GetPointCloudArchive:(NSString *)photosceneid format:(NSString *)format {
    NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init] ;
	[parameters setObject:_clientID forKey:@"clientID"] ;
	[parameters setObject:photosceneid forKey:@"photosceneid"] ;
	[parameters setObject:format forKey:@"format"] ;
	[restClient clearAllParameters] ;
	[restClient addParameters:parameters] ;
	
	NSURLRequest *req =[restClient get:[NSString stringWithFormat:@"photoscene/%@", photosceneid] headers:nil] ;
	lastResponse =[restClient send:req] ;
	NSLog(@"(get) photoscene/... response: %@", [lastResponse string]) ;
	return ([lastResponse isOk]) ;
}

- (BOOL)DeleteScene:(NSString *)photosceneid {
	NSMutableDictionary *parameters =[[NSMutableDictionary alloc] init] ;
	[parameters setObject:_clientID forKey:@"clientID"] ;
	[restClient clearAllParameters] ;
	[restClient addParameters:parameters] ;
	
	NSURLRequest *req =[restClient delete:[NSString stringWithFormat:@"photoscene/%@", photosceneid] headers:nil] ;
	lastResponse =[restClient send:req] ;
	NSLog(@"(delete) photoscene/... response: %@", [lastResponse string]) ;
	return ([lastResponse isOk]) ;
}

- (NSString *)ErrorMessage:(BOOL)display {
	if ( lastResponse == nil )
		return (@"") ;
	NSString *errmsg ;
	if ( lastResponse->error != nil ) {
		errmsg =[lastResponse->error localizedDescription] ;
	} else {
		NSLog(@"%@", [lastResponse string]) ;
		DDXMLDocument *xml =[self xml] ;
		if ( xml != nil) {
			NSError *error ;
			NSArray *errorCode =[xml nodesForXPath:@"/Response/Error/code" error:&error] ;
			NSArray *results =[xml nodesForXPath:@"/Response/Error/msg" error:&error] ;
			errmsg =[NSString stringWithFormat:@"%@ (# %@)", [[results objectAtIndex:0] stringValue], [[errorCode objectAtIndex:0] stringValue]] ;
		} else {
			errmsg =@"Not an XML response." ;
		}
	}
	if ( display == YES ) {
		UIAlertView *alert =[[UIAlertView alloc] initWithTitle:@"ReCap Error" message:errmsg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] ;
		[alert show] ;
	}
	return (errmsg) ;
}

- (DDXMLDocument *)xml {
	if ( lastResponse == nil || lastResponse->error != nil )
		return (nil) ;
	NSError *error =nil ;
    DDXMLDocument *theDocument =[[DDXMLDocument alloc] initWithXMLString:[lastResponse string] options:0 error:&error] ;
	return (theDocument) ;
}

@end
