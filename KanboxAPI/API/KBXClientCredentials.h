//
//  KBXClientCredentials.h
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

@interface KBXClientCredentials : NSObject <NSCoding> {
    NSString *clientID;
    NSString *clientSecret;
}

@property (nonatomic, copy) NSString *clientID;
@property (nonatomic, copy) NSString *clientSecret;

-(id)initWithClientID:(NSString *)theID secret:(NSString *)theSecret;

@end
