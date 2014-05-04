//
//  ViewController.m
//  BangaloreHack
//
//  Created by Cyrille Fauvel on 03/05/14.
//  Copyright (c) 2014 Cyrille. All rights reserved.
//

#import "ViewController.h"
#import "AdskReCap.h"
#import "ZipArchive.h"
#import "DDXML.h"
#import "UserSettings.h"
#import "AdskObjViewerController.h"

@interface ViewController ()

@end

@implementation ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ( (self =[super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) ) {
		_recapQueue =dispatch_queue_create ("com.autodesk.recap", 0) ;
		_recapSemaphore =dispatch_semaphore_create (1) ;
    }
    return (self) ;
}

/*- (void)dealloc {
	dispatch_release (_recapQueue) ;
	dispatch_release (_recapSemaphore) ;
	[super dealloc] ;
}*/
- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self] ;
}

- (void)viewDidLoad {
	_recapQueue =dispatch_queue_create ("com.autodesk.recap", 0) ;
	_recapSemaphore =dispatch_semaphore_create (1) ;
	[self viewInitializations] ;
	[self.view addSubview:_progressBar] ;
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	_oaController =[[AdskOAuthController alloc] initWithNibName:nil bundle:nil] ;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionStatusChanged:) name:@"A360ConnectionStatusChanged" object:nil] ;

}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated] ;
	[self testInternetConnection] ;
}

- (void)viewInitializations {
	_blackButton =[UIImage imageNamed:@"button-black.png"] ;
	_blueButton =[UIImage imageNamed:@"button-blue.png"] ;
	_redButton =[UIImage imageNamed:@"button-red.png"] ;
	_greenButton =[UIImage imageNamed:@"button-green.png"] ;
	_loginImg =[UIImage imageNamed:@"login-icon.png"] ;
	_logoutImg =[UIImage imageNamed:@"logout-icon.png"] ;
	
	_progressBar =[UIButton buttonWithType:UIButtonTypeRoundedRect] ;
	_progressBar.frame =CGRectMake (0, 0, 320, 35) ;
	[_progressBar setTitle:@" " forState:UIControlStateNormal] ;
	[_progressBar setTitleColor:[UIColor yellowColor] forState:UIControlStateNormal] ;
	[_progressBar setBackgroundColor:[UIColor darkGrayColor]] ;
	[_progressBar setBackgroundImage:_blackButton forState:UIControlStateNormal] ;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning] ;
    // Dispose of any resources that can be recreated.
}

- (void)networkStatusChanged:(NSNotification *)note {
    Reachability *reach =[note object] ;
	self.loginout.enabled =YES ;
    if ( [reach isReachable] )
		[self tryToConnectToA360] ;
    else
		[self connectionFailed] ;
}

- (void)testInternetConnection {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStatusChanged:) name:kReachabilityChangedNotification object:nil] ;

    _internetReachable =[Reachability reachabilityWithHostname:@"www.google.com"] ;
    // Internet is reachable
    _internetReachable.reachableBlock =^(Reachability* reach) {
        // Update the UI on the main thread
        dispatch_async (dispatch_get_main_queue (), ^{
            NSLog(@"Yayyy, we have the interwebs!") ;
        }) ;
    } ;
    // Internet is not reachable
    _internetReachable.unreachableBlock =^(Reachability* reach) {
        // Update the UI on the main thread
        dispatch_async (dispatch_get_main_queue (), ^{
            NSLog(@"Someone broke the internet :(") ;
        }) ;
    } ;
    [_internetReachable startNotifier] ;
}

- (void)connectionSuccessful {
	_isConnectedToA360 =YES ;
	[self.loginout setImage:_loginImg forState:UIControlStateNormal] ;
	self.startReCap.enabled =YES ;
}

- (void)connectionFailed {
	_isConnectedToA360 =NO ;
	[self.loginout setImage:_logoutImg forState:UIControlStateNormal] ;
	self.startReCap.enabled =NO ;
}

- (void)connectionStatusChanged:(NSNotification *)note {
	NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults] ;
	if ( [defaults objectForKey:@"oauth_token"] || ![[defaults stringForKey:@"oauth_token"]  isEqual: @""] ) {
		dispatch_async (dispatch_get_main_queue (), ^{
			[self connectionSuccessful] ;
		}) ;
	} else {
		dispatch_async (dispatch_get_main_queue (), ^{
			[self connectionFailed] ;
		}) ;
	}
}

- (void)tryToConnectToA360 {
	if ( ![_oaController AccessToken:YES PIN:nil] ) {
		[self presentViewController:_oaController animated:YES completion:^() {
		}] ;
	} else
		[self connectionFailed] ;
}

- (void)tryToDisconnectFromA360 {
	[_oaController InvalidateToken] ;
	[self connectionFailed] ;
}

- (IBAction)loginoutClick:(id)sender {
	if ( [_internetReachable isReachable] == NO ) {
		[self testInternetConnection] ;
		return ;
	}
	
	if ( _isConnectedToA360 == NO )
		[self tryToConnectToA360] ;
	else
		[self tryToDisconnectFromA360] ;
	
}

- (IBAction)startReCapClick:(id)sender {
	[self sendToReCap] ;
}

- (void)waitForReCapToFinish {
    dispatch_semaphore_wait (_recapSemaphore, DISPATCH_TIME_FOREVER) ;
    dispatch_semaphore_signal (_recapSemaphore) ;
}

// PPKlq6vTPcLTK5R1ehPZYc5qSU4
// For DEBUG only
- (void)getMyPhotoSceneNow {
	_photosceneid =@"PPKlq6vTPcLTK5R1ehPZYc5qSU4" ; // snail
	_photosceneid =@"2vFFLFLtTeZyqdHaUd49gbHACMQ" ; // Viru
	
													//_photosceneid =@"EG8WAPuP7KWqjZVZ5B5cvaePjaY" ; // calc
													//_photosceneid =@"yP4LwlQRRxwhFP5e16q6HVf0R8I" ; // dog
													//_photosceneid =@"a7Wvr9zpUP008D7iJchtVjOzJTg" ; // mouse (with error)
													//_photosceneid =@"fUK6FM0pEMB6exm1Gg1NWZprd7A" ; // pen
	[myT invalidate] ;
	myT =[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(DetectReCapCompleted) userInfo:nil repeats:YES] ;
}

- (void)sendToReCap {

	// For DEBUG only
	[self getMyPhotoSceneNow] ; return ;
	
	dispatch_async (dispatch_get_main_queue (), ^{
		[_progressBar setBackgroundImage:_blueButton forState:UIControlStateNormal] ;
		[_progressBar setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal] ;
	}) ;
	
	dispatch_async (_recapQueue, ^{
		// Initialize the ReCap / Oxygen authentication
		NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults] ;
		AdskReCap *recap =[[AdskReCap alloc] initWithTokens:ReCapClientID
												consumerKey:CONSUMER_KEY
											 consumerSecret:CONSUMER_SECRET
													  oauth:[defaults objectForKey:@"oauth_token"]
												oauthSecret:[defaults objectForKey:@"oauth_token_secret"]] ;
		
		// 1- Create a new Photoscene
		NSError *error =nil ;
		dispatch_async (dispatch_get_main_queue (), ^{
			[_progressBar setTitle:@"Creating Photoscene..." forState:UIControlStateNormal] ;
		}) ;
		if ( ![recap CreateSimplePhotoscene:@"obj" meshQuality:@"7"] ) {
			NSString *errmsg =[recap ErrorMessage:YES] ;
			dispatch_async (dispatch_get_main_queue (), ^{
				[_progressBar setTitle:errmsg forState:UIControlStateNormal] ;
				[_progressBar setBackgroundImage:_redButton forState:UIControlStateNormal] ;
				[_progressBar setTitleColor:[UIColor yellowColor] forState:UIControlStateNormal] ;
			}) ;
			dispatch_semaphore_signal (_recapSemaphore) ;
			return ;
		}
		DDXMLDocument *xml =[recap xml] ;
		NSArray *results =[xml nodesForXPath:@"/Response/Photoscene/photosceneid" error:&error] ;
		_photosceneid =[[results objectAtIndex:0] stringValue] ;
		NSLog(@"[sendToReCap] Your photosceneid: %@", _photosceneid) ;
		dispatch_sync (dispatch_get_main_queue (), ^{
			[_progressBar setTitle:[NSString stringWithFormat:@"Your photosceneid: %@", _photosceneid] forState:UIControlStateNormal] ;
		}) ;

		// 2- Upload photos to the ReCap server & Photoscene
		NSMutableDictionary *files =[[NSMutableDictionary alloc] init] ;
		int i =0 ;
/*		for ( UICollectionViewCell *cell in _collectionView.visibleCells ) {
			NSString *name =[NSString stringWithFormat:@"ReCap%d.jpg", i] ;
			UIImageView *av =(UIImageView *)cell.backgroundView ;
			UIImage *img =av.image ;
			if ( CGSizeEqualToSize (img.size, CGSizeMake (96, 96)) ) // This is the default image
				continue ;
			NSData *imgData =[NSData dataWithData:UIImageJPEGRepresentation (img, 0.2)] ;
			[files setObject:imgData forKey:name] ;
			i++ ;
		}
*/
		NSString *resourcePath =[[NSBundle mainBundle] resourcePath] ;
		//NSString *documentsPath =[resourcePath stringByAppendingPathComponent:@"Viru"] ;
		//NSString *documentsPath =[resourcePath stringByAppendingString:@"Viru"] ;
		//NSError *error;
		NSArray *directoryContents =[[NSFileManager defaultManager] contentsOfDirectoryAtPath:resourcePath error:&error] ;
		NSPredicate *fltr =[NSPredicate predicateWithFormat:@"self CONTAINS 'ReCap'"] ;
		//https://developer.apple.com/library/mac/documentation/cocoa/reference/foundation/classes/nsfilemanager_class/reference/reference.html
		NSArray *list =[directoryContents filteredArrayUsingPredicate:fltr] ;
		for ( /*NSURL *theURL*/NSString *fileName in list ) {
			// Retrieve the file name. From NSURLNameKey, cached during the enumeration.
			//NSString *fileName =[[NSString alloc] initWithString:[theURL path]] ;// lastPathComponent] ;
			// Retrieve whether a directory. From NSURLIsDirectoryKey, also cached during the enumeration.
			//BOOL isDirectory =![theURL isFileURL] ;
			// Ignore files under the _extras directory
			//if (   [fileName caseInsensitiveCompare:@"_extras"] == NSOrderedSame
			//	&& isDirectory == YES
			//) {
			//	continue ;
			//}
			// Add full path for non directories
			//if ( isDirectory == NO ) {
				//NSString *url =[[NSString alloc] initWithString:[theURL path]] ;
				//NSString *url =[[NSString alloc] initWithFormat:@"%@/%@", resourcePath, fileName] ;
				UIImage *img =[UIImage imageNamed:fileName] ;
				NSData *imgData =[NSData dataWithData:UIImageJPEGRepresentation (img, 0.2)] ;
				NSString *name =[fileName stringByDeletingPathExtension] ;
				[files setObject:imgData forKey:name] ;
			//}
			i++ ;
			if ( i == 19 )
				break ;
		}
		
		// For debug
		if ( [files count] == 0 ) {
			//for ( int i =16, j=0 ; i <= 34 ; i++, j++ ) {
			for ( int i =16, j=0 ; i <= 21 ; i++, j++ ) {
				NSString *name =[NSString stringWithFormat:@"IMG_00%d", i] ;
				NSString *pathImg =[[NSBundle mainBundle] pathForResource:name ofType:@"JPG"] ;
				UIImage *image =[UIImage imageWithContentsOfFile:pathImg] ;
				name =[NSString stringWithFormat:@"ReCap%d.jpg", j] ;
				NSData *imgData =[NSData dataWithData:UIImageJPEGRepresentation (image, 0.2)] ;
				[files setObject:imgData forKey:name] ;
			}
		}
		dispatch_sync (dispatch_get_main_queue (), ^{
			[_progressBar setTitle:@"Uploading photos to your scene..." forState:UIControlStateNormal] ;
		}) ;
		if ( ![recap UploadFiles:_photosceneid files:files] ) {
			NSString *errmsg =[recap ErrorMessage:YES] ;
			dispatch_async (dispatch_get_main_queue (), ^{
				[_progressBar setTitle:errmsg forState:UIControlStateNormal] ;
				[_progressBar setBackgroundImage:_redButton forState:UIControlStateNormal] ;
				[_progressBar setTitleColor:[UIColor yellowColor] forState:UIControlStateNormal] ;
			}) ;
			dispatch_semaphore_signal (_recapSemaphore) ;
			return ;
		}
		
		// 3- Launch Photoscene processing
		dispatch_sync (dispatch_get_main_queue (), ^{
			[_progressBar setTitle:@"Launching scene..." forState:UIControlStateNormal] ;
		}) ;
		if ( ![recap ProcessScene:_photosceneid] ) {
			NSString *errmsg =[recap ErrorMessage:YES] ;
			dispatch_async (dispatch_get_main_queue (), ^{
				[_progressBar setTitle:errmsg forState:UIControlStateNormal] ;
				[_progressBar setBackgroundImage:_redButton forState:UIControlStateNormal] ;
				[_progressBar setTitleColor:[UIColor yellowColor] forState:UIControlStateNormal] ;
			}) ;
			dispatch_semaphore_signal (_recapSemaphore) ;
			return ;
		}
		
		// 4- Now we need to wait for the ReCap server to complete the Photoscene
		dispatch_async (dispatch_get_main_queue (), ^{
			[myT invalidate] ;
			myT =[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(DetectReCapCompleted) userInfo:nil repeats:YES] ;
		}) ;
	}) ;
}

- (void)DetectReCapCompleted {
	dispatch_async (_recapQueue, ^{
		// Initialize the ReCap / Oxygen authentication
		NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults] ;
		AdskReCap *recap=[[AdskReCap alloc] initWithTokens:ReCapClientID
											   consumerKey:CONSUMER_KEY
											consumerSecret:CONSUMER_SECRET
													 oauth:[defaults objectForKey:@"oauth_token"]
											   oauthSecret:[defaults objectForKey:@"oauth_token_secret"]] ;
		
		// 5- Check progress on the server worker processing the scene
		NSLog(@"[DetectReCapCompleted] Your photosceneid: %@", _photosceneid) ;
		if ( ![recap SceneProgress:_photosceneid] ) {
			[myT invalidate] ;
			myT =nil ;
			NSString *errmsg =[recap ErrorMessage:YES] ;
			dispatch_async (dispatch_get_main_queue (), ^{
				[_progressBar setTitle:errmsg forState:UIControlStateNormal] ;
				[_progressBar setBackgroundImage:_redButton forState:UIControlStateNormal] ;
				[_progressBar setTitleColor:[UIColor yellowColor] forState:UIControlStateNormal] ;
			}) ;
			dispatch_semaphore_signal (_recapSemaphore) ;
			return ;
		}
		NSError *error =nil ;
		DDXMLDocument *xml =[recap xml] ;
		NSArray *results =[xml nodesForXPath:@"/Response/Photoscene/progress" error:&error] ;
		NSString *value =[results [0] stringValue] ;
		
		// Display progress
		dispatch_sync (dispatch_get_main_queue (), ^{
			[_progressBar setTitleColor:[UIColor yellowColor] forState:UIControlStateNormal] ;
			[_progressBar setTitle:[NSString stringWithFormat:@"%.02f %%", [value floatValue]] forState:UIControlStateNormal] ;
			
			UIGraphicsBeginImageContextWithOptions (_progressBar.bounds.size, NO, 0.0) ;
			[_blackButton drawAtPoint:CGPointMake (0, 0)] ;
			[[UIColor magentaColor] setFill] ;
			CGFloat x =_progressBar.bounds.size.width * [value floatValue] / 100 ;
			UIRectFill (CGRectMake (0, 0, x, _progressBar.bounds.size.height)) ;
			
			UIImage *blank =UIGraphicsGetImageFromCurrentImageContext () ;
			UIGraphicsEndImageContext () ;
			[_progressBar setBackgroundImage:blank forState:UIControlStateNormal] ;
		}) ;
		
		// When the worker has completed download and process the mesh
		if ( [value isEqual: @"100"] ) {
			[myT invalidate] ;
			myT =nil ;
			[self GetReCapResult] ;
			dispatch_semaphore_signal (_recapSemaphore) ;
			//return ;
		}
	}) ;
}

- (void)GetReCapResult {
	//dispatch_async (_recapQueue, ^{
	
	// Initialize the ReCap / Oxygen authentication
	NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults] ;
	AdskReCap *recap=[[AdskReCap alloc] initWithTokens:ReCapClientID
										   consumerKey:CONSUMER_KEY
										consumerSecret:CONSUMER_SECRET
												 oauth:[defaults objectForKey:@"oauth_token"]
										   oauthSecret:[defaults objectForKey:@"oauth_token_secret"]] ;
	
	// 6- Download resulting mesh
	dispatch_async (dispatch_get_main_queue (), ^{
		[_progressBar setBackgroundImage:_blueButton forState:UIControlStateNormal] ;
		[_progressBar setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal] ;
		[_progressBar setTitle:@"Downloading scene result..." forState:UIControlStateNormal] ;
	}) ;
	NSLog(@"[GetReCapResult] Your photosceneid: %@", _photosceneid) ;
	if ( ![recap GetPointCloudArchive:_photosceneid format:@"obj"] ) {
		NSString *errmsg =[recap ErrorMessage:YES] ;
		dispatch_async (dispatch_get_main_queue (), ^{
			[_progressBar setTitle:errmsg forState:UIControlStateNormal] ;
			[_progressBar setBackgroundImage:_redButton forState:UIControlStateNormal] ;
			[_progressBar setTitleColor:[UIColor yellowColor] forState:UIControlStateNormal] ;
		}) ;
		return ;
	}
	// Get the web link & download the file (no authentication required)
	NSError *error =nil ;
	DDXMLDocument *xmlPointCloudLink =[recap xml] ;
	NSArray *resultsLink =[xmlPointCloudLink nodesForXPath:@"/Response/Photoscene/scenelink" error:&error] ;
	NSString *valueLink =[resultsLink [0] stringValue] ;
	if ( [valueLink isEqualToString:@""] ) { // progressmsg certainly says ERROR
		NSString *errmsg =@"PhotoScene failed :(" ;
		dispatch_async (dispatch_get_main_queue (), ^{
			[_progressBar setTitle:errmsg forState:UIControlStateNormal] ;
			[_progressBar setBackgroundImage:_redButton forState:UIControlStateNormal] ;
			[_progressBar setTitleColor:[UIColor yellowColor] forState:UIControlStateNormal] ;
		}) ;
		return ;
	}
	NSURL *myUrl =[NSURL URLWithString:valueLink] ;
	NSData *myData =[NSData dataWithContentsOfURL:myUrl] ;
	// Workaround the bug when the file is not yet ready to download
	NSArray *resultsLink2 =[xmlPointCloudLink nodesForXPath:@"/Response/Photoscene/filesize" error:&error] ;
	NSString *size =[resultsLink2 [0] stringValue] ;
	if ( [size isEqualToString:@"0"] || myData == nil || [myData length] == 0 ) {
		[recap SceneProperties:_photosceneid] ; // To see if there is any difference for the next time
		dispatch_async (dispatch_get_main_queue (), ^{
			NSString *errmsg =@"Waiting for mesh file..." ;
			[_progressBar setTitle:errmsg forState:UIControlStateNormal] ;
			[_progressBar setBackgroundImage:_redButton forState:UIControlStateNormal] ;
			[_progressBar setTitleColor:[UIColor yellowColor] forState:UIControlStateNormal] ;
		}) ;
		while ( myData == nil || [myData length] == 0 ) {
			[NSThread sleepForTimeInterval:5] ;
			myData =[NSData dataWithContentsOfURL:myUrl] ;
		}
		[recap SceneProperties:_photosceneid] ;
	}
	
	// 7- Unzip the Photoscene zip into the user Document folder
	dispatch_async (dispatch_get_main_queue (), ^{
		[_progressBar setTitle:@"Unzipping scene result..." forState:UIControlStateNormal] ;
	}) ;
	NSString *path =[NSSearchPathForDirectoriesInDomains (NSCachesDirectory, NSUserDomainMask, YES) lastObject] ;
	NSString *zipFilePath =[path stringByAppendingPathComponent:@"temp.zip"] ;
	NSString *pathDoc =[NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES) lastObject] ;
	NSString *zipOutputPath =[pathDoc stringByAppendingPathComponent:_photosceneid] ;
	if ( ![[NSFileManager defaultManager] fileExistsAtPath:zipOutputPath] )
		[[NSFileManager defaultManager] createDirectoryAtPath:zipOutputPath withIntermediateDirectories:NO attributes:nil error:&error] ;
	NSError *writeError =nil ;
	[myData writeToFile:zipFilePath options:0 error:&writeError] ;
	if ( writeError) {
		NSString *errmsg =[NSString stringWithFormat:@"Error in writing file %@ (# %@)", zipFilePath , writeError] ;
		NSLog(@"%@", errmsg) ;
		UIAlertView *alert =[[UIAlertView alloc] initWithTitle:@"ReCap Error" message:errmsg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] ;
		[alert show] ;
		dispatch_async (dispatch_get_main_queue (), ^{
			[_progressBar setTitle:errmsg forState:UIControlStateNormal] ;
			[_progressBar setBackgroundImage:_redButton forState:UIControlStateNormal] ;
			[_progressBar setTitleColor:[UIColor yellowColor] forState:UIControlStateNormal] ;
		}) ;
		return ;
	}
	ZipArchive* za =[[ZipArchive alloc] init] ;
	if ( ![za UnzipOpenFile:zipFilePath] ) {
		// There was an issue to open the zip file
		NSString *errmsg =[NSString stringWithFormat:@"Failed to open %@", zipFilePath] ;
		NSLog(@"%@", errmsg) ;
		UIAlertView *alert =[[UIAlertView alloc] initWithTitle:@"ReCap Error" message:errmsg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] ;
		[alert show] ;
		dispatch_async (dispatch_get_main_queue (), ^{
			[_progressBar setTitle:errmsg forState:UIControlStateNormal] ;
			[_progressBar setBackgroundImage:_redButton forState:UIControlStateNormal] ;
			[_progressBar setTitleColor:[UIColor yellowColor] forState:UIControlStateNormal] ;
		}) ;
		return ;
	}
	/*BOOL ret =*/[za UnzipFileTo:zipOutputPath overWrite:YES] ;
	[za UnzipCloseFile] ;
	
	// 8- Load mesh in the preview panel
	NSArray *directoryContents =[[NSFileManager defaultManager] contentsOfDirectoryAtPath:zipOutputPath error:&error] ;
	if ( [directoryContents count] > 0 ) {
		NSPredicate *filter =[NSPredicate predicateWithFormat:@"self ENDSWITH '.obj'"] ;
		NSArray *objFiles =[directoryContents filteredArrayUsingPredicate:filter] ;
		NSLog(@"Files: %@", objFiles) ;
		NSString *objFilePath =[NSString stringWithFormat:@"%@/%@", zipOutputPath, [objFiles objectAtIndex:0]] ;
		
		filter =[NSPredicate predicateWithFormat:@"self ENDSWITH '.mtl'"] ;
		objFiles =[directoryContents filteredArrayUsingPredicate:filter] ;
		NSLog(@"Files: %@", objFiles) ;
		NSString *mtlFilePath =[NSString stringWithFormat:@"%@/%@", zipOutputPath, [objFiles objectAtIndex:0]] ;
		
		filter =[NSPredicate predicateWithFormat:@"self LIKE 'tex_*.jpg'"] ;
		objFiles =[directoryContents filteredArrayUsingPredicate:filter] ;
		NSLog(@"Files: %@", objFiles) ;
		NSString *texFilePath =[NSString stringWithFormat:@"%@/%@", zipOutputPath, [objFiles objectAtIndex:0]] ;
		
		dispatch_async (dispatch_get_main_queue (), ^{
			[_progressBar setTitle:@"Loading mesh..." forState:UIControlStateNormal] ;
		}) ;
		dispatch_async (dispatch_get_main_queue (), ^{
			_objFilePath =[NSString stringWithString:objFilePath] ;
			_mtlFilePath =[NSString stringWithString:mtlFilePath] ;
			_texFilePath =[NSString stringWithString:texFilePath] ;
			NSLog(@"OBJ/MTL files: %@ / %@ / %@", _objFilePath, _mtlFilePath, _texFilePath) ;
			// Load mesh in the preview panel
			//AdskVwrPanel *vwPanel =(AdskVwrPanel *)AcRegistry::instance ()->getPanel ("VWR") ;
			//vwPanel->loadObj (string ([objFilePath UTF8String]), string ([valueLink UTF8String])) ;
			[_progressBar setTitle:@"Your mesh is available for insertion & preview!" forState:UIControlStateNormal] ;
			[_progressBar setBackgroundImage:_greenButton forState:UIControlStateNormal] ;
			[_progressBar setTitleColor:[UIColor magentaColor] forState:UIControlStateNormal] ;
			// Switch panels
			//AdskReCapPanel *recapPanel =(AdskReCapPanel *)AcRegistry::instance ()->getPanel ("RECAP") ;
			//recapPanel->hide () ;
			//vwPanel->show () ;

			AdskEAGLView *glView =[[AdskEAGLView alloc] initWithFrame:CGRectMake(0, 0, [[self view] frame].size.width, [[self view] frame].size.height)] ;
			//AdskObjViewerController *objController =[[AdskObjViewerController alloc] initWithNibName:nil bundle:nil] ;
			AdskObjViewerController *objController =[[AdskObjViewerController alloc] initWithObj:objFilePath photosceneid:valueLink] ;
			//[objController loadObj:objFilePath photosceneid:valueLink] ;
			[objController setupGesture:glView] ;
			[glView setController:objController] ;
			[glView startAnimation] ;
			[self presentViewController:objController animated:YES completion:nil] ;

		
		}) ;
	}
	
	//}) ;
}

@end
