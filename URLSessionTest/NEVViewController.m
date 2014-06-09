//
//  NEVViewController.m
//  URLSessionTest
//
//  Created by Joachim Bengtsson on 2013-10-03.
//  Copyright (c) 2013 test. All rights reserved.
//

#import "NEVViewController.h"
#import "NEVUploadController.h"

@interface NEVViewController ()
{
    NSTimer *_statusTimer;
	NEVUploadController *_uploader;
}
@property(nonatomic,weak) IBOutlet UILabel *statusLabel;
@end

@implementation NEVViewController
- (void)viewDidLoad
{
	_uploader = [NEVUploadController shared];
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

- (IBAction)startUpload:(id)sender
{
    [_uploader uploadBigFile];
}

- (IBAction)cancel:(id)sender
{
    [_uploader cancel];
}

- (IBAction)terminate:(id)sender
{
    exit(13);
}

- (void)updateStatus
{
    _statusLabel.text = [_uploader status];
}

@end
