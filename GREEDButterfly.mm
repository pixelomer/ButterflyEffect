#import "GREEDButterfly.h"
#import "GREEDButterflyBundle.h"

@implementation GREEDButterfly {
	GREEDButterflyBundle *_currentBundle;
}

static NSLock *_enabledButterfliesLock;
static NSArray<GREEDButterflyBundle *> *_allButterflies;
static NSArray<GREEDButterflyBundle *> *_enabledButterflies;

static void GREEDButterfliesChanged(
	CFNotificationCenterRef center,
	void *observer,
	CFNotificationName name,
	const void *object,
	CFDictionaryRef userInfo
) {
	[NSUserDefaults.standardUserDefaults synchronize];
	NSMutableArray *enabledButterflies = [NSMutableArray new];
	for (GREEDButterflyBundle *bundle in _allButterflies) {
		NSString *key = [NSString
			stringWithFormat:@"Butterfly/%@",
			[bundle.bundle bundleIdentifier]
		];
		NSNumber *enabled = [[NSUserDefaults standardUserDefaults]
			objectForKey:key
			inDomain:@"com.pixelomer.greed"
		] ?: @(YES);
		if ([enabled boolValue]) {
			[enabledButterflies addObject:bundle];
		}
	}
	[_enabledButterfliesLock lock];
	_enabledButterflies = [enabledButterflies copy];
	[_enabledButterfliesLock unlock];
}

+ (void)initialize {
	if (self == [GREEDButterfly class]) {
		#if GREED_TARGET_SIMULATOR
		#if GREED_TARGET_TVOS
		NSString * const rootPath = @"/opt/simjectTV/ButterflyEffect/Butterflies";
		#elif GREED_TARGET_IOS
		NSString * const rootPath = @"/opt/simject/ButterflyEffect/Butterflies";
		#endif
		#else
		NSString * const rootPath = @"/Library/ButterflyEffect/Butterflies";
		#endif
		NSMutableArray *butterflies = [NSMutableArray new];
		NSError *error = nil;
		NSArray<NSString *> *contents = [[[NSFileManager defaultManager]
			contentsOfDirectoryAtPath:rootPath
			error:&error
		] sortedArrayUsingSelector:@selector(compare:)];;
		if (!contents) {
			[NSException raise:NSGenericException format:@"Failed to get tweak directory contents. Error: %@", error];
		}
		for (NSString *relativePath in contents) {
			if (![relativePath hasSuffix:@".bundle"]) continue;
			NSString *absolutePath = [rootPath stringByAppendingPathComponent:relativePath];
			GREEDButterflyBundle *bundle = [[GREEDButterflyBundle alloc] initWithPath:absolutePath error:&error];
			if (!bundle) {
				[NSException raise:NSGenericException format:@"Failed to open butterfly bundle at \"%@\". Error: %@", absolutePath, error];
			}
			[butterflies addObject:bundle];
		}
		_allButterflies = butterflies.copy;
		for (GREEDButterflyBundle *bundle1 in _allButterflies) {
			for (GREEDButterflyBundle *bundle2 in _allButterflies) {
				if ((bundle1 != bundle2) && ([[bundle1.bundle bundleIdentifier] isEqualToString:[bundle2.bundle bundleIdentifier]])) {
					[NSException raise:NSGenericException format:@"Bundle at \"%@\" has the same bundle identifier as the bundle at \"%@\". All butterfly bundles must have unique bundle identifiers.", bundle1.bundle.bundlePath, bundle2.bundle.bundlePath];
				}
			}
		}
		_enabledButterfliesLock = [NSLock new];
		CFNotificationCenterAddObserver(
			CFNotificationCenterGetDarwinNotifyCenter(),
			NULL,
			&GREEDButterfliesChanged,
			CFSTR("com.pixelomer.greed/ButterfliesChanged"),
			NULL,
			0
		);
		GREEDButterfliesChanged(NULL, NULL, NULL, NULL, NULL);
	}
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p; butterfly = %@>",
		NSStringFromClass(self.class),
		self,
		_currentBundle
	];
}

- (CGSize)sizeThatFits:(CGSize)size {
	return CGSizeMake(
		_currentBundle.animationSize.width,
		_currentBundle.animationSize.height
	);
}

- (void)layoutSubviews {
	[super layoutSubviews];
	CGRect imageRect = CGRectMake(
		0,
		0,
		_currentBundle.animationSize.width,
		_currentBundle.animationSize.height
	);
	_imageView.frame = imageRect;
}

- (instancetype)init {
	if (_enabledButterflies.count == 0) {
		return nil;
	}
	GREEDButterflyBundle *currentBundle;
	[_enabledButterfliesLock lock];
	currentBundle = _enabledButterflies[arc4random_uniform(_enabledButterflies.count)];
	[_enabledButterfliesLock unlock];
	if ((self = [super init])) {
		_imageView = [UIImageView new];
		_imageView.contentMode = UIViewContentModeTopLeft;
		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
		self.clipsToBounds = YES;
		[self addSubview:_imageView];
		_currentBundle = currentBundle;
		_imageView.animationImages = _currentBundle.frames;
		_imageView.animationDuration = _currentBundle.duration;
		[_imageView startAnimating];
	}
	return self;
}

@end
