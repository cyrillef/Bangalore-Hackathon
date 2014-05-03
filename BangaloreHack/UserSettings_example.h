//
//  UserSettings.h
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

// Oauth: Fill in these 3 macros with the correct information
//#define CONSUMER_KEY       @"mycloud-staging.autodesk.com"
//#define CONSUMER_SECRET    @"Secret123"
//#define O2_HOST            @"https://accounts-staging.autodesk.com/"

#define CONSUMER_KEY       @"your consumer key"
#define CONSUMER_SECRET    @"your secret key"
#define O2_HOST            @"https://accounts.autodesk.com/"

#define O2_REQUESTTOKEN    @"OAuth/RequestToken"
#define O2_ACCESSTOKEN     @"OAuth/AccessToken"
#define O2_AUTHORIZE       @"OAuth/Authorize"
#define O2_INVALIDATETOKEN @"OAuth/InvalidateToken"
#define O2_ALLOW           O2_HOST @"OAuth/Allow"

#define LOGIN @"Log In"
#define LOGOUT @"Log Out"

// ReCap: Fill in these macros with the correct information (only the 2 first are important)
#define ReCapAPIURL        @"http://rc-api-adn.autodesk.com/3.1/API/"
#define ReCapClientID      @"your recap client ID"
#define ReCapKey           @"your recap key" // not used
#define ReCapUserID        @"your recap user ID" // Needed only for using the ReCapSceneList, otherwise bail
