//
//  ViewController.h
//  BangaloreHack
//
//  Created by Cyrille Fauvel on 03/05/14.
//  Copyright (c) 2014 Cyrille. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AdskOAuthController.h"

@interface ViewController : UIViewController {
	AdskOAuthController *_oaController ;
	
	UIButton *_progressBar ;
	UIImage *_blackButton, *_blueButton, *_redButton, *_greenButton ;

	NSString *_photosceneid ;
	NSString *_objFilePath, *_mtlFilePath, *_texFilePath ;
	
	NSTimer *myT ;
	dispatch_queue_t _recapQueue ;
	dispatch_semaphore_t _recapSemaphore ;
}

@property (nonatomic, weak) IBOutlet UIButton *startReCap ;
- (IBAction)startReCapClick:(id)sender ;

- (void)viewDidAppear:(BOOL)animated ;

- (void)sendToReCap ;
- (void)DetectReCapCompleted ;
- (void)GetReCapResult ;

@end
