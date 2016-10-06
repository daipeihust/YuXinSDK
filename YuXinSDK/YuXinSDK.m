//
//  YuXinSDK.m
//  YuXinSDK
//
//  Created by Dai Pei on 16/6/24.
//  Copyright © 2016年 Dai Pei. All rights reserved.
//

#import "YuXinSDK.h"
#import "YuXinXmlParser.h"
#import "iconv.h"

static NSString *URL_LOGIN                  = @"http://dian.hust.edu.cn:81/bbslogin";
static NSString *URL_LOGOUT                 = @"http://dian.hust.edu.cn:81/bbslogout";
static NSString *URL_SUBBOARD               = @"http://dian.hust.edu.cn:81/bbsboa";
static NSString *URL_FAVOURITES             = @"http://dian.hust.edu.cn:81/bbsbrd";
static NSString *URL_ADD_FAVOURITES_BOARD   = @"http://dian.hust.edu.cn:81/bbsbrdadd";
static NSString *URL_DEL_FAVOURITES_BOARD   = @"http://dian.hust.edu.cn:81/bbsbrddel";
static NSString *URL_ARTICLES               = @"http://dian.hust.edu.cn:81/bbsnewtdoc";
static NSString *URL_ARTICLE                = @"http://dian.hust.edu.cn:81/bbsnewtcon";
static NSString *URL_ARTICLE_ONE            = @"http://dian.hust.edu.cn:81/bbscon";
static NSString *URL_POST_ARTICLE           = @"http://dian.hust.edu.cn:81/bbssnd";
static NSString *URL_DEL_ARTICLE            = @"http://dian.hust.edu.cn:81/bbsdel";
static NSString *URL_USER_DETAIL            = @"http://dian.hust.edu.cn:81/bbsqry";
static NSString *URL_MAILS                  = @"http://dian.hust.edu.cn:81/bbsmail";
static NSString *URL_MAIL_DETAIL            = @"http://dian.hust.edu.cn:81/bbsmailcon";
static NSString *URL_POST_MAIL              = @"http://dian.hust.edu.cn:81/bbssndmail";
static NSString *URL_DEL_MAIL               = @"http://dian.hust.edu.cn:81/bbsdelmail";
static NSString *URL_NEW_MAIL               = @"http://dian.hust.edu.cn:81/bbsgetmsg";
static NSString *URL_FRIENDS                = @"http://dian.hust.edu.cn:81/bbsfall";
static NSString *URL_ADD_FRIEND             = @"http://dian.hust.edu.cn:81/bbsfadd";
static NSString *URL_DEL_FRIEND             = @"http://dian.hust.edu.cn:81/bbsfdel";
static NSString *URL_GET_BOARD_POST_POWER   = @"http://dian.hust.edu.cn:81/bbspst";
static NSString *URL_REPRINT                = @"http://dian.hust.edu.cn:81/bbsccc";

static const NSInteger maxRequestCount = 2;
static const NSTimeInterval requestTimeOut = 5;

@interface YuXinSDK()

@property (nonatomic, copy) NSString *cookies;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;

@end

@implementation YuXinSDK

#pragma mark - Init

+ (instancetype)sharedInstance {
    static YuXinSDK *instance = nil;
    static dispatch_once_t onceTocken;
    dispatch_once(&onceTocken, ^{
        instance = [[YuXinSDK alloc] init];
        instance.logLevel = DPLogLevelSimple;
    });
    return instance;
}

#pragma mark - Public Method

- (void)loginWithUsername:(NSString *)username password:(NSString *)password completion:(CompletionHandler)handler {
    
    NSString *bodyStr = [NSString stringWithFormat:@"xml=1&pw=%@&id=%@", [self percentEscapesString:password], username];
    NSData *bodyData = [bodyStr dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableURLRequest *request = [self createRequestWithUrl:[URL_LOGIN copy] query:nil method:@"POST" cookie:nil body:bodyData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *loginTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (!error) {
            weakSelf.username = username;
            weakSelf.password = password;
            NSData *convertedData = [weakSelf cleanGB2312:data];
            NSData *refinedData = [weakSelf refineTheData:convertedData];
            YuXinXmlParser *parser = [[YuXinXmlParser alloc] initWithParserType:YuXinXmlParserTypeLogin parserData:refinedData];
            [parser startParserWithCompletion:^(NSArray *models, NSString *error) {
                [weakSelf makeLogWithError:error modelsCount:0 requestInfo:[NSString stringWithFormat:@"login"] logLevel:DPLogLevelSimple];
                if (!error) {
                    YuXinLoginInfo *loginInfo = models[0];
                    weakSelf.cookies = [NSString stringWithFormat:@"utmpkey=%@;contdays=%@;utmpuserid=%@;utmpnum=%@;invisible=%@;version=1", loginInfo.utmpKey, loginInfo.contdays, loginInfo.utmpUserID, loginInfo.utmpNum, loginInfo.invisible];
                    if (handler) {
                        handler(nil, [models copy]);
                    }
                }else {
                    if (handler) {
                        handler(error, nil);
                    }
                }
            }];
        }else {
            [weakSelf makeLogWithError:error.localizedDescription modelsCount:0 requestInfo:@"login" logLevel:DPLogLevelSimple];
            if (handler) {
                handler(error.localizedDescription, nil);
            }
        }
    }];
    [loginTask resume];
}

- (void)logoutWithCompletion:(CompletionHandler)handler {
    NSMutableURLRequest *request = [self createRequestWithUrl:URL_LOGOUT query:@"?xml=1" method:@"GET" cookie:self.cookies body:nil];
    
    NSURLSession *session = [NSURLSession sharedSession];
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *logoutTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [weakSelf makeLogWithError:error.localizedDescription modelsCount:0 requestInfo:@"logout" logLevel:DPLogLevelSimple];
        if (!error) {
            weakSelf.cookies = nil;
            if (handler) {
                handler(nil, nil);
            }
        }else {
            if (handler) {
                handler(error.localizedDescription, nil);
            }
        }
    }];
    [logoutTask resume];
}

- (void)fetchFavourateBoardWithCompletion:(CompletionHandler)handler {
    [self fetchFavourateBoardWithRequestCount:1 completion:handler];
    
}

- (void)queryUserInfoWithUserID:(NSString *)userID completion:(CompletionHandler)handler {
    NSString *queryStr = [NSString stringWithFormat:@"?userid=%@&xml=1", userID];
    NSMutableURLRequest *request = [self createRequestWithUrl:URL_USER_DETAIL query:queryStr method:@"GET" cookie:self.cookies body:nil];
    
    NSURLSession *session = [NSURLSession sharedSession];
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *queryTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            NSData *convertedData = [weakSelf cleanGB2312:data];
            NSData *refinedData = [weakSelf refineTheData:convertedData];
            YuXinXmlParser *parser = [[YuXinXmlParser alloc] initWithParserType:YuXinXmlParserTypeUserDetail parserData:refinedData];
            [parser startParserWithCompletion:^(NSArray *models, NSString *error) {
                
                [weakSelf makeLogWithError:error modelsCount:[models count] requestInfo:@"user info" logLevel:DPLogLevelSimple];
                if (handler) {
                    handler(error, [models copy]);
                }
            }];
        }else {
            [weakSelf makeLogWithError:error.localizedDescription modelsCount:1 requestInfo:@"user info" logLevel:DPLogLevelSimple];
            if (handler) {
                handler(error.localizedDescription, nil);
            }
        }
    }];
    [queryTask resume];
}

- (void)fetchFriendListWithCompletion:(CompletionHandler)handler {
    [self fetchFriendListWithRequestCount:1 completion:handler];
}

- (void)fetchArticleTitleListWithBoard:(NSString *)boardName start:(NSNumber *)startNum completion:(CompletionHandler)handler {
    [self fetchArticleTitleListWithBoard:boardName start:startNum requestCount:1 completion:handler];
}

- (void)fetchSubboard:(YuXinBoardType)boardType completion:(CompletionHandler)handler {
    [self fetchSubboard:boardType requestCount:1 completion:handler];
}

- (void)addFavourateBoard:(NSString *)boardName completion:(CompletionHandler)handler {
    [self addFavourateBoard:boardName requestCount:1 completion:handler];
}

- (void)delFavourateBoard:(NSString *)boardName completion:(CompletionHandler)handler {
    NSString *queryStr = [NSString stringWithFormat:@"?board=%@&xml=1", boardName];
    NSMutableURLRequest *request = [self createRequestWithUrl:URL_DEL_FAVOURITES_BOARD query:queryStr method:@"GET" cookie:self.cookies body:nil];
    
    NSURLSession *session = [NSURLSession sharedSession];
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *delTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [weakSelf makeLogWithError:error.localizedDescription modelsCount:0 requestInfo:[NSString stringWithFormat:@"delete %@ board", boardName] logLevel:DPLogLevelSimple];
        if (handler) {
            handler(error.localizedDescription, nil);
        }
    }];
    [delTask resume];
}

- (void)fetchArticlesWithBoard:(NSString *)boardName file:(NSString *)fileName completion:(CompletionHandler)handler{
    [self fetchArticlesWithBoard:boardName file:fileName requestCount:1 completion:handler];
}

- (void)postArticleWithContent:(NSString *)content title:(NSString *)title board:(NSString *)boardName canReply:(BOOL)canReply userID:(NSString *)userID completion:(CompletionHandler)handler {
    [self postArticleWithContent:content title:title board:boardName canReply:canReply userID:userID requestCount:1 completion:handler];
}

- (void)commentArticle:(NSString *)articleName content:(NSString *)content board:(NSString *)boardName canReply:(BOOL)canReply file:(NSString *)fileName completion:(CompletionHandler)handler {
    [self commentArticle:articleName content:content board:boardName canReply:canReply file:fileName requestCount:1 completion:handler];
}

- (void)deleteArticleWithBoard:(NSString *)boardName file:(NSString *)fileName completion:(CompletionHandler)handler{
    [self deleteArticleWithBoard:boardName file:fileName requestCount:1 completion:handler];
}

- (void)reprintArticleWithFile:(NSString *)fileName from:(NSString *)originBoard to:(NSString *)targetBoard completion:(CompletionHandler)handler {
    [self reprintArticleWithFile:fileName from:originBoard to:targetBoard requestCount:1 completion:handler];
}

#pragma mark - Privite Method

- (void)fetchFavourateBoardWithRequestCount:(NSUInteger)requestCount completion:(CompletionHandler)handler {
    NSString *queryStr = @"?xml=1";
    NSMutableURLRequest *request = [self createRequestWithUrl:URL_FAVOURITES query:queryStr method:@"GET" cookie:self.cookies body:nil];
    
    NSURLSession *session = [NSURLSession sharedSession];
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *fetchTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            NSData *convertedData = [weakSelf cleanGB2312:data];
            NSData *refinedData = [weakSelf refineTheData:convertedData];
            YuXinXmlParser *parser = [[YuXinXmlParser alloc] initWithParserType:YuXinXmlParserTypeFavourites parserData:refinedData];
            [parser startParserWithCompletion:^(NSArray *models, NSString *error) {
                if (error && requestCount < maxRequestCount && weakSelf.username && weakSelf.password) {
                    [weakSelf loginAgainWithCompletion:^(NSString *error, NSArray *responseModels) {
                        [weakSelf fetchFavourateBoardWithRequestCount:requestCount + 1 completion:handler];
                    }];
                    return ;
                }
                [weakSelf makeLogWithError:error modelsCount:[models count] requestInfo:@"favourate board" logLevel:DPLogLevelSimple];
                if (handler) {
                    handler(error, [models copy]);
                }
            }];
        }else {
            [weakSelf makeLogWithError:error.localizedDescription modelsCount:1 requestInfo:@"favourate board" logLevel:DPLogLevelSimple];
            if (handler) {
                handler(error.localizedDescription, nil);
            }
        }
    }];
    [fetchTask resume];
}

- (void)fetchFriendListWithRequestCount:(NSUInteger)requestCount completion:(CompletionHandler)handler {
    NSMutableURLRequest *request = [self createRequestWithUrl:URL_FRIENDS query:@"?xml=1" method:@"GET" cookie:self.cookies body:nil];
    
    NSURLSession *session = [NSURLSession sharedSession];
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *fetchTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            NSData *convertedData = [weakSelf cleanGB2312:data];
            NSData *refinedData = [weakSelf refineTheData:convertedData];
            YuXinXmlParser *parser = [[YuXinXmlParser alloc] initWithParserType:YuXinXmlParserTypeFriends parserData:refinedData];
            [parser startParserWithCompletion:^(NSArray *models, NSString *error) {
                if (error && requestCount < maxRequestCount && weakSelf.username && weakSelf.password) {
                    [weakSelf loginAgainWithCompletion:^(NSString *error, NSArray *responseModels) {
                        [weakSelf fetchFriendListWithRequestCount:requestCount + 1 completion:handler];
                    }];
                    return ;
                }
                [weakSelf makeLogWithError:error modelsCount:[models count] requestInfo:@"friends info" logLevel:DPLogLevelSimple];
                if (handler) {
                    handler(error, [models copy]);
                }
            }];
        }else {
            [weakSelf makeLogWithError:error.localizedDescription modelsCount:1 requestInfo:@"friend info" logLevel:DPLogLevelSimple];
            if (handler) {
                handler(error.localizedDescription, nil);
            }
        }
    }];
    [fetchTask resume];
}

- (void)fetchArticleTitleListWithBoard:(NSString *)boardName start:(NSNumber *)startNum requestCount:(NSUInteger)requestCount completion:(CompletionHandler)handler {
    
    NSString *queryStr = [NSString stringWithFormat:@"?board=%@&xml=1&start=%@&summary=1", boardName, startNum];
    NSMutableURLRequest *request = [self createRequestWithUrl:URL_ARTICLES query:queryStr method:@"GET" cookie:self.cookies body:nil];
    
    NSURLSession *session = [NSURLSession sharedSession];
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *fetchTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            NSData *convertedData = [weakSelf cleanGB2312:data];
            NSData *refinedData = [weakSelf refineTheData:convertedData];
            YuXinXmlParser *parser = [[YuXinXmlParser alloc] initWithParserType:YuXinXmlParserTypeArticles parserData:refinedData];
            [parser startParserWithCompletion:^(NSArray *models, NSString *error) {
                if (error && requestCount < maxRequestCount && weakSelf.username && weakSelf.password) {
                    [weakSelf loginAgainWithCompletion:^(NSString *error, NSArray *responseModels) {
                        [weakSelf fetchArticleTitleListWithBoard:boardName start:startNum requestCount:requestCount + 1 completion:handler];
                    }];
                    return ;
                }
                [weakSelf makeLogWithError:error modelsCount:[models count] requestInfo:@"article titles" logLevel:DPLogLevelSimple];
                if (handler) {
                    handler(error, [models copy]);
                }
            }];
        }else {
            [weakSelf makeLogWithError:error.localizedDescription modelsCount:1 requestInfo:@"article titles" logLevel:DPLogLevelSimple];
            if (handler) {
                handler(error.localizedDescription, nil);
            }
        }
    }];
    
    [fetchTask resume];
}

- (void)fetchSubboard:(YuXinBoardType)boardType requestCount:(NSUInteger)requestCount completion:(CompletionHandler)handler {
    NSString *queryStr = [NSString stringWithFormat:@"?%ld=1&xml=1", (long)boardType];
    
    NSMutableURLRequest *request = [self createRequestWithUrl:URL_SUBBOARD query:queryStr method:@"GET" cookie:self.cookies body:nil];
    
    NSURLSession *session = [NSURLSession sharedSession];
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *fetchTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            NSData *convertedData = [weakSelf cleanGB2312:data];
            NSData *refinedData = [weakSelf refineTheData:convertedData];
            YuXinXmlParser *parser = [[YuXinXmlParser alloc] initWithParserType:YuXinXmlParserTypeSubboard parserData:refinedData];
            [parser startParserWithCompletion:^(NSArray *models, NSString *error) {
                if (error && requestCount < maxRequestCount && weakSelf.username && weakSelf.password) {
                    [weakSelf loginAgainWithCompletion:^(NSString *error, NSArray *responseModels) {
                        [weakSelf fetchSubboard:boardType requestCount:requestCount + 1 completion:handler];
                    }];
                    return ;
                }
                [weakSelf makeLogWithError:error modelsCount:[models count] requestInfo:@"subboard" logLevel:DPLogLevelSimple];
                if (handler) {
                    handler(error, [models copy]);
                }
            }];
        }else {
            [weakSelf makeLogWithError:error.localizedDescription modelsCount:1 requestInfo:@"subboard" logLevel:DPLogLevelSimple];
            if (handler) {
                handler(error.localizedDescription, nil);
            }
        }
    }];
    
    [fetchTask resume];
}

- (void)addFavourateBoard:(NSString *)boardName requestCount:(NSUInteger)requestCount completion:(CompletionHandler)handler {
    NSString *queryStr = [NSString stringWithFormat:@"?board=%@&xml=1", boardName];
    NSMutableURLRequest *request = [self createRequestWithUrl:URL_ADD_FAVOURITES_BOARD query:queryStr method:@"GET" cookie:self.cookies body:nil];
    
    NSURLSession *session = [NSURLSession sharedSession];
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *addTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            NSData *convertedData = [weakSelf cleanGB2312:data];
            NSData *refinedData = [weakSelf refineTheData:convertedData];
            YuXinXmlParser *parser = [[YuXinXmlParser alloc] initWithParserType:YuXinXmlParserTypeAddFavouritesBoard parserData:refinedData];
            [parser startParserWithCompletion:^(NSArray *models, NSString *error) {
                if (error && requestCount < maxRequestCount && weakSelf.username && weakSelf.password) {
                    [weakSelf loginAgainWithCompletion:^(NSString *error, NSArray *responseModels) {
                        [weakSelf addFavourateBoard:boardName requestCount:requestCount + 1 completion:handler];
                    }];
                    return ;
                }
                [weakSelf makeLogWithError:error modelsCount:0 requestInfo:[NSString stringWithFormat:@"add %@ board", boardName] logLevel:DPLogLevelSimple];
                if (handler) {
                    handler(error, models);
                }
            }];
        }else {
            [weakSelf makeLogWithError:error.localizedDescription modelsCount:0 requestInfo:[NSString stringWithFormat:@"add %@ board", boardName] logLevel:DPLogLevelSimple];
            if (handler) {
                handler(error.localizedDescription, nil);
            }
        }
    }];
    [addTask resume];
}

- (void)fetchArticlesWithBoard:(NSString *)boardName file:(NSString *)fileName requestCount:(NSUInteger)requestCount completion:(CompletionHandler)handler{
    NSString *queryStr = [NSString stringWithFormat:@"?board=%@&file=%@&xml=1", boardName, fileName];
    NSMutableURLRequest *request = [self createRequestWithUrl:URL_ARTICLE query:queryStr method:@"GET" cookie:self.cookies body:nil];
    
    NSURLSession *session = [NSURLSession sharedSession];
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *fetchTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            NSData *convertedData = [weakSelf cleanGB2312:data];
            NSData *refinedData = [weakSelf refineTheData:convertedData];
            YuXinXmlParser *parser = [[YuXinXmlParser alloc] initWithParserType:YuXinXmlParserTypeArticle parserData:refinedData];
            [parser startParserWithCompletion:^(NSArray *models, NSString *error) {
                if (error && requestCount < maxRequestCount && weakSelf.username && weakSelf.password) {
                    [weakSelf loginAgainWithCompletion:^(NSString *error, NSArray *responseModels) {
                        [weakSelf fetchArticlesWithBoard:boardName file:fileName requestCount:requestCount + 1 completion:handler];
                    }];
                    return ;
                }
                [weakSelf makeLogWithError:error modelsCount:[models count] requestInfo:@"articles" logLevel:DPLogLevelSimple];
                if (handler) {
                    handler(error, models);
                }
            }];
        }else {
            [weakSelf makeLogWithError:error.localizedDescription modelsCount:1 requestInfo:@"articles" logLevel:DPLogLevelSimple];
            if (handler) {
                handler(error.localizedDescription, nil);
            }
        }
    }];
    [fetchTask resume];
}

- (void)postArticleWithContent:(NSString *)content title:(NSString *)title board:(NSString *)boardName canReply:(BOOL)canReply userID:(NSString *)userID requestCount:(NSUInteger)requestCount completion:(CompletionHandler)handler {
    NSString *bodyStr;
    bodyStr = [NSString stringWithFormat:@"text=%@&title=%@&xml=1&board=%@&signature=1&nore=%@&userid=%@&", [self percentEscapesString:content encoding:kCFStringEncodingGB_18030_2000], [self percentEscapesString:title encoding:kCFStringEncodingGB_18030_2000], boardName, canReply? @"off" : @"on", userID];
    NSStringEncoding gb2312 = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSData *bodyData = [bodyStr dataUsingEncoding:gb2312];
    NSMutableURLRequest *request = [self createRequestWithUrl:URL_POST_ARTICLE query:nil method:@"POST" cookie:self.cookies body:bodyData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *postTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            NSData *convertedData = [weakSelf cleanGB2312:data];
            NSData *refinedData = [weakSelf refineTheData:convertedData];
            YuXinXmlParser *parser = [[YuXinXmlParser alloc] initWithParserType:YuXinXmlParserTypePostArticle parserData:refinedData];
            [parser startParserWithCompletion:^(NSArray *models, NSString *error) {
                if (error && requestCount < maxRequestCount && weakSelf.username && weakSelf.password) {
                    [weakSelf loginAgainWithCompletion:^(NSString *error, NSArray *responseModels) {
                        [weakSelf postArticleWithContent:content title:title board:boardName canReply:canReply userID:userID requestCount:requestCount + 1 completion:handler];
                    }];
                    return ;
                }
                [weakSelf makeLogWithError:error modelsCount:0 requestInfo:@"post a article" logLevel:DPLogLevelSimple];
                if (handler) {
                    handler(error, models);
                }
            }];
        }else {
            [weakSelf makeLogWithError:error.localizedDescription modelsCount:0 requestInfo:@"post a article" logLevel:DPLogLevelSimple];
            if (handler) {
                handler(error.localizedDescription, nil);
            }
        }
    }];
    [postTask resume];
}

- (void)commentArticle:(NSString *)articleName content:(NSString *)content board:(NSString *)boardName canReply:(BOOL)canReply file:(NSString *)fileName requestCount:(NSUInteger)requestCount completion:(CompletionHandler)handler {
    NSString *bodyStr= [NSString stringWithFormat:@"text=%@&title=Re: %@&xml=1&board=%@&signature=1&nore=%@&file=%@&", [self percentEscapesString:content encoding:kCFStringEncodingGB_18030_2000], [self percentEscapesString:articleName encoding:kCFStringEncodingGB_18030_2000], boardName, canReply? @"off" : @"on", fileName];
    NSStringEncoding gb2312 = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSData *bodyData = [bodyStr dataUsingEncoding:gb2312];
    NSMutableURLRequest *request = [self createRequestWithUrl:URL_POST_ARTICLE query:nil method:@"POST" cookie:self.cookies body:bodyData];
    
    NSURLSession *session = [NSURLSession sharedSession];
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *commentTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            NSData *convertedData = [weakSelf cleanGB2312:data];
            NSData *refinedData = [weakSelf refineTheData:convertedData];
            YuXinXmlParser *parser = [[YuXinXmlParser alloc] initWithParserType:YuXinXmlParserTypePostArticle parserData:refinedData];
            [parser startParserWithCompletion:^(NSArray *models, NSString *error) {
                if (error && requestCount < maxRequestCount && weakSelf.username && weakSelf.password) {
                    [weakSelf loginAgainWithCompletion:^(NSString *error, NSArray *responseModels) {
                        [weakSelf commentArticle:articleName content:content board:boardName canReply:canReply file:fileName requestCount:requestCount + 1 completion:handler];
                    }];
                    return ;
                }
                [weakSelf makeLogWithError:error modelsCount:0 requestInfo:@"comment" logLevel:DPLogLevelSimple];
                if (handler) {
                    handler(error, models);
                }
            }];
        }else {
            [weakSelf makeLogWithError:error.localizedDescription modelsCount:0 requestInfo:@"comment" logLevel:DPLogLevelSimple];
            if (handler) {
                handler(error.localizedDescription, nil);
            }
        }
    }];
    [commentTask resume];
}

- (void)deleteArticleWithBoard:(NSString *)boardName file:(NSString *)fileName requestCount:(NSUInteger)requestCount completion:(CompletionHandler)handler{
    NSString *queryStr = [NSString stringWithFormat:@"?board=%@&file=%@&xml=1", boardName, fileName];
    NSMutableURLRequest *request = [self createRequestWithUrl:URL_DEL_ARTICLE query:queryStr method:@"POST" cookie:self.cookies body:nil];
    
    NSURLSession *session = [NSURLSession sharedSession];
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *deleteTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            NSData *convertedData = [weakSelf cleanGB2312:data];
            NSData *refinedData = [weakSelf refineTheData:convertedData];
            YuXinXmlParser *parser = [[YuXinXmlParser alloc] initWithParserType:YuXinXmlParserTypeDelArticle parserData:refinedData];
            [parser startParserWithCompletion:^(NSArray *models, NSString *error) {
                if (error && requestCount < maxRequestCount && weakSelf.username && weakSelf.password) {
                    [weakSelf loginAgainWithCompletion:^(NSString *error, NSArray *responseModels) {
                        [weakSelf deleteArticleWithBoard:boardName file:fileName requestCount:requestCount + 1 completion:handler];
                    }];
                    return ;
                }
                [weakSelf makeLogWithError:error modelsCount:0 requestInfo:@"delete article" logLevel:DPLogLevelSimple];
                if (handler) {
                    handler(error, models);
                }
            }];
        }else {
            [weakSelf makeLogWithError:error.localizedDescription modelsCount:0 requestInfo:@"delete article" logLevel:DPLogLevelSimple];
            if (handler) {
                handler(error.localizedDescription, nil);
            }
        }
    }];
    [deleteTask resume];
}

- (void)reprintArticleWithFile:(NSString *)fileName from:(NSString *)originBoard to:(NSString *)targetBoard requestCount:(NSUInteger)requestCount completion:(CompletionHandler)handler {
    NSString *queryStr = [NSString stringWithFormat:@"?board=%@&file=%@&target=%@&xml=1", originBoard, fileName, targetBoard];
    NSMutableURLRequest *request = [self createRequestWithUrl:URL_REPRINT query:queryStr method:@"GET" cookie:self.cookies body:nil];
    
    NSURLSession *session = [NSURLSession sharedSession];
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *reprintTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            NSData *convertedData = [weakSelf cleanGB2312:data];
            NSData *refinedData = [weakSelf refineTheData:convertedData];
            YuXinXmlParser *parser = [[YuXinXmlParser alloc] initWithParserType:YuXinXmlParserTypeDelArticle parserData:refinedData];
            [parser startParserWithCompletion:^(NSArray *models, NSString *error) {
                if (error && requestCount < maxRequestCount && weakSelf.username && weakSelf.password) {
                    [weakSelf loginAgainWithCompletion:^(NSString *error, NSArray *responseModels) {
                        [weakSelf reprintArticleWithFile:fileName from:originBoard to:targetBoard requestCount:requestCount + 1 completion:handler];
                    }];
                    return ;
                }
                [weakSelf makeLogWithError:error modelsCount:0 requestInfo:@"reprint" logLevel:DPLogLevelSimple];
                if (handler) {
                    handler(error, models);
                }
            }];
        }else {
            [weakSelf makeLogWithError:error.localizedDescription modelsCount:0 requestInfo:@"reprint" logLevel:DPLogLevelSimple];
            if (handler) {
                handler(error.localizedDescription, nil);
            }
        }
    }];
    [reprintTask resume];
}

- (void)loginAgainWithCompletion:(CompletionHandler)handler {
    [self loginWithUsername:self.username password:self.password completion:handler];
}

- (NSMutableURLRequest *)createRequestWithUrl:(NSString *)urlStr query:(NSString *)queryStr method:(NSString *)method cookie:(NSString *)cookie body:(NSData *)body {
    NSMutableString *completeUrlStr = [NSMutableString stringWithString:urlStr];
    if (queryStr) {
        [completeUrlStr appendString:queryStr];
    }
    NSURL *url = [NSURL URLWithString:completeUrlStr];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:method];
    [request setTimeoutInterval:requestTimeOut];
    [request setValue:@"Keep-Alive" forHTTPHeaderField:@"Connection"];
    if (cookie) {
        [request setValue:cookie forHTTPHeaderField:@"Cookie"];
    }
    if (body) {
        [request setHTTPBody:body];
    }
    return request;
}

- (NSString *)percentEscapesString:(NSString *)string {
    return [self percentEscapesString:string encoding:kCFStringEncodingUTF8];
}

- (NSString *)percentEscapesString:(NSString *)string encoding:(CFStringEncoding)encoding {
    return (__bridge NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)string, NULL, (CFStringRef) @"!*'();:@&=+$,/?%#[]", encoding);
}

- (void)logTheResponse:(NSData *)data {
    if (self.logLevel == DPLogLevelAll) {
        NSStringEncoding gb2312 = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
        NSString *response = [[NSString alloc] initWithData:data encoding:gb2312];
        NSLog(@"[YuXinSDK]: response1: %@", response);
    }
}

- (NSData *)refineTheData:(NSData *)data {
    
    NSStringEncoding gb2312 = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSString *rawStr = [[NSString alloc] initWithData:data encoding:gb2312];
    NSString *refinedStr = rawStr;
    NSString *targetStr = @"\0\1\2\3\10\11\13\27\30\31\32\33\34\35\36\37";
    NSString *tmpStr;
    for (int i = 0; i < targetStr.length; i++) {
        tmpStr = [targetStr substringWithRange:NSMakeRange(i, 1)];
        refinedStr = [refinedStr stringByReplacingOccurrencesOfString:tmpStr withString:@""];
    }
    refinedStr = [refinedStr stringByReplacingOccurrencesOfString:@"gb2312" withString:@"utf-8"];
    
    
    return [refinedStr dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSData *)cleanGB2312:(NSData *)data {
    
    iconv_t cd = iconv_open("gb2312", "gb2312");
    int one = 1;
    iconvctl(cd, ICONV_SET_DISCARD_ILSEQ, &one);
    size_t inbytesleft, outbytesleft;
    inbytesleft = outbytesleft = data.length;
    char *inbuf  = (char *)data.bytes;
    char *outbuf = malloc(sizeof(char) * data.length);
    char *outptr = outbuf;
    if (iconv(cd, &inbuf, &inbytesleft, &outptr, &outbytesleft)
        == (size_t)-1) {
        if (self.logLevel >= DPLogLevelSimple) {
            NSLog(@"[YuXinSDK]: this should not happen, seriously");
        }
        return nil;
    }
    NSData *result = [NSData dataWithBytes:outbuf length:data.length - outbytesleft];
    iconv_close(cd);
    free(outbuf);
    return result;
}

- (NSData *)cleanUTF8:(NSData *)data {
    
    iconv_t cd = iconv_open("utf-8", "utf-8");
    int one = 1;
    iconvctl(cd, ICONV_SET_DISCARD_ILSEQ, &one);
    size_t inbytesleft, outbytesleft;
    inbytesleft = outbytesleft = data.length;
    char *inbuf  = (char *)data.bytes;
    char *outbuf = malloc(sizeof(char) * data.length);
    char *outptr = outbuf;
    if (iconv(cd, &inbuf, &inbytesleft, &outptr, &outbytesleft)
        == (size_t)-1) {
        if (self.logLevel >= DPLogLevelSimple) {
            NSLog(@"[YuXinSDK]: this should not happen, seriously");
        }
        return nil;
    }
    NSData *result = [NSData dataWithBytes:outbuf length:data.length - outbytesleft];
    iconv_close(cd);
    free(outbuf);
    return result;
}

- (void)makeLogWithError:(NSString *)error modelsCount:(NSInteger)count requestInfo:(NSString *)info logLevel:(DPLogLevel)level {
    if (self.logLevel >= level) {
        if (!error) {
            if (count) {
                NSLog(@"[YuXinSDK]: success to get %zi %@", count, info);
            }else {
                NSLog(@"[YuXinSDK]: success to %@", info);
            }
        }else {
            if (count) {
                NSLog(@"[YuXinSDK]: fail to get %@ with error: %@", info, error);
            }else {
                NSLog(@"[YuXinSDK]: fail to %@ with error: %@", info, error);
            }
        }
    }
}

@end
