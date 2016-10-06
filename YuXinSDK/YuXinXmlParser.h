//
//  YuXinXmlParser.h
//  YuXinSDK
//
//  Created by Dai Pei on 16/6/30.
//  Copyright © 2016年 Dai Pei. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ParserCompletion)(NSArray *models, NSString *error);

typedef NS_ENUM(NSUInteger, YuXinXmlParserType) {
    YuXinXmlParserTypeLogin,
    YuXinXmlParserTypeLogout,
    YuXinXmlParserTypeSubboard,
    YuXinXmlParserTypeFavourites,
    YuXinXmlParserTypeAddFavouritesBoard,
    YuXinXmlParserTypeDelFavouritesBoard,
    YuXinXmlParserTypeArticles,
    YuXinXmlParserTypeArticle,
    YuXinXmlParserTypeArticleOne,
    YuXinXmlParserTypePostArticle,
    YuXinXmlParserTypeDelArticle,
    YuXinXmlParserTypeUserDetail,
    YuXinXmlParserTypeMails,
    YuXinXmlParserTypeMailDetail,
    YuXinXmlParserTypePostMail,
    YuXinXmlParserTypeDelMail,
    YuXinXmlParserTypeNewMail,
    YuXinXmlParserTypeFriends,
    YuXinXmlParserTypeAddFriend,
    YuXinXmlParserTypeDelFriend,
    YuXinXmlParserTypeGetBoardPostPower,
    YuXinXmlParserTypeReprint
};

@interface YuXinXmlParser : NSObject

- (instancetype)initWithParserType:(YuXinXmlParserType)type parserData:(NSData *)data;
- (void)startParserWithCompletion:(ParserCompletion)handler;

@end
