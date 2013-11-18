//
//  PRHForceFeedbackWindowController.m
//  ForceFeedbackTest
//
//  Created by Peter Hosey on 2013-11-17.
//  Copyright (c) 2013 Peter Hosey. All rights reserved.
//

#import "PRHForceFeedbackWindowController.h"

#import "PRHDeviceInfoViewController.h"

#import <IOKit/hid/IOHIDLib.h>
#import <ForceFeedback/ForceFeedback.h>

@interface PRHForceFeedbackWindowController () <NSTableViewDataSource, NSTableViewDelegate>

@property (weak) IBOutlet NSTableView *devicesTable;

@property (strong) IBOutlet PRHDeviceInfoViewController *deviceInfoVC;

@end

static void devicePluggedIn(void           *context,
							IOReturn        result,
							void           *sender,
							IOHIDDeviceRef  device);
static void deviceUnplugged(void           *context,
							IOReturn        result,
							void           *sender,
							IOHIDDeviceRef  device);

@implementation PRHForceFeedbackWindowController
{
	IOHIDManagerRef _manager;
	NSMutableSet *_devices;
	IOHIDDeviceRef _currentDevice;
	FFDeviceObjectReference _currentDeviceFF;
}

- (instancetype) initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
    if (self) {
		_manager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDManagerOptionNone);
		if (_manager != NULL) {
			IOHIDManagerSetDeviceMatchingMultiple(_manager, (__bridge CFArrayRef)@[
				@{
					@(kIOHIDDeviceUsagePageKey): @(kHIDPage_GenericDesktop),
					@(kIOHIDDeviceUsageKey): @(kHIDUsage_GD_GamePad)
				},
				@{
					@(kIOHIDDeviceUsagePageKey): @(kHIDPage_GenericDesktop),
					@(kIOHIDDeviceUsageKey): @(kHIDUsage_GD_Joystick)
				},
			]);
			IOHIDManagerRegisterDeviceMatchingCallback(_manager, devicePluggedIn, (__bridge void *)self);
			IOHIDManagerRegisterDeviceRemovalCallback(_manager, deviceUnplugged, (__bridge void *)self);

			IOHIDManagerScheduleWithRunLoop(_manager, CFRunLoopGetMain(), kCFRunLoopDefaultMode);

			_devices = [(__bridge_transfer NSSet *)IOHIDManagerCopyDevices(_manager) mutableCopy];

			IOHIDManagerOpen(_manager, kIOHIDManagerOptionNone);
		}
    }
    
    return self;
}

- (instancetype) init {
	return [self initWithWindowNibName:NSStringFromClass([self class])];
}

-(void)dealloc {
	if (_currentDeviceFF != NULL) {
		FFReleaseDevice(_currentDeviceFF);
		_currentDeviceFF = NULL;
	}

	IOHIDManagerUnscheduleFromRunLoop(_manager, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
	IOHIDManagerClose(_manager, kIOHIDOptionsTypeNone);
	CFRelease(_manager);
}

- (void) devicePluggedIn:(IOHIDDeviceRef)device withResult:(IOReturn)result sender:(void *)sender {
	[_devices addObject:(__bridge id)device];
	[self.devicesTable reloadData];
}

- (void) deviceUnplugged:(IOHIDDeviceRef)device withResult:(IOReturn)result sender:(void *)sender {
	[_devices removeObject:(__bridge id)device];
	[self.devicesTable reloadData];
}

- (NSArray *)devicesInOrder {
	NSArray *allDevices = [_devices allObjects];
	return [allDevices sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		IOHIDDeviceRef device1 = (__bridge IOHIDDeviceRef)obj1;
		IOHIDDeviceRef device2 = (__bridge IOHIDDeviceRef)obj2;
		NSString *device1Product = (__bridge id)IOHIDDeviceGetProperty(device1, CFSTR(kIOHIDProductKey));
		NSString *device2Product = (__bridge id)IOHIDDeviceGetProperty(device2, CFSTR(kIOHIDProductKey));
		return [device1Product localizedStandardCompare:device2Product];
	}];
}

#pragma mark NSTableViewDataSource protocol conformance

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return _devices.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row {
	IOHIDDeviceRef device = (__bridge IOHIDDeviceRef)(self.devicesInOrder[row]);
	if ([column.identifier isEqualToString:@"icon"]) {
		NSNumber *usageNum = (__bridge id)(IOHIDDeviceGetProperty(device, CFSTR(kIOHIDDeviceUsageKey)));
		int usage = usageNum.intValue;
		switch (usage) {
			case kHIDUsage_GD_Joystick:
				return [NSImage imageNamed:@"Joystick"];
				break;

			case kHIDUsage_GD_GamePad:
			default:
				return [NSImage imageNamed:@"GamePad"];
				break;
		}
	} else if ([column.identifier isEqualToString:@"name"]) {
		NSString *product = (__bridge id)IOHIDDeviceGetProperty(device, CFSTR(kIOHIDProductKey));
		return product;
	}
	return nil;
}

#pragma mark NSTableViewDelegate protocol conformance

- (bool) shouldDeviceBeEnabled:(IOHIDDeviceRef) device {
	bool enable = true;

	IOReturn openStatus = IOHIDDeviceOpen(device, kIOHIDOptionsTypeSeizeDevice);
	if (openStatus != kIOReturnSuccess)
		enable = false;
	else {
		FFDeviceObjectReference deviceFF = NULL;
		HRESULT ffStatus = FFCreateDevice(IOHIDDeviceGetService(device), &deviceFF);
		if (ffStatus != FF_OK)
			enable = false;
		else
			FFReleaseDevice(deviceFF);

		IOHIDDeviceClose(device, kIOHIDOptionsTypeNone);
	}

	return enable;
}
- (bool) shouldDeviceRowBeEnabled:(NSInteger)row {
	IOHIDDeviceRef device = (__bridge IOHIDDeviceRef)(self.devicesInOrder[row]);
	return [self shouldDeviceBeEnabled:device];
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)column row:(NSInteger)row {
	bool enable = [self shouldDeviceRowBeEnabled:row];
	NSCell *cell = aCell;
	[cell setCellAttribute:NSCellDisabled to: ! enable];
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
	return [self shouldDeviceRowBeEnabled:row];
}

- (void)tableViewSelectionIsChanging:(NSNotification *)notification {
	if (_currentDeviceFF != NULL) {
		FFReleaseDevice(_currentDeviceFF);
		_currentDeviceFF = NULL;
	}
	if (_currentDevice != NULL) {
		IOHIDDeviceClose(_currentDevice, kIOHIDOptionsTypeNone);
		_currentDevice = NULL;
	}
}
- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	if (_currentDeviceFF != NULL) {
		FFReleaseDevice(_currentDeviceFF);
		_currentDeviceFF = NULL;
	}
	if (_currentDevice != NULL) {
		IOHIDDeviceClose(_currentDevice, kIOHIDOptionsTypeNone);
		_currentDevice = NULL;
	}

	NSTableView *tableView = notification.object;
	NSIndexSet *selection = tableView.selectedRowIndexes;
	if (selection.count > 0) {
		_currentDevice = (__bridge IOHIDDeviceRef)(self.devicesInOrder[selection.firstIndex]);
		IOReturn openStatus = IOHIDDeviceOpen(_currentDevice, kIOHIDOptionsTypeSeizeDevice);
		HRESULT ffStatus = FFCreateDevice(IOHIDDeviceGetService(_currentDevice), &_currentDeviceFF);
		NSLog(@"IOHIDDeviceOpen: %d; FFCreateDevice: %d", openStatus, ffStatus);
	}

	self.deviceInfoVC.deviceFF = _currentDeviceFF;
}

@end

static void devicePluggedIn(void           *context,
							IOReturn        result,
							void           *sender,
							IOHIDDeviceRef  device)
{
	PRHForceFeedbackWindowController *self = (__bridge id)context;
	[self devicePluggedIn:device withResult:result sender:sender];
}

static void deviceUnplugged(void           *context,
							IOReturn        result,
							void           *sender,
							IOHIDDeviceRef  device)
{
	PRHForceFeedbackWindowController *self = (__bridge id)context;
	[self deviceUnplugged:device withResult:result sender:sender];
}
