//
//  LVTwitterOAuthClient.h
//
//  Created by Martín Fernández on 11/8/13.
//  Copyright (c) 2013 Loovin, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ACAccount;

typedef void(^TWOAuthResponseHandler)(NSString * oAuthAccessToken, NSString *oAuthTokenSecret, NSError *error);

typedef enum LVTwitterOAuthClientErrorCode {
    
    LVTwitterOAuthClientErrorAuthorizationFailed = 1,
    LVTwitterOAuthClientErrorGeneric
    
} LVTwitterOAuthClientErrorCode;

extern NSString * const LVTwitterOAuthClientDomain;

@interface LVTwitterOAuthClient : NSObject


- (id) initWithConsumerKey:(NSString *)consumerKey andConsumerSecret:(NSString *)consumerSecret;
- (void)requestTokensForAccount:(ACAccount *)account withHandler:(TWOAuthResponseHandler)handler;
- (void)cancelAllRequests;
@end
