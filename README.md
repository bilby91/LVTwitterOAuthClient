# LVTwitterOAuthClient 

LVTwitterOAuthClient is a super simple client for performing Twitter's reverse auth and retrieving user's access token, just that.

## Usage

Initialise an `LVTwitterOAuthClient` with this initialiser:

```objective-c
LVTwitterOAuthClient * client = [[LVTwitterOAuthClient alloc] 
									initWithConsumerKey:@"YourConsumerKey"
									  andConsumerSecret:@"YourConsumerSecret"];
```

For retrieving the tokens do this:
```objective-c
    [client requestTokensForAccount:account withHandler:^(NSString *oAuthAccessToken, 
    													  NSString *oAuthTokenSecret, 
    													  NSError *error) {
       // Start using twitter api :) 
    }];
```

In case you need to cancel any operation, call this method:
````objective-c
[client cancelAllRequests];
````

## Contribution

Any kind of contribution is more than welcome! Dropping some tests won't hurt :). 

If you find any bug just submit a pull request. 

Thanks!

## License

Copyright (c) 2013 Loovin  (http://loovin.com/)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
