//
//  KBXAuthViewController.m
//
//  Copyright 2012 Kanbox
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//

#import "KBXAuthViewController.h"
#import "KBXKanboxClient.h"

@interface KBXAuthViewController () {
@private
    UIWebView *webView;
	UIActivityIndicatorView *activityIndicator;
}

@end

@implementation KBXAuthViewController

@synthesize completionHandler = _completionHandler;
@synthesize failureHandler = _failureHandler;

- (id)init {
    self = [super init];
    if (self) {
		self.navigationItem.title = NSLocalizedString(@"Connect with Kanbox", nil);
		
		UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelTapped:)];
		self.navigationItem.rightBarButtonItem = cancelButton;
    }
    return self;
}

-(void)cancelTapped:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)loadView {
	webView = [[UIWebView alloc] init];
	self.view = webView;
	
	activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	activityIndicator.hidesWhenStopped = YES;
	[self.view addSubview:activityIndicator];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
	[[KBXKanboxClient sharedClient] loginWithWebView:webView completionHandler:self.completionHandler failureHadler:self.failureHandler];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

-(void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	activityIndicator.center = self.view.center;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}



@end
