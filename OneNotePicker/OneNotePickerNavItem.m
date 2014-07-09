//
// Copyright (c) Microsoft Open Technologies, Inc.  All rights reserved.  Licensed under the Apache License, Version 2.0.
// See License.txt in the project root for license information.
//

#import "OneNotePickerController.h"
#import "OneNotePickerNavItem.h"
#import "OneNotePickerSection.h"
#import "OneNotePickerSectionGroup.h"
#import "OneNotePickerNotebook.h"

NSString * const kOneNotePickerNavItemLoadedDataNotification = @"OneNotePickerNavItemLoadedDataNotification";

@interface OneNotePickerNavItem () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (strong, nonatomic) NSURLConnection *sectionsConnection;
@property (strong, nonatomic) NSURLConnection *sectionGroupsConnection;
@property (copy, nonatomic) void (^loadCompletionBlock)(NSDictionary *);
@property (strong, nonatomic) NSMutableData *data; // For loading URLs into

@end

@implementation OneNotePickerNavItem

- (id)initWithDictionary:(NSDictionary *)dictionary
{
	if (self = [self init]) {
		jsonData_ = dictionary;
		self.ID = dictionary[@"id"];
		self.name = dictionary[@"name"];
		self.data = [NSMutableData data];
		if (self.type == kOneNotePickerNavItemTypeRoot) {
			self.name = @"OneNote";
		}
	}
	return self;
}

- (BOOL)isLoaded
{
	return self.sections != nil || (self.sectionGroups != nil && self.type == kOneNotePickerNavItemTypeRoot);
}

- (NSDictionary *)resultDictionary
{
	return nil;
}

- (void)loadChildrenWithToken:(NSString *)token completionBlock:(void (^)(NSDictionary *))completionBlock
{
	if (self.type != kOneNotePickerNavItemTypeSection && !self.sectionGroupsConnection) {
		BOOL iPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
		NSURL *URL = [self URLForSectionGroups];
		if (self.type == kOneNotePickerNavItemTypeRoot) {
			URL = [self URLForNotebooks];
		}
		self.loadCompletionBlock = completionBlock;
		
		NSString *userAgent = iPad ? @"iPad OneNotePicker" :  @"iPhone OneNotePicker";
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
		[request addValue:userAgent forHTTPHeaderField:@"User-Agent"];
		[request addValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
		self.sectionGroupsConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
		
		if (self.type != kOneNotePickerNavItemTypeRoot) {
			URL = [self URLForSections];
			NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
			[request addValue:userAgent forHTTPHeaderField:@"User-Agent"];
			[request addValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
			self.sectionsConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
		} else {
			[self.sectionGroupsConnection start];
		}
	}
}

- (NSURL *)URLForSections
{
	return [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [self baseAPIString], @"Sections"]];
}

- (NSURL *)URLForSectionGroups
{
	return [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [self baseAPIString], @"SectionGroups"]];
}

- (NSURL *)URLForNotebooks
{
	return [NSURL URLWithString:[self baseAPIString]];
}

- (NSString *)baseAPIString
{
	NSString *groupType = self.type == kOneNotePickerNavItemTypeSectionGroup ? @"SectionGroups" : @"Notebooks";
	NSString *base = [NSString stringWithFormat:@"%@/%@",
					  kOneNotePickerRootAPIURL,
					  groupType];
	if (self.type == kOneNotePickerNavItemTypeRoot) {
		return base;
	} else {
		return [NSString stringWithFormat:@"%@/%@", base, self.ID];
	}
}

- (OneNotePickerNavItemType)type
{
	return kOneNotePickerNavItemTypeRoot;
}

- (void)reset
{
	jsonData_ = nil;
	[self.sectionsConnection cancel];
	[self.sectionGroupsConnection cancel];
	self.sectionsConnection = nil;
	self.sectionGroupsConnection = nil;
	self.sections = nil;
	self.sectionGroups = nil;
	self.ID = nil;
	[self.data setLength:0];
}

#pragma mark - NSURLConnectionDelegate / NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[self.data setLength:0];
	if (self.loadCompletionBlock) {
		self.loadCompletionBlock(@{
								   OneNotePickerControllerIsAPIError: @(NO),
								   OneNotePickerControllerSystemError: error
								   });
		self.loadCompletionBlock = nil;
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSError *error;
	NSDictionary *json = [NSJSONSerialization JSONObjectWithData:self.data options:0 error:&error];
	[self.data setLength:0];
	if (error) {
		self.loadCompletionBlock(@{
								   OneNotePickerControllerIsAPIError: @(NO),
								   OneNotePickerControllerSystemError: error
								   });
		return;
	}
	
	if (json[@"error"]) {
		self.loadCompletionBlock(@{
								   OneNotePickerControllerIsAPIError: @(YES),
								   OneNotePickerControllerAPIErrorCode: json[@"error"][@"code"] ?: [NSNull null],
								   OneNotePickerControllerAPIErrorString: json[@"error"][@"message"] ?: [NSNull null],
								   OneNotePickerControllerAPIErrorURL: json[@"error"][@"@api.url"] ?: [NSNull null]
								   });
	}
	
	NSMutableArray *array = [NSMutableArray array];
	for (NSDictionary *item in json[@"value"]) {
		OneNotePickerNavItem *navItem = nil;
		if (connection == self.sectionGroupsConnection) {
			if (self.type == kOneNotePickerNavItemTypeRoot) {
				navItem = [[OneNotePickerNotebook alloc] initWithDictionary:item];
			} else {
				navItem = [[OneNotePickerSectionGroup alloc] initWithDictionary:item];
			}
		} else {
			navItem = [[OneNotePickerSection alloc] initWithDictionary:item];
		}
		[array addObject:navItem];
	}
	if (connection == self.sectionGroupsConnection) {
		self.sectionGroups = array;
		if (self.loadCompletionBlock) {
			self.loadCompletionBlock(nil);
			self.loadCompletionBlock = nil;
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:kOneNotePickerNavItemLoadedDataNotification object:self];
	} else {
		self.sections = array;
		[self.sectionGroupsConnection start];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
	[self.data setLength:0];
	if (httpResponse.statusCode >= 400 && httpResponse.statusCode < 599) {
		[connection cancel];
		self.loadCompletionBlock(@{
								   OneNotePickerControllerIsAPIError: @(YES),
								   OneNotePickerControllerAPIErrorCode: [NSNull null],
								   OneNotePickerControllerAPIErrorString: [NSString stringWithFormat: @"Failed to load API request with response code: %d", (int)httpResponse.statusCode],
								   OneNotePickerControllerAPIErrorURL: [NSNull null]
								   });
		self.loadCompletionBlock = nil;
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[self.data appendData:data];
}

@end
