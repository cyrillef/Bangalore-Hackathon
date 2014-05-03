//
//  AdskReCap.h
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
#pragma once

#import <Foundation/Foundation.h>

// 0 - NO_ERROR
// 1 - ERROR                              => 'General error'
// 2 - DB_ERROR                           => 'Database error'
// 3 - DB_BAD_ID                          => 'Given ID doesn't match one in database'
// 4 - NOT_YET                            => 'Not yet implemented'
// 5 - BAD_TYPE                           => 'The given type is not valid'
// 6 - EMPTY_RESOURCE_ID                  => 'The resource doesn't have an id'
// 7 - NOT_EMPTY_RESOURCE_ID              => 'The resource has an id but shouldn't'
// 8 - BAD_RESOURCE                       => 'The used resource is not correct'
// 9 - NOT_ENOUGH_IMAGES                  => 'You need at least 3 images to process a photoscene'
// 10- DB_ALREADY_EXISTS                  => 'Given attribute already exists'
// 
// 12- BAD_AUTHENTICATION                 => 'Bad authentication'
// 13- SECURITY_ERROR                     => 'Current user cannot access requested data'
// 14- BAD_VALUES                         => 'Given values are not correct'
// 15- CLIENT_DOESNT_EXIST                => 'Given client doesn't exist or is invalid'
// 16- BAD_TIMESTAMP                      => 'Bad timestamp'
// 17- FILE_DOESNT_EXIST                  => 'Given FileID doesn t exist'
// 18- BAD_IMAGE_PROTOCOL                 => 'The given image protocol is not correct'
// 19- BAD_SCENE_ID                       => 'The given Photoscene ID doesn t exist in the database'
// 20- USER_NOT_IDENTIFIED                => 'The user is not correctly identified'
// 21- NO_CREDENTIALS                     => 'You don't have the credentials to use this function'
// 22- NOT_READY                          => 'Your data is not ready'
// 23- FILE_ALREADY_EXISTS                => 'One file of the same kind already exists in the repository, you cannot overwrite it'
// 24- SCENE_ALREADY_PROCESSED            => 'This photoscene has already been processed you cannot change the source file you must create a new Photoscene with this photoscene as reference'
// 25- NO_RIGHTS                          => 'You don't have currently the correct rights'
// 26- CANNOT_SEND_MESSAGE                => 'Processing message cannot be sent'
// 27- CLIENT_NOT_ACTIVATED               => 'This client is not valid. Please contact ReCap.Api (at) autodesk.com '
// 28- SCENE_NAME_EMPTY                   => 'The scene name cannot be empty'
// 29- PERMISSION_DENIED                  => 'This client cannot access the asked resource'
// 30- MISSING_REF_PID                    => 'The reference photoscene ID is missing'
// 31- NO_EMAIL                           => 'Email address has not been entered for this user'
// 32- ERROR_MSG_DOESNT_EXIST             => 'Message doesn't exist'
// 33- ERROR_SENDING_NOTIFICATION         => 'An error occured while sending the notification'
// 34- CANT_COPY_FILE                     => 'An error occured while copying the file'
// 35- PHOTOSCENE_CORRUPTED               => 'Photoscene seems to have corrupted information (parameters, files) ...'
// 36- BAD_NOTIFICATION_PROTOCOL          => 'The given notification callback protocol is not correct'
// 37- NO_CALLBACK_DEFINED                => 'No callback has been defined'
// 38- USER_DOESNT_EXIST                  => 'Given user doesn't exist or is invalid'
// 39- CANNOT_ALLOCATE_PHOTOSCENEID       => 'The service was unable to create new photoscene'
// 40- BAD_REFERENCE_PROJECT_ID           => 'Given reference project ID doesn't match one in database'
// 41- CANT_RETRIEVE_PHOTOSCENE_FILE      => 'The source file is unreachable.'
// 42- CANT_READ_PHOTOSCENE_FILE          => 'Source file seems to be corrupted. Your source file was probably saved in UTF-8 instead of UTF-16 (Unicode)'
// 43- NAMESPACE_NOT_FOUND                => 'The namespace associated to client is not found.'
// 44- BAD_O2_AUTHENTICATION              => 'Bad O2 Authentication (signature)'
// 45- OAUTH_HEADER_DOESNT_FIND           => 'No OAuth header has been found'
// 46- PROJECT_NOT_FINISHED               => 'The specified project is not finished'

@class AdskOauthPlugin ;
@class AdskRESTful ;
@class AdskRESTfulResponse ;

@class DDXMLDocument ;

@interface AdskReCap : NSObject {
	@private
	NSDictionary *_tokens ;
	NSString *_clientID ;

	AdskOauthPlugin *oauthClient ;
	AdskRESTful *restClient ;
	AdskRESTfulResponse *lastResponse ;
}

// json or xml ?
- (id)initWithTokens:(NSString *)clientID tokens:(NSDictionary *)tokens ;
- (id)initWithTokens:(NSString *)clientID
		 consumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret
			   oauth:(NSString *)oauth oauthSecret:(NSString *)oauthSecret ;

// BOOL or response
- (BOOL)ServerTime ;
- (BOOL)Version ;
- (BOOL)SetNotificationMessage:(NSString *)emailType msg:(NSString *)msg ; // @"ERROR" @"SUCCESS"
- (BOOL)CreateSimplePhotoscene:(NSString *)format meshQuality:(NSString *)meshQuality ;
- (BOOL)SceneList:(NSString *)attributeName criteria:(NSString *)attributeValue ;
- (BOOL)SceneProperties:(NSString *)photosceneid ;
- (BOOL)UploadFiles:(NSString *)photosceneid files:(NSDictionary *)files ;
- (BOOL)ProcessScene:(NSString *)photosceneid ;
- (BOOL)SceneProgress:(NSString *)photosceneid ;
- (BOOL)GetPointCloudArchive:(NSString *)photosceneid format:(NSString *)format ;
- (BOOL)DeleteScene:(NSString *)photosceneid ;

- (NSString *)ErrorMessage:(BOOL)display ;

- (DDXMLDocument *)xml ;
//- (void)json ;

@end
