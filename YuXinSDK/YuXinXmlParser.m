//
//  YuXinXmlParser.m
//  YuXinSDK
//
//  Created by Dai Pei on 16/6/30.
//  Copyright © 2016年 Dai Pei. All rights reserved.
//

#import "YuXinXmlParser.h"
#import "YuXinModel.h"

static NSString *const loginInfoElementNames = @"utmpnum,utmpkey,utmpuserid,invisible,contdays";
static NSString *const loginInfoElementTitle = @"logininfo";

static NSString *const favouratesElementNames = @"boardname,boardtitle,filenum";
static NSString *const favouratesElementTitle = @"board";

static NSString *const userInfoElementNames = @"userid,nick,numlogins,gender,horoscope,lastlogin,newmail,numposts,netage,strnetage,life,exp,strexp,money,medals,duty";
static NSString *const userInfoElementTitle = @"userinfo";

static NSString *const friendElementNames = @"userid,remark";
static NSString *const friendElementTitle = @"friend";

static NSString *const titleElementNames = @"author,date,filename,name,num,flag,canRe,reNum,summary";
static NSString *const titleElementTitle = @"title";

static NSString *const subboardElementNames = @"ename,cname,bm,postnum,onlinenum";
static NSString *const subboardElementTitle = @"board";

static NSString *const articleElementNames = @"title,filename,owner,content";
static NSString *const articleElementTitle = @"article";


@interface YuXinXmlParser() <NSXMLParserDelegate>

@property (nonatomic, assign) YuXinXmlParserType parserType;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSMutableArray *modelArray;
@property (nonatomic, assign) BOOL storingFlag;
@property (nonatomic, strong) NSMutableArray *elementToParse;
@property (nonatomic, strong) NSString *elementTitle;
@property (nonatomic, strong) NSMutableString *currentElementValue;
@property (nonatomic, copy) ParserCompletion completionHandler;
@property (nonatomic, assign) BOOL parseCompleted;

@property (nonatomic, strong) YuXinLoginInfo *loginInfo;
@property (nonatomic, strong) YuXinBoard *board;
@property (nonatomic, strong) YuXinUserInfo *userInfo;
@property (nonatomic, strong) YuXinFriend *friend;
@property (nonatomic, strong) YuXinTitle *title;
@property (nonatomic, strong) YuXinArticle *article;

@end

@implementation YuXinXmlParser

#pragma mark - Init

- (instancetype)initWithParserType:(YuXinXmlParserType)type parserData:(NSData *)data{
    self = [super init];
    if (self) {
        self.parserType = type;
        self.data = data;
        self.modelArray = [[NSMutableArray alloc] init];
        self.storingFlag = NO;
        switch (type) {
            case YuXinXmlParserTypeLogin:
                self.elementToParse = [NSMutableArray arrayWithArray:[loginInfoElementNames componentsSeparatedByString:@","]];
                self.elementTitle = [loginInfoElementTitle copy];
                break;
            case YuXinXmlParserTypeFavourites:
                self.elementToParse = [NSMutableArray arrayWithArray:[favouratesElementNames componentsSeparatedByString:@","]];
                self.elementTitle = [favouratesElementTitle copy];
                break;
            case YuXinXmlParserTypeUserDetail:
                self.elementToParse = [NSMutableArray arrayWithArray:[userInfoElementNames componentsSeparatedByString:@","]];
                self.elementTitle = [userInfoElementTitle copy];
                break;
            case YuXinXmlParserTypeFriends:
                self.elementToParse = [NSMutableArray arrayWithArray:[friendElementNames componentsSeparatedByString:@","]];
                self.elementTitle = [friendElementTitle copy];
                break;
            case YuXinXmlParserTypeArticles:
                self.elementToParse = [NSMutableArray arrayWithArray:[titleElementNames componentsSeparatedByString:@","]];
                self.elementTitle = [titleElementTitle copy];
                break;
            case YuXinXmlParserTypeSubboard:
                self.elementToParse = [NSMutableArray arrayWithArray:[subboardElementNames componentsSeparatedByString:@","]];
                self.elementTitle = [subboardElementTitle copy];
                break;
            case YuXinXmlParserTypeAddFavouritesBoard:
                self.elementToParse = [NSMutableArray array];
                self.elementTitle = @"add favourite board";
                break;
            case YuXinXmlParserTypeArticle:
                self.elementToParse = [NSMutableArray arrayWithArray:[articleElementNames componentsSeparatedByString:@","]];
                self.elementTitle = [articleElementTitle copy];
                break;
            case YuXinXmlParserTypePostArticle:
                self.elementToParse = [NSMutableArray array];
                self.elementTitle = @"post article";
                break;
            case YuXinXmlParserTypeDelArticle:
                self.elementToParse = [NSMutableArray array];
                self.elementTitle = @"delete article";
                break;
            case YuXinXmlParserTypeReprint:
                self.elementToParse = [NSMutableArray array];
                self.elementTitle = @"reprint article";
            default:
                break;
        }
        [self.elementToParse addObject:@"error"];
    }
    return self;
}

#pragma mark - Public Method

- (void)startParserWithCompletion:(ParserCompletion)completionHandler {
    
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:self.data];
    [parser setDelegate:self];
    self.parseCompleted = NO;
    self.completionHandler = completionHandler;
    
    if ([parser parse]) {
        if (!self.parseCompleted) {
//            NSLog(@"[YuXinXmlParser]: parse %@ finish", self.elementTitle);
            if (completionHandler) {
                completionHandler(self.modelArray, nil);
            }
        }
    }else {
        if (!self.parseCompleted) {
            if (self.parserType == YuXinXmlParserTypeAddFavouritesBoard ||
                self.parserType == YuXinXmlParserTypePostArticle ||
                self.parserType == YuXinXmlParserTypeDelArticle ||
                self.parserType == YuXinXmlParserTypeReprint) {
                if (completionHandler) {
                    completionHandler(nil, nil);
                }
                return ;
            }
//            NSLog(@"[YuXinXmlParser]: error: %@", parser.parserError);
            if (completionHandler) {
                completionHandler(nil, @"parse failed");
            }
        }
    }
}

#pragma mark - NSXMLParserDelegate

- (void)parserDidStartDocument:(NSXMLParser *)parser {
//    NSLog(@"[YuXinXmlParser]: parse %@ start", self.elementTitle);
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(nullable NSString *)namespaceURI qualifiedName:(nullable NSString *)qName attributes:(NSDictionary<NSString *, NSString *> *)attributeDict {
    
    switch (self.parserType) {
        case YuXinXmlParserTypeLogin:{
            if ([elementName isEqualToString:self.elementTitle]) {
                self.loginInfo = [[YuXinLoginInfo alloc] init];
            }
            break;
        }
        case YuXinXmlParserTypeFavourites:{
            if ([elementName isEqualToString:self.elementTitle]) {
                self.board = [[YuXinBoard alloc] init];
            }else if ([elementName isEqualToString:@"master"]) {
                self.board.master = [attributeDict objectForKey:@"userid"];
            }
            break;
        }
        case YuXinXmlParserTypeUserDetail:{
            if ([elementName isEqualToString:self.elementTitle]) {
                self.userInfo = [[YuXinUserInfo alloc] init];
            }
            break;
        }
        case YuXinXmlParserTypeFriends:{
            if ([elementName isEqualToString:self.elementTitle]) {
                self.friend = [[YuXinFriend alloc] init];
            }
            break;
        }
        case YuXinXmlParserTypeArticles:{
            if ([elementName isEqualToString:self.elementTitle]) {
                self.title = [[YuXinTitle alloc] init];
            }
            break;
        }
        case YuXinXmlParserTypeSubboard:{
            if ([elementName isEqualToString:self.elementTitle]) {
                self.board = [[YuXinBoard alloc] init];
            }
            break;
        }
        case YuXinXmlParserTypeArticle:{
            if ([elementName isEqualToString:self.elementTitle]) {
                self.article = [[YuXinArticle alloc] init];
            }
            break;
        }
        default:
            break;
    }
    self.storingFlag = [self.elementToParse containsObject:elementName];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    
    if (self.storingFlag) {
        if (!self.currentElementValue) {
            self.currentElementValue = [[NSMutableString alloc] initWithString:string];
        }
        else {
            [self.currentElementValue appendString:string];
        }
    }
    
}

- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock {
    if (self.storingFlag) {
        NSString *tmpStr = [[NSString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding];
        if (!self.currentElementValue) {
            self.currentElementValue = [[NSMutableString alloc] initWithString:tmpStr];
        }else {
            [self.currentElementValue appendString:tmpStr];
        }
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(nullable NSString *)namespaceURI qualifiedName:(nullable NSString *)qName {
    
    NSString *trimmedString = [self.currentElementValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    self.currentElementValue = nil;
    
    if (self.storingFlag) {
//        NSLog(@"[YuXinXmlParser]: %@: %@", elementName, trimmedString);
    }
    if ([elementName isEqualToString:@"error"]) {
        if (self.completionHandler) {
            self.completionHandler(nil, [trimmedString copy]);
        }
        self.parseCompleted = YES;
    }
    switch (self.parserType) {
        case YuXinXmlParserTypeLogin:{
            if ([elementName isEqualToString:@"utmpnum"]) {
                self.loginInfo.utmpNum = trimmedString;
            }else if ([elementName isEqualToString:@"utmpkey"]) {
                self.loginInfo.utmpKey = trimmedString;
            }else if ([elementName isEqualToString:@"utmpuserid"]) {
                self.loginInfo.utmpUserID = trimmedString;
            }else if ([elementName isEqualToString:@"invisible"]) {
                self.loginInfo.invisible = trimmedString;
            }else if ([elementName isEqualToString:@"contdays"]) {
                self.loginInfo.contdays = trimmedString;
            }else if ([elementName isEqualToString:self.elementTitle]) {
                if (self.loginInfo) {
                    [self.modelArray addObject:self.loginInfo];
                    self.loginInfo = nil;
                }
            }
            break;
        }
        case YuXinXmlParserTypeFavourites:{
            if ([elementName isEqualToString:@"boardname"]) {
                self.board.boardName = trimmedString;
            }else if ([elementName isEqualToString:@"boardtitle"]) {
                self.board.boardTitle = trimmedString;
            }else if ([elementName isEqualToString:@"filenum"]) {
                self.board.postNum = trimmedString;
            }else if ([elementName isEqualToString:self.elementTitle]) {
                if (self.board) {
                    [self.modelArray addObject:self.board];
                    self.board = nil;
                }
            }
            break;
        }
        case YuXinXmlParserTypeUserDetail:{
            if ([elementName isEqualToString:@"userid"]) {
                self.userInfo.userID = trimmedString;
            }else if ([elementName isEqualToString:@"nick"]) {
                self.userInfo.nickName = trimmedString;
            }else if ([elementName isEqualToString:@"numlogins"]) {
                self.userInfo.loginNum = trimmedString;
            }else if ([elementName isEqualToString:@"gender"]) {
                self.userInfo.gender = trimmedString;
            }else if ([elementName isEqualToString:@"horoscope"]) {
                self.userInfo.horoscope = trimmedString;
            }else if ([elementName isEqualToString:@"lastlogin"]) {
                self.userInfo.lastLogin = trimmedString;
            }else if ([elementName isEqualToString:@"newmail"]) {
                self.userInfo.mailNum = trimmedString;
            }else if ([elementName isEqualToString:@"numposts"]) {
                self.userInfo.postNum = trimmedString;
            }else if ([elementName isEqualToString:@"netage"]) {
                self.userInfo.netAge = trimmedString;
            }else if ([elementName isEqualToString:@"strnetage"]) {
                self.userInfo.netAgeDescription = trimmedString;
            }else if ([elementName isEqualToString:@"life"]) {
                self.userInfo.life = trimmedString;
            }else if ([elementName isEqualToString:@"exp"]) {
                self.userInfo.experienceValue = trimmedString;
            }else if ([elementName isEqualToString:@"strexp"]) {
                self.userInfo.experienceDescription = trimmedString;
            }else if ([elementName isEqualToString:@"money"]) {
                self.userInfo.money = trimmedString;
            }else if ([elementName isEqualToString:@"medals"]) {
                self.userInfo.medalNum = trimmedString;
            }else if ([elementName isEqualToString:@"duty"]) {
                self.userInfo.duty = trimmedString;
            }else if ([elementName isEqualToString:self.elementTitle]) {
                if (self.userInfo) {
                    [self.modelArray addObject:self.userInfo];
                    self.userInfo = nil;
                }
            }
            break;
        }
        case YuXinXmlParserTypeFriends:{
            if ([elementName isEqualToString:@"userid"]) {
                self.friend.userID = trimmedString;
            }else if ([elementName isEqualToString:@"remark"]) {
                self.friend.nickName = trimmedString;
            }else if ([elementName isEqualToString:self.elementTitle]) {
                if (self.friend) {
                    [self.modelArray addObject:self.friend];
                    self.friend = nil;
                }
            }
            break;
        }
        case YuXinXmlParserTypeArticles:{
            if ([elementName isEqualToString:@"author"]) {
                self.title.author = trimmedString;
            }else if ([elementName isEqualToString:@"date"]) {
                self.title.date = trimmedString;
            }else if ([elementName isEqualToString:@"filename"]) {
                self.title.fileName = trimmedString;
            }else if ([elementName isEqualToString:@"name"]) {
                self.title.name = trimmedString;
            }else if ([elementName isEqualToString:@"num"]) {
                self.title.serialNum = trimmedString;
            }else if ([elementName isEqualToString:@"canRe"]) {
                self.title.canReply = trimmedString;
            }else if ([elementName isEqualToString:@"reNum"]) {
                self.title.replyNum = trimmedString;
            }else if ([elementName isEqualToString:@"summary"]) {
                self.title.summary = trimmedString;
            }else if ([elementName isEqualToString:self.elementTitle]) {
                if (self.title) {
                    [self.modelArray addObject:self.title];
                    self.title = nil;
                }
            }
            break;
        }
        case YuXinXmlParserTypeSubboard:{
            if ([elementName isEqualToString:@"ename"]) {
                self.board.boardName = trimmedString;
            }else if ([elementName isEqualToString:@"cname"]) {
                self.board.boardTitle = trimmedString;
            }else if ([elementName isEqualToString:@"bm"]) {
                self.board.master = trimmedString;
            }else if ([elementName isEqualToString:@"postnum"]) {
                self.board.postNum = trimmedString;
            }else if ([elementName isEqualToString:@"onlinenum"]) {
                self.board.onlineNum = trimmedString;
            }else if ([elementName isEqualToString:self.elementTitle]) {
                if (self.board) {
                    [self.modelArray addObject:self.board];
                    self.board = nil;
                }
            }
            break;
        }
        case YuXinXmlParserTypeArticle:{
            if ([elementName isEqualToString:@"title"]) {
                self.article.title = trimmedString;
            }else if ([elementName isEqualToString:@"filename"]) {
                self.article.fileName = trimmedString;
            }else if ([elementName isEqualToString:@"owner"]) {
                self.article.author = trimmedString;
            }else if ([elementName isEqualToString:@"content"]) {
                self.article.content = trimmedString;
            }else if ([elementName isEqualToString:self.elementTitle]) {
                if (self.article) {
                    [self.modelArray addObject:self.article];
                    self.article = nil;
                }
            }
            break;
        }
        default:
            break;
    }
}

@end
