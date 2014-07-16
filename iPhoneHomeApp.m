#import "iPhoneHomeApp.h"
#import <UIKit/UINavigationItemView.h>
#import <GraphicsServices/GraphicsServices.h>
#include <IOKit/IOKitLib.h>
#import <UIKit/UIView-Geometry.h>
#include <sys/stat.h>
#include <stdio.h>
#include <errno.h>
#include <sys/types.h>


@interface MyUIPickerView: UIPickerView{
	id	*app;

}
-(BOOL)table:(UIPickerTable*)table canSelectRow:(int)row;
@end

@implementation MyUIPickerView

-(id)initWithFrame:(struct CGRect)frame withApp:(id *)aApp{
	self = [super initWithFrame: frame];
	app = aApp;
	return self;
}

// this seems to be the only SEL sent when a row is tapped.
// probably ought to return YES, and close picker
-(BOOL) table:(UIPickerTable*)table canSelectRow:(int)row{
	if(row == 7){
		[app askForNumber];
	}else{
		[app setTopCell:row];		
	}

//	NSLog(@"table:canSelectRow:%i",row);
	return YES;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
	//NSLog(@"UIDatePicker: respondsToSelector: selector = %@", NSStringFromSelector(aSelector));
	return [super respondsToSelector:aSelector];
}
@end

@implementation iPhoneHomeApp

+(id)init:(NSArray *)aString
{

	
	//NSLog(@"initString: %d", [aString count]);
	self = [super init];

	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:@"NO" forKey:PREFS_LAUNCH_NUMBER];		
	
	//LOOK FOR --launchURL.  IF IT EXISTS THEN WE WERE CALLED FROM DOUBLETAP
	if([aString count] > 2){

		if([[aString objectAtIndex:2] isEqualToString:@"--launchURL"]){
			if([aString count] > 3){
				NSString *getNumber = [[[aString objectAtIndex:3] componentsSeparatedByString:@"?"] objectAtIndex:1];
				[userDefaults setObject:getNumber forKey:PREFS_NUMBER];	
				[userDefaults setObject:@"YES" forKey:PREFS_LAUNCH_NUMBER];
			}  
		}

	}
			
	return self;
}


- (void) applicationDidFinishLaunching: (id) unused
{

	//CHECK VERSION NUMBER
	NSString *operatingSystemVersionString = [[NSProcessInfo processInfo] operatingSystemVersionString];
	if (operatingSystemVersionString) {
		NSString *ver = [operatingSystemVersionString substringWithRange:NSMakeRange(8, 5)];
		NSString *base = @"1.1.3";
		if([ver compare:base options:NSNumericSearch] < 0){
			osAbove113 = NO;
			plistLocation = @"/var/root/Library/Preferences/com.apple.springboard.plist";
		}else{
			osAbove113 = YES;
			plistLocation = @"/var/mobile/Library/Preferences/com.apple.springboard.plist";
		}
		
	}
	
	if([[[NSUserDefaults standardUserDefaults] objectForKey: PREFS_LAUNCH_NUMBER] isEqualToString:@"YES"]){
		NSString *myTmpString = [[NSUserDefaults standardUserDefaults] objectForKey: PREFS_NUMBER];
		
		[self openURL:[NSURL URLWithString:[[NSString stringWithString:@"tel:"] stringByAppendingString:myTmpString]] asPanel:NO];
		[self terminate];
	}

	UIWindow *window;
	
	dataArray = [self getAllApplications];
	
	float cyan[4] = {0, 0.6823, 0.9372, 1};
	float black[4] = {0, 0.0, 0.0, 1};
	float white[4] = {1.0, 1.0, 1.0, 1};
	float transparent[4] = {0.0, 0.8, 1.0, 1};
	float realtransparent[4] = {0.0, 0.8, 1.0, 0.0};
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	
	// create the main view so we can put the table in it
 	CGRect rect = [UIHardware fullScreenApplicationContentRect];
    rect.origin.x = rect.origin.y = 0.0f;
	
	
  	window = [[UIWindow alloc] initWithContentRect: rect];
	mainView = [[UIView alloc] initWithFrame: rect];

	adCell = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0, 120.0)];
	[adCell setImage:[UIImage imageAtPath:[[NSBundle mainBundle] pathForResource:@"ad" ofType:@"png" inDirectory:@"/"]]];
	
	imageCell = [[UIImageView alloc] initWithFrame:CGRectMake(10.0f, 124.0f, 60.0, 60.0)];
	[imageCell setImage:[UIImage imageAtPath:[[NSBundle mainBundle] pathForResource:@"icon" ofType:@"png" inDirectory:@"/"]]];
	

	testview = [[UIView alloc] initWithFrame: CGRectMake(0.0f, rect.size.height-0, rect.size.width, 400.0f)];
	[testview setBackgroundColor: CGColorCreate(CGColorSpaceCreateDeviceRGB(), cyan)];

	appName = [[UIView alloc] initWithFrame:CGRectMake(0.0, 120.0f, 320.0, 64.0)];
	[appName setBackgroundColor: CGColorCreate(CGColorSpaceCreateDeviceRGB(), cyan)];
	
	backdrop = [[UIView alloc] initWithFrame: CGRectMake(0.0f, 0.0f, rect.size.width, rect.size.height)];
	[backdrop setBackgroundColor: CGColorCreate(CGColorSpaceCreateDeviceRGB(), black)];
	
	UIView *buttonBacks = [[UIView alloc] initWithFrame: CGRectMake(0.0f, 185.0f, 320.0f, 60.0f)];
	[buttonBacks setImage:[UIImage applicationImageNamed:@"button-backs.png"]];

	titleLabel = [[UITextLabel alloc] init];
	[titleLabel setColor:CGColorCreate(colorSpace, white)];
	[titleLabel setBackgroundColor:CGColorCreate(colorSpace, realtransparent)];
	[titleLabel setFont:[NSClassFromString(@"WebFontCache") createFontWithFamily:@"Helvetica" traits:2 size:27.]];
	//[titleLabel setAlignment:1];
	
	UITextLabel *credits = [[UITextLabel alloc] init];
	[credits setText:@"iPhoneHome v0.7.3 - Jerry Jones"];
	[credits setColor:CGColorCreate(colorSpace, white)];
	[credits setFrame:CGRectMake(26.0f, 410.0f, 320.0, 60.0)];
//	[credits setAlignment:1];
	[credits setColor:CGColorCreate(colorSpace, white)];
	[credits setBackgroundColor:CGColorCreate(colorSpace, realtransparent)];
	[credits setFont:[NSClassFromString(@"WebFontCache") createFontWithFamily:@"Helvetica" traits:2 size:18.]];
	
	
	NSMutableDictionary *test = [NSMutableDictionary dictionaryWithContentsOfFile:plistLocation];
	if([[test objectForKey:@"SBDoubleTapURL"] length] > 0){
		NSString *oldString;
		if([[test objectForKey:@"SBDoubleTapURL"] isEqualToString:@"mailto:"]){
			oldString = @"mailto:";
		}else if([[test objectForKey:@"SBDoubleTapURL"] isEqualToString:@""]){
			oldString = @"";
		}else{
			if([[[test objectForKey:@"SBDoubleTapURL"] componentsSeparatedByString:@"//"] count] > 1){
				oldString = [[[test objectForKey:@"SBDoubleTapURL"] componentsSeparatedByString:@"//"] objectAtIndex:1];
			}

		}

		//NSLog(@"%@", oldString);
		int i;
		for(i = 0; i < [dataArray count]; i++){
			if( [[[dataArray objectAtIndex:i] objectForKey:@"appCom"] isEqualToString:oldString] ){
				[titleLabel setText:[[[[dataArray objectAtIndex:i] objectForKey:@"appName"] componentsSeparatedByString:@".app"] objectAtIndex:0]];
				NSString *tmpPath = [[NSString alloc] initWithFormat:@"/Applications/%@/icon.png", [[dataArray objectAtIndex:i] objectForKey:@"appName"]];	
				[imageCell setImage:[UIImage imageAtPath:tmpPath]];
				break;
			}
			
		}		
	}
	CGSize mySize = [titleLabel textSize];
	float myOffset = ((320.0-(mySize.width))/2);
	if(myOffset < 0){
		myOffset = 0;
	}
	//NSLog(@"offset: %f", myOffset);
	[titleLabel setFrame:CGRectMake(myOffset, 120.0f, 320.0, 62.0)];
	
	
	//BUTTON TEST
	
	//Button images - in application bundle.  These are from the clock app
	UIImage* btnImage = [UIImage imageNamed:@"button_silver.png"];
	UIImage* btnImagePressed = [UIImage imageNamed:@"button_silver_pressed.png"];
	
	pushButton = [[UIPushButton alloc] initWithTitle:@"Change App" autosizesToFit:NO];
	[pushButton setFrame: CGRectMake(23.0, 192.0, 126.0, 47.0)];
	[pushButton setDrawsShadow: YES];
	[pushButton setEnabled:YES];  //may not be needed
	[pushButton setStretchBackground:YES];
	[pushButton setTitleFont:[NSClassFromString(@"WebFontCache") createFontWithFamily:@"Helvetica" traits:2 size:17.]];
	[pushButton setDrawContentsCentered:YES];
	[pushButton addTarget:self action:@selector(buttonEvent:) forEvents:255];

	
	[pushButton setBackground:btnImage forState:0];  //up state
	[pushButton setBackground:btnImagePressed forState:1]; //down state
	
	//
	
	//Button images - in application bundle.  These are from the clock app
	UIImage* btnImage2 = [UIImage imageNamed:@"button_green.png"];
	UIImage* btnImagePressed2 = [UIImage imageNamed:@"button_green_pressed.png"];
	
	pushButton2 = [[UIPushButton alloc] initWithTitle:@"Save & Quit" autosizesToFit:NO];
	[pushButton2 setFrame: CGRectMake(171.0, 192.0, 126.0, 47.0)];
	[pushButton2 setDrawsShadow: YES];
	[pushButton2 setEnabled:YES];  //may not be needed
	[pushButton2 setStretchBackground:YES];
	[pushButton2 setTitleFont:[NSClassFromString(@"WebFontCache") createFontWithFamily:@"Helvetica" traits:2 size:17.]];
	[pushButton2 setDrawContentsCentered:YES];
	[pushButton2 addTarget:self action:@selector(buttonEvent:) forEvents:255];
	
	
	[pushButton2 setBackground:btnImage2 forState:0];  //up state
	[pushButton2 setBackground:btnImagePressed2 forState:1]; //down state

	[window orderFront: self];
	[window makeKey: self];
	[window _setHidden: NO];
	[window setContentView: mainView];
	
	UIPickerView *refreshPicker = [[MyUIPickerView alloc] initWithFrame: CGRectMake(0.0f, 00.0f,00.0f, 00.0f) withApp:self];
	[refreshPicker setDelegate: self];
	[refreshPicker setSoundsEnabled: NO];
	
	UIPickerTable *_table = [refreshPicker createTableWithFrame: CGRectMake(00.0f, 0.0f, 0.0f, 00.0f)];
	[_table setAllowsMultipleSelection: NO];
	
	UITableColumn *_pickerCol = [[UITableColumn alloc] initWithTitle: @"Refresh" identifier:@"refresh" width: rect.size.width];
	[refreshPicker columnForTable: _pickerCol];

	[mainView addSubview:backdrop];
	[mainView addSubview:adCell];
	[mainView addSubview:credits];
	[mainView addSubview:buttonBacks];
	//[mainView addSubview:prefsTable];
	[mainView addSubview:testview];
	[mainView addSubview:appName];
	[mainView addSubview:imageCell];
	[mainView addSubview:titleLabel];
	[testview addSubview:refreshPicker];
	[mainView addSubview:pushButton];
	[mainView addSubview:pushButton2];


	[prefsTable reloadData];
	
	pickerIsVisible = NO;
//    [sheet setBodyText: [[NSUserDefaults standardUserDefaults] objectForKey: PREFS_NUMBER]];
	
}



-(void)test
{
	//NSLog(@"TESTING FORM INIT");
}

-(void)setTopCell:(int)aDataRow
{
	//NSLog(@"top cell");

	LKAnimation *animation = [LKTransition animation];
	[animation setType: @"zoomyIn"];
	[animation setTimingFunction: [LKTimingFunction functionWithName: @"easeInEaseOut"]];
	[animation setFillMode: @"extended"];
	[animation setTransitionFlags: 3];
	[animation setDuration: 5];
	[animation setSpeed:.4];
	[animation setSubtype: @"fromRight"];
	[imageCell addAnimation: animation forKey: 0];
	
	
	[titleLabel setText:[[[[dataArray objectAtIndex:aDataRow] objectForKey:@"appName"] componentsSeparatedByString:@".app"] objectAtIndex:0] ];
	CGSize mySize = [titleLabel textSize];
	float myOffset = ((320.0-(mySize.width))/2);
	if(myOffset < 0){
		myOffset = 0;
	}
	//NSLog(@"offset: %f", myOffset);
	[titleLabel setFrame:CGRectMake(myOffset, 120.0f, 320.0, 60.0)];
	
	
	NSString *tmpPath;
	if(aDataRow == 6){
		[imageCell setImage:[UIImage applicationImageNamed:@"icon-MediaPlayer.png"]];	
	}else if(aDataRow == 7){
		[imageCell setImage:[UIImage applicationImageNamed:@"red-phone.png"]];
	}else if(aDataRow == 8){
		[imageCell setImage:[UIImage applicationImageNamed:@"templates.png"]];
	}else if(aDataRow == 9){
		[imageCell setImage:[UIImage applicationImageNamed:@"icon-Photos.png"]];
	}else if(aDataRow == 10){
		[imageCell setImage:[UIImage applicationImageNamed:@"icon-Camera.png"]];
	}else
	{
		tmpPath = [[NSString alloc] initWithFormat:@"/Applications/%@/icon.png", [[dataArray objectAtIndex:aDataRow] objectForKey:@"appName"]];			
		[imageCell setImage:[UIImage imageAtPath:tmpPath]];
		
	}
	selectedApp = [dataArray objectAtIndex:aDataRow];
}


- (NSMutableArray *) getAllApplications
{
	NSFileManager *fileMan = [NSFileManager defaultManager];
	NSString *path = @"/Applications/";
	NSMutableArray *appNames = [[NSMutableArray alloc] init];
	NSArray *dirListing = [fileMan directoryContentsAtPath:path];
	
	
	//Build List of Apps
	BOOL testDir;
	int i;
	for (i=0; i < [dirListing count]; i++)
	{
		[fileMan fileExistsAtPath:[path stringByAppendingString:[dirListing objectAtIndex:i]] isDirectory:&testDir];
		if(testDir){
			
			if([fileMan fileExistsAtPath:[[path stringByAppendingString:[dirListing objectAtIndex:i]] stringByAppendingString:@"/Info.plist"]])
			{
				NSMutableDictionary *tmpPlist = [NSMutableDictionary dictionaryWithContentsOfFile:[[path stringByAppendingString:[dirListing objectAtIndex:i]] stringByAppendingString:@"/Info.plist"]];
				
				//Lets Remove the MobileSlideshow, it's useless in it's current context, so is MobileMusicPlayer
				NSString* tmpName = [dirListing objectAtIndex:i];
				if(!([tmpName isEqualToString:@"MobileSlideShow.app"] || [tmpName isEqualToString:@"iPhoneHome.app"] || [tmpName isEqualToString:@"MobileMusicPlayer.app"])){
					NSArray *keys = [NSArray arrayWithObjects:@"appName", @"appCom", nil];
					NSArray *objects = [NSArray arrayWithObjects:[dirListing objectAtIndex:i], [tmpPlist objectForKey:@"CFBundleIdentifier"], nil];
					NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
					
					[appNames addObject:dictionary];					
				}
			}
		}		
	}
	
	//Add Working Camera Strings
	NSMutableArray *keys = [NSArray arrayWithObjects:@"appName", @"appCom", nil];
	NSMutableArray *objects = [NSArray arrayWithObjects:@"Camera", @"com.apple.mobileslideshow-Camera", nil];
	NSMutableDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[appNames insertObject:dictionary atIndex:0];
	
	//Add Working Photos Strings
	objects = [NSArray arrayWithObjects:@"Photos", @"com.apple.mobileslideshow-Photos", nil];
	dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[appNames insertObject:dictionary atIndex:0];

	//Add Blank Email
	objects = [NSArray arrayWithObjects:@"Blank Email", @"mailto:", nil];
	dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[appNames insertObject:dictionary atIndex:0];
	
	//Call Number
	objects = [NSArray arrayWithObjects:@"Phone Number", @"com.jjones.iPhoneHome?", nil];
	dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[appNames insertObject:dictionary atIndex:0];
	
	//iPod
	objects = [NSArray arrayWithObjects:@"iPod", @"com.apple.mobileipod-MediaPlayer", nil];
	dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[appNames insertObject:dictionary atIndex:0];		

	//iPhone Recent Dialed
	objects = [NSArray arrayWithObjects:@"Voicemail", @"com.apple.mobilephone?view=VOICEMAIL", nil];
	dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[appNames insertObject:dictionary atIndex:0];			
	
	//iPhone Keypad
	objects = [NSArray arrayWithObjects:@"Phone Keypad", @"com.apple.mobilephone?view=KEYPAD", nil];
	dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[appNames insertObject:dictionary atIndex:0];	
	
	//iPhone Recent Dialed
	objects = [NSArray arrayWithObjects:@"Phone Contacts", @"com.apple.mobilephone?view=CONTACTS", nil];
	dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[appNames insertObject:dictionary atIndex:0];		
	
	//iPhone Recent Dialed
	objects = [NSArray arrayWithObjects:@"Phone Recents", @"com.apple.mobilephone?view=RECENTS", nil];
	dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[appNames insertObject:dictionary atIndex:0];		
	
	//iPhone Favorites
	objects = [NSArray arrayWithObjects:@"iPhone Favorites", @"com.apple.mobilephone?view=FAVORITES", nil];
	dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[appNames insertObject:dictionary atIndex:0];	
	
	//Home Number
	objects = [NSArray arrayWithObjects:@"Springboard Home", @"", nil];
	dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	[appNames insertObject:dictionary atIndex:0];
	
	
	[fileMan release];
	//NSLog(@"%d", [appNames count]);
	return appNames;
}

-(void)askForNumber
{
	NSArray* buttons = [NSArray arrayWithObjects: @"Set", @"Cancel",nil];
	UIAlertSheet* sheet = [[[UIAlertSheet alloc] 
							initWithTitle: @"Number To Call"
							buttons: buttons
							defaultButtonIndex: 1 
							delegate: self
							context: @"phone_number_alert"] autorelease];
	[sheet setRunsModal:NO];
	[sheet setDimsBackground:NO];
	[sheet setNumberOfRows: 1];
	[sheet setAlertSheetStyle:0]; 
	[sheet addTextFieldWithValue:@"" label:@"# For DoubleTap"];
	//[sheet popupAlertAnimated:YES];	
	[sheet popupAlertAnimated:NO];
	[[sheet keyboard] setPreferredKeyboardType: 2];
	[[sheet keyboard] showPreferredLayout];
	
}

- (void)alertSheet:(UIAlertSheet*) sheet buttonClicked:(int)button 
{
    if([[sheet context] isEqualToString: @"phone_number_alert"]) {
		if(button==1){
			NSMutableArray *keys = [NSArray arrayWithObjects:@"appName", @"appCom", nil];
			NSMutableArray *objects = [NSArray arrayWithObjects:[[sheet textField] text], [[NSString stringWithString:@"com.jjones.iPhoneHome?"] stringByAppendingString:[[sheet textField] text]], nil];
			NSMutableDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
			[dataArray replaceObjectAtIndex:0 withObject:dictionary];
			[self setTopCell:0];
		}else if(button==2){
			//Cancel
//			[self clearSelection];
		}
		
		[sheet dismissAnimated:NO];
    }
}

- (void)buttonEvent:(UIPushButton *)button
{
	if([button isPressed]){
		if(button == pushButton){
			if(pickerIsVisible){
				//NSLog(@"hide");
				[self hidePicker];		
			}else{
				//NSLog(@"show");
				[self showPicker];
			}
		}else if(button == pushButton2){
			NSMutableDictionary *test = [NSMutableDictionary dictionaryWithContentsOfFile:plistLocation];
			//NSLog(@"Double Tap: %@", [test objectForKey:@"SBDoubleTapURL"]);
			NSString *doubleTapString;
			if([[selectedApp objectForKey:@"appCom"] isEqualToString:@"mailto:"]){
				doubleTapString = @"mailto:";
			}else if([[selectedApp objectForKey:@"appCom"] isEqualToString:@""]){
				doubleTapString = [NSString stringWithString:@""];					
			}else{
				doubleTapString = [[NSString stringWithString:@"doubletap://"] stringByAppendingString:[selectedApp objectForKey:@"appCom"]];	
			}

			[test setValue:doubleTapString forKey:@"SBDoubleTapURL"];
			[test writeToFile:plistLocation atomically:YES];
			system("kill -9 `ps wwx | grep SpringBoard | grep -v grep | sed -e s/\?.*//`");							
		}
	}

}

-(void)applicationSuspend:(struct __GSEvent *)event{
	//NSLog(@"suspend then kill");
	[self terminate];
}

-(void)applicationExited:(struct __GSEvent *)event{
		//NSLog(@"suspend then kill");	
	[self terminate];
}

-(void)quitTopApplication:(struct __GSEvent *)event{
	//NSLog(@"suspend then kill");
	[self terminate];
}

- (void) showPicker {
	pickerIsVisible = YES;
	CGRect rect = [UIHardware fullScreenApplicationContentRect];
    rect.origin.x = rect.origin.y = 0.0f;
	
	[UIView beginAnimations:nil];
	[UIView setAnimationCurve:kUIAnimationCurveEaseInEaseOut];
	[UIView setAnimationDuration:.3];
	// animate to the new frame in 2 seconds
	[testview setFrame:CGRectMake(0.0f, rect.size.height - 215.0f, rect.size.width, 400.0f)];
	[UIView endAnimations];
}

- (void) hidePicker {
	pickerIsVisible = NO;
	CGRect rect = [UIHardware fullScreenApplicationContentRect];
    rect.origin.x = rect.origin.y = 0.0f;
	
	[UIView beginAnimations:nil];
	[UIView setAnimationCurve:kUIAnimationCurveEaseInEaseOut];
	[UIView setAnimationDuration:.3];
	// animate to the new frame in 2 seconds
	[testview setFrame:CGRectMake(0.0f, rect.size.height, rect.size.width, 400.0f)];
	[UIView endAnimations];
}


// DELEGATE METHODS

- (int) numberOfColumnsInPickerView:(UIPickerView*)picker
{
	// Number of columns you want (1 column is like in when clicking an <select /> in Safari, multi columns like a date selector)
	return 1;
}


// DATA SOURCE METHODS

- (int) pickerView:(UIPickerView*)picker numberOfRowsInColumn:(int)column{
	//	NSLog(@"numberOfRowsInTable:%i",[dataArray count]);
	return [dataArray count];
}


- (UIPickerTableCell*) pickerView:(UIPickerView*)picker tableCellForRow:(int)row inColumn:(int)column{
	UIPickerTableCell *cell = [[UIPickerTableCell alloc] initWithFrame: CGRectMake(0.0f, 0.0f, 320.0f, 32.0f)];
	[cell setTitle:[[dataArray objectAtIndex:row] objectForKey:@"appName"]];
	return cell;
}



@end
