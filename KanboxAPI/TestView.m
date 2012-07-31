//
//  TestView.m
//
//  Copyright 2012 Kanbox
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//

#import "TestView.h"
#import "KBXAuthorizer.h"
#import "KBXKanboxClient.h"
#import "KBXAuthViewController.h"
#import "KBXClientCredentials.h"
#import "KBXAccessToken.h"

#define kKanboxAccessTokenSettingKey @"KanboxAccessToken"

typedef enum {
	kActionFileListIndex,
	kActionUploadIndex,
	kActionDownloadIndex,
	kActionCopyIndex,
	kActionMoveIndex,
	kActionDeleteIndex,
	kActionNewFolderIndex,
} testActions;

@interface TestView () <UINavigationControllerDelegate, UIImagePickerControllerDelegate> {
@private
	NSString *rootFileListHash;
}

@end


@implementation TestView

-(id)init {
	self = [super init];
	if (self) {
		self.navigationItem.title = NSLocalizedString(@"Kanbox API Demo", nil);
		logoutButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Logout", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(logoutTapped:)];
		actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionTapped:)];
	}
	return self;
}


-(BOOL)isLoggedIn {
	return loggedIn;
}

-(void)setLoggedIn:(BOOL)val {
	if (val == loggedIn)
		return;
	loggedIn = val;

	loginButton.hidden = loggedIn;
	infoLabel.hidden = !loggedIn;
	[self.navigationItem setRightBarButtonItem:((loggedIn) ? logoutButton : nil) animated:YES];
	[self.navigationItem setLeftBarButtonItem:((loggedIn) ? actionButton : nil) animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)loadView {
	CGRect appFrame = [UIScreen mainScreen].bounds;
	UIView *contentView = [[UIView alloc] initWithFrame:appFrame];
	contentView.backgroundColor = [UIColor whiteColor];
	
	loginButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[loginButton setTitle:NSLocalizedString(@"Connect with Kanbox", nil) forState:UIControlStateNormal];
	loginButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
	loginButton.frame = CGRectMake(0, 0, 200, 35);
	loginButton.center = contentView.center;
	[loginButton addTarget:self action:@selector(loginTapped:) forControlEvents:UIControlEventTouchUpInside];
	
	infoLabel = [[UILabel alloc] initWithFrame:CGRectInset(appFrame, 10, 10)];
	infoLabel.lineBreakMode = UILineBreakModeWordWrap;
	infoLabel.numberOfLines = 0;
	
	[contentView addSubview:infoLabel];
	[contentView addSubview:loginButton];

	
	self.view = contentView;
}

-(void)loginTapped:(id)sender {
	KBXAuthViewController *authVC = [[KBXAuthViewController alloc] init];
	authVC.completionHandler = ^{
		[self dismissModalViewControllerAnimated:YES];
		self.loggedIn = YES;
		[self loadKanboxAccountInfo];
	};
	
	authVC.failureHandler = ^(NSError *error) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Could not connect with Kanbox", nil) message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
		[alert show];
	};
	
	UINavigationController *authNavC = [[UINavigationController alloc] initWithRootViewController:authVC];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		authNavC.modalPresentationStyle = UIModalPresentationFormSheet;
	}
	[self presentModalViewController:authNavC animated:YES];
}

-(void)logoutTapped:(id)sender {
	rootFileListHash = nil;
	[[KBXKanboxClient sharedClient] unlink];
	self.loggedIn = NO;
}

-(void)actionTapped:(id)sender {
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Actions" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:
								  @"File List",
								  @"Upload",
								  @"Download",
								  @"Copy",
								  @"Move",
								  @"Delete",
								  @"New Folder",
								  nil];
	[actionSheet showFromBarButtonItem:sender animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	switch (buttonIndex) {
		case kActionFileListIndex: {
			[[KBXKanboxClient sharedClient] getFileList:@"/" hash:rootFileListHash completionHandler:^(NSArray *fileList, NSString *hash) {
				NSLog(@"## file list :: %@", fileList);
				NSString *msg = ([hash isEqualToString:rootFileListHash]) ? @"No new files since last time" :  [NSString stringWithFormat:@"%d items", fileList.count];
				rootFileListHash = hash;
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Succussfully got file list" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			} failureHadler:^(NSError *error) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could not get file list" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			}];
			break;
		}
		case kActionCopyIndex: {
			[[KBXKanboxClient sharedClient] copyPath:@"/test.jpg" toPath:@"/test2.jpg" completionHandler:^{
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Succussfully copied file" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			} failureHadler:^(NSError *error) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could not copy file" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			}];
			break;
		}
		case kActionMoveIndex: {
			[[KBXKanboxClient sharedClient] movePath:@"/test2.jpg" toPath:@"/test3.jpg" completionHandler:^{
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Succussfully moved file" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			} failureHadler:^(NSError *error) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could not move file" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			}];
			break;
		}
		case kActionDeleteIndex: {
			[[KBXKanboxClient sharedClient] deletePath:@"/test3.jpg" completionHandler:^{
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Succussfully deleted file" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			} failureHadler:^(NSError *error) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could not delete file" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			}];
			break;
		}
		case kActionNewFolderIndex: {
			[[KBXKanboxClient sharedClient] createNewFolder:@"/newfolder1" completionHandler:^{
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Succussfully created folder" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			} failureHadler:^(NSError *error) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could not create new folder" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			}];
			break;
		}
		case kActionUploadIndex: {
			UIImagePickerController *picker = [[UIImagePickerController alloc] init];
			picker.delegate = self;
			[self presentModalViewController:picker animated:YES];
			break;
		}
		case kActionDownloadIndex: {
			NSString *downloadPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"downloaded_image.jpg"];
			[[KBXKanboxClient sharedClient] downloadPath:@"/test.jpg" toLocalPath:downloadPath completionHandler:^{
				NSLog(@"file saved to: %@", downloadPath);
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"File downloaded successfully!" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			} failureHadler:^(NSError *error) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could not download" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			}];
			break;
		}
	}
}

-(void)loadKanboxAccountInfo {
	[[KBXKanboxClient sharedClient] getAccountInfo:^(NSString *userEmail, NSNumber *spaceQuota, NSNumber *usedSpace) {
		unsigned long long spaceQuotaValue = [spaceQuota unsignedLongLongValue];
		unsigned long long usedSpaceValue = [usedSpace unsignedLongLongValue];
		float percentUsed = (float)usedSpaceValue / (float)spaceQuotaValue * 100.0f;
		
		NSString *displayString = [NSString stringWithFormat:NSLocalizedString(@"Email: %@\nUsed Space: %llu bytes (%.02f%% of available space)", @"Account Info Format String"),
								   userEmail, usedSpaceValue, percentUsed];
		infoLabel.text = displayString;
	} failureHadler:^(NSError *error) {
		infoLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Failed to get Kanbox account info with error: %@", @"Account Info Error Format String"), error];
	}];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	if ([KBXKanboxClient sharedClient].isLoggedIn) {
		self.loggedIn = YES;
		[self loadKanboxAccountInfo];
	} else {
		self.loggedIn = NO;
	}
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	[self dismissModalViewControllerAnimated:YES];
	
	UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
	NSString *imagePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"image_to_upload.jpg"];
	[UIImageJPEGRepresentation(image, 0.5) writeToFile:imagePath atomically:YES];
	
	[[KBXKanboxClient sharedClient] uploadFile:imagePath toRemotePath:@"/test.jpg" completionHandler:^{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Image uploaded successfully!" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
	} failureHadler:^(NSError *error) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could not upload" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
	}];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[self dismissModalViewControllerAnimated:YES];
}


@end
