//
//  NEVUploadController.m
//  URLSessionTest
//
//  Created by Joachim Bengtsson on 2014-06-09.
//  Copyright (c) 2014 test. All rights reserved.
//

#import "NEVUploadController.h"

#define USE_BACKGROUND_SESSION 1

#define HOST @"http://Reika.local/upload.php"

@interface NEVUploadController ()  <NSURLSessionDelegate, NSURLSessionTaskDelegate>
{
    NSURLSession *_urlSession;
    NSMutableArray *_tasks;
}

@end


@implementation NEVUploadController

- (id)init
{
	if(!(self = [super init]))
		return nil;
	
	NSLog(@"Upload controller created");
	
    _tasks = [NSMutableArray new];
#if USE_BACKGROUND_SESSION
    NSURLSessionConfiguration *conf = [NSURLSessionConfiguration backgroundSessionConfiguration:@"test"];
#else
    NSURLSessionConfiguration *conf = [NSURLSessionConfiguration defaultSessionConfiguration];
#endif
    conf.allowsCellularAccess = NO;
    _urlSession = [NSURLSession sessionWithConfiguration:conf delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    [self start];
	
	return self;
}

+ (instancetype)shared
{
	static id g;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		g = [self new];
	});
	return g;
}

- (void)start
{
    __block UIBackgroundTaskIdentifier bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
    }];
	
	[self notify:@"start"];
    
    [_urlSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        for(NSURLSessionUploadTask *task in uploadTasks) {
            NSLog(@"Restored upload task %zu for %@", (unsigned long)task.taskIdentifier, task.originalRequest.URL);
            [_tasks addObject:task];
            [task resume];
        }
        for(NSURLSessionDownloadTask *task in downloadTasks) {
            NSLog(@"Restored download task %zu for %@", (unsigned long)task.taskIdentifier, task.originalRequest.URL);
            [_tasks addObject:task];
            [task resume];
        }
        
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
    }];
}

- (void)cancel
{
    for(NSURLSessionTask *task in _tasks) {
        [task cancel];
    }
}

- (void)notify:(NSString*)what
{
	__block UIBackgroundTaskIdentifier task = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
		NSLog(@"Oops, notify expired");
		[[UIApplication sharedApplication] endBackgroundTask:task];
	}];
	
	NSLog(@"Notifying %@", what);
	[NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: HOST @"?notify=%@", what]]] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
		NSLog(@"Finished notifying %@", what);
		[[UIApplication sharedApplication] endBackgroundTask:task];
	}];
}



- (void)uploadBigFile
{
    size_t s = 1000*1000;
    char *big = malloc(s);
    NSData *d = [NSData dataWithBytesNoCopy:big length:s freeWhenDone:YES];
    
    NSString *name = [[[[NSUUID UUID] UUIDString] substringToIndex:5] lowercaseString];
    
    NSURL *fullPath = [NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:name]];
    [d writeToFile:fullPath.path atomically:NO];
    uint64_t bytesTotalForThisFile = [[[NSFileManager defaultManager] attributesOfItemAtPath:fullPath.path error:NULL] fileSize];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat: HOST @"?name=%@", name]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:[NSString stringWithFormat:@"%llu", bytesTotalForThisFile] forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];

#if USE_BACKGROUND_SESSION
    NSURLSessionTask *task = [_urlSession uploadTaskWithRequest:request fromFile:fullPath];
#else
    [request setHTTPBody:d];
    NSURLSessionTask *task = [_urlSession dataTaskWithRequest:request];
#endif
    task.taskDescription = name;
    [_tasks addObject:task];
    NSLog(@"Started upload for %@ as task %zu/%@/%@", fullPath.lastPathComponent, (unsigned long)task.taskIdentifier, task.taskDescription, task);
    [task resume];
}

// http://stackoverflow.com/a/572623/48125
NSString *stringFromFileSize(unsigned long long theSize)
{
    double floatSize = theSize;
    if (theSize<1023)
        return([NSString stringWithFormat:@"%lli bytes",theSize]);
    floatSize = floatSize / 1024;
    if (floatSize<1023)
        return([NSString stringWithFormat:@"%1.1f KB",floatSize]);
    floatSize = floatSize / 1024;
    if (floatSize<1023)
        return([NSString stringWithFormat:@"%1.1f MB",floatSize]);
    floatSize = floatSize / 1024;

    return([NSString stringWithFormat:@"%1.1f GB",floatSize]);
}

- (NSString*)status
{
    int64_t sent = 0, toSend = 0;
    for(NSURLSessionUploadTask *task in _tasks) {
        sent += task.countOfBytesSent;
        toSend += task.countOfBytesExpectedToSend;
    }
    return [NSString stringWithFormat:@"%@ being uploaded (%@ of %@)\nFiles on disk: %@",
        [_tasks valueForKeyPath:@"taskDescription"],
        stringFromFileSize(sent),
        stringFromFileSize(toSend),
        
        [[NSFileManager defaultManager]
            contentsOfDirectoryAtPath:NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0]
            error:NULL]
    ];
}


#pragma mark -
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
                           didCompleteWithError:(NSError *)error
{
    NSLog(@"Finished uploading task %zu %@: %@ %@, HTTP %ld", (unsigned long)[task taskIdentifier], task.originalRequest.URL, error ?: @"Success", task.response, (long)[(id)task.response statusCode]);
    [_tasks removeObject:task];
    NSURL *fullPath = [NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:task.taskDescription]];
    [[NSFileManager defaultManager] removeItemAtURL:fullPath error:NULL];
	
	[self notify:[NSString stringWithFormat:@"taskfinish-%ld", (unsigned long)[task taskIdentifier]]];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
                                     didReceiveData:(NSData *)data
{
    NSLog(@"Response:: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    NSLog(@"sadface :( %@", error);
}


- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    NSLog(@"finihed events for bg session");
	[self notify:@"sessionfinish"];
}

@end
