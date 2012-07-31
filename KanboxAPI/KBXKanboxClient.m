//
//  KBXKanboxClient.m
//
//  Copyright 2012 Kanbox
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//

#import "KBXKanboxClient.h"
#import "KBXAuthorizer.h"
#import "KBXClientCredentials.h"
#import "JSONKit.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "ASINetworkQueue.h"

#define kbxAPIOpsUrl @"https://api.kanbox.com/0/"
#define kbxAPIUploadUrl @"https://api-upload.kanbox.com/0/"

#define kbxAPIOpAccountInfo @"info"
#define kbxAPIOpList @"list"
#define kbxAPIOpDownload @"download"
#define kbxAPIOpUpload @"upload"
#define kbxAPIOpDelete @"delete"
#define kbxAPIOpMove @"move"
#define kbxAPIOpCopy @"copy"
#define kbxAPIOpNewFolder @"create_folder"

#define kbxResponseStatusKey @"status"
#define kbxErrorCodeKey @"errorCode"

#define kAPIOperationKey @"operation"
#define kLocalPathKey @"localPath"
#define kOriginalPathKey @"originalPath"

#define kbxDestinationPathParam @"destination_path"

#define kbxAccountInfoEmailKey @"email"
#define kbxAccountInfoSpaceQuotaKey @"spaceQuota"
#define kbxAccountInfoUsedSpaceKey @"spaceUsed"

#define kbxFileListHashKey @"hash"
#define kbxFileListContentsKey @"contents"



NSString* const KBXKanboxServerErrorDomain = @"KBXKanboxServerErrorDomain";


@interface KBXKanboxClient () {
@private
	KBXAuthorizer *authorizer;
	ASINetworkQueue *mainOperationsQueue;
	ASINetworkQueue *downloadsQueue;
	ASINetworkQueue *uploadsQueue;
}

@property (strong) ASINetworkQueue *mainOperationsQueue;
@property (strong) ASINetworkQueue *downloadsQueue;
@property (strong) ASINetworkQueue *uploadsQueue;

-(id)initWithAuthorizer:(KBXAuthorizer *)authorizer;

@end

@implementation KBXKanboxClient

@synthesize mainOperationsQueue, downloadsQueue, uploadsQueue;

+(KBXKanboxClient *)sharedClient {
    static dispatch_once_t pred;
    static KBXKanboxClient *_sharedClient = nil;
	
    dispatch_once(&pred, ^{ 
		KBXAuthorizer *authorizer = [[KBXAuthorizer alloc] init];
		_sharedClient = [[self alloc] initWithAuthorizer:authorizer];
	});
    return _sharedClient;
}

-(id)initWithAuthorizer:(KBXAuthorizer *)theAuthorizer {
	self = [super init];
	if (self) {
		authorizer = theAuthorizer;
		
		self.mainOperationsQueue = [[ASINetworkQueue alloc] init];
		self.mainOperationsQueue.maxConcurrentOperationCount = 1;
		[self.mainOperationsQueue go];
		
		self.downloadsQueue = [[ASINetworkQueue alloc] init];
		[self.downloadsQueue go];
		
		self.uploadsQueue = [[ASINetworkQueue alloc] init];
		[self.uploadsQueue go];
		
	}
	return self;
}

-(void)setClientID:(NSString *)clientID clientSecret:(NSString *)clientSecret {
	KBXClientCredentials *clientCredentials = [[KBXClientCredentials alloc] initWithClientID:clientID secret:clientSecret];
	authorizer.clientCredentials = clientCredentials;
}

#if TARGET_OS_IPHONE
-(void)loginWithWebView:(UIWebView *)webView completionHandler:(kbxSimpleBlock)completionHandler failureHadler:(kbxErrorHandler)failureHandler {
	[authorizer authorizeWithWebView:webView completionHandler:completionHandler failureHadler:failureHandler];
}
#endif

-(void)unlink {
	[authorizer unlink];
}

-(BOOL)isLoggedIn {
	return authorizer.accessToken != nil;
}

-(NSURL *)urlForAPIOperation:(NSString *)apiOp path:(NSString *)path params:(NSString *)params {
	NSString *baseUrl = nil;
	if ([apiOp isEqualToString:kbxAPIOpUpload])
		baseUrl = kbxAPIUploadUrl;
	else
		baseUrl = kbxAPIOpsUrl;
	
	NSString *urlString = [NSString stringWithFormat:@"%@%@%@", baseUrl, apiOp, path];
	urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	if (params) {
		urlString = [NSString stringWithFormat:@"%@?%@", urlString, params];
	}

	return [NSURL URLWithString:urlString];
}

+(KBXAPIStatus)statusFromDictionary:(NSDictionary *)dictionary {
	static dispatch_once_t pred;
    static  NSDictionary *apiStatusStringMapping = nil;
    dispatch_once(&pred, ^{ 
		apiStatusStringMapping = [[NSDictionary alloc] initWithObjectsAndKeys:
								  [NSNumber numberWithInt:KBXAPIStatusOK], @"ok",
								  [NSNumber numberWithInt:KBXAPIStatusError], @"error",
								  [NSNumber numberWithInt:KBXAPIStatusNoChange], @"nochange",
								  nil];
	});
	
	NSString *statusStr = [dictionary objectForKey:kbxResponseStatusKey];
	if (statusStr == nil) {
		return KBXAPIStatusError;
	}
	
	NSNumber *statusNumber = [apiStatusStringMapping objectForKey:statusStr];
	if (statusNumber == nil)
		return KBXAPIStatusError;
	return (KBXAPIStatus)[statusNumber intValue];
}

+(NSError *)errorFromDictionary:(NSDictionary *)dictionary {
	NSString *errorCode = [dictionary objectForKey:kbxErrorCodeKey];
	NSString *errorDescription = [NSString stringWithFormat:NSLocalizedString(@"Error from Kanbox server: '%@'", nil), errorCode];
	
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  errorDescription, NSLocalizedDescriptionKey,
							  nil];
	NSError *error = [NSError errorWithDomain:KBXKanboxServerErrorDomain code:0 userInfo:userInfo];
	return error;
}


#pragma mark - API Operations

-(void)getAccountInfo:(kbxAccountInfoHandler)handler failureHadler:(kbxErrorHandler)failureHandler {
	NSString *urlString = [NSString stringWithFormat:@"%@%@",
						   kbxAPIOpsUrl, kbxAPIOpAccountInfo];
	NSURL *url = [NSURL URLWithString:urlString];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	__unsafe_unretained ASIHTTPRequest *unretainedRequest = request;
	
	[authorizer addAuthenticatedRequest:request toQueue:self.mainOperationsQueue handler:^{
		NSError *jsonError = nil;
		NSDictionary *dictionary = [[unretainedRequest responseData] objectFromJSONDataWithParseOptions:JKParseOptionStrict error:&jsonError];
		if (jsonError == nil) {
			KBXAPIStatus status = [KBXKanboxClient statusFromDictionary:dictionary];
			if (status == KBXAPIStatusOK) {
				NSString *userEmail = [dictionary objectForKey:kbxAccountInfoEmailKey];
				NSNumber *spaceQuota = [dictionary objectForKey:kbxAccountInfoSpaceQuotaKey];
				NSNumber *usedSpace = [dictionary objectForKey:kbxAccountInfoUsedSpaceKey]; 
				if (handler) {
					handler(userEmail, spaceQuota, usedSpace);
				}
			} else {
				if (failureHandler) {
					failureHandler([KBXKanboxClient errorFromDictionary:dictionary]);
				}
			}
		} else {
			if (failureHandler) {
				failureHandler(jsonError);
			}
		}
	} failureHandler:failureHandler retryBlock:^{
		[[KBXKanboxClient sharedClient] getAccountInfo:handler failureHadler:failureHandler];
	}];
}

-(void)getFileList:(NSString *)folderPath hash:(NSString *)hash completionHandler:(kbxFileListHandler)completionHandler failureHadler:(kbxErrorHandler)failureHandler {
	NSString *urlParams = nil;
	if (hash) {
		urlParams = [NSString stringWithFormat:@"%@=%@", kbxFileListHashKey, hash];
	}
	NSURL *url = [self urlForAPIOperation:kbxAPIOpList path:folderPath params:urlParams];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	__unsafe_unretained ASIHTTPRequest *unretainedRequest = request;
	
	[authorizer addAuthenticatedRequest:request toQueue:self.mainOperationsQueue handler:^{
		NSError *jsonError = nil;
		NSDictionary *dictionary = [[unretainedRequest responseData] objectFromJSONDataWithParseOptions:JKParseOptionStrict error:&jsonError];
		if (jsonError == nil) {
			KBXAPIStatus status = [KBXKanboxClient statusFromDictionary:dictionary];
			switch (status) {
				case KBXAPIStatusOK: {
					NSArray *fileList = [dictionary objectForKey:kbxFileListContentsKey];
					NSString *newHash = [NSString stringWithFormat:@"%@", [dictionary objectForKey:kbxFileListHashKey]];
					if (completionHandler) {
						completionHandler(fileList, newHash);
					}
					break;
				}
				case KBXAPIStatusNoChange: {
					if (completionHandler) {
						completionHandler(nil, hash);
					}
					break;
				}
				default: {
					if (failureHandler) {
						failureHandler([KBXKanboxClient errorFromDictionary:dictionary]);
					}
					break;
				}
			}
		} else {
			if (failureHandler) {
				failureHandler(jsonError);
			}
		}
	} failureHandler:failureHandler retryBlock:^{
		[[KBXKanboxClient sharedClient] getFileList:folderPath hash:hash completionHandler:completionHandler failureHadler:failureHandler];
	}];
}

-(void)downloadPath:(NSString *)path toLocalPath:(NSString *)localPath completionHandler:(kbxSimpleBlock)completionHandler failureHadler:(kbxErrorHandler)failureHandler {
	NSURL *url = [self urlForAPIOperation:kbxAPIOpDownload path:path params:nil];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request setDownloadDestinationPath:localPath];	

	[authorizer addAuthenticatedRequest:request toQueue:self.downloadsQueue handler:completionHandler failureHandler:failureHandler retryBlock:^{
		[[KBXKanboxClient sharedClient] downloadPath:path toLocalPath:localPath completionHandler:completionHandler failureHadler:failureHandler];
	}];
}

-(void)uploadFile:(NSString *)localFilePath	toRemotePath:(NSString *)remotePath completionHandler:(kbxSimpleBlock)completionHandler failureHadler:(kbxErrorHandler)failureHandler {
	NSURL *url = [self urlForAPIOperation:kbxAPIOpUpload path:remotePath params:nil];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setFile:localFilePath forKey:@"file"];
	[authorizer addAuthenticatedRequest:request toQueue:self.uploadsQueue handler:^{
		if (completionHandler)
			completionHandler();
	} failureHandler:failureHandler retryBlock:^{
		[[KBXKanboxClient sharedClient] uploadFile:localFilePath toRemotePath:remotePath completionHandler:completionHandler failureHadler:failureHandler];
	}];
}

-(void)createNewFolder:(NSString *)newFolderPath completionHandler:(kbxSimpleBlock)completionHandler failureHadler:(kbxErrorHandler)failureHandler {
	NSURL *url = [self urlForAPIOperation:kbxAPIOpNewFolder path:newFolderPath params:nil];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	__unsafe_unretained ASIHTTPRequest *unretainedRequest = request;
	
	[authorizer addAuthenticatedRequest:request toQueue:self.mainOperationsQueue handler:^{
		NSError *jsonError = nil;
		NSDictionary *dictionary = [[unretainedRequest responseData] objectFromJSONDataWithParseOptions:JKParseOptionStrict error:&jsonError];
		if (jsonError == nil) {
			if ([KBXKanboxClient statusFromDictionary:dictionary] == KBXAPIStatusOK) {
				if (completionHandler) {
					completionHandler();
				}
			} else {
				if (failureHandler) {
					failureHandler([KBXKanboxClient errorFromDictionary:dictionary]);
				}
			}
		} else {
			if (failureHandler) {
				failureHandler(jsonError);
			}
		}
	} failureHandler:failureHandler retryBlock:^{
		[[KBXKanboxClient sharedClient] createNewFolder:newFolderPath completionHandler:completionHandler failureHadler:failureHandler];
	}];
}

-(void)copyPath:(NSString *)sourcePath toPath:(NSString *)destinationPath completionHandler:(kbxSimpleBlock)completionHandler failureHadler:(kbxErrorHandler)failureHandler {
	
	NSString *urlParams = [NSString stringWithFormat:@"%@=%@", kbxDestinationPathParam, destinationPath];
	NSURL *url = [self urlForAPIOperation:kbxAPIOpCopy path:sourcePath params:urlParams];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	__unsafe_unretained ASIHTTPRequest *unretainedRequest = request;
	
	[authorizer addAuthenticatedRequest:request toQueue:self.mainOperationsQueue handler:^{
		NSError *jsonError = nil;
		NSDictionary *dictionary = [[unretainedRequest responseData] objectFromJSONDataWithParseOptions:JKParseOptionStrict error:&jsonError];
		if (jsonError == nil) {
			if ([KBXKanboxClient statusFromDictionary:dictionary] == KBXAPIStatusOK) {
				if (completionHandler) {
					completionHandler();
				}
			} else {
				if (failureHandler) {
					failureHandler([KBXKanboxClient errorFromDictionary:dictionary]);
				}
			}
		} else {
			if (failureHandler) {
				failureHandler(jsonError);
			}
		}
	} failureHandler:failureHandler retryBlock:^{
		[[KBXKanboxClient sharedClient] copyPath:sourcePath toPath:destinationPath completionHandler:completionHandler failureHadler:failureHandler];
	}];
}

-(void)movePath:(NSString *)sourcePath toPath:(NSString *)destinationPath completionHandler:(kbxSimpleBlock)completionHandler failureHadler:(kbxErrorHandler)failureHandler {
	
	NSString *urlParams = [NSString stringWithFormat:@"%@=%@", kbxDestinationPathParam, destinationPath];
	NSURL *url = [self urlForAPIOperation:kbxAPIOpMove path:sourcePath params:urlParams];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	__unsafe_unretained ASIHTTPRequest *unretainedRequest = request;
	
	[authorizer addAuthenticatedRequest:request toQueue:self.mainOperationsQueue handler:^{
		NSError *jsonError = nil;
		NSDictionary *dictionary = [[unretainedRequest responseData] objectFromJSONDataWithParseOptions:JKParseOptionStrict error:&jsonError];
		if (jsonError == nil) {
			if ([KBXKanboxClient statusFromDictionary:dictionary] == KBXAPIStatusOK) {
				if (completionHandler) {
					completionHandler();
				}
			} else {
				if (failureHandler) {
					failureHandler([KBXKanboxClient errorFromDictionary:dictionary]);
				}
			}
		} else {
			if (failureHandler) {
				failureHandler(jsonError);
			}
		}
	} failureHandler:failureHandler retryBlock:^{
		[[KBXKanboxClient sharedClient] copyPath:sourcePath toPath:destinationPath completionHandler:completionHandler failureHadler:failureHandler];
	}];
}

-(void)deletePath:(NSString *)path completionHandler:(kbxSimpleBlock)completionHandler failureHadler:(kbxErrorHandler)failureHandler {
	NSURL *url = [self urlForAPIOperation:kbxAPIOpDelete path:path params:nil];
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	__unsafe_unretained ASIHTTPRequest *unretainedRequest = request;
	
	[authorizer addAuthenticatedRequest:request toQueue:self.mainOperationsQueue handler:^{
		NSError *jsonError = nil;
		NSDictionary *dictionary = [[unretainedRequest responseData] objectFromJSONDataWithParseOptions:JKParseOptionStrict error:&jsonError];
		if (jsonError == nil) {
			if ([KBXKanboxClient statusFromDictionary:dictionary] == KBXAPIStatusOK) {
				if (completionHandler) {
					completionHandler();
				}
			} else {
				if (failureHandler) {
					failureHandler([KBXKanboxClient errorFromDictionary:dictionary]);
				}
			}
		} else {
			if (failureHandler) {
				failureHandler(jsonError);
			}
		}
	} failureHandler:failureHandler retryBlock:^{
		[[KBXKanboxClient sharedClient] deletePath:path completionHandler:completionHandler failureHadler:failureHandler];
	}];
	
}

@end
