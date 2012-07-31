//
//  KBXKanboxClient.h
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

@class KBXAuthorizer;

typedef enum {
	KBXAPIStatusOK = 0,
	
	KBXAPIStatusError = 1,
	KBXAPIStatusNoChange = 2,
} KBXAPIStatus;

@interface KBXKanboxClient : NSObject

+(KBXKanboxClient *)sharedClient;

-(void)setClientID:(NSString *)clientID clientSecret:(NSString *)clientSecret;

@property (nonatomic, readonly) BOOL isLoggedIn;

#if TARGET_OS_IPHONE

-(void)loginWithWebView:(UIWebView *)webView completionHandler:(kbxSimpleBlock)completionHandler failureHadler:(kbxErrorHandler)failureHandler;

#endif

-(void)unlink;

-(void)getAccountInfo:(kbxAccountInfoHandler)handler failureHadler:(kbxErrorHandler)failureHandler;

-(void)downloadPath:(NSString *)remotePath toLocalPath:(NSString *)localPath completionHandler:(kbxSimpleBlock)completionHandler failureHadler:(kbxErrorHandler)failureHandler;

-(void)uploadFile:(NSString *)localPath	toRemotePath:(NSString *)remotePath completionHandler:(kbxSimpleBlock)completionHandler failureHadler:(kbxErrorHandler)failureHandler;

//-(void)uploadData:(NSData *)fileData toRemotePath:(NSString *)remotePath completionHandler:(kbxSimpleBlock)completionHandler failureHadler:(kbxErrorHandler)failureHandler;

-(void)getFileList:(NSString *)folderPath hash:(NSString *)hash completionHandler:(kbxFileListHandler)completionHandler failureHadler:(kbxErrorHandler)failureHandler;

-(void)copyPath:(NSString *)sourcePath toPath:(NSString *)destinationPath completionHandler:(kbxSimpleBlock)completionHandler failureHadler:(kbxErrorHandler)failureHandler;

-(void)movePath:(NSString *)sourcePath toPath:(NSString *)destinationPath completionHandler:(kbxSimpleBlock)completionHandler failureHadler:(kbxErrorHandler)failureHandler;

-(void)createNewFolder:(NSString *)newFolderPath completionHandler:(kbxSimpleBlock)completionHandler failureHadler:(kbxErrorHandler)failureHandler;

-(void)deletePath:(NSString *)path completionHandler:(kbxSimpleBlock)completionHandler failureHadler:(kbxErrorHandler)failureHandler;

@end
