//
//  AecountViewController.m
//  aecount
//
//  Created by Johan Halin on 3.4.2012.
//  Copyright (c) 2012 Aero Deko. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/QuartzCore.h>
#import "AecountViewController.h"
#import "AecountCountManager.h"
#import "AECGHelpers.h"
#import "AEUIViewAdditions.h"
#import "SimpleAudioEngine.h"

@interface AecountViewController ()
@property (nonatomic, strong) IBOutlet UIButton *hideKeyboardButton;
@property (nonatomic, strong) IBOutlet UIImageView *topShadow;
@property (nonatomic, strong) IBOutlet UIImageView *bottomShadow;
@property (nonatomic, strong) IBOutlet UILabel *countLabel;
@property (nonatomic, strong) IBOutlet UITextField *titleField;
@property (nonatomic, strong) IBOutlet UITextField *targetField;
@property (nonatomic, strong) IBOutlet UIView *backgroundContainer;
@property (nonatomic, strong) IBOutlet UIView *topView;
@property (nonatomic, strong) IBOutlet UIView *bottomView;
@property (nonatomic, strong) IBOutlet UIView *targetProgressView;
@property (nonatomic, assign) CGRect defaultCountLabelFrame;
@property (nonatomic, assign) CGRect defaultTopViewFrame;
@property (nonatomic, assign) CGRect defaultBottomViewFrame;
@property (nonatomic, assign) CGRect defaultTitleFieldFrame;
@property (nonatomic, assign) CGRect defaultTargetFieldFrame;
@property (nonatomic, assign) NSInteger count;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchRecognizer;
@property (nonatomic, strong) UISwipeGestureRecognizer *swipeRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;
@end

typedef enum
{
	CountLabelAnimationDirectionLeft = -1,
	CountLabelAnimationDirectionRight = 1,
} CountLabelAnimationDirection;

enum
{
	kSoundIncrement = 0,
	kSoundDecrement,
	kSoundReset,
};

const NSTimeInterval kDefaultAnimationTimeInterval = 0.2;

@implementation AecountViewController

#pragma mark - Private

- (void)ae_updateCountLabel
{
	self.countLabel.text = [self.countManager countString];
	self.countLabel.accessibilityLabel = self.countLabel.text;
}

- (void)ae_animateCountLabelChangeWithDirection:(CountLabelAnimationDirection)direction
{
	CGRect frame = self.defaultCountLabelFrame;
	[UIView animateWithDuration:kDefaultAnimationTimeInterval / 2.0 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
		self.countLabel.alpha = 0.0;
		self.countLabel.frame = CGRectMake(frame.origin.x + (30.0 * direction), frame.origin.y, frame.size.width, frame.size.height);
	} completion:^(BOOL finished) {
		[self ae_updateCountLabel];

		self.countLabel.frame = CGRectMake(frame.origin.x - (30.0 * direction), frame.origin.y, frame.size.width, frame.size.height);
		
		[UIView animateWithDuration:kDefaultAnimationTimeInterval / 2.0 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
			self.countLabel.alpha = 1.0;
			self.countLabel.frame = frame;
		} completion:nil];
	}];
}

- (void)ae_updateTargetProgressBar
{	
	if (self.countManager.count == 0 || self.countManager.targetCount == 0)
	{
		[UIView animateWithDuration:kDefaultAnimationTimeInterval delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
			self.targetProgressView.frame = AECGRectWithWidth(self.targetProgressView.frame, 0);
		} completion:nil];
	}
	else
	{
		CGFloat progress = floor(((double)self.countManager.count / (double)self.countManager.targetCount) * self.view.frame.size.width);
		UIColor *color = [UIColor colorWithWhite:0 alpha:0.1];
		if (progress >= self.view.frame.size.width)
			color = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.1];
		
		[UIView animateWithDuration:kDefaultAnimationTimeInterval delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
			self.targetProgressView.frame = AECGRectWithWidth(self.targetProgressView.frame, progress);
			self.targetProgressView.backgroundColor = color;
		} completion:nil];
	}
}

- (void)ae_tapRecognized:(UITapGestureRecognizer *)recognizer
{
	self.count++;
	[self.countManager saveCount:self.count];
	
	[self ae_playSound:kSoundIncrement];
	[self ae_animateCountLabelChangeWithDirection:CountLabelAnimationDirectionLeft];
	[self ae_updateTargetProgressBar];
}

- (void)ae_swipeRecognized:(UISwipeGestureRecognizer *)recognizer
{
	if (self.count <= 0)
		return;
	
	self.count--;
	[self.countManager saveCount:self.count];
	
	[self ae_playSound:kSoundDecrement];
	[self ae_animateCountLabelChangeWithDirection:CountLabelAnimationDirectionRight];
	[self ae_updateTargetProgressBar];
}

- (void)ae_restoreViews
{
	[UIView animateWithDuration:kDefaultAnimationTimeInterval animations:^{
		self.topView.frame = self.defaultTopViewFrame;
		self.bottomView.frame = self.defaultBottomViewFrame;
		self.titleField.frame = self.defaultTitleFieldFrame;
		self.topShadow.frame = AECGRectPlaceY(self.topShadow.frame, self.topView.frame.origin.y + self.topView.frame.size.height);
		self.bottomShadow.frame = AECGRectPlaceY(self.bottomShadow.frame, self.bottomView.frame.origin.y - self.bottomShadow.frame.size.height);
		self.targetField.frame = self.defaultTargetFieldFrame;
	}];

	[self ae_updateTargetProgressBar];
}

- (void)ae_pinchRecognized:(UIPinchGestureRecognizer *)recognizer
{
	if (self.count <= 0)
		return;
	
	CGRect topViewFrame = self.defaultTopViewFrame;
	CGRect bottomViewFrame = self.defaultBottomViewFrame;
	CGRect titleFieldFrame = self.defaultTitleFieldFrame;
	CGRect targetFieldFrame = self.defaultTargetFieldFrame;
	CGFloat mininumScale = .5;
	CGFloat minimumVelocity = -2.0;
	
	if (recognizer.state == UIGestureRecognizerStateEnded && (recognizer.scale < mininumScale || recognizer.velocity < minimumVelocity))
	{
		self.count = 0;
		[self.countManager saveCount:self.count];
		
		[self ae_playSound:kSoundReset];
		
		[UIView animateWithDuration:kDefaultAnimationTimeInterval delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
			self.topView.frame = AECGRectPlaceY(self.topView.frame, 0);
			self.bottomView.frame = AECGRectPlaceY(self.bottomView.frame, self.topView.frame.size.height);
			self.titleField.frame = AECGRectPlaceY(titleFieldFrame, titleFieldFrame.origin.y - (topViewFrame.origin.y - self.topView.frame.origin.y));
			self.topShadow.frame = AECGRectPlaceY(self.topShadow.frame, self.topView.frame.size.height);
			self.bottomShadow.frame = AECGRectPlaceY(self.bottomShadow.frame, self.bottomView.frame.origin.y - self.bottomShadow.frame.size.height);
			self.targetField.frame = AECGRectPlaceY(targetFieldFrame, targetFieldFrame.origin.y - (bottomViewFrame.origin.y - self.bottomView.frame.origin.y));
		} completion:^(BOOL finished) {
			[self ae_updateCountLabel];
			[self ae_restoreViews];
		}];
	}
	else if (recognizer.state == UIGestureRecognizerStateEnded && recognizer.scale >= mininumScale)
	{
		[self ae_restoreViews];
	}
	else if (recognizer.scale < 1.0 && (recognizer.state == UIGestureRecognizerStateBegan || recognizer.state == UIGestureRecognizerStateChanged))
	{
		self.topView.frame = AECGRectPlaceY(topViewFrame, topViewFrame.origin.y + ((1.0 - recognizer.scale) * -topViewFrame.origin.y));
		self.bottomView.frame = AECGRectPlaceY(bottomViewFrame, bottomViewFrame.origin.y - ((1.0 - recognizer.scale) * -topViewFrame.origin.y));
		self.titleField.frame = AECGRectPlaceY(titleFieldFrame, titleFieldFrame.origin.y - (topViewFrame.origin.y - self.topView.frame.origin.y));
		self.topShadow.frame = AECGRectPlaceY(self.topShadow.frame, self.topView.frame.origin.y + self.topView.frame.size.height);
		self.bottomShadow.frame = AECGRectPlaceY(self.bottomShadow.frame, self.bottomView.frame.origin.y - self.bottomShadow.frame.size.height);
		self.targetField.frame = AECGRectPlaceY(targetFieldFrame, targetFieldFrame.origin.y - (bottomViewFrame.origin.y - self.bottomView.frame.origin.y));
	}
}

- (void)ae_applyNoiseTextures
{
	self.topView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"noisetexture"]];
	self.bottomView.backgroundColor = self.topView.backgroundColor;
	self.titleField.textColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"dark-noisetexture"]];
	self.countLabel.textColor = self.titleField.textColor;
	self.targetField.textColor = self.titleField.textColor;
	self.backgroundContainer.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"white-noisetexture"]];
}

- (void)ae_playSound:(NSInteger)sound
{
	if (sound == kSoundIncrement)
		[[SimpleAudioEngine sharedEngine] playEffect:@"increment.caf"];
	else if (sound == kSoundDecrement)
		[[SimpleAudioEngine sharedEngine] playEffect:@"decrement.caf"];
	else if (sound == kSoundReset)
		[[SimpleAudioEngine sharedEngine] playEffect:@"reset.caf"];
	else
		return;
}

- (void)ae_updateTargetField
{
	self.targetField.text = [self.countManager targetCountString];
}

- (void)ae_updateTitleField
{
	self.titleField.text = self.countManager.title;
}

#pragma mark - Public

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(ae_tapRecognized:)];
	[self.backgroundContainer addGestureRecognizer:self.tapRecognizer];
	
	self.swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(ae_swipeRecognized:)];
	[self.backgroundContainer addGestureRecognizer:self.swipeRecognizer];
	
	self.pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(ae_pinchRecognized:)];
	[self.view addGestureRecognizer:self.pinchRecognizer];
	
	self.count = self.countManager.count;
	self.countLabel.font = [UIFont fontWithName:@"ChunkFive" size:170];
	[self ae_updateCountLabel];
	
	if ( ! self.countManager.title)
	{
		[self.countManager saveTitle:NSLocalizedString(@"Counter", nil)];
		[self.countManager saveTargetCount:20];
	}
	self.titleField.font = [UIFont fontWithName:@"ChunkFive" size:60];
	[self ae_updateTitleField];
	
	self.targetField.font = self.titleField.font;
	[self ae_updateTargetField];
	
	self.defaultCountLabelFrame = self.countLabel.frame;
	self.defaultTopViewFrame = self.topView.frame;
	self.defaultBottomViewFrame = self.bottomView.frame;
	self.defaultTitleFieldFrame = self.titleField.frame;
	self.defaultTargetFieldFrame = self.targetField.frame;
	
	[self ae_applyNoiseTextures];
	[self ae_updateTargetProgressBar];
	
	self.titleField.layer.shadowColor = [UIColor colorWithRed:0.371 green:0.418 blue:0.000 alpha:0.8].CGColor;
	self.titleField.layer.shadowRadius = 0;
	self.titleField.layer.shadowOpacity = 1;
	self.titleField.layer.shadowOffset = CGSizeMake(0, -1);
	self.titleField.textAlignment = UITextAlignmentCenter;
	self.targetField.layer.shadowColor = self.titleField.layer.shadowColor;
	self.targetField.layer.shadowRadius = self.titleField.layer.shadowRadius;
	self.targetField.layer.shadowOpacity = self.titleField.layer.shadowOpacity;
	self.targetField.layer.shadowOffset = self.titleField.layer.shadowOffset;
	self.targetField.textAlignment = self.titleField.textAlignment;
	
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"increment.caf"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"decrement.caf"];
	[[SimpleAudioEngine sharedEngine] preloadEffect:@"reset.caf"];
	
	self.view.frame = AECGRectPlaceY(self.view.frame, self.view.frame.size.height + 20.0);
	[self.view setDefaultRoundedCorners];
	[UIView animateWithDuration:.3 delay:.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
		self.view.frame = AECGRectPlaceY(self.view.frame, 0.0);
	} completion:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - IBActions

- (IBAction)hideKeyboardButtonTouched:(id)sender
{
	[self.titleField resignFirstResponder];
	[self.targetField resignFirstResponder];
	
	[UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
		self.titleField.textColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"dark-noisetexture"]];
		self.targetField.textColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"dark-noisetexture"]];
		self.hideKeyboardButton.alpha = 0.0;
		self.view.frame = AECGRectPlaceY(self.view.frame, 20);
	} completion:^(BOOL finished) {
		self.hideKeyboardButton.hidden = YES;
	}];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	self.hideKeyboardButton.alpha = 0.0;
	self.hideKeyboardButton.hidden = NO;
	[UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
		textField.textColor = [UIColor whiteColor];
		self.hideKeyboardButton.alpha = 1.0;

		if (textField == self.targetField)
			self.view.frame = AECGRectPlaceY(self.view.frame, -196.0);
	}];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[self hideKeyboardButtonTouched:textField];
	
	return NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	if (textField == self.titleField)
	{
		[self.countManager saveTitle:textField.text];
		[self ae_updateTitleField];
	}
	else if (textField == self.targetField)
	{
		[self.countManager saveTargetCount:[textField.text integerValue]];
		[self ae_updateTargetField];
		[self ae_updateTargetProgressBar];
	}	
}

@end
