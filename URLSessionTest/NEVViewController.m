//
//  NEVViewController.m
//  URLSessionTest
//
//  Created by Joachim Bengtsson on 2013-10-03.
//  Copyright (c) 2013 test. All rights reserved.
//

#import "NEVViewController.h"

@interface NEVViewController () <NSURLSessionDelegate, NSURLSessionTaskDelegate>
{
    NSURLSession *_urlSession;
    NSTimer *_statusTimer;
    NSMutableArray *_tasks;
}
@property(nonatomic,weak) IBOutlet UILabel *statusLabel;
@end

@implementation NEVViewController
- (void)viewDidLoad
{
    _tasks = [NSMutableArray new];
    NSURLSessionConfiguration *conf = [NSURLSessionConfiguration backgroundSessionConfiguration:[NSString stringWithFormat:@"test"]];
    conf.allowsCellularAccess = NO;
    _urlSession = [NSURLSession sessionWithConfiguration:conf delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    [self start];
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _statusTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateStatus) userInfo:nil repeats:YES];
}
- (void)viewDidDisappear:(BOOL)animated
{
    [_statusTimer invalidate];
}


- (void)start
{
    __block UIBackgroundTaskIdentifier bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
    }];
    
    
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

- (IBAction)startUpload:(id)sender
{
    [self uploadBigFile];
}

- (IBAction)cancel:(id)sender
{
    for(NSURLSessionTask *task in _tasks) {
        [task cancel];
    }
}

- (IBAction)terminate:(id)sender
{
    exit(13);
}

- (void)uploadBigFile
{
    size_t s = 128; //1024*1024*10;
    char *big = malloc(s);
    NSData *d = [NSData dataWithBytesNoCopy:big length:s freeWhenDone:YES];
    
    NSString *name = [[[[NSUUID UUID] UUIDString] substringToIndex:5] lowercaseString];
    
    NSURL *fullPath = [NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:name]];
    [d writeToFile:fullPath.path atomically:NO];
    uint64_t bytesTotalForThisFile = [[[NSFileManager defaultManager] attributesOfItemAtPath:fullPath.path error:NULL] fileSize];
    
    //NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://Reika.local/upload.php?name=%@", name]];
    NSURL *url = [NSURL URLWithString:@"https://s3-eu-west-1.amazonaws.com/lookback-production/qFemC7bf9c4ZdLFAu/screen.m4v?Expires=1381060455&AWSAccessKeyId=AKIAJC77E2MNKD4ZK2ZA&Signature=uu1r%2BTI9apJwpnp3i1w2BqB4Qa8%3D"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"PUT"];
    [request setValue:[NSString stringWithFormat:@"%llu", bytesTotalForThisFile] forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];

    NSURLSessionUploadTask *task = [_urlSession uploadTaskWithRequest:request fromFile:fullPath];
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

- (void)updateStatus
{
    int64_t sent = 0, toSend = 0;
    for(NSURLSessionUploadTask *task in _tasks) {
        sent += task.countOfBytesSent;
        toSend += task.countOfBytesExpectedToSend;
    }
    _statusLabel.text = [NSString stringWithFormat:@"%@ being uploaded (%@ of %@)\nFiles on disk: %@",
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
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    NSLog(@"sadface :( %@", error);
}


- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    NSLog(@"finihed events for bg session");
}


@end
