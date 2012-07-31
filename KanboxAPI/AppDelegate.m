//
//  AppDelegate.m
//
//  Copyright 2012 Kanbox
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//

#import "AppDelegate.h"
#import "TestView.h"
#import "KBXKanboxClient.h"
#import "KanboxAPICredentials.h"

@interface AppDelegate()

@property (nonatomic, strong) UIViewController *mainViewController;

@end

@implementation AppDelegate


@synthesize window=_window;
@synthesize mainViewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	[[KBXKanboxClient sharedClient] setClientID:kKanboxClientID clientSecret:kKanboxClientSecret];
	
	CGRect appFrame = [UIScreen mainScreen].bounds;
	UIWindow *win = [[UIWindow alloc] initWithFrame:appFrame];
	self.window = win;
	
	TestView *testView = [[TestView alloc] init];
	testView.view.frame = appFrame;
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:testView];
	[self.window addSubview:navController.view];
	self.mainViewController = navController;
	
	[self.window makeKeyAndVisible];
	
	
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {

}

- (void)applicationDidEnterBackground:(UIApplication *)application {

}

- (void)applicationWillEnterForeground:(UIApplication *)application {

}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {
	
}


@end
