//
//  NSURL+QueryStringParams.m
//
//  Copyright 2012 Kanbox
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//

#import "NSURL+QueryStringParams.h"


@implementation NSURL (QueryStringParams)

-(NSDictionary *)queryStringParams {
	NSString *queryString = self.query;
	if (queryString == nil) {
		NSArray *parts = [[self absoluteString] componentsSeparatedByString:@"?"];
		if ([parts count] == 2) {
			queryString = [parts objectAtIndex:1];
		} else {
			return [[NSDictionary alloc] init];
		}
	}
	
	NSArray *parts = [queryString componentsSeparatedByString:@"&"];
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:[parts count]];

	for (NSString *part in parts) {
		NSArray *components = [part componentsSeparatedByString:@"="];
		if ([components count] == 2) {
			NSString *key = [[[components objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"+" withString:@" "];
			NSString *value = [[[components objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"+" withString:@" "];
			[params setValue:value forKey:key];
		}
	}
	
	return [[NSDictionary alloc] initWithDictionary:params];
}

@end
