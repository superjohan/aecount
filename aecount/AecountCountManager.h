//
//  AecountCountManager.h
//  aecount
//
//  Created by Johan Halin on 4/12/12.
//  Copyright (c) 2012 Aero Deko. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AecountCountManager : NSObject

@property (nonatomic, assign, readonly) NSInteger count;
@property (nonatomic, assign, readonly) NSInteger targetCount;
@property (nonatomic, strong, readonly) NSString *title;

- (void)saveCount:(NSInteger)count;
- (void)saveTitle:(NSString *)title;
- (void)saveTargetCount:(NSInteger)targetCount;
- (NSString *)countString;
- (NSString *)targetCountString;

@end
