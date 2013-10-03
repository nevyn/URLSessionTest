//
//  NEVAppDelegate.m
//  URLSessionTest
//
//  Created by Joachim Bengtsson on 2013-10-03.
//  Copyright (c) 2013 test. All rights reserved.
//

#import "NEVAppDelegate.h"

@implementation NEVAppDelegate
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
{
    NSLog(@"Background URL session needs events handled: %@", identifier);
    completionHandler();
}

@end
