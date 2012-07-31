//
//  KBXAuthorizer.h
//
//  Copyright 2012 Kanbox
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//

#import "KBXTypes.h"

@class KBXClientCredentials;
@class KBXAccessToken;
@class ASIHTTPRequest;
@class ASINetworkQueue;

typedef enum {
    KBXAuthorizerParsingAccessTokenErrorType = 1,
	KBXAuthorizerParsingAuthorizationCodeErrorType = 2
} KBXAuthorizerErrorType;

typedef void(^kbxAccessTokenHandler)(KBXAccessToken *accessToken);


@interface KBXAuthorizer : NSObject <
#if TARGET_OS_IPHONE
UIWebViewDelegate
#endif
>

@property (nonatomic, strong) KBXClientCredentials *clientCredentials;
@property (nonatomic, strong) KBXAccessToken *accessToken;

#if TARGET_OS_IPHONE
-(void)authorizeWithWebView:(UIWebView *)webView completionHandler:(kbxSimpleBlock)completionHandler failureHadler:(kbxErrorHandler)failureHandler;
#endif

-(void)unlink;

-(void)addAuthenticatedRequest:(ASIHTTPRequest *)request toQueue:(ASINetworkQueue *)queue handler:(kbxSimpleBlock)handler failureHandler:(kbxErrorHandler)failureHandler retryBlock:(kbxSimpleBlock)retryBlock;

@end
