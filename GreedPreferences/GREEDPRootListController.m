#import <Preferences/PSSpecifier.h>
#import "GREEDPRootListController.h"

@implementation GREEDPRootListController

- (void)openLinkWithSpecifier:(PSSpecifier *)specifier {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[specifier propertyForKey:@"URL"]]];
}

- (void)setPreferenceValue:(NSNumber *)value specifier:(PSSpecifier *)specifier {
	[super setPreferenceValue:value specifier:specifier];
	if ([(NSString *)[specifier propertyForKey:@"key"] isEqualToString:@"Enabled"]) {
		CFNotificationCenterPostNotification(
			CFNotificationCenterGetDarwinNotifyCenter(),
			CFSTR("com.pixelomer.greed/EnabledChanged"),
			NULL, NULL, YES
		);
	}
	else {
		CFNotificationCenterPostNotification(
			CFNotificationCenterGetDarwinNotifyCenter(),
			CFSTR("com.pixelomer.greed/ButterfliesChanged"),
			NULL, NULL, YES
		);
	}
}

- (PSSpecifier *)buttonWithName:(NSString *)name target:(NSString *)URLString {
	PSSpecifier *button = [PSSpecifier
		preferenceSpecifierNamed:name
		target:self
		set:nil
		get:nil
		detail:nil
		cell:PSButtonCell
		edit:nil
	];
	button.buttonAction = @selector(openLinkWithSpecifier:);
	[button setProperty:URLString forKey:@"URL"];
	return button;
}

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}
	NSString * const rootPath = @"/Library/ButterflyEffect/Butterflies";
	NSArray<NSString *> *contents = [[[NSFileManager defaultManager]
		contentsOfDirectoryAtPath:rootPath
		error:nil
	] sortedArrayUsingSelector:@selector(compare:)];
	NSMutableArray *bundleIdentifiers = [NSMutableArray new];
	for (NSString *bundleName in contents) {
		if (![bundleName hasSuffix:@".bundle"]) continue;
		NSBundle *bundle = [NSBundle bundleWithPath:[rootPath stringByAppendingPathComponent:bundleName]];
		if (!bundle) continue;
		if ([bundleIdentifiers containsObject:[bundle bundleIdentifier]]) {
			PSSpecifier *errorSpecifier = [PSSpecifier groupSpecifierWithName:nil];
			[errorSpecifier setProperty:@"You have conflicting butterfly bundles. Please resolve these conflicts before trying to configure ButterflyEffect." forKey:@"footerText"];
			_specifiers = [@[errorSpecifier] mutableCopy];
			return _specifiers;
		}
		[bundleIdentifiers addObject:[bundle bundleIdentifier]];
		SEL setter = @selector(setPreferenceValue:specifier:);
		SEL getter = @selector(readPreferenceValue:);
		PSSpecifier *specifier = [PSSpecifier
			preferenceSpecifierNamed:[bundle objectForInfoDictionaryKey:@"CFBundleName"]
			target:self
			set:setter
			get:getter
			detail:nil
			cell:PSSwitchCell
			edit:nil
		];
		[specifier
			setProperty:[NSString
				stringWithFormat:@"Butterfly/%@",
				[bundle bundleIdentifier]
			]
			forKey:@"key"
		];
		[specifier setProperty:@"com.pixelomer.greed" forKey:@"defaults"];
		[specifier setProperty:@(YES) forKey:@"default"];
		[_specifiers addObject:specifier];
	}
	[_specifiers addObjectsFromArray:@[
		[PSSpecifier groupSpecifierWithName:@"Links"],
		[self
			buttonWithName:@"@pixelomer on Twitter"
			target:@"https://twitter.com/pixelomer"
		],
		[self
			buttonWithName:@"Source Code"
			target:@"https://github.com/pixelomer/ButterflyEffect"
		],
		[self
			buttonWithName:@"Default Butterfly Source"
			target:@"https://www.youtube.com/watch?v=lQaufCqi5v4"
		]
	]];
	return _specifiers;
}

@end
