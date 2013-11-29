//
//  LVTwitterOAuthClient.m
//
//  Created by Martín Fernández on 11/8/13.
//  Copyright (c) 2013 Loovin, Inc. All rights reserved.
//

#import "LVTwitterOAuthClient.h"
#import "OAuthCore.h"
#import <Social/Social.h>



#define TW_API_ROOT                  @"https://api.twitter.com"
#define TW_X_AUTH_MODE_KEY           @"x_auth_mode"
#define TW_X_AUTH_MODE_REVERSE_AUTH  @"reverse_auth"
#define TW_X_AUTH_MODE_CLIENT_AUTH   @"client_auth"
#define TW_X_AUTH_REVERSE_PARMS      @"x_reverse_auth_parameters"
#define TW_X_AUTH_REVERSE_TARGET     @"x_reverse_auth_target"
#define TW_OAUTH_URL_REQUEST_TOKEN   TW_API_ROOT "/oauth/request_token"
#define TW_OAUTH_URL_AUTH_TOKEN      TW_API_ROOT "/oauth/access_token"
#define TW_HTTP_HEADER_AUTHORIZATION @"Authorization"

#define REQUEST_TIMEOUT_INTERVAL 15


NSString * const LVTwitterOAuthClientDomain = @"com.loovin.twitterOAuthClient";


@class ACAccount;

typedef void(^TWOAuthHandler)(NSData *data, NSError *error);


NSString * const kOAuthAccessTokenKey = @"oauth_access_token";
NSString * const kOAuthTokenSecretKey = @"oauth_token_secret";

@interface LVTwitterOAuthClient()

@property (nonatomic, copy)     NSString            *consumerKey;
@property (nonatomic, copy)     NSString            *consumerSecret;
@property (nonatomic, copy)     NSString            *oAuthAccessToken;
@property (nonatomic, copy)     NSString            *oAuthTokenSecret;
@property (nonatomic, strong)   NSURLConnection     *connection;
@property (nonatomic, strong)   NSOperationQueue    *queue;

@end

@implementation LVTwitterOAuthClient


@synthesize consumerKey         = _consumerKey;
@synthesize consumerSecret      = _consumerSecret;
@synthesize oAuthAccessToken    = _oAuthAccessToken;
@synthesize oAuthTokenSecret    = _oAuthTokenSecret;
@synthesize connection          = _connection;
@synthesize queue               = _queue;



-(id)init
{
    self = [super init];
    
    if (self) {
        _queue = [[NSOperationQueue alloc] init];
    }
    
    return self;
}

-(id)initWithConsumerKey:(NSString *)consumerKey andConsumerSecret:(NSString *)consumerSecret
{
    self = [super init];
    
    if (self) {
        
        _queue          = [[NSOperationQueue alloc] init];
        _consumerKey    = consumerKey;
        _consumerSecret = consumerSecret;
    }
    
    return self;
}

-(void)requestTokensForAccount:(ACAccount *)account withHandler:(TWOAuthResponseHandler)handler
{
    [self _step1WithCompletion:^(NSData *data, NSError *error) {
        
        if (error) {
            handler(nil,nil,error);
            return;
        }
        
        if (!data) {
            handler(nil,nil,[NSError errorWithDomain:LVTwitterOAuthClientDomain code:LVTwitterOAuthClientErrorGeneric userInfo:nil]);
            return;
        }
        
        NSString *signedReverseAuthSignature = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [self _step2WithAccount:account signature:signedReverseAuthSignature andHandler:^(NSData *data, NSError *error) {
            
            if (error) {
                handler(nil,nil,error);
            }
            NSDictionary *parsedResponse = [self parseOAuthData:data];
            if (parsedResponse[kOAuthAccessTokenKey] && parsedResponse[kOAuthTokenSecretKey]) {
                
                self.oAuthAccessToken = parsedResponse[kOAuthAccessTokenKey];
                self.oAuthTokenSecret = parsedResponse[kOAuthTokenSecretKey];
                
                handler(_oAuthAccessToken,_oAuthTokenSecret,nil);
            } else {
                handler(nil,nil,[NSError errorWithDomain:LVTwitterOAuthClientDomain code:LVTwitterOAuthClientErrorAuthorizationFailed userInfo:nil]);
            }
        }];
    }];
}

# pragma mark - Private API

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
    
    NSDictionary *params = @{
                             TW_X_AUTH_REVERSE_TARGET: _consumerKey,
                             TW_X_AUTH_REVERSE_PARMS: signedReverseAuthSignature
                             };
    
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
        NSString *token     = [[[tmp objectAtIndex:0] componentsSeparatedByString:@"="] lastObject];
        NSString *secret    = [[[tmp objectAtIndex:1] componentsSeparatedByString:@"="] lastObject];
        return @{
                 kOAuthAccessTokenKey   : token,
                 kOAuthTokenSecretKey   : secret
                 };
    } @catch(NSException *) {
        return nil;
    }
}

- (void)cancelAllRequests
{
    [_queue cancelAllOperations];
}


@end
