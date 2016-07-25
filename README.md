## chuckpad-social-ios

iOS library that interacts with the [chuckpad-social][1] service.

### Setup
* Add to an existing iOS project as a git submodule with: ```git submodule add git@github.com:markcerqueira/chuckpad-social-ios.git path-to-directory``` Example: ```git submodule add git@github.com:markcerqueira/chuckpad-social-ios.git chuckpad-social-ios-test/chuckpad-social-ios```

* Link with Security.framework in Build Phases (this library [FXKeychain][3] internally to store some sensitive information)

See [chuckpad-social-ios-test][2] for a "Hello, World" project that uses this library.

[1]: https://github.com/markcerqueira/chuckpad-social
[2]: https://github.com/markcerqueira/chuckpad-social-ios-test
[3]: https://github.com/nicklockwood/FXKeychain
