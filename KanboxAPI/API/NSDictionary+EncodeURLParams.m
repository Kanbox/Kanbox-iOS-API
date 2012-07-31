//
//  NSDictionary+EncodePostParams.m
//
//  Copyright 2012 Kanbox
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//

#import "NSDictionary+EncodeURLParams.h"

#define kParamKeyValuePair @"="
#define kParamJoin @"&"

@implementation NSDictionary (EncodeURLParams)

-(NSData *)encodedURLParams {
	NSMutableArray *params = [[NSMutableArray alloc] initWithCapacity:[self count]];
	for (NSString *key in self) {
		NSString *encodedKey = [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		NSString *encodedValue = [[self objectForKey:key] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		[params addObject:[NSString stringWithFormat:@"%@%@%@", encodedKey, kParamKeyValuePair, encodedValue]];
	}
	
	NSString *paramString = [params componentsJoinedByString:kParamJoin];
	return [paramString dataUsingEncoding:NSUTF8StringEncoding];
}

@end
