//
//  AecountCountManager.m
//  aecount
//
//  Created by Johan Halin on 4/12/12.
//  Copyright (c) 2012 Aero Deko. All rights reserved.
//

#import "AecountCountManager.h"

NSString * const kAecountCountKey = @"count";
NSString * const kAecountTitleKey = @"title";
NSString * const kAecountTargetCountKey = @"targetCount";

@implementation AecountCountManager

#pragma mark - Public

- (NSInteger)count
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:kAecountCountKey];
}

- (NSString *)title
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:kAecountTitleKey];
}

- (NSInteger)targetCount
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:kAecountTargetCountKey];
}

- (void)saveCount:(NSInteger)count
{
	[[NSUserDefaults standardUserDefaults] setInteger:count forKey:kAecountCountKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)saveTitle:(NSString *)title
{
	[[NSUserDefaults standardUserDefaults] setObject:title forKey:kAecountTitleKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)saveTargetCount:(NSInteger)targetCount
{
	[[NSUserDefaults standardUserDefaults] setInteger:targetCount forKey:kAecountTargetCountKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)countString
{
	return [NSString stringWithFormat:@"%d", self.count];
}

- (NSString *)targetCountString
{
	if (self.targetCount > 0)
		return [NSString stringWithFormat:@"%d", self.targetCount];
	else
		return @"";
}

@end
