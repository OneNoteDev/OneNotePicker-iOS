//
// Copyright (c) Microsoft Open Technologies, Inc.  All rights reserved.  Licensed under the Apache License, Version 2.0.
// See License.txt in the project root for license information.
//

#import <Foundation/Foundation.h>

#import "OneNotePickerConstants.h"

typedef enum {
	kOneNotePickerNavItemTypeRoot,
	kOneNotePickerNavItemTypeNotebook,
	kOneNotePickerNavItemTypeSection,
	kOneNotePickerNavItemTypeSectionGroup
} OneNotePickerNavItemType;

extern NSString * const kOneNotePickerNavItemLoadedDataNotification;

@interface OneNotePickerNavItem : NSObject
{
	@protected
	NSDictionary *jsonData_;
}

@property (readonly, nonatomic) OneNotePickerNavItemType type;
@property (strong, nonatomic) NSString *ID;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSArray *sections;
@property (strong, nonatomic) NSArray *sectionGroups;
@property (readonly, nonatomic) BOOL isLoaded;

- (id)initWithDictionary:(NSDictionary *)dictionary;
- (void)loadChildrenWithToken:(NSString *)token completionBlock:(void(^)(NSDictionary *errorInfo))completionBlock;
- (NSDictionary *)resultDictionary; // Only relevant for sections
- (void)reset; // Delete all data and stop connections; ONLY call this on the root nav item

@end
