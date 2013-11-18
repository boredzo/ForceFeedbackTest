//
//  PRHDeviceInfoViewController.m
//  ForceFeedbackTest
//
//  Created by Peter Hosey on 2013-11-17.
//  Copyright (c) 2013 Peter Hosey. All rights reserved.
//

#import "PRHDeviceInfoViewController.h"

@interface PRHDeviceInfoViewController () <NSTableViewDataSource>

@property (weak) IBOutlet NSTableView *effectsTable;

@end

@implementation PRHDeviceInfoViewController
{
	FFCAPABILITIES _capabilities;
	FFEffectObjectReference _currentEffect;
}

- (void) awakeFromNib {
	self.effectsTable.doubleAction = @selector(toggleEffect:);
	self.effectsTable.target = self;
}

- (bool) isAnySupportedAxis:(UInt8)axis {
	return (_capabilities.numFfAxes >= 1 && _capabilities.ffAxes[0] == axis)
	|| (_capabilities.numFfAxes >= 2 && _capabilities.ffAxes[1] == axis)
	|| (_capabilities.numFfAxes >= 3 && _capabilities.ffAxes[2] == axis);
}

+ (NSSet *) keyPathsThatAffectDeviceInfoProperties {
	return [NSSet setWithArray:@[ @"deviceFF" ]];
}

+ (NSSet *) keyPathsForValuesAffectingSupportsKinesthesis {
	return [self keyPathsThatAffectDeviceInfoProperties];
}
- (bool) supportsKinesthesis {
	NSLog(@"%s", __func__);
	return _capabilities.supportedEffects & FFCAP_ST_KINESTHETIC;
}
+ (NSSet *)keyPathsForValuesAffectingSupportsVibration {
	return [self keyPathsThatAffectDeviceInfoProperties];
}
- (bool) supportsVibration {
	NSLog(@"%s", __func__);
	return _capabilities.supportedEffects & FFCAP_ST_VIBRATION;
}
+ (NSSet *)keyPathsForValuesAffectingSupportsXAxis {
	return [self keyPathsThatAffectDeviceInfoProperties];
}
- (bool) supportsXAxis {
	NSLog(@"%s", __func__);
	return [self isAnySupportedAxis:FFJOFS_X];
}
+ (NSSet *)keyPathsForValuesAffectingSupportsYAxis {
	return [self keyPathsThatAffectDeviceInfoProperties];
}
- (bool) supportsYAxis {
	NSLog(@"%s", __func__);
	return [self isAnySupportedAxis:FFJOFS_Y];
}
+ (NSSet *)keyPathsForValuesAffectingSupportsZAxis {
	return [self keyPathsThatAffectDeviceInfoProperties];
}
- (bool) supportsZAxis {
	NSLog(@"%s", __func__);
	return [self isAnySupportedAxis:FFJOFS_Z];
}

- (void) setDeviceFF:(FFDeviceObjectReference)deviceFF {
	[self willChangeValueForKey:@"supportsKinesthesis"];
	[self willChangeValueForKey:@"supportsVibration"];
	[self willChangeValueForKey:@"supportsXAxis"];
	[self willChangeValueForKey:@"supportsYAxis"];
	[self willChangeValueForKey:@"supportsZAxis"];

	_deviceFF = deviceFF;
	FFDeviceGetForceFeedbackCapabilities(_deviceFF, &_capabilities);

	[self didChangeValueForKey:@"supportsZAxis"];
	[self didChangeValueForKey:@"supportsYAxis"];
	[self didChangeValueForKey:@"supportsXAxis"];
	[self didChangeValueForKey:@"supportsVibration"];
	[self didChangeValueForKey:@"supportsKinesthesis"];

	[self.effectsTable reloadData];
}

- (IBAction) toggleEffect:(id)sender {
	if (_currentEffect != NULL) {
		FFEffectStop(_currentEffect);
	}

	NSTableView *tableView = sender;
	if (tableView == self.effectsTable) {
		NSInteger desiredEffectIndex = tableView.clickedRow;
	}
}

#pragma mark NSTableViewDataSource protocol conformance

- (NSArray *) effectNames {
	static NSArray *effectNames = nil;
	if (effectNames == nil) {
		effectNames = @[
			NSLocalizedString(@"Constant force", /*comment*/ @"Effect names"),
			NSLocalizedString(@"Ramp force", /*comment*/ @"Effect names"),
			NSLocalizedString(@"Square wave", /*comment*/ @"Effect names"),
			NSLocalizedString(@"Sine wave", /*comment*/ @"Effect names"),
			NSLocalizedString(@"Triangle wave", /*comment*/ @"Effect names"),
			NSLocalizedString(@"Sawtooth (up)", /*comment*/ @"Effect names"),
			NSLocalizedString(@"Sawtooth (down)", /*comment*/ @"Effect names"),
			NSLocalizedString(@"Spring", /*comment*/ @"Effect names"),
			NSLocalizedString(@"Damper", /*comment*/ @"Effect names"),
			NSLocalizedString(@"Inertia", /*comment*/ @"Effect names"),
			NSLocalizedString(@"Friction", /*comment*/ @"Effect names"),
			NSLocalizedString(@"Custom force", /*comment*/ @"Effect names"),
		];
	}
	return effectNames;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [self effectNames].count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row {
	if ([column.identifier isEqualToString:@"effectName"]) {
		return [self effectNames][row];
	} else if ([column.identifier isEqualToString:@"effectIsSupportedNatively"]) {
		UInt32 effect = 1U << row;
		return @((_capabilities.supportedEffects & effect) && ((~_capabilities.emulatedEffects) & effect));
	}
	return nil;
}

#pragma mark NSTableViewDelegate protocol conformance

- (bool) shouldEffectRowBeEnabled:(NSInteger) row {
	if (row < 0)
		return false;

	UInt32 effect = 1U << row;
	bool enable = _capabilities.supportedEffects & effect;
	return enable;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)column row:(NSInteger)row {
	bool enable = [self shouldEffectRowBeEnabled:row];
	NSCell *cell = aCell;
	[cell setCellAttribute:NSCellDisabled to: ! enable];
}

@end
