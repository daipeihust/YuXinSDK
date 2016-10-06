//
//  YuXinModel.h
//  YuXinSDK
//
//  Created by Dai Pei on 16/6/30.
//  Copyright © 2016年 Dai Pei. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YuXinModel : NSObject


@end

@interface YuXinLoginInfo : YuXinModel

@property (nonatomic, strong) NSString *utmpNum;
@property (nonatomic, strong) NSString *utmpKey;
@property (nonatomic, strong) NSString *utmpUserID;
@property (nonatomic, strong) NSString *invisible;
@property (nonatomic, strong) NSString *contdays;

@end

@interface YuXinBoard : YuXinModel

@property (nonatomic, strong) NSString *boardName;
@property (nonatomic, strong) NSString *boardTitle;
@property (nonatomic, strong) NSString *master;
@property (nonatomic, strong) NSString *postNum;
@property (nonatomic, strong) NSString *onlineNum;

@end

@interface YuXinUserInfo : YuXinModel

@property (nonatomic, strong) NSString *userID;
@property (nonatomic, strong) NSString *nickName;
@property (nonatomic, strong) NSString *loginNum;
@property (nonatomic, strong) NSString *gender;
@property (nonatomic, strong) NSString *horoscope;
@property (nonatomic, strong) NSString *lastLogin;
@property (nonatomic, strong) NSString *readableLastLogin;
@property (nonatomic, strong) NSString *mailNum;
@property (nonatomic, strong) NSString *postNum;
@property (nonatomic, strong) NSString *netAge;
@property (nonatomic, strong) NSString *netAgeDescription;
@property (nonatomic, strong) NSString *life;
@property (nonatomic, strong) NSString *experienceValue;
@property (nonatomic, strong) NSString *experienceDescription;
@property (nonatomic, strong) NSString *money;
@property (nonatomic, strong) NSString *medalNum;
@property (nonatomic, strong) NSString *duty;

@end

@interface YuXinFriend : YuXinModel

@property (nonatomic, strong) NSString *userID;
@property (nonatomic, strong) NSString *nickName;

@end

@interface YuXinTitle : YuXinModel

@property (nonatomic, strong) NSString *author;
@property (nonatomic, strong) NSString *date;
@property (nonatomic, strong) NSString *readableDate;
@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *serialNum;
@property (nonatomic, strong) NSString *canReply;
@property (nonatomic, strong) NSString *replyNum;
@property (nonatomic, strong) NSString *displaySummary;
@property (nonatomic, strong) NSString *summary;

@end

@interface YuXinArticle : YuXinModel

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *author;
@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSString *num;
@property (nonatomic, strong) NSString *realContent;
@property (nonatomic, strong) NSString *header;
@property (nonatomic, strong) NSString *readableDate;
@property (nonatomic, strong) NSString *userIDAndName;
@property (nonatomic, strong) NSString *displayContent;
@property (nonatomic, strong) NSAttributedString *colorfulContent;
@property (nonatomic, strong) NSString *replyStr;
@property (nonatomic, strong) NSString *replyUserIDAndName;
@property (nonatomic, strong) NSString *replyUserID;

@end




