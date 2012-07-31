//
//  TestView.h
//
//  Copyright 2012 Kanbox
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//

@interface TestView : UIViewController <UIActionSheetDelegate> {
	UILabel *infoLabel;
	UIButton *loginButton;
	UIBarButtonItem *logoutButton;
	UIBarButtonItem *actionButton;
	
	BOOL loggedIn;
}

@property (assign, getter = isLoggedIn) BOOL loggedIn;

@end
