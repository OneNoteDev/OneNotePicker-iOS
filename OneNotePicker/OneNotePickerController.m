//
// Copyright (c) Microsoft Open Technologies, Inc.  All rights reserved.  Licensed under the Apache License, Version 2.0.
// See License.txt in the project root for license information.
//

#import "OneNotePickerController.h"
#import "OneNotePickerNavItem.h"
#import "OneNotePickerViewController.h"

NSString *const OneNotePickerControllerSectionID = @"OneNotePickerControllerSectionID";
NSString *const OneNotePickerControllerSectionName = @"OneNotePickerControllerSectionName";
NSString *const OneNotePickerControllerPagesURL = @"OneNotePickerControllerPagesURL";
NSString *const OneNotePickerControllerCreatedTime = @"OneNotePickerControllerCreatedTime";
NSString *const OneNotePickerControllerModifiedTime = @"OneNotePickerControllerModifiedTime";
NSString *const OneNotePickerControllerLastModifiedBy = @"OneNotePickerControllerLastModifiedBy";

NSString *const OneNotePickerControllerIsAPIError = @"OneNotePickerControllerIsAPIError";
NSString *const OneNotePickerControllerAPIErrorCode = @"OneNotePickerControllerAPIErrorCode";
NSString *const OneNotePickerControllerAPIErrorString = @"OneNotePickerControllerAPIErrorString";
NSString *const OneNotePickerControllerAPIErrorURL = @"OneNotePickerControllerAPIErrorURL";
NSString *const OneNotePickerControllerSystemError = @"OneNotePickerControllerSystemError";

@interface OneNotePickerController () <OneNotePickerViewControllerDelegate>

@property (strong, nonatomic) OneNotePickerNavItem *rootNavItem;
@property (strong, nonatomic) NSMutableArray *navItemsToLoad;
@property (strong, nonatomic) NSMutableArray *nextNavItemsToLoad;
@property (nonatomic) BOOL viewIsVisible;
@property (copy, nonatomic) void (^onAppearHandler) ();

@end

@implementation OneNotePickerController

- (id)init
{
	if (self = [self initWithNavigationBarClass:nil toolbarClass:nil]) {
		self.navTextColor = [UIColor colorWithRed:0x80 / 255.0 green:0x39 / 255.0 blue:0x7B / 255.0 alpha:1.0];
		[self.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0x33 / 255.0 alpha:1.0]}];
		self.rootNavItem = [[OneNotePickerNavItem alloc] initWithDictionary:nil];
		self.navItemsToLoad = [NSMutableArray arrayWithObject:self.rootNavItem];
		self.nextNavItemsToLoad = [NSMutableArray array];
		self.modalPresentationStyle = UIModalPresentationFormSheet;
		
		OneNotePickerViewController *viewController = [[OneNotePickerViewController alloc] initWithNavItem:self.rootNavItem];
		viewController.delegate = self;
		[self pushViewController:viewController animated:NO];
	}
	return self;
}

- (void)loadNextNavItem
{
	if (self.navItemsToLoad.count) {
		OneNotePickerNavItem *item = [self.navItemsToLoad firstObject];
		[self.navItemsToLoad removeObjectAtIndex:0];
		[item getOneNoteEntitiesWithToken:self.accessToken completionBlock:^(NSDictionary *errorInfo) {
			if (errorInfo) {
				void (^notifyDelegateBlock) () = ^{
					if ([self.delegate respondsToSelector:@selector(oneNotePickerController:didErrorWithInfo:)]) {
						[self.delegate oneNotePickerController:self didErrorWithInfo:errorInfo];
					}
				};
				if (self.viewIsVisible) {
					notifyDelegateBlock();
				} else {
					self.onAppearHandler = notifyDelegateBlock;
				}
			}
		}];
	}
}

- (void)oneNotePickerViewControllerDidCancel:(OneNotePickerViewController *)viewController
{
	if ([self.delegate respondsToSelector:@selector(oneNotePickerControllerDidCancel:)]) {
		[self.delegate oneNotePickerControllerDidCancel:self];
	}
}

- (void)oneNotePickerViewController:(OneNotePickerViewController *)viewController choseSection:(OneNotePickerNavItem *)section
{
	if ([self.delegate respondsToSelector:@selector(oneNotePickerController:didFinishPickingSectionWithInfo:)]) {
		[self.delegate oneNotePickerController:self didFinishPickingSectionWithInfo:[section resultDictionary]];
	}
}

#pragma mark - UIViewController subclass

- (void)viewWillAppear:(BOOL)animated
{
	[self.rootNavItem reset];
	[self.navItemsToLoad removeAllObjects];
	[self.navItemsToLoad addObject:self.rootNavItem];
	[self.nextNavItemsToLoad removeAllObjects];
	[self loadNextNavItem];
	[self popToRootViewControllerAnimated:NO];
	self.topViewController.navigationItem.prompt = self.headerInstructions;
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	self.viewIsVisible = YES;
	if (self.onAppearHandler) {
		self.onAppearHandler();
		self.onAppearHandler = nil;
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	self.viewIsVisible = NO;
}

#pragma mark - Properties

- (UIColor *)navTextColor
{
	return self.navigationBar.tintColor;
}

- (void)setNavTextColor:(UIColor *)navTextColor
{
	self.navigationBar.tintColor = navTextColor;
}

- (NSString *)promptForOneNotePickerViewController:(OneNotePickerViewController *)viewController
{
	return self.headerInstructions;
}

@end
