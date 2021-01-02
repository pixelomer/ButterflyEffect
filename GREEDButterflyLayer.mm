#import "GREEDButterflyLayer.h"
#import "GREEDButterfly.h"
#import <objc/runtime.h>
#define c(cname) objc_getClass(#cname)

@interface SpringBoard : UIApplication
- (id)_accessibilityFrontMostApplication;
- (BOOL)isLocked;
@end

@interface SBBacklightController : NSObject
+ (instancetype)sharedInstance;
- (BOOL)screenIsOn;
- (BOOL)screenIsOff;
@end

@implementation GREEDButterflyLayer {
	NSTimer *_timer;
	NSInteger _visibleButterflyCount;
}

static BOOL _layerEnabled;

static void GREEDEnabledChanged(
	CFNotificationCenterRef center,
	void *observer,
	CFNotificationName name,
	const void *object,
	CFDictionaryRef userInfo
) {
	[NSUserDefaults.standardUserDefaults synchronize];
	_layerEnabled = [(NSNumber *)(
		[NSUserDefaults.standardUserDefaults
			objectForKey:@"Enabled"
			inDomain:@"com.pixelomer.greed"
		] ?: @(YES)
	) boolValue];
}

+ (void)initialize {
	if (self == [GREEDButterflyLayer class]) {
		CFNotificationCenterAddObserver(
			CFNotificationCenterGetDarwinNotifyCenter(),
			NULL,
			&GREEDEnabledChanged,
			CFSTR("com.pixelomer.greed/EnabledChanged"),
			NULL,
			0
		);
		GREEDEnabledChanged(NULL, NULL, NULL, NULL, NULL);
	}
}

- (void)didMoveToWindow {
	if (_timer && !self.window) {
		[_timer invalidate];
		_timer = nil;
	}
	else if (!_timer && self.window) {
		_timer = [NSTimer
			timerWithTimeInterval:0.4
			target:self
			selector:@selector(addButterflyTimerTick:)
			userInfo:nil
			repeats:YES
		];
		[[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
	}
}

- (void)addButterflyTimerTick:(id)sender {
	if (!_layerEnabled) {
		// The tweak was disabled
		return;
	}
#if GREED_TARGET_IOS
	SpringBoard *springboard = (SpringBoard *)[UIApplication sharedApplication];
	BOOL screenIsOn = YES;
	if (kCFCoreFoundationVersionNumber >= 847.20) {
		// iOS 7.0 and higher
		SBBacklightController *backlightController = [c(SBBacklightController) sharedInstance];
		if ([backlightController respondsToSelector:@selector(screenIsOn)]) {
			screenIsOn = [backlightController screenIsOn];
		}
		else if ([backlightController respondsToSelector:@selector(screenIsOff)]) {
			screenIsOn = ![backlightController screenIsOff];
		}
	}
	if (
		// Return if there is an app in the foreground and if the device is not locked
		([springboard _accessibilityFrontMostApplication] && ![springboard isLocked]) ||
		// Return if the screen is off
		!screenIsOn
	) {
		return;
	}
#endif
	// Add a new butterfly
	_visibleButterflyCount++;
	[self addButterfly];
}

- (void)addButterfly {
	// Butterfly with random properties
	GREEDButterfly *butterfly = [GREEDButterfly new];
	if (!butterfly) {
		// There are no enabled butterflies
		return;
	}
	CGFloat scale = 0.3 + ((CGFloat)arc4random_uniform(200000) / 1000000.0);
	butterfly.layer.zPosition = scale * 1000.0;
	[butterfly.imageView stopAnimating];
	NSTimeInterval durationChange = ((NSTimeInterval)arc4random_uniform(150) - 75.0) / 1000.0;
	butterfly.imageView.animationDuration += durationChange;
	[butterfly.imageView startAnimating];
	butterfly.transform = CGAffineTransformScale(
		CGAffineTransformIdentity,
		scale,
		scale
	);
	CGRect rect;
	rect.size = [butterfly sizeThatFits:CGSizeZero];
	CGPoint startPoint = CGPointMake(
		arc4random_uniform(self.frame.size.width) - ((rect.size.width * scale) / 2.0),
		self.frame.size.height
	);
	rect.origin = startPoint;
	rect.size.width *= scale;
	rect.size.height *= scale;
	butterfly.frame = rect;
	[self addSubview:butterfly];
	[UIView
		animateWithDuration:(
			(self.frame.size.height / butterfly.frame.size.height / 2.0)
			+ (durationChange * 7.0)
		)
		delay:0.0
		options:UIViewAnimationOptionCurveLinear
		animations:^{
			butterfly.frame = CGRectMake(
				startPoint.x,
				-butterfly.frame.size.height,
				butterfly.frame.size.width,
				butterfly.frame.size.height
			);
		}
		completion:^(BOOL completed){
			[butterfly removeFromSuperview];
			_visibleButterflyCount--;
		}
	];
}

@end