//
//  NEVUploadController.h
//  URLSessionTest
//
//  Created by Joachim Bengtsson on 2014-06-09.
//  Copyright (c) 2014 test. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NEVUploadController : NSObject
- (instancetype)init;
+ (instancetype)shared;
- (void)uploadBigFile;
- (NSString*)status;
- (void)cancel;
@end
