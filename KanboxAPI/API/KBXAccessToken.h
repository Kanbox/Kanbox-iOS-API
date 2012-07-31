//
//  KBXAccessToken.h
//
//  Copyright 2012 Kanbox
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>


@interface KBXAccessToken : NSObject <NSCoding> {
    NSString *accessToken;
    NSDate *accessTokenExpiration;
    NSString *refreshToken;
}

@property (nonatomic, readonly, copy) NSString *accessToken;
@property (nonatomic, readonly, strong) NSDate *accessTokenExpiration;
@property (nonatomic, readonly, copy) NSString *refreshToken;

-(id)initWithAccessToken:(NSString *)theAccessToken accessTokenExpiration:(NSDate *)theAccessTokenExpiration refreshToken:(NSString *)theRefreshToken;

@end
