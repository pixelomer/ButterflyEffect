#import <Foundation/Foundation.h>

#define NSLog(args...) NSLog(@"[Greed] "args)

NSBundle *GetNotAnImpostorBundle();

@interface NSUserDefaults(Private)
- (id)objectForKey:(NSString *)key inDomain:(NSString *)domain;
@end