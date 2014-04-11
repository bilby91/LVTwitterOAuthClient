![LVTwitterOAuthClient logo](http://s3.amazonaws.com/loovin/assets/LVTwitterOAuthClient.png "LVTwitterOAuthClient") 

[![License MIT](https://go-shields.herokuapp.com/license-MIT-blue.png)]() [![Cocoapods](https://cocoapod-badges.herokuapp.com/v/LVTwitterOAuthClient/badge.png)](http://beta.cocoapods.org/?q=name%LVTwitterOAuthClient%2A) [![Cocoapods](https://cocoapod-badges.herokuapp.com/p/LVTwitterOAuthClient/badge.png)](http://beta.cocoapods.org/?q=name%LVTwitterOAuthClientw%2A)[![Build Status](https://travis-ci.org/loovin/LVTwitterOAuthClient.svg?branch=master)](https://travis-ci.org/loovin/LVTwitterOAuthClient)

**LVTwitterOAuthClient** is a super simple client for performing Twitter's reverse auth and retrieving user's access token, just that.

## Usage

Initialise an `LVTwitterOAuthClient` with this initialiser:

	LVTwitterOAuthClient * client = [[LVTwitterOAuthClient alloc] initWithConsumerKey:@"YourConsumerKey" andConsumerSecret:@"YourConsumerSecret"];

For retrieving the tokens do this:

    [client requestTokensForAccount:twitterAccount completionBlock:^(NSDictionary *oAuthResponse, NSError *error) {  
		NSString oAuthToken = [oAuthResponse objectForKey: kLVOAuthAccessTokenKey];  
		NSString oAuthSecret = [oAuthResponse objectForKey: kLVOAuthTokenSecretKey];  
		// Start using twitter api :)   
	}]; 

If your are using iOS 6 you need to set the accountType of the account before requesting the tokens, this is a strange behaviour, probably a bug in the SDK.

Source: [StackOverflow](http://stackoverflow.com/questions/13349187/strange-behaviour-when-trying-to-use-twitter-acaccount)

	ACAccountStore *accountStore = [[ACAccountStore alloc] init];
	ACAccountType *twitterAccountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    NSArray *twitterAccounts = [accountStore accountsWithAccountType:twitterAccountType];
    
    [accountStore requestAccessToAccountsWithType:twitterAccountType options:NULL completion:^(BOOL granted, NSError *error) {
        if (granted) {
            ACAccount *twitterAccount = [twitterAccounts firstObject];
            // Here.
            twitterAccount.accountType = twitterAccountType;

            [client requestTokensForAccount:twitterAccount completionBlock:^(NSDictionary *oAuthResponse, NSError *error) {
					NSString oAuthToken = [oAuthResponse objectForKey: kLVOAuthAccessTokenKey];
					NSString oAuthSecret = [oAuthResponse objectForKey: kLVOAuthTokenSecretKey];
					// Start using twitter api :) 
            }];
		}
	}];

In case you need to cancel any operation, call this method:

	[client cancelAllRequests];

## Contribution

Any kind of contribution is more than welcome! Dropping some tests won't hurt :). 

If you find any bug just submit a pull request. 

Thanks!

## License

Copyright (c) 2013 Loovin  (http://loovin.com/) / hackers@loovin.com

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
