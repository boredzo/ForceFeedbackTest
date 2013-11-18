//
//  PRHDeviceInfoViewController.h
//  ForceFeedbackTest
//
//  Created by Peter Hosey on 2013-11-17.
//  Copyright (c) 2013 Peter Hosey. All rights reserved.
//

#import <ForceFeedback/ForceFeedback.h>

@interface PRHDeviceInfoViewController : NSViewController

@property(nonatomic, assign) FFDeviceObjectReference deviceFF;

@property(nonatomic, readonly) bool supportsKinesthesis;
@property(nonatomic, readonly) bool supportsVibration;

@property(nonatomic, readonly) bool supportsXAxis;
@property(nonatomic, readonly) bool supportsYAxis;
@property(nonatomic, readonly) bool supportsZAxis;

@end
