//
// Copyright (c) Microsoft Open Technologies, Inc.  All rights reserved.  Licensed under the Apache License, Version 2.0.
// See License.txt in the project root for license information.
//

#import "OneNotePickerViewController.h"

static const NSUInteger topBottomMargin = 30;

@interface OneNotePickerViewController ()

@end

@implementation OneNotePickerViewController

- (id)initWithNavItem:(OneNotePickerNavItem *)navItem
{
	BOOL iPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
	self = [self initWithNibName:[@"OneNotePicker.framework/Resources/OneNotePickerView" stringByAppendingString:iPad ? @"_iPad" : @""] bundle:nil];
	if (self) {
		self.navItem = navItem;
		self.title = self.navItem.name;
		UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
																		style:UIBarButtonItemStyleDone
																	   target:self
																	   action:@selector(cancelButtonClicked:)];
		self.navigationItem.rightBarButtonItem = rightButton;
        
        if (navItem.type == kOneNotePickerNavItemTypeRoot){
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:kOneNotePickerNavItemLoadedDataNotification object:self.navItem];
        } else {
            [self reloadData];
        }
	}
	return self;
}

- (void)updateSpinner
{
	if (spinner_.isAnimating == self.navItem.isLoaded) {
		self.navItem.isLoaded ? [spinner_ stopAnimating] : [spinner_ startAnimating];
	}
}

- (void)updateTableFrame
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		CGRect frame = tableView_.frame;
		frame.size.height = tableView_.rowHeight * [tableView_ numberOfRowsInSection:0];
		frame.origin.y = self.navigationController.navigationBar.frame.size.height + topBottomMargin;
		if (frame.size.height + frame.origin.y + topBottomMargin > self.view.frame.size.height) {
			frame.size.height = self.view.frame.size.height - frame.origin.y - topBottomMargin;
			tableView_.scrollEnabled = YES;
		} else {
			tableView_.scrollEnabled = NO;
		}
		tableView_.frame = frame;
	}
}

- (void)cancelButtonClicked:(id)sender
{
	[self.delegate oneNotePickerViewControllerDidCancel:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	tableView_.tableFooterView = [[UIView alloc] init];
	[self updateSpinner];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		tableView_.layer.borderWidth = 1.0;
		tableView_.layer.borderColor = [UIColor colorWithRed:0xDE / 255.0 green:0xDE / 255.0 blue:0xE0 / 255.0 alpha:1.0].CGColor;
		tableView_.layer.cornerRadius = 4.0;
		tableView_.layer.backgroundColor = [UIColor whiteColor].CGColor;
		[self updateTableFrame];
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reloadData
{
	[self updateSpinner];
	[tableView_ reloadData];
	[self updateTableFrame];
}

- (OneNotePickerNavItem *)navItemForRowIndex:(NSUInteger)row
{
	NSUInteger sectionCount = self.navItem.sections.count;
	OneNotePickerNavItem *item = row < sectionCount ? self.navItem.sections[row] : self.navItem.sectionGroups[row - sectionCount];
	return item;
}

- (UIImage *)imageForNavItem:(OneNotePickerNavItem *)navItem
{
	NSString *imageName = nil;
	BOOL iPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
	switch (navItem.type) {
		case kOneNotePickerNavItemTypeNotebook: {
			imageName = iPad ? @"iPad/ON_Notebooks.png" : @"iPhone/ON_iPhone_NotebooksDrawer_N.png";
			break;
		}
		case kOneNotePickerNavItemTypeSectionGroup: {
			imageName = iPad ? @"iPad/ON_iPad_SectionGroups_Sections_iOS.png" : @"iPhone/ON_iPhone_SectionGroups_Sections.png";
			break;
		}
		case kOneNotePickerNavItemTypeSection: {
			imageName = iPad ? @"iPad/ON_iPad_Section_Icon.png" : @"iPhone/ON_iPhone_Section_Icon.png";
			break;
		}
			
		default: {
			return nil;
			break;
		}
	}
	return [UIImage imageNamed:[@"OneNotePicker.framework/Resources/" stringByAppendingString:imageName]];
}

#pragma mark - UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	OneNotePickerNavItem *navItem = [self navItemForRowIndex:indexPath.row];
	if (navItem.type == kOneNotePickerNavItemTypeSection) {
		[self.delegate oneNotePickerViewController:self choseSection:navItem];
	} else {
		OneNotePickerViewController *viewController = [[OneNotePickerViewController alloc] initWithNavItem:navItem];
		viewController.delegate = self.delegate;
		viewController.navigationItem.prompt = self.navigationItem.prompt;
		[self.navigationController pushViewController:viewController animated:YES];
	}
	return nil;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.navItem.sections.count + self.navItem.sectionGroups.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	OneNotePickerNavItem *item = [self navItemForRowIndex:indexPath.row];
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NavItem"];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NavItem"];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
		cell.backgroundColor = [UIColor whiteColor];
	}
	
	if (item.type == kOneNotePickerNavItemTypeSection) {
		cell.accessoryType = UITableViewCellAccessoryNone;
	} else {
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	
	cell.textLabel.text = item.name;
	cell.textLabel.textColor = [UIColor colorWithWhite:0x42 / 255.0 alpha:1.0];
	cell.imageView.image = [self imageForNavItem:item];
	return cell;
}

@end
