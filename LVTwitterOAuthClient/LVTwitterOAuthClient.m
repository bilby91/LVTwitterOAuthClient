//
//  LVTwitterOAuthClient.m
//
//  Created by Martín Fernández on 11/8/13.
//  Copyright (c) 2013 Loovin, Inc. All rights reserved.
//

#import <Social/Social.h>
#import <OAuthCore/OAuthCore.h>
#import "LVTwitterOAuthClient.h"

#define TW_API_ROOT                  @"https://api.twitter.com"
#define TW_X_AUTH_MODE_KEY           @"x_auth_mode"
#define TW_X_AUTH_MODE_REVERSE_AUTH  @"reverse_auth"
#define TW_X_AUTH_REVERSE_PARMS      @"x_reverse_auth_parameters"
#define TW_X_AUTH_REVERSE_TARGET     @"x_reverse_auth_target"
#define TW_OAUTH_URL_REQUEST_TOKEN   TW_API_ROOT "/oauth/request_token"
#define TW_OAUTH_URL_AUTH_TOKEN      TW_API_ROOT "/oauth/access_token"
#define TW_HTTP_HEADER_AUTHORIZATION @"Authorization"
//#define TW_X_AUTH_MODE_CLIENT_AUTH   @"client_auth" -> never used

#define REQUEST_TIMEOUT_INTERVAL 15

NSString * const kLVOAuthUserIDKey          = @"user_id";
NSString * const kLVOAuthScreenNameKey      = @"screen_name";
NSString * const kLVOAuthAccessTokenKey     = @"oauth_token";
NSString * const kLVOAuthTokenSecretKey     = @"oauth_token_secret";
NSString * const LVTwitterOAuthClientDomain = @"com.loovin.twitterOAuthClient";

@class ACAccount;

typedef void(^TWOAuthHandler)(NSData *data, NSError *error);

@interface LVTwitterOAuthClient()

@property (nonatomic, strong)   NSOperationQueue    *queue;
@property (nonatomic, copy)     NSString            *consumerKey;
@property (nonatomic, copy)     NSString            *consumerSecret;

@end

@implementation LVTwitterOAuthClient

#pragma mark - Public APIs -

- (id)init
{
    self = [super init];
    if (self) {
        _queue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (id)initWithConsumerKey:(NSString *)consumerKey andConsumerSecret:(NSString *)consumerSecret
{
    self = [super init];
    if (self) {
        _queue          = [[NSOperationQueue alloc] init];
        _consumerKey    = [consumerKey copy];
        _consumerSecret = [consumerSecret copy];

    }
    return self;
}

- (void)requestTokensForAccount:(ACAccount *)account withHandler:(TWOAuthResponseHandler)handler
{
    [self requestTokensForAccount:account completionBlock:^(NSDictionary *oAuthResponse, NSError *error) {
	    if (handler) {
		    handler(oAuthResponse[kLVOAuthAccessTokenKey], oAuthResponse[kLVOAuthTokenSecretKey], error);
	    }
    }];
}

- (void)requestTokensForAccount:(ACAccount *)account completionBlock:(LVOAuthResponseBlock)completionBlock
{
	[self _step1WithCompletion:^(NSData *data, NSError *error) {
		if (error) {
			completionBlock(nil, error);
			return;
		}

		if (!data) {
			completionBlock(nil, [NSError errorWithDomain:LVTwitterOAuthClientDomain
			                                         code:LVTwitterOAuthClientErrorGeneric
				                                 userInfo:nil]);
			return;
		}

		NSString *signedReverseAuthSignature = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		[self _step2WithAccount:account signature:signedReverseAuthSignature andHandler:^(NSData *oAuthData, NSError *theError) {
			if (theError) {
				completionBlock(nil, theError);
			}
			else {
				NSDictionary *parsedResponse = [self parseOAuthData:oAuthData];
				if (parsedResponse) {
					completionBlock(parsedResponse, theError);
				}
				else {
					completionBlock(nil, [NSError errorWithDomain:LVTwitterOAuthClientDomain
					                                         code:LVTwitterOAuthClientErrorAuthorizationFailed
						                                 userInfo:nil]);
				}
			}
		}];
	}];
}

# pragma mark - Private APIs -

- (void)_step1WithCompletion:(TWOAuthHandler)completion
{
    NSURL *url = [NSURL URLWithString:TW_OAUTH_URL_REQUEST_TOKEN];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    [self prepareAuthorizedRequest:request withURL:url];

    [NSURLConnection sendAsynchronousRequest:request queue:_queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        completion(data,connectionError);
    }];
}

- (void)_step2WithAccount:(ACAccount *)account signature:(NSString *)signedReverseAuthSignature andHandler:(TWOAuthHandler)completion
{
    NSParameterAssert(account);
    NSParameterAssert(signedReverseAuthSignature);

    NSDictionary *params = @{TW_X_AUTH_REVERSE_TARGET: _consumerKey,
                             TW_X_AUTH_REVERSE_PARMS: signedReverseAuthSignature};

    NSURL *authTokenURL = [NSURL URLWithString:TW_OAUTH_URL_AUTH_TOKEN];

    SLRequest *request =[SLRequest requestForServiceType:SLServiceTypeTwitter
                                           requestMethod:SLRequestMethodPOST
                                                     URL:authTokenURL
                                              parameters:params];

    [request setAccount:account];

    [NSURLConnection sendAsynchronousRequest:request.preparedURLRequest queue:_queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        completion(data, connectionError);
    }];
}

- (void)prepareAuthorizedRequest:(NSMutableURLRequest *)request withURL:(NSURL *)url
{
    NSDictionary *params = @{ TW_X_AUTH_MODE_KEY: TW_X_AUTH_MODE_REVERSE_AUTH };

    NSMutableString *paramsAsString = [[NSMutableString alloc] init];

    [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [paramsAsString appendFormat:@"%@=%@&", key, obj];
    }];

    NSData *bodyData                = [paramsAsString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *authorizationHeader   = OAuthorizationHeader(url, @"POST", bodyData, _consumerKey, _consumerSecret, nil, nil);

    request.HTTPMethod      = @"POST";
    request.HTTPBody        = bodyData;
    request.timeoutInterval = REQUEST_TIMEOUT_INTERVAL;

    [request setValue:authorizationHeader forHTTPHeaderField:TW_HTTP_HEADER_AUTHORIZATION];
}

- (NSDictionary *)parseOAuthData:(NSData *)data
{
    @try {
      NSString *response  = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
      NSArray  *tmp       = [response componentsSeparatedByString:@"&"];
	    NSMutableDictionary *parsedOAuthData = [NSMutableDictionary dictionaryWithCapacity:tmp.count];

	    for (NSString *parameter in tmp) {
		    NSArray *parameterComponents = [parameter componentsSeparatedByString:@"="];
		    NSString *value = [parameterComponents lastObject];
		    NSString *key = [parameterComponents firstObject];

		    if (key && value) {
			    [parsedOAuthData setObject:value forKey:key];
		    }
	    }

	    return [parsedOAuthData copy];
    }
    @catch(NSException *) {
        return nil;
    }
}

- (void)cancelAllRequests
{
    [_queue cancelAllOperations];
}

@end
