#import <UIKit/UIKit.h>
#import <TargetConditionals.h>
#import "GREEDButterflyLayer.h"
#import <objc/runtime.h>

#if !GREED_TARGET_IOS && !GREED_TARGET_TVOS
#error Invalid target
#elif GREED_TARGET_IOS && GREED_TARGET_TVOS
#error Invalid target
#endif

@interface SBFWallpaperView : UIView
@end

@interface SBWallpaperView : UIView
@end

@interface PBWallpaperViewController : UIViewController
- (UIView *)wallpaperView;
@end

@interface UIView(Private)
- (UIViewController *)_viewControllerForAncestor;
@end

@interface _SBWallpaperWindow : UIWindow
@property (nonatomic, strong) GREEDButterflyLayer *Greed_butterflyLayer;
@end

static void GREEDAddButterflyLayer(UIView *view) {
	SEL key = @selector(Greed_butterflyLayer);
	UIView *layer = objc_getAssociatedObject(view, key);
	if (view && !layer) {
		layer = [GREEDButterflyLayer new];
		layer.layer.zPosition = CGFLOAT_MAX;
		layer.translatesAutoresizingMaskIntoConstraints = NO;
		[view addSubview:layer];
		if (kCFCoreFoundationVersionNumber >= 793.00) {
			[view addConstraints:@[
				[NSLayoutConstraint
					constraintWithItem:layer
					attribute:NSLayoutAttributeTop
					relatedBy:NSLayoutRelationEqual
					toItem:view
					attribute:NSLayoutAttributeTop
					multiplier:1.0
					constant:0.0
				],
				[NSLayoutConstraint
					constraintWithItem:layer
					attribute:NSLayoutAttributeRight
					relatedBy:NSLayoutRelationEqual
					toItem:view
					attribute:NSLayoutAttributeRight
					multiplier:1.0
					constant:0.0
				],
				[NSLayoutConstraint
					constraintWithItem:layer
					attribute:NSLayoutAttributeLeft
					relatedBy:NSLayoutRelationEqual
					toItem:view
					attribute:NSLayoutAttributeLeft
					multiplier:1.0
					constant:0.0
				],
				[NSLayoutConstraint
					constraintWithItem:layer
					attribute:NSLayoutAttributeBottom
					relatedBy:NSLayoutRelationEqual
					toItem:view
					attribute:NSLayoutAttributeBottom
					multiplier:1.0
					constant:0.0
				]
			]];
		}
		else {
			view.frame = CGRectMake(
				0.0,
				0.0,
				view.bounds.size.width,
				view.bounds.size.height
			);
		}
		objc_setAssociatedObject(view, key, layer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
}

%group iOS6
%hook SBWallpaperView

- (SBWallpaperView *)initWithOrientation:(int)arg1 variant:(int)arg2 {
	SBWallpaperView *orig = %orig;
	GREEDAddButterflyLayer(orig);
	return orig;
}

%end
%end

%group iOS7
%hook SBFWallpaperView

// This is less reliable than _SBWallpaperWindow but it works
- (void)didMoveToWindow {
	%orig;
	if ([self class] == %c(SBFStaticWallpaperView)) {
		GREEDAddButterflyLayer(self);
	}
}

%end
%end

%group iOS10
%hook _SBWallpaperWindow

- (_SBWallpaperWindow *)initWithScreen:(UIScreen *)screen debugName:(id)name {
	_SBWallpaperWindow *orig = %orig;
	GREEDAddButterflyLayer(orig);
	return orig;
}

%end
%end

%group tvOS
%hook PBWallpaperViewController

- (void)viewDidLoad {
	%orig;
	GREEDAddButterflyLayer([self view]);
	GREEDAddButterflyLayer([self wallpaperView]);
}

%end
%end

%ctor {
#if GREED_TARGET_IOS
	if (kCFCoreFoundationVersionNumber >= 1333.20) {
		%init(iOS10);
	}
	else if (kCFCoreFoundationVersionNumber >= 847.20) {
		%init(iOS7);
	}
	else if (kCFCoreFoundationVersionNumber >= 793.00) {
		%init(iOS6);
	}
#elif GREED_TARGET_TVOS
	if (@available(tvOS 12.0, *)) {
		%init(tvOS);
	}
#endif
	else {
		NSLog(@"This system version is not supported.");
		return;
	}
	NSLog(@"Greed.");
}