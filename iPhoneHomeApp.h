#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIPickerView.h>
#import <UIKit/UIPickerTable.h>
#import <UIKit/UIPickerTableCell.h>
#import <UIKit/UIPreferencesTable.h>
#import <UIKit/UIPreferencesTableCell.h>
#import <UIKit/UIPreferencesTextTableCell.h>
#import <WebCore/WebFontCache.h>

#define PREFS_NUMBER	@"number"
#define PREFS_LAUNCH_NUMBER @"doLaunchNumber"


@interface iPhoneHomeApp : UIApplication {
	UIAlertSheet			*deleteConfirmationSheet;
	UIView					*mainView;
	UIView					*testview;
	UIView					*backdrop;
	UIView					*appName;
	UIImageView				*imageCell;
	UIImageView				*adCell;
	UITextLabel				*titleLabel;
	UIPreferencesTable		*prefsTable;
	UIPreferencesTableCell	*doubleTapcell;
	
	UIPushButton			*pushButton;
	UIPushButton			*pushButton2;
	
	NSMutableArray *dataArray;
	
	BOOL					*pickerIsVisible;
	BOOL					*settingEmail;
	NSDictionary			*selectedApp;
	
	BOOL					*osAbove113;
	NSString				*plistLocation;
	
}

+(id)init:(NSArray *)aString;
-(NSMutableArray *) getAllApplications;

//datasource methods
-(int) pickerView:(UIPickerView*)picker numberOfRowsInColumn:(int)column;
-(UIPickerTableCell*) pickerView:(UIPickerView*)picker tableCellForRow:(int)row inColumn:(int)column;
-(void)setTopCell:(int)aDataRow;
-(void)showPicker;
-(void)hidePicker;
-(void)buttonEvent:(UIPushButton *)button;
-(void)test;
-(void)askForNumber;

@end
