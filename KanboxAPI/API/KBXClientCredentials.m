//
//  KBXClientCredentials.m
//
//  Copyright 2012 Kanbox
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//

#import "KBXClientCredentials.h"

@interface KBXClientCredentials ()

//@property (nonatomic, copy, readwrite) NSString *clientID;
//@property (nonatomic, copy) NSString *clientSecret;

@end

@implementation KBXClientCredentials

@synthesize clientID, clientSecret;

-(id)initWithClientID:(NSString *)theID secret:(NSString *)theSecret {
	self = [super init];
	if (self) {
		self.clientID = theID;
		self.clientSecret = theSecret;
	}
	return self;
}


#pragma mark -
#pragma mark NSCoding Implementation

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.clientID forKey:@"clientID"];
    [aCoder encodeObject:self.clientSecret forKey:@"clientSecret"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super init])) {
        self.clientID = [aDecoder decodeObjectForKey:@"clientID"];
        self.clientSecret = [aDecoder decodeObjectForKey:@"clientSecret"];
    }
    return self;
}


@end
