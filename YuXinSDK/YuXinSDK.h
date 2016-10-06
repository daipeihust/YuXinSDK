//
//  YuXinSDK.h
//  YuXinSDK
//
//  Created by Dai Pei on 16/6/24.
//  Copyright © 2016年 Dai Pei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YuXinModel.h"

typedef void(^CompletionHandler)(NSString *error, NSArray *responseModels);

typedef NS_ENUM(NSInteger, YuXinBoardType) {
    YuXinBoardTypeYuXinXingKong,
    YuXinBoardTypeDianXinFengCai,
    YuXinBoardTypeShuZiShiDai,
    YuXinBoardTypeXueShuXueKe,
    YuXinBoardTypeRenWenYiShu,
    YuXinBoardTypeChunZhenShiDai,
    YuXinBoardTypeXiuXianYuLe,
    YuXinBoardTypeShiShiKuaiDi
};

typedef NS_ENUM(NSUInteger, DPLogLevel) {
    DPLogLevelNone = 0,
    DPLogLevelSimple = 1,
    DPLogLevelAll = 2
};

@interface YuXinSDK : NSObject

@property (nonatomic, assign) DPLogLevel logLevel;

+ (instancetype)sharedInstance;
- (void)loginWithUsername:(NSString *)username password:(NSString *)password completion:(CompletionHandler)handler;
- (void)logoutWithCompletion:(CompletionHandler)handler;
- (void)fetchFavourateBoardWithCompletion:(CompletionHandler)handler;
- (void)queryUserInfoWithUserID:(NSString *)userID completion:(CompletionHandler)handler;
- (void)fetchFriendListWithCompletion:(CompletionHandler)handler;
- (void)fetchArticleTitleListWithBoard:(NSString *)boardName start:(NSNumber *)startNum completion:(CompletionHandler)handler;
- (void)fetchSubboard:(YuXinBoardType)boardType completion:(CompletionHandler)handler;
- (void)addFavourateBoard:(NSString *)boardName completion:(CompletionHandler)handler;
- (void)delFavourateBoard:(NSString *)boardName completion:(CompletionHandler)handler;
- (void)fetchArticlesWithBoard:(NSString *)boardName file:(NSString *)fileName completion:(CompletionHandler)handler;
- (void)postArticleWithContent:(NSString *)content title:(NSString *)title board:(NSString *)boardName canReply:(BOOL)canReply userID:(NSString *)userID completion:(CompletionHandler)handler;
- (void)commentArticle:(NSString *)articleName content:(NSString *)content board:(NSString *)boardName canReply:(BOOL)canReply file:(NSString *)fileName completion:(CompletionHandler)handler;
- (void)deleteArticleWithBoard:(NSString *)boardName file:(NSString *)fileName completion:(CompletionHandler)handler;
- (void)reprintArticleWithFile:(NSString *)fileName from:(NSString *)originBoard to:(NSString *)targetBoard completion:(CompletionHandler)handler;

@end
