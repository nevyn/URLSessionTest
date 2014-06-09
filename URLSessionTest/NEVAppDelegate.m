//
//  NEVAppDelegate.m
//  URLSessionTest
//
//  Created by Joachim Bengtsson on 2013-10-03.
//  Copyright (c) 2013 test. All rights reserved.
//

#import "NEVAppDelegate.h"
#import "NEVUploadController.h"

@implementation NEVAppDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	NSLog(@"Will finish launching");
	[NEVUploadController shared]; // create global instance
	return YES;
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
{
    NSLog(@"Background URL session needs events handled: %@", identifier);
    completionHandler();
}

@end
