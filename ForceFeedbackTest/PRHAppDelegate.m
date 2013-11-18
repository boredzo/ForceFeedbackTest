//
//  PRHAppDelegate.m
//  ForceFeedbackTest
//
//  Created by Peter Hosey on 2013-11-17.
//  Copyright (c) 2013 Peter Hosey. All rights reserved.
//

#import "PRHAppDelegate.h"

#import "PRHForceFeedbackWindowController.h"

@implementation PRHAppDelegate
{
	PRHForceFeedbackWindowController *_wc;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
	_wc = [PRHForceFeedbackWindowController new];
	[_wc showWindow:nil];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
	[_wc close];
	_wc = nil;
}

@end
