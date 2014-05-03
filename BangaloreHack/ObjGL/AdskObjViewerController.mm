//
//  AdskObjViewController.m
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

#import "AdskObjViewerController.h"
#import "AdskRESTful.h"

#include <vector>

@implementation AdskObjViewerController

@synthesize _myMesh ;
@synthesize _path ;
@synthesize _photosceneid ;

- (id)initWithObj:(NSString *)path photosceneid:(NSString *)photosceneid {
	if ( (self =[super init]) ) {
		_path =[[NSString alloc] initWithString:path] ;
		_photosceneid =_photosceneid == nil ? nil : [[NSString alloc] initWithString:photosceneid] ;
		_lastScale =1.0f ;
		_currentCalculatedMatrix =CATransform3DIdentity ;
		_objLoaderQueue =dispatch_queue_create ("com.autodesk.objloader", 0) ;
		_objLoaderSemaphore =dispatch_semaphore_create (1) ;
		_objViewerSemaphore =dispatch_semaphore_create (1) ;
		
		NSNotificationCenter *nc =[NSNotificationCenter defaultCenter] ;
		[nc addObserver:self selector:@selector(showRenderingIndicator:) name:kRenderingStartedNotification object:nil] ;
		[nc addObserver:self selector:@selector(updateRenderingIndicator:) name:kRenderingUpdateNotification object:nil] ;
		[nc addObserver:self selector:@selector(hideRenderingIndicator:) name:kRenderingEndedNotification object:nil] ;
	}
	return (self) ;
}

- (id)initWithParser:(AdskObjParser *)parser {
	if ( (self =[super init]) ) {
		_path =_photosceneid =nil ;
		_lastScale =1.0f ;
		_currentCalculatedMatrix =CATransform3DIdentity ;
		_objLoaderQueue =dispatch_queue_create ("com.autodesk.objloader", 0) ;
		_objLoaderSemaphore =dispatch_semaphore_create (1) ;
		_objViewerSemaphore =dispatch_semaphore_create (1) ;
		_myMesh =parser ;
	}
	return (self) ;
}

/*- (void)dealloc {
	[_path release] ;
	[_photosceneid release] ;
	[_myMesh release] ;
	dispatch_release (_objLoaderQueue) ;
	dispatch_release (_objLoaderSemaphore) ;
	dispatch_release (_objViewerSemaphore) ;
	[super dealloc] ;
}*/

- (void)setupView:(AdskEAGLView *)view {
	if ( dispatch_semaphore_wait (_objViewerSemaphore, DISPATCH_TIME_NOW) != 0 )
		return ;
	
	if ( _path ) {
		if ( dispatch_semaphore_wait (_objLoaderSemaphore, DISPATCH_TIME_NOW) == 0 ) {
			_myMesh =[[AdskObjParser alloc] initWithPath:_path progress:nil] ;
			[_myMesh loadTextures] ;
			dispatch_semaphore_signal (_objLoaderSemaphore) ;
		} else {
			[_myMesh loadTextures] ;
		}
	}
	GLfloat scale =fabs (1 / (_myMesh->_geometry->_maxPoint.x - _myMesh->_geometry->_minPoint.x)) ;
	scale =MIN(scale, fabs (1 / (_myMesh->_geometry->_maxPoint.y - _myMesh->_geometry->_minPoint.y))) ;
	scale =MIN(scale, fabs (1 / (_myMesh->_geometry->_maxPoint.z - _myMesh->_geometry->_minPoint.z))) ;

	view->_model =CATransform3DMakeScale (scale, scale, scale) ;
	view->_model =CATransform3DTranslate (view->_model, -_myMesh->_geometry->_center.x, -_myMesh->_geometry->_center.y, -_myMesh->_geometry->_center.z) ;
	view->_camera =CATransform3DIdentity ;
	view->_projection =CATransform3DIdentity ;
	
	glViewport (0, 0, self.view.frame.size.width, self.view.frame.size.height) ;
	
	dispatch_semaphore_signal (_objViewerSemaphore) ;
}

- (void)drawView:(AdskEAGLView *)view {
	static GLfloat rotation =0.0 ;

	glEnable (GL_DEPTH_TEST) ;
	glClearColor (0.5f, 0.5f, 0.5f, 1.0f) ; // Set the color we use for clearing our _viewRenderbuffer
	glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT) ; // Clear the color/depth buffers
	
	CATransform3D ret =CATransform3DIdentity ;
	if ( [view isAnimated] ) {
		ret =CATransform3DMakeRotation (rotation * M_PI / 180.0f, 1.0f, 1.0f, 1.0f) ;
		ret =CATransform3DConcat (view->_model, ret) ;
		ret =CATransform3DConcat (view->_camera, ret) ;
		view->_mvp =CATransform3DConcat (view->_projection, ret) ;
	} else {
		ret =CATransform3DMakeScale (_lastScale, _lastScale, _lastScale) ;
		/*ret =CATransform3DConcat (view->_model, ret) ;
		//ret =CATransform3DTranslate (ret, _lastX, _lastY, 0.0f) ;
		ret =CATransform3DConcat (view->_camera, ret) ;
		ret =CATransform3DConcat (view->_projection, ret) ;
		ret =CATransform3DTranslate (ret, _posX, _posY, 0.0) ;
		ret =CATransform3DRotate (ret, _lastZ * M_PI / 180.0f, 0.0f, 0.0f, 1.0f) ;
		ret =CATransform3DRotate (ret, _lastX * M_PI / 180.0f, 1.0f, 0.0f, 0.0f) ;
		view->_mvp =CATransform3DRotate (ret, _lastY * M_PI / 180.0f, 0.0f, 1.0f, 0.0f) ;*/
		ret =CATransform3DConcat (_currentCalculatedMatrix, ret) ;
		ret =CATransform3DConcat (view->_model, ret) ;
		ret =CATransform3DConcat (view->_camera, ret) ;
		ret =CATransform3DConcat (view->_projection, ret) ;
		view->_mvp =ret ;
	}
	
	// Tell the GPU we want to use our program
	glUseProgram (view->_simpleProgram) ;
	glUniformMatrix4fv (view->_uniformMvp, 1, GL_FALSE, (GLfloat *)&(view->_mvp)) ;
	// Set the colour uniform (r=1.0, g=1.0, b=1.0, a=1.0)
	//glUniform4f (view->_uniformColour, 1.0, 0, 0, 1.0) ;
	
	[_myMesh setup:view->_uniformTexture] ;
	[_myMesh draw] ;
	
	static NSTimeInterval lastDrawTime ;
	if ( lastDrawTime && [view isAnimated] ) {
		NSTimeInterval timeSinceLastDraw =[NSDate timeIntervalSinceReferenceDate] - lastDrawTime ;
		rotation +=10 * timeSinceLastDraw ;
	}
	lastDrawTime =[NSDate timeIntervalSinceReferenceDate] ;
}

- (void)setupGesture:(AdskEAGLView *)view {
	// Start/Stop animation
	UITapGestureRecognizer *singleTapGesture =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(stopAnimation:)] ;
	[singleTapGesture setNumberOfTapsRequired:1] ;
	[singleTapGesture setNumberOfTouchesRequired:1] ;
	[singleTapGesture setCancelsTouchesInView:NO] ;
	// Insert image into Ac360
	if ( _path ) {
		UITapGestureRecognizer *doubleTapGesture =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(insertImage:)] ;
		[doubleTapGesture setNumberOfTapsRequired:2] ;
		[singleTapGesture requireGestureRecognizerToFail:doubleTapGesture] ;
		[view addGestureRecognizer:doubleTapGesture] ;
		doubleTapGesture =nil ;
	}
	[view addGestureRecognizer:singleTapGesture] ;
	singleTapGesture =nil ;
	// Full screen preview
	UILongPressGestureRecognizer *longTapGesture ;
	if ( _path )
		longTapGesture =[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(fullScreen:)] ;
	else
		longTapGesture =[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(backToPanel:)] ;
	longTapGesture.minimumPressDuration =2.0 ;
	[view addGestureRecognizer:longTapGesture] ;
	//[longTapGesture release] ;
	// Zoom
	UIPinchGestureRecognizer *pinchGesture =[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(scaleMesh:)] ;
	//[pinchGesture setScale:_lastScale] ;
	[view addGestureRecognizer:pinchGesture] ;
	pinchGesture =nil ;
	// Pan -> Rotation X/Y
	UIPanGestureRecognizer *panGesture =[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(rotatePanMesh:)] ;
	[panGesture setMaximumNumberOfTouches:2] ;
	[view addGestureRecognizer:panGesture] ;
	panGesture =nil ;
	// Pan -> 2 finger pan X/Y
	panGesture =[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(translatePanMesh:)] ;
	[panGesture setMinimumNumberOfTouches:2] ;
	[view addGestureRecognizer:panGesture] ;
	panGesture =nil ;
	// Rotation along Z
	UIRotationGestureRecognizer *rotationGesture =[[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotateMesh:)] ;
    [view addGestureRecognizer:rotationGesture] ;
	rotationGesture =nil ;
}

- (void)stopAnimation:(UITapGestureRecognizer *)sender {
	AdskEAGLView *view =(AdskEAGLView *)[sender view] ;
	if ( [view isAnimated] )
		[view stopAnimation] ;
	else
		[view startAnimation] ;
	[view drawView] ;
}

- (void)loadObj:(NSString *)path photosceneid:(NSString *)photosceneid {
	if ( dispatch_semaphore_wait (_objLoaderSemaphore, DISPATCH_TIME_NOW) != 0 ) {
		UIAlertView *alert =[[UIAlertView alloc] initWithTitle:@"ReCap Error" message:@"A scene is already loading!" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] ;
		[alert show] ;
		return ;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:kRenderingStartedNotification object:nil] ;
	[[NSNotificationCenter defaultCenter] postNotificationName:kRenderingUpdateNotification object:[NSNumber numberWithDouble:0.0]] ;
		
	dispatch_async (_objLoaderQueue, ^{
		AdskEAGLView *glView =(AdskEAGLView *)self.view ;
		AdskObjParser *myMesh =[[AdskObjParser alloc] initWithPath:path progress:kRenderingUpdateNotification] ;
		dispatch_sync (dispatch_get_main_queue (), ^{
			[[NSNotificationCenter defaultCenter] postNotificationName:kRenderingUpdateNotification object:[NSNumber numberWithDouble:0.85]] ;
		}) ;
		
		dispatch_async (dispatch_get_main_queue (), ^{
			BOOL bWasAnimated =[glView stopAnimation] ;
			
			_path =[[NSString alloc] initWithString:path] ;
			_photosceneid =[[NSString alloc] initWithString:photosceneid] ;
			_lastScale =1.0f ;
			_currentCalculatedMatrix =CATransform3DIdentity ;
			[[NSNotificationCenter defaultCenter] postNotificationName:kRenderingUpdateNotification object:[NSNumber numberWithDouble:0.92]] ;
			_myMesh =myMesh ;
			[self setupView:glView] ;
			[[NSNotificationCenter defaultCenter] postNotificationName:kRenderingUpdateNotification object:[NSNumber numberWithDouble:1.0]] ;
			
			if ( bWasAnimated )
				[glView startAnimation] ;
			else
				[glView drawView] ;

			[[NSNotificationCenter defaultCenter] postNotificationName:kRenderingEndedNotification object:nil] ;
			dispatch_semaphore_signal (_objLoaderSemaphore) ;
		}) ;
	}) ;
}

- (void)insertImage:(UITapGestureRecognizer *)sender {
	if ( sender.state == UIGestureRecognizerStateEnded ) {
		if ( _photosceneid == nil )
			return ;
		// Now creates an image directly out of the OpenGL preview view
		AdskEAGLView *glvw =(AdskEAGLView *)[self view] ;
		UIImage *destImage =[glvw screenShot] ;
		//UIImage *destImage =[AdskObjParser flipImageVertically:cap] ;
		
        NSString *path =[NSSearchPathForDirectoriesInDomains (NSCachesDirectory, NSUserDomainMask, YES) lastObject] ;
		path =[path stringByAppendingPathComponent:[NSString stringWithFormat:@"icon%@.jpg", [AdskRESTful timestamp]]] ;
		NSData *imageData =[NSData dataWithData:UIImageJPEGRepresentation (destImage, 0.2)] ;
		NSError *writeError =nil ;
		[imageData writeToFile:path options:NSDataWritingAtomic error:&writeError] ;
		if ( writeError != nil ) {
			NSString *errmsg =[NSString stringWithFormat:@"Error in writing file %@ (# %@)", path , writeError] ;
			NSLog(@"%@", errmsg) ;
			UIAlertView *alert =[[UIAlertView alloc] initWithTitle:@"ReCap Error" message:@"Could not create an image for insertion" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] ;
			[alert show] ;
		} else {
			//AdskVwrPanel *vwPanel =(AdskVwrPanel *)AcRegistry::instance ()->getPanel ("VWR") ;
			//vwPanel->hide () ;
			
			//AcRuntimeServices::instance ()->toolManager ()->getAttachImageToolAdapter ()->startToolWithImage ([path UTF8String]) ;
			// Selection does not change with a tool command
		}
	}
}

- (void)fullScreen:(UILongPressGestureRecognizer *)sender {
	if ( _path == nil )
		return ;
	AdskEAGLView *glvw =(AdskEAGLView *)[sender view] ;
	AdskObjViewerController *theController =(AdskObjViewerController *)[glvw controller] ;
	[glvw stopAnimation] ;
	
	CGRect rect =[[UIScreen mainScreen] bounds] ;
	AdskEAGLView *glView =[[AdskEAGLView alloc] initWithView:glvw frame:rect] ;
	AdskObjViewerController *controller =[[AdskObjViewerController alloc] initWithParser:theController._myMesh] ;
	[glView setController:controller] ;
	[controller setupGesture:glView] ;
	[glView startAnimation] ;
	
	[self presentViewController:controller animated:YES completion:nil] ;
}

- (void)backToPanel:(UILongPressGestureRecognizer *)sender {
	if ( _path != nil )
		return ;
	AdskEAGLView *glvw =(AdskEAGLView *)[sender view] ;
	AdskObjViewerController *theController =(AdskObjViewerController *)[glvw controller] ;
	[theController dismissViewControllerAnimated:YES completion:nil] ;
}

- (void)scaleMesh:(UIPinchGestureRecognizer *)sender {
	static float startScale =0.0f ;
	if ( [sender state] == UIGestureRecognizerStateBegan )
		startScale =_lastScale ;
	_lastScale =[sender scale] * startScale ;
	if ( ![(AdskEAGLView *)[sender view] isAnimated] )
		[(AdskEAGLView *)[sender view] drawView] ;
}

- (void)rotatePanMesh:(UIPanGestureRecognizer *)sender {
	CGPoint translation =[sender translationInView:[sender view]] ;
	[sender setTranslation:CGPointZero inView:[sender view]] ;
	GLfloat totalRotation =sqrt (translation.x * translation.x + translation.y * translation.y) ;
	CATransform3D temporaryMatrix =CATransform3DRotate (
				_currentCalculatedMatrix, totalRotation * M_PI / 180.0f,
				((-translation.x / totalRotation) * _currentCalculatedMatrix.m12 + (-translation.y / totalRotation) * _currentCalculatedMatrix.m11),
				((-translation.x / totalRotation) * _currentCalculatedMatrix.m22 + (-translation.y / totalRotation) * _currentCalculatedMatrix.m21),
				((-translation.x / totalRotation) * _currentCalculatedMatrix.m32 + (-translation.y / totalRotation) * _currentCalculatedMatrix.m31)) ;
	if ( temporaryMatrix.m11 >= -100.0 && temporaryMatrix.m11 <= 100.0 )
		_currentCalculatedMatrix =temporaryMatrix ;
	if ( ![(AdskEAGLView *)[sender view] isAnimated] )
		[(AdskEAGLView *)[sender view] drawView] ;
}

- (void)translatePanMesh:(UIPanGestureRecognizer *)sender {
	CGPoint translation =[sender translationInView:[sender view]] ;
	[sender setTranslation:CGPointZero inView:[sender view]] ;
	GLfloat scalingForMovement =0.01f ;
	if ( UI_USER_INTERFACE_IDIOM () == UIUserInterfaceIdiomPad )
		scalingForMovement =0.00425f ;
	// Translate the model by the accumulated amount
	GLfloat currentScaleFactor =sqrt (
									  pow (_currentCalculatedMatrix.m11, 2.0f)
									+ pow (_currentCalculatedMatrix.m12, 2.0f)
									+ pow (_currentCalculatedMatrix.m13, 2.0f)) ;
	translation.x =translation.x * scalingForMovement / (currentScaleFactor * currentScaleFactor) ;
	translation.y =-translation.y * scalingForMovement / (currentScaleFactor * currentScaleFactor) ;
	// Use the (0,4,8) components to figure the eye's X axis in the model coordinate system, translate along that
	CATransform3D temporaryMatrix =CATransform3DTranslate (
														   _currentCalculatedMatrix,
														   translation.x * _currentCalculatedMatrix.m11, translation.x * _currentCalculatedMatrix.m21, translation.x * _currentCalculatedMatrix.m31) ;
	// Use the (1,5,9) components to figure the eye's Y axis in the model coordinate system, translate along that
	temporaryMatrix =CATransform3DTranslate (
											 temporaryMatrix,
											 translation.y * _currentCalculatedMatrix.m12, translation.y * _currentCalculatedMatrix.m22, translation.y * _currentCalculatedMatrix.m32) ;
	if ( temporaryMatrix.m11 >= -100.0 && temporaryMatrix.m11 <= 100.0 )
		_currentCalculatedMatrix =temporaryMatrix ;
	if ( ![(AdskEAGLView *)[sender view] isAnimated] )
		[(AdskEAGLView *)[sender view] drawView] ;
}

- (void)rotateMesh:(UIRotationGestureRecognizer *)sender {
	//_lastZ -=sender.rotation * 180.0f / M_PI / 10.0f ;
	//NSLog(@"angle %.2f %.2f", lastZ) ;
	if ( ![(AdskEAGLView *)[sender view] isAnimated] )
		[(AdskEAGLView *)[sender view] drawView] ;
}

- (void)showRenderingIndicator:(NSNotification *)note {
	if ( renderingProgressIndicator != nil ) {
		[renderingProgressIndicator removeFromSuperview] ;
		renderingProgressIndicator =nil ;
	}
	float renderingIndicatorWidth =round (self.view.frame.size.width * 0.6) ;
	renderingProgressIndicator =[[UIProgressView alloc]
								 initWithFrame:CGRectMake (round (self.view.frame.size.width / 2.0f - renderingIndicatorWidth / 2.0f),
														   round (self.view.frame.size.height / 2.0f + 15.0f),
														   renderingIndicatorWidth, 9.0f)] ;
	[renderingProgressIndicator setProgress:0.0f] ;
	renderingProgressIndicator.progressViewStyle =UIProgressViewStyleBar ;

	if ( renderingActivityLabel != nil )	{
		[renderingActivityLabel removeFromSuperview] ;
		renderingActivityLabel =nil ;
	}

	renderingActivityLabel =[[UILabel alloc] initWithFrame:CGRectMake (
												round (self.view.frame.size.width / 2.0f - 219.0f / 2.0f),
												round(self.view.frame.size.height / 2.0f - 15.0f - 21.0f),
												219.0f, 21.0f)] ;
	renderingActivityLabel.font =[UIFont systemFontOfSize:17.0f] ;
	renderingActivityLabel.text =@"Loading/Rendering mesh..." ;
	renderingActivityLabel.textAlignment =NSTextAlignmentCenter ;
	renderingActivityLabel.backgroundColor =[UIColor clearColor] ;
	renderingActivityLabel.textColor =[UIColor blackColor] ;

	[renderingProgressIndicator setProgress:0.0] ;
	[self.view addSubview:renderingProgressIndicator] ;
	[self.view addSubview:renderingActivityLabel] ;
}

- (void)updateRenderingIndicator:(NSNotification *)note {
	float percentComplete =[(NSNumber *)[note object] floatValue] ;
	if ( renderingProgressIndicator != nil )
		renderingProgressIndicator.progress =percentComplete ;
}

- (void)hideRenderingIndicator:(NSNotification *)note {
	[renderingActivityLabel removeFromSuperview] ;
	[renderingProgressIndicator removeFromSuperview] ;
	renderingActivityLabel =nil ;
	renderingProgressIndicator =nil ;
}

@end
