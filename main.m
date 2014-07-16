#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "iPhoneHomeApp.h"

int main(int argc, char *argv[]) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSArray *args = [[NSProcessInfo processInfo] arguments];
	//NSLog(@"args count: %i", [args count]);
	int ret = UIApplicationMain(argc, argv, [[iPhoneHomeApp class] init:args]);
	[pool release];
	return ret;
}
