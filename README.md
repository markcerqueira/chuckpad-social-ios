## chuckpad-social-ios

iOS library that interacts with the [chuckpad-social][1] service.

### Setup
* Add to an existing iOS project as a git submodule with: ```git submodule add git@github.com:markcerqueira/chuckpad-social-ios.git path-to-directory``` Example: ```git submodule add git@github.com:markcerqueira/chuckpad-social-ios.git hello-chuckpad/chuckpad-social-ios```.
* Add the chuckpad-social-ios folder into your Xcode project. Note that if you update this submodule to a newer version there may be new files added so remember to add those to your project if you are getting compilation errors after pulling. 
* Link with Security.framework in Build Phases; this library uses [FXKeychain][3] internally to store some information and FXLibrary requires the Security framework.

### Related Repositories
* [hello-chuckpad][2] is a "Hello, World" project that uses this library with a suite of unit tests to verify the interactions between this iOS library and the server. 
* [chuckpad-social][1] is the server that this client-side library interacts with. 
* [miniAudicle][5] will be the first "go-to market" product that uses the chuckpad-social service and this library. 

### Libraries Used
* [FXKeychain][3]
* [NSDate+Helper][4]

[1]: https://github.com/markcerqueira/chuckpad-social
[2]: https://github.com/markcerqueira/hello-chuckpad
[3]: https://github.com/nicklockwood/FXKeychain
[4]: https://github.com/billymeltdown/nsdate-helper/wiki
[5]: https://github.com/ccrma/miniAudicle
