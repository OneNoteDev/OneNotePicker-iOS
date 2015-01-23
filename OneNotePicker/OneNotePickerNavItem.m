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

@property (copy, nonatomic) void (^loadCompletionBlock)(NSDictionary *);
@property (strong, nonatomic) NSMutableData *data; // For loading URLs into

@end

@implementation OneNotePickerNavItem

- (id)initWithDictionary:(NSDictionary *)dictionary;
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

- (NSDictionary *)resultDictionary
{
	return nil;
}

- (BOOL)isLoaded
{
	return self.sections != nil || (self.sectionGroups != nil && self.type == kOneNotePickerNavItemTypeRoot);
}

- (void)getOneNoteEntitiesWithToken:(NSString *)token completionBlock:(void (^)(NSDictionary *))completionBlock
{
    BOOL iPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
    NSURL *URL = [self URLForOneNoteHierarchy];
        
    self.loadCompletionBlock = completionBlock;
		
    NSString *userAgent = iPad ? @"iPad OneNotePicker" :  @"iPhone OneNotePicker";
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request addValue:userAgent forHTTPHeaderField:@"User-Agent"];
    [request addValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    
    [connection start];
}

- (NSURL *)URLForOneNoteHierarchy
{
	return [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",
					  kOneNotePickerRootAPIURL,
					  @"notebooks?$expand=sections,sectionGroups($expand=sections,sectionGroups($expand=sections;$levels=max))"]];
}

- (OneNotePickerNavItemType)type
{
	return kOneNotePickerNavItemTypeRoot;
}

- (void)reset
{
	jsonData_ = nil;
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
    
    // Handle connection errors
	if (error) {
		self.loadCompletionBlock(@{
								   OneNotePickerControllerIsAPIError: @(NO),
								   OneNotePickerControllerSystemError: error
								   });
		return;
	}
	
    // The OneNote API might return an error - handle this case
	if (json[@"error"]) {
		self.loadCompletionBlock(@{
								   OneNotePickerControllerIsAPIError: @(YES),
								   OneNotePickerControllerAPIErrorCode: json[@"error"][@"code"] ?: [NSNull null],
								   OneNotePickerControllerAPIErrorString: json[@"error"][@"message"] ?: [NSNull null],
								   OneNotePickerControllerAPIErrorURL: json[@"error"][@"@api.url"] ?: [NSNull null]
								   });
	}
	
    // No error in the OneNote API - Parse out the returned JSON response
	NSMutableArray *notebooksArray = [NSMutableArray array];
	for (NSDictionary *notebookItem in json[@"value"]) {
        // Build all notebooks
		OneNotePickerNotebook *notebookNavItem = nil;
        notebookNavItem = [[OneNotePickerNotebook alloc] initWithDictionary:notebookItem];
        
        // Get the notebooks' sections
        notebookNavItem.sections = [self getSectionsNavItemArrayFromParent:notebookItem];
        
        // Get the notebooks' sectionGroups
        notebookNavItem.sectionGroups = [self getSectionGroupsNavItemArrayFromParent:notebookItem];;
        
        [notebooksArray addObject:notebookNavItem];
	}
    
    self.sectionGroups = notebooksArray;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kOneNotePickerNavItemLoadedDataNotification object:self];
}

-(NSArray *)getSectionGroupsNavItemArrayFromParent:(NSDictionary *)parentItem{
    NSMutableArray *sectionGroupsArray = [NSMutableArray array];
    for (NSDictionary *sectionGroupItem in parentItem[@"sectionGroups"]) {
        OneNotePickerSectionGroup *sectionGroupNavItem = nil;
        sectionGroupNavItem = [[OneNotePickerSectionGroup alloc] initWithDictionary:sectionGroupItem];
        
        // Get the notebooks' sections
        sectionGroupNavItem.sections = [self getSectionsNavItemArrayFromParent:sectionGroupItem];
        
        // Get the notebooks' sectionGroups
        sectionGroupNavItem.sectionGroups = [self getSectionGroupsNavItemArrayFromParent:sectionGroupItem];;
        
        [sectionGroupsArray addObject:sectionGroupNavItem];
    }
    return sectionGroupsArray;
}

-(NSArray *)getSectionsNavItemArrayFromParent:(NSDictionary *)parentItem{
    NSMutableArray *sectionsArray = [NSMutableArray array];
    for (NSDictionary *sectionItem in parentItem[@"sections"]) {
        OneNotePickerSection *sectionNavItem = nil;
        sectionNavItem = [[OneNotePickerSection alloc] initWithDictionary:sectionItem];
        [sectionsArray addObject:sectionNavItem];
    }
    return sectionsArray;
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
