//
//  KBXAccessToken.m
//
//  Copyright 2012 Kanbox
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//

#import "KBXAccessToken.h"

@interface KBXAccessToken ()

@property (nonatomic, readwrite, copy) NSString *accessToken;
@property (nonatomic, readwrite, strong) NSDate *accessTokenExpiration;
@property (nonatomic, readwrite, copy) NSString *refreshToken;

@end

@implementation KBXAccessToken

@synthesize accessToken, accessTokenExpiration, refreshToken;

-(id)initWithAccessToken:(NSString *)theAccessToken accessTokenExpiration:(NSDate *)theAccessTokenExpiration refreshToken:(NSString *)theRefreshToken {
	self = [super init];
	if (self) {
		self.accessToken = theAccessToken;
		self.accessTokenExpiration = theAccessTokenExpiration;
		self.refreshToken = theRefreshToken;
	}
	return self;
}


#pragma mark -
#pragma mark NSCoding Implementation

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.accessToken forKey:@"accessToken"];
    [aCoder encodeObject:self.accessTokenExpiration forKey:@"accessTokenExpiration"];
    [aCoder encodeObject:self.refreshToken forKey:@"refreshToken"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super init])) {
        self.accessToken = [aDecoder decodeObjectForKey:@"accessToken"];
        self.accessTokenExpiration = [aDecoder decodeObjectForKey:@"accessTokenExpiration"];
        self.refreshToken = [aDecoder decodeObjectForKey:@"refreshToken"];
    }
    return self;
}

@end
