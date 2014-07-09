//
// Copyright (c) Microsoft Open Technologies, Inc.  All rights reserved.  Licensed under the Apache License, Version 2.0.
// See License.txt in the project root for license information.
//

#import "OneNotePickerSection.h"
#import "OneNotePickerController.h"

@implementation OneNotePickerSection

- (NSDictionary *)resultDictionary
{
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	
	// Two formatters to support milliseconds or no milliseconds
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.S'Z'"];
	[formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
	NSDateFormatter *formatter2 = [[NSDateFormatter alloc] init];
	[formatter2 setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
	[formatter2 setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
	
	NSDate *date = [formatter dateFromString:jsonData_[@"createdTime"]];
	NSDate *date2 = [formatter2 dateFromString:jsonData_[@"createdTime"]];
	if (date || date2) {
		result[OneNotePickerControllerCreatedTime] = date ?: date2;
	}
	date = [formatter dateFromString:jsonData_[@"modifiedTime"]];
	date2 = [formatter2 dateFromString:jsonData_[@"modifiedTime"]];
	if (date || date2) {
		result[OneNotePickerControllerModifiedTime] = date ?: date2;
	}
	
	NSURL *pagesUrl = [NSURL URLWithString:jsonData_[@"pagesUrl"]];
	if (pagesUrl) {
		result[OneNotePickerControllerPagesURL] = pagesUrl;
	}
	
	NSDictionary *stringValues = @{
								   OneNotePickerControllerSectionID: @"id",
								   OneNotePickerControllerSectionName: @"name",
								   OneNotePickerControllerLastModifiedBy: @"lastModifiedBy"
								   };
	for (NSString *key in [stringValues allKeys]) {
		if (jsonData_[stringValues[key]]) {
			result[key] = jsonData_[stringValues[key]];
		}
	}
	
	return result;
}

- (OneNotePickerNavItemType)type
{
	return kOneNotePickerNavItemTypeSection;
}

@end
