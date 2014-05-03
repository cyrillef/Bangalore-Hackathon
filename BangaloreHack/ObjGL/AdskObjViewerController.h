//
//  AdskObjViewController.h
//
//  Created by Cyrille Fauvel on 10/25/13.
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

#import <UIKit/UIKit.h>

#import "AdskObjParser.h"
#import "AdskEAGLView.h"

@interface AdskObjViewerController : AdskObjViewerBaseController {
	@private
	AdskObjParser *_myMesh ;
	NSString *_path ;
	NSString *_photosceneid ;
	//@public
	float _lastScale ;
	CATransform3D _currentCalculatedMatrix ;

	UIProgressView *renderingProgressIndicator ;
	UILabel *renderingActivityLabel ;
	
	dispatch_queue_t _objLoaderQueue ;
	dispatch_semaphore_t _objLoaderSemaphore, _objViewerSemaphore ;
}

@property (nonatomic, retain) AdskObjParser *_myMesh ;
@property (nonatomic, copy) NSString *_path ;
@property (nonatomic, copy) NSString *_photosceneid ;

- (id)initWithObj:(NSString *)path photosceneid:(NSString *)photosceneid ;
- (id)initWithParser:(AdskObjParser *)parser ;
//- (void)dealloc ;
- (void)setupView:(AdskEAGLView *)view ;
- (void)drawView:(AdskEAGLView *)view ;
- (void)setupGesture:(AdskEAGLView *)view ;
- (void)stopAnimation:(UITapGestureRecognizer *)sender ;
- (void)loadObj:(NSString *)path photosceneid:(NSString *)photosceneid ;
- (void)insertImage:(UITapGestureRecognizer *)sender ;
- (void)fullScreen:(UILongPressGestureRecognizer *)sender ;
- (void)backToPanel:(UILongPressGestureRecognizer *)sender ;
- (void)scaleMesh:(UIPinchGestureRecognizer *)sender ;
- (void)rotatePanMesh:(UIPanGestureRecognizer *)sender ;
- (void)translatePanMesh:(UIPanGestureRecognizer *)sender ;
- (void)rotateMesh:(UIRotationGestureRecognizer *)sender ;
- (void)showRenderingIndicator:(NSNotification *)note ;
- (void)updateRenderingIndicator:(NSNotification *)note ;
- (void)hideRenderingIndicator:(NSNotification *)note ;

@end
