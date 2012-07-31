//
//  KBXAuthorizerDelegate.h
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


@class KBXAuthorizer;
@class KBXAccessToken;

@protocol KBXAuthorizerDelegate <NSObject>

@optional

-(void)authorizer:(KBXAuthorizer *)authorizer didGetAccessToken:(KBXAccessToken *)accessToken;
-(void)authorizer:(KBXAuthorizer *)authorizer didRefreshAccessToken:(KBXAccessToken *)accessToken;

-(void)webViewForAuthorizerDidFinishLoad:(KBXAuthorizer *)authorizer;


-(void)authorizer:(KBXAuthorizer *)authorizer failedGettingAccessTokenWithError:(NSError *)error;
//-(void)authorizer:(KBXAuthorizer *)authorizer didRefreshAccessToken:(KBXAccessToken *)accessToken;


@end