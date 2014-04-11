//
//  LVTwitterOAuthClient.h
//
//  Created by Martín Fernández on 11/8/13.
//  Copyright (c) 2013 Loovin, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ACAccount;

/**
 *  The handler called when requestTokensForAccount:withHandler: is finished.
 *
 *  @param oAuthAccessToken The user's Access Token.
 *  @param oAuthTokenSecret The user's Token Secret.
 *  @param error            A pointer to an error to be set in the event that the operation could not be completed successfully.
 *
 */
typedef void(^TWOAuthResponseHandler)(NSString *oAuthAccessToken, NSString *oAuthTokenSecret, NSError *error) __deprecated;

/**
 *  The block called when requestTokensForAccount:completionBlock: is finished.
 *
 *  @param oAuthResponse    The serialized response from Twitter or nil.
 *  @param error            A pointer to an error set in the event that the operation couldn't be completed successfully.
 */
typedef void (^LVOAuthResponseBlock)(NSDictionary *oAuthResponse, NSError *error);

typedef NS_ENUM(NSUInteger , LVTwitterOAuthClientErrorCode) {
    LVTwitterOAuthClientErrorAuthorizationFailed = 1,
    LVTwitterOAuthClientErrorGeneric
};

FOUNDATION_EXTERN NSString * const kLVOAuthUserIDKey;
FOUNDATION_EXTERN NSString * const kLVOAuthScreenNameKey;
FOUNDATION_EXTERN NSString * const kLVOAuthAccessTokenKey;
FOUNDATION_EXTERN NSString * const kLVOAuthTokenSecretKey;
FOUNDATION_EXTERN NSString * const LVTwitterOAuthClientDomain;

/**
 *  The `LVTwitterOAuthClient` class is one that communicates with twitter API and gets the Access Token & Token Secret. It's very simple to use,
 *  you just need to call one method after proper initialisation.
 */
@interface LVTwitterOAuthClient : NSObject

/**
 *  Initialises an `LVTwitterOAuthClient` with a given consumer key and consumer secret.
 *
 *  @param consumerKey    The consumer key of the registered app.
 *  @param consumerSecret The consumer secret of the registered app.
 *
 *  @return An initialised instance.
 */
- (id)initWithConsumerKey:(NSString *)consumerKey andConsumerSecret:(NSString *)consumerSecret;

/**
 *  Performs reverse auth and retrieves the Access Token & Token Secret.
 *  @note This method is deprecated. Please use -[requestTokensForAccount:withCompletionBlock:] instead.
 *
 *  @param account The ACAccount of the user that needs the tokens.
 *  @param handler The handler that is going to be called after the operation is done.
 */
- (void)requestTokensForAccount:(ACAccount *)account withHandler:(TWOAuthResponseHandler)handler __deprecated;

/**
 *  Performs reverse auth and retrieves the Access Token & Token Secret.
 *
 *  @param account          The ACAccount of the user that needs the tokens.
 *  @param completionBlock  The completionBlock that is going to be called after the operation is done.
 */
- (void)requestTokensForAccount:(ACAccount *)account completionBlock:(LVOAuthResponseBlock)completionBlock;

/**
 *  Cancels all requests that are at the moment on the internal queue.
 */
- (void)cancelAllRequests;

@end
