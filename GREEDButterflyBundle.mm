#import "GREEDButterflyBundle.h"

@implementation GREEDButterflyBundle : NSObject

- (instancetype)initWithPath:(NSString *)path error:(NSError *__strong *)errorPt {
	#define makeError(c, f...) [NSError \
		errorWithDomain:@"com.pixelomer.greed.bundle/Initialization" \
		code:c \
		userInfo:@{ \
			NSLocalizedDescriptionKey: [NSString stringWithFormat:f] \
		} \
	]
	NSError *_error;
	if (!errorPt) errorPt = &_error;
	NSBundle *bundle = [[NSBundle alloc] initWithPath:path];
	if (!bundle) {
		*errorPt = makeError(1, @"Failed to load the butterfly bundle at \"%@\".", path);
		return nil;
	}
	if (![[bundle bundleIdentifier] isKindOfClass:[NSString class]]) {
		*errorPt = makeError(2, @"Butterfly bundle at path \"%@\" doesn't have a valid bundle identifier.", path);
		return nil;
	}
	if ((self = [super init])) {
		#define getInfo(_target, _key, _default, _class) do { \
			__kindof NSObject *defaultValue = _default; \
			__kindof NSString *key = _key; \
			__kindof NSObject *value = [bundle objectForInfoDictionaryKey:key] ?: defaultValue; \
			if (!value) { \
				*errorPt = makeError(7, @"Info.plist key \"%@\" is missing.", key); \
				return nil; \
			} \
			if (defaultValue && ![value isKindOfClass:[_class class]]) { \
				*errorPt = makeError(6, @"Info.plist value for key \"%@\" is invalid. Expected %s, got %@ instead.", key, #_class, value ? NSStringFromClass([value class]) : nil); \
				return nil; \
			} \
			_target = value; \
		} while (0)

		// Get anchor point
		{
			NSString *anchorPointString;
			getInfo(anchorPointString, @"GREEDCenter", @"{0.5,0.5}", NSString);
			_anchorPoint = CGPointFromString(anchorPointString);
		}

		// Set NSBundle *bundle property
		_bundle = bundle;

		// Get bundle version
		{
			NSNumber *bundleVersion;
			getInfo(bundleVersion, @"GREEDVersion", @(1), NSNumber);
			_bundleVersion = [bundleVersion integerValue];
		}

		// Get duration
		{
			NSNumber *duration;
			getInfo(duration, @"GREEDDuration", nil, NSString);
			_duration = [duration doubleValue];
		}
		
		// Get all of the frames and the frame dimensions.
		// There must be a better way to do this.
		_animationSize = CGSizeZero;
		NSMutableArray *images = [NSMutableArray new];
		unsigned int i=0;
		while (++i) {
			NSString *relativePath = [NSString stringWithFormat:@"frame%u.png", i];
			NSString *fullPath = [path stringByAppendingPathComponent:relativePath];
			if (![NSFileManager.defaultManager fileExistsAtPath:fullPath]) {
				break;
			}
			UIImage *image = [UIImage imageWithContentsOfFile:fullPath];
			if (!image) {
				*errorPt = makeError(3, @"Failed to read image at \"%@\".", fullPath);
				return nil;
			}
			if (
				!CGSizeEqualToSize(CGSizeZero, _animationSize) &&
				!CGSizeEqualToSize(image.size, _animationSize)
			) {
				*errorPt = makeError(4, @"Bundle at \"%@\" contains animation frames with different dimensions. All animation frames must have the same dimensions.", path);
				return nil;
			}
			_animationSize = image.size;
			[images addObject:image];
		}
		if (images.count <= 0) {
			*errorPt = makeError(5, @"Bundle at \"%@\" contains no animation frames. Animation frames must be at the root of the bundle and have the name format \"frame%%u.png\".", path);
			return nil;
		}
		_frames = images.copy;
		#undef getInfo
	}
	return self;
	#undef makeError
}

@end