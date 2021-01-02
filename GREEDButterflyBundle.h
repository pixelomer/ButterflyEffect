#import <UIKit/UIKit.h>

@interface GREEDButterflyBundle : NSObject

// The NSBundle that was used to get the rest of the properties.
@property (nonatomic, strong, readonly) NSBundle *bundle;

// An array containing all of the frames as UIImage objects. All of these images
// have the same dimensions. These dimensions can be accessed using the animationSize
// property.
@property (nonatomic, strong, readonly) NSArray<UIImage *> *frames;

// The dimensions of all of the images in the frames array. All of the frames
// have the same dimensions. -[GREEDButterflyBundle initWithPath:error:] will
// fail for bundles that contain frames with different sizes.
@property (nonatomic, assign, readonly) CGSize animationSize;

// The center that is used for rotating the butterflies. Initially, the butterflies
// were going to have a non-linear path. However, this proved to be challenging
// so I didn't implement it in the initial release. Right now, the anchor point
// is not used for anything.
@property (nonatomic, assign, readonly) CGPoint anchorPoint;

// The amount of time it should take for all of the frames to be displayed before
// repeating.
@property (nonatomic, assign, readonly) NSTimeInterval duration;

// Has the value for the "GREEDVersion" key in the Info.plist. This key exists
// for backwards compatibility reasons. This value hasn't been used for anything
// yet.
@property (nonatomic, assign, readonly) NSInteger bundleVersion;

// This is the only initializer that should be used for initializing an instance
// of GREEDButterflyBundle.
- (instancetype)initWithPath:(NSString *)path error:(NSError *__strong *)error;

@end