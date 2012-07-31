Kanbox iOS API
==============

Requirements
-------
* Xcode 4.4 or greater.
* This project uses ARC, so deployment is supported for iOS 4.0 or greater.

Adding Kanbox API to your project
---------
1. Import all files from the API folder.
2. If you don't have them in your project already, import **ASIHTTPRequest**, **Reachability** and **JSONKit** frameworks. Make sure they are not using ARC by adding the `-fno-objc-arc` Compiler Flag in the Compile Sources pane of the Build Phases tab of the project settings.
3. In your app delegate, in `-application:didFinishLaunchingWithOptions:` setup the Kanbox client with your supplied Client ID and Client Secret, like this:

```objc
	[[KBXKanboxClient sharedClient] setClientID:@"my_client_id" clientSecret:@"my_client_secret"];
```

Getting your Client ID and Client Secret
-----------
Please register your application at http://open.kanbox.com/.

Using the API Client
----------
* The API client is a singleton object, referenced as `[KBXKanboxClient sharedClient]`.
* You will need to check if the user is logged in to Kanbox, using `[KBXKanboxClient sharedClient].isLoggedIn`.
* If not logged in, you will need to display a `KBXAuthViewController` login view. See `-loginTapped:` in [TestView.m](https://github.com/Kanbox/Kanbox-iOS-API/blob/master/KanboxAPI/TestView.m) for an example.
* See [TestView.m](https://github.com/Kanbox/Kanbox-iOS-API/blob/master/KanboxAPI/TestView.m) for examples of using the different functions of the API.
