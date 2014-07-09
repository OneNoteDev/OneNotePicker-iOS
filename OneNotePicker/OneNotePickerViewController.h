//
// Copyright (c) Microsoft Open Technologies, Inc.  All rights reserved.  Licensed under the Apache License, Version 2.0.
// See License.txt in the project root for license information.
//

#import <UIKit/UIKit.h>
#import "OneNotePickerNavItem.h"

@class OneNotePickerViewController;

@protocol OneNotePickerViewControllerDelegate <NSObject>

- (void)oneNotePickerViewControllerDidCancel:(OneNotePickerViewController *)viewController;
- (void)oneNotePickerViewController:(OneNotePickerViewController *)viewController choseSection:(OneNotePickerNavItem *)section;
- (NSString *)promptForOneNotePickerViewController:(OneNotePickerViewController *)viewController;

@end

@interface OneNotePickerViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>
{
	IBOutlet UITableView *tableView_;
	IBOutlet UIActivityIndicatorView *spinner_;
}

@property (strong, nonatomic) OneNotePickerNavItem *navItem;
@property (weak, nonatomic) id<OneNotePickerViewControllerDelegate> delegate;

- (id)initWithNavItem:(OneNotePickerNavItem *)navItem;

@end
