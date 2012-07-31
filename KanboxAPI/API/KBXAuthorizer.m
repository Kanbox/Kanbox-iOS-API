//
//  KBXAuthorizer.m
//  KanboxAPI
//
//  Created by Jonathan Hemi on 4/12/11.
//  Copyright 2011 none. All rights reserved.
//

#import "KBXAuthorizer.h"
#import "KBXClientCredentials.h"
#import "NSURL+QueryStringParams.h"
#import "KBXAccessToken.h"
#import "JSONKit.h"
#import "NSDictionary+EncodeURLParams.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "ASIFormDataRequest.h"

NSString* const KBXAuthorizerErrorDomain = @"KBXAuthorizerErrorDomain";

// How long before an Access Token expires to request a new one (in seconds)
#define kAccessTokenExpirationBufferTimeInterval 10

#define kbxAuthUrlBase @"https://auth.kanbox.com/0/"
#define kbxAuthAuthenticationEndpoint @"auth"
#define kbxAuthTokenEndpoint @"token"
#define kbxAuthCodeQueryStringParam @"code"
#define kbxOOBUri @"urn:ietf:wg:oauth:2.0:oob"

#define kbxAuthJSONAccessTokenKey @"access_token"
#define kbxAuthJSONAccessTokenExpirationKey @"expires_in"
#define kbxAuthJSONRefreshTokenKey @"refresh_token"
#define kbxAuthJSONErrorKey @"error"

#define kOAuth2BearerToken @"Bearer"
#define kOAuth2AuthorizationHTTPHeader @"Authorization"
#define kHTTPUnauthorizedStatusCode 401

#define kKanboxAccessTokenDefaultsKey @"kanboxAccessToken"

@interface KBXAuthorizer () {
@private
	ASINetworkQueue *accessTokenQueue;
}

-(void)handleAuthCodeFromCallbackURL:(NSURL *)callbackURL;
-(NSURLRequest *)authCodeRequest;

-(ASIHTTPRequest *)accessTokenRequest:(NSString *)authCode;

-(void)parseAccessToken:(NSDictionary *)jsonResult;

@property (copy) kbxSimpleBlock webAuthorizationCompletionHandler;
@property (copy) kbxErrorHandler webAuthorizationFailureHandler;

@property (nonatomic, strong) KBXAccessToken *userDefaultsAccessToken;


@end

@implementation KBXAuthorizer

@synthesize accessToken = _accessToken, clientCredentials = _clientCredentials;
@synthesize webAuthorizationCompletionHandler = _webAuthorizationCompletionHandler, webAuthorizationFailureHandler = _webAuthorizationFailureHandler;

-(id)init {
	self = [super init];
	if (self) {
		accessTokenQueue = [[ASINetworkQueue alloc] init];
		accessTokenQueue.maxConcurrentOperationCount = 1;
		accessTokenQueue.shouldCancelAllRequestsOnFailure = NO;
		[accessTokenQueue go];
		
		self.accessToken = self.userDefaultsAccessToken;
	}
	return self;
}

-(void)dealloc {
	[accessTokenQueue cancelAllOperations];
}

-(KBXAccessToken *)userDefaultsAccessToken {
	NSData *accessTokenData = [[NSUserDefaults standardUserDefaults] objectForKey:kKanboxAccessTokenDefaultsKey];
	if (accessTokenData == nil) {
		return nil;
	}
	KBXAccessToken *token = [NSKeyedUnarchiver unarchiveObjectWithData:accessTokenData];
	return token;
}

-(void)setUserDefaultsAccessToken:(KBXAccessToken *)value {
	NSData *accessTokenData = [NSKeyedArchiver archivedDataWithRootObject:value];
	[[NSUserDefaults standardUserDefaults] setObject:accessTokenData forKey:kKanboxAccessTokenDefaultsKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Access Token

-(ASIHTTPRequest *)accessTokenRequest:(NSString *)authCode {
    NSString *urlString = [NSString stringWithFormat:@"%@%@", kbxAuthUrlBase, kbxAuthTokenEndpoint];
	NSURL *url = [NSURL URLWithString:urlString];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setPostValue:@"authorization_code" forKey:@"grant_type"];
	[request setPostValue:self.clientCredentials.clientID forKey:@"client_id"];
	[request setPostValue:self.clientCredentials.clientSecret forKey:@"client_secret"];
	[request setPostValue:kbxOOBUri forKey:@"redirect_uri"];
	[request setPostValue:authCode forKey:@"code"];
	
    return request;
}

#pragma mark Authorization Code

-(NSURLRequest *)authCodeRequest {
    NSString *url = [NSString stringWithFormat:@"%@%@?response_type=code&client_id=%@&redirect_uri=%@",
                     kbxAuthUrlBase, kbxAuthAuthenticationEndpoint, [self.clientCredentials.clientID stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], kbxOOBUri];
	NSLog(@"authCodeRequest returning request for url '%@'", url);
    return [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
}

-(void)finishAuthorization:(BOOL)successful error:(NSError *)error {
	if (successful) {
		if (self.webAuthorizationCompletionHandler) {
			self.webAuthorizationCompletionHandler();
		}
	} else {
		if (self.webAuthorizationFailureHandler) {
			self.webAuthorizationFailureHandler(error);
		}
	}
	self.webAuthorizationCompletionHandler = nil;
	self.webAuthorizationFailureHandler = nil;
}

-(void)authorizeWithWebView:(UIWebView *)webView completionHandler:(kbxSimpleBlock)completionHandler failureHadler:(kbxErrorHandler)failureHandler {
	self.webAuthorizationCompletionHandler = completionHandler;
	self.webAuthorizationFailureHandler = failureHandler;
	
	NSURLRequest *request = [self authCodeRequest];
    webView.delegate = self;
    [webView loadRequest:request];
}

-(void)unlink {
	self.accessToken = nil;
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:kKanboxAccessTokenDefaultsKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)handleAuthCodeFromCallbackURL:(NSURL *)callbackURL {
	NSDictionary *queryParams = [callbackURL queryStringParams];
	NSString *authCode = [queryParams objectForKey:kbxAuthCodeQueryStringParam];
	if (authCode == nil) {
		NSError *parsingError = [NSError errorWithDomain:KBXAuthorizerErrorDomain code:KBXAuthorizerParsingAccessTokenErrorType userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to parse Auth Code", nil), NSLocalizedDescriptionKey, nil]];
		[self finishAuthorization:NO error:parsingError];
		return;
	}
	
	ASIHTTPRequest *request = [self accessTokenRequest:authCode];
	if (request == nil) {
		NSError *parsingError = [NSError errorWithDomain:KBXAuthorizerErrorDomain code:KBXAuthorizerParsingAccessTokenErrorType userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to request Access Token", nil), NSLocalizedDescriptionKey, nil]];
		[self finishAuthorization:NO error:parsingError];
		return;
	}
	
	__unsafe_unretained ASIHTTPRequest *unretainedRequest = request;
	[request setCompletionBlock:^{
		NSError *error = nil;
		NSDictionary *dict = [[unretainedRequest responseData] objectFromJSONDataWithParseOptions:JKParseOptionStrict error:&error];
		if (!error) {		
			[self parseAccessToken:dict];
		} else {
			[self finishAuthorization:NO error:error];
		}
	}];
	[request setFailedBlock:^{
		NSError *error = [unretainedRequest error];
		[self finishAuthorization:NO error:error];
	}];
	[accessTokenQueue addOperation:request];
}

#pragma mark Access Token

-(void)parseAccessToken:(NSDictionary *)jsonResult {
	NSString *errorStr = [jsonResult objectForKey:kbxAuthJSONErrorKey];
	if (errorStr != nil) {
		NSError *parsingError = [NSError errorWithDomain:KBXAuthorizerErrorDomain code:KBXAuthorizerParsingAccessTokenErrorType userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Could not verify account", nil), NSLocalizedDescriptionKey, errorStr, NSLocalizedFailureReasonErrorKey, nil]];
		[self finishAuthorization:NO error:parsingError];
		return;
	}
	
	NSString *accessTokenStr = [jsonResult objectForKey:kbxAuthJSONAccessTokenKey];
	if (accessTokenStr == nil) {
		NSError *parsingError = [NSError errorWithDomain:KBXAuthorizerErrorDomain code:KBXAuthorizerParsingAccessTokenErrorType userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to parse Access Token JSON data", nil), NSLocalizedDescriptionKey, nil]];
		[self finishAuthorization:NO error:parsingError];
		return;
	}
	NSTimeInterval accessTokenExpiresIn = (NSTimeInterval)[[jsonResult objectForKey:kbxAuthJSONAccessTokenExpirationKey] intValue];
    NSDate *accessTokenExpiration = [NSDate dateWithTimeIntervalSinceNow:accessTokenExpiresIn];
	NSString *refreshToken = [jsonResult objectForKey:kbxAuthJSONRefreshTokenKey];
	
	KBXAccessToken *token = [[KBXAccessToken alloc] initWithAccessToken:accessTokenStr accessTokenExpiration:accessTokenExpiration refreshToken:refreshToken];
	self.accessToken = token;
	self.userDefaultsAccessToken = token;

	//NSLog(@"Got new Access Token :: %@", token);
	[self finishAuthorization:YES error:nil];
}


#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {  
	if ([[request.URL absoluteString] hasPrefix:kbxOOBUri]) {
		[self handleAuthCodeFromCallbackURL:request.URL];
		return NO;
	} else {
		//NSLog(@"### Loading URL :: %@", request.URL);
		return YES;
	}
}

-(void)parseAccessToken:(NSDictionary *)jsonResult handler:(kbxAccessTokenHandler)handler failureHandler:(kbxErrorHandler)failureHandler {
	NSString *errorStr = [jsonResult objectForKey:kbxAuthJSONErrorKey];
	if (errorStr != nil) {
		if (failureHandler) {
			NSError *parsingError = [NSError errorWithDomain:KBXAuthorizerErrorDomain code:KBXAuthorizerParsingAccessTokenErrorType userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Could not verify account", nil), NSLocalizedDescriptionKey, errorStr, NSLocalizedFailureReasonErrorKey, nil]];
			failureHandler(parsingError);
		}
		return;
	}
	
	NSString *accessTokenStr = [jsonResult objectForKey:kbxAuthJSONAccessTokenKey];
	if (accessTokenStr == nil) {
		if (failureHandler) {
			NSError *parsingError = [NSError errorWithDomain:KBXAuthorizerErrorDomain code:KBXAuthorizerParsingAccessTokenErrorType userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Unable to parse Access Token JSON data", nil), NSLocalizedDescriptionKey, nil]];
			failureHandler(parsingError);
		}
		return;
	}
	NSTimeInterval accessTokenExpiresIn = (NSTimeInterval)[[jsonResult objectForKey:kbxAuthJSONAccessTokenExpirationKey] intValue];
    NSDate *accessTokenExpiration = [NSDate dateWithTimeIntervalSinceNow:accessTokenExpiresIn];
	NSString *refreshToken = [jsonResult objectForKey:kbxAuthJSONRefreshTokenKey];
	
	KBXAccessToken *token = [[KBXAccessToken alloc] initWithAccessToken:accessTokenStr accessTokenExpiration:accessTokenExpiration refreshToken:refreshToken];
	self.accessToken = token;
	self.userDefaultsAccessToken = token;
	
	if (handler) {
		handler(token);
	}
}

#pragma mark - Refreshing Tokens

-(ASIHTTPRequest *)refreshAccessTokenRequest {
	NSString *urlString = [NSString stringWithFormat:@"%@%@", kbxAuthUrlBase, kbxAuthTokenEndpoint];
	NSURL *url = [NSURL URLWithString:urlString];
	ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:url];
	[request setPostValue:@"refresh_token" forKey:@"grant_type"];
	[request setPostValue:self.clientCredentials.clientID forKey:@"client_id"];
	[request setPostValue:self.clientCredentials.clientSecret forKey:@"client_secret"];
	[request setPostValue:kbxOOBUri forKey:@"redirect_uri"];
	[request setPostValue:self.accessToken.refreshToken forKey:@"refresh_token"];	
    return request;
}

-(void)refreshAccessTokenWithRetryBlock:(kbxSimpleBlock)retryBlock failureHandler:(kbxErrorHandler)failureHandler {
	//NSLog(@"Requesting new access token, current token == %@", accessToken);
	ASIHTTPRequest *request = [self refreshAccessTokenRequest];
	__unsafe_unretained ASIHTTPRequest *unretainedRequest = request;
	[request setCompletionBlock:^{
		NSError *error = nil;
		NSDictionary *response = [[unretainedRequest responseData] objectFromJSONDataWithParseOptions:JKParseOptionStrict error:&error];
		if (!error) {
			[self parseAccessToken:response handler:^(KBXAccessToken *newToken) {
				if (retryBlock) {
					retryBlock();
				}
			} failureHandler:failureHandler];
		} else {
			//NSLog(@"Error parsing response '%@' :: %@", [unretainedRequest responseString], error);
			if (failureHandler) {
				failureHandler(error);
			}
		}
	}];
	[request setFailedBlock:^{
		//NSLog(@"Error refreshing access token : %@", [unretainedRequest error]);
		if (failureHandler)
			failureHandler([unretainedRequest error]);
	}];
	[accessTokenQueue addOperation:request];
}


-(void)addRequest:(ASIHTTPRequest *)request toQueue:(ASINetworkQueue *)queue handler:(kbxSimpleBlock)handler failureHandler:(kbxErrorHandler)failureHandler retryBlock:(kbxSimpleBlock)retryBlock {
	__unsafe_unretained ASIHTTPRequest *unretainedRequest = request;
	NSString *authorizationHeader = [NSString stringWithFormat:@"%@ %@", kOAuth2BearerToken, self.accessToken.accessToken];
	[request addRequestHeader:kOAuth2AuthorizationHTTPHeader value:authorizationHeader];
	[request setCompletionBlock:handler];
	[request setFailedBlock:^{
		switch ([unretainedRequest responseStatusCode]) {
			case 401:	// 401 Unauthorized - get a new access token
				//NSLog(@"Got HTTP 401 result, refreshing access token");
				[self refreshAccessTokenWithRetryBlock:retryBlock failureHandler:failureHandler];
				break;
			default:
				failureHandler([unretainedRequest error]);
				break;
		}
	}];
	[queue addOperation:request];
}

-(void)addAuthenticatedRequest:(ASIHTTPRequest *)request toQueue:(ASINetworkQueue *)queue handler:(kbxSimpleBlock)handler failureHandler:(kbxErrorHandler)failureHandler retryBlock:(kbxSimpleBlock)retryBlock {
	if ([self.accessToken.accessTokenExpiration timeIntervalSinceNow] < kAccessTokenExpirationBufferTimeInterval) {
		[self refreshAccessTokenWithRetryBlock:retryBlock failureHandler:failureHandler];
	} else {
		// Access token is not expired, go ahead and use it
		[self addRequest:request toQueue:queue handler:handler failureHandler:failureHandler retryBlock:retryBlock];
	}

}

@end
