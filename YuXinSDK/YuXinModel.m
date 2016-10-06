//
//  YuXinModel.m
//  YuXinSDK
//
//  Created by Dai Pei on 16/6/30.
//  Copyright © 2016年 Dai Pei. All rights reserved.
//

#define DPRegExColor                                @"\\[{1}[0-9]{0,2}[;[0-9]{1,2}]*m"
#define DPRegExTime1                                @"[0-9]{4}年[0-9]{2}月[0-9]{2}日[0-9]{2}:[0-9]{2}:[0-9]{2}"
#define DPRegExTime2                                @"\\w{3}\\s{1,2}\\d{1,2} \\d{2}:\\d{2}:\\d{2} \\d{4}"
#define DPRegExName                                 @"[A-Za-z0-9_]+ [(]{1}.+[)]{1}"
#define DPRegExReplyUserIDAndName                   @"[A-Za-z0-9_]+ [(]{1}.+[)]{1}"
#define DPRegExReply                                @"【 在 .+"
#define DPRegExHeader                               @"发信站:"
#define DPRegExFooter                               @"※ "

#define DPTextColorParameterBlack                   @"30"
#define DPTextColorParameterRed                     @"31"
#define DPTextColorParameterGreen                   @"32"
#define DPTextColorParameterYellow                  @"33"
#define DPTextColorParameterDarkBlue                @"34"
#define DPTextColorParameterPink                    @"35"
#define DPTextColorParameterLightBlue               @"36"
#define DPTextColorParameterWhite                   @"37"

#define DPTextColorBlack                        [UIColor blackColor]
#define DPTextColorRed                          [UIColor redColor]
#define DPTextColorGreen                        [UIColor greenColor]
#define DPTextColorYellow                       [UIColor yellowColor]
#define DPTextColorDarkBlue                     [UIColor blueColor]
#define DPTextColorPink                         [UIColor magentaColor]
#define DPTextColorLightBlue                    [UIColor cyanColor]
#define DPTextColorWhite                        [UIColor lightGrayColor]

#import "YuXinModel.h"
#import "NSString+DPExtension.h"
#import <UIKit/UIKit.h>

@interface YuXinModel()

@property (nonatomic, strong) NSString *colorRegEx;

@end

@implementation YuXinModel

- (NSString *)compareCurrentTime:(NSString *)str withDateFormatter:(NSDateFormatter *)formatter{
    NSDate *timeDate = [formatter dateFromString:str];
    
    NSTimeInterval  timeInterval = [timeDate timeIntervalSinceNow];
    timeInterval = -timeInterval;
    
    long temp = 0;
    NSString *result;
    if (timeInterval < 60) {
        result = [NSString stringWithFormat:@"刚刚"];
    }
    else if((temp = timeInterval/60) <60){
        result = [NSString stringWithFormat:@"%ld分钟前",temp];
    }
    else if((temp = temp/60) <24){
        result = [NSString stringWithFormat:@"%ld小时前",temp];
    }
    else if((temp = temp/24) <30){
        result = [NSString stringWithFormat:@"%ld天前",temp];
    }
    else if((temp = temp/30) <12){
        result = [NSString stringWithFormat:@"%ld个月前",temp];
    }
    else{
        temp = temp/12;
        result = [NSString stringWithFormat:@"%ld年前",temp];
    }
    return  result;
}

- (NSString *)colorRegEx {
    if (!_colorRegEx) {
        _colorRegEx = DPRegExColor;
    }
    return _colorRegEx;
}

@end



@implementation YuXinLoginInfo

@end



@implementation YuXinBoard


@end



@interface YuXinUserInfo ()

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation YuXinUserInfo

- (void)setLastLogin:(NSString *)lastLogin {
    _lastLogin = lastLogin;
    _readableLastLogin = [super compareCurrentTime:lastLogin withDateFormatter:self.dateFormatter];
}

#pragma mark - Getter

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"EEE MMM d HH:mm:ss yyyy"];
        [_dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    }
    return _dateFormatter;
}

@end



@implementation YuXinFriend


@end



@interface YuXinTitle()

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation YuXinTitle


- (void)setDate:(NSString *)date {
    _date = date;
    NSString *newDate = [self compareCurrentTime:date withDateFormatter:self.dateFormatter];
    _readableDate = newDate;
}

- (void)setSummary:(NSString *)summary {
    _displaySummary = [self getDisplaySummary:summary];
    _summary = summary;
}

- (NSString *)getDisplaySummary:(NSString *)summary {
    NSRange range = [summary rangeOfString:self.colorRegEx options:NSRegularExpressionSearch];
    while (range.location < summary.length) {
        summary = [summary stringByReplacingCharactersInRange:range withString:@""];
        range = [summary rangeOfString:self.colorRegEx options:NSRegularExpressionSearch];
    }
    return summary;
}

#pragma mark - Getter

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"MMM d HH:mm:ss yyyy"];
        [_dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    }
    return _dateFormatter;
}

@end



@interface YuXinArticle()

@property (nonatomic, strong) NSString *timeRegEx1;
@property (nonatomic, strong) NSString *timeRegEx2;
@property (nonatomic, strong) NSString *nameRegEx;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSString *replyRegEx;
@property (nonatomic, strong) NSString *replyUserIDAndNameRegEx;
@property (nonatomic, strong) NSString *headerRegEx;
@property (nonatomic, strong) NSString *footerRegEx;

@end

@implementation YuXinArticle


- (void)setContent:(NSString *)content {
    _readableDate = [self getReadableDateFrom:content];
    _userIDAndName = [self getUserIDAndNameFrom:content];
    _realContent = [self getRealContent:content];
    _replyUserIDAndName = [self getUserIDAndNameFrom:_replyStr];
    _replyUserID = [self getUserIDFromUserIDAndName:_replyUserIDAndName];
    _colorfulContent = [self getAttributedStringFrom:_realContent];
    _content = content;
}

- (NSString *)getRealContent:(NSString *)content {
    NSRange range = [content rangeOfString:self.headerRegEx];
    if (range.location < content.length) {
        content = [content substringFromIndex:range.location];
        content = [content substringFromIndex:[content indexOfLine:2]];
    }
    range = [content rangeOfString:@"\n--\n"];
    if (range.location < content.length) {
        content = [content substringToIndex:range.location];
    }
    range = [content rangeOfString:@"\n-\n"];
    if (range.location < content.length) {
        content = [content substringToIndex:range.location];
    }
    range = [content rangeOfString:self.footerRegEx];
    if (range.location < content.length) {
        content = [content substringToIndex:range.location];
        content = [content substringToIndex:[content indexOfLastLine:1]];
    }
    range = [content rangeOfString:self.replyRegEx options:NSRegularExpressionSearch];
    if (range.location < content.length) {
        _replyStr = [content substringFromIndex:range.location];
        content = [content substringToIndex:range.location - 1];
    }
    range = [content rangeOfString:@"在.+的大" options:NSRegularExpressionSearch];
    if (range.location < content.length) {
        _replyStr = [content substringFromIndex:range.location];
        content = [content substringToIndex:range.location - 1];
    }
    content = [content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return content;
}

- (NSString *)getReadableDateFrom:(NSString *)content {
    NSString *result;
    NSRange range1 = [content rangeOfString:self.timeRegEx1 options:NSRegularExpressionSearch];
    NSRange range2 = [content rangeOfString:self.timeRegEx2 options:NSRegularExpressionSearch];
    if (range1.location < content.length) {
        result = [content substringWithRange:range1];
        [self.dateFormatter setDateFormat:@"yyyy年MM月dd日HH:mm:ss"];
    }else if (range2.location < content.length) {
        result = [content substringWithRange:range2];
        [self.dateFormatter setDateFormat:@"MMM d HH:mm:ss yyyy"];
    }
    result = [self compareCurrentTime:result withDateFormatter:self.dateFormatter];
    return result;
}

- (NSString *)getUserIDAndNameFrom:(NSString *)content {
    NSString *result;
    NSRange range = [content rangeOfString:self.nameRegEx options:NSRegularExpressionSearch];
    if (range.location < content.length) {
        result = [content substringWithRange:range];
    }
    return result;
}

- (NSString *)getUserIDFromUserIDAndName:(NSString *)userIDAndName {
    NSString *result = [userIDAndName copy];
    NSRange range = [result rangeOfString:@"("];
    if (range.location < userIDAndName.length) {
        result = [result substringToIndex:range.location];
    }
    return result;
}

- (NSAttributedString *)getAttributedStringFrom:(NSString *)content {
    NSMutableAttributedString *result;
    NSRange range;
    NSMutableArray<NSString *> *colorInfoArray = [NSMutableArray array];
    NSMutableArray<NSNumber *> *indexInfoArray = [NSMutableArray array];
    UIColor *textColor;
    range = [content rangeOfString:self.colorRegEx options:NSRegularExpressionSearch];
    while (range.location < content.length) {
        NSString *tmpStr = [content substringWithRange:range];
        [indexInfoArray addObject:@(range.location)];
        [colorInfoArray addObject:tmpStr];
        content = [content stringByReplacingCharactersInRange:range withString:@""];
        range = [content rangeOfString:self.colorRegEx options:NSRegularExpressionSearch];
    }
    self.displayContent = content;
    [indexInfoArray addObject:@(content.length)];
    result = [[NSMutableAttributedString alloc] initWithString:content];
    for (int i = 0; i < indexInfoArray.count - 1; i++) {
        if ([colorInfoArray[i] containsString:DPTextColorParameterBlack]) {
            textColor = DPTextColorBlack;
        }
        else if ([colorInfoArray[i] containsString:DPTextColorParameterRed]) {
            textColor = DPTextColorRed;
        }
        else if ([colorInfoArray[i] containsString:DPTextColorParameterGreen]) {
            textColor = DPTextColorGreen;
        }
        else if ([colorInfoArray[i] containsString:DPTextColorParameterYellow]) {
            textColor = DPTextColorYellow;
        }
        else if ([colorInfoArray[i] containsString:DPTextColorParameterDarkBlue]) {
            textColor = DPTextColorDarkBlue;
        }
        else if ([colorInfoArray[i] containsString:DPTextColorParameterPink]) {
            textColor = DPTextColorPink;
        }
        else if ([colorInfoArray[i] containsString:DPTextColorParameterLightBlue]) {
            textColor = DPTextColorLightBlue;
        }
        else if ([colorInfoArray[i] containsString:DPTextColorParameterWhite]) {
            textColor = DPTextColorWhite;
        }
        else {
            textColor = DPTextColorBlack;
        }
        NSInteger index1 = indexInfoArray[i].integerValue;
        NSInteger index2 = indexInfoArray[i + 1].integerValue;
        if (index1 < result.length && index1 < index2) {
            [result setAttributes:@{NSForegroundColorAttributeName : textColor} range:NSMakeRange(index1, index2 - index1)];
        }
    }
    return [result copy];
}

#pragma mark - Getter

- (NSString *)timeRegEx1 {
    if (!_timeRegEx1) {
        _timeRegEx1 = DPRegExTime1;
    }
    return _timeRegEx1;
}

- (NSString *)timeRegEx2 {
    if (!_timeRegEx2) {
        _timeRegEx2 = DPRegExTime2;
    }
    return _timeRegEx2;
}

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    }
    return _dateFormatter;
}

- (NSString *)nameRegEx {
    if (!_nameRegEx) {
        _nameRegEx = DPRegExName;
    }
    return _nameRegEx;
}

- (NSString *)replyRegEx {
    if (!_replyRegEx) {
        _replyRegEx = DPRegExReply;
    }
    return _replyRegEx;
}

- (NSString *)replyUserIDAndNameRegEx {
    if (!_replyUserIDAndNameRegEx) {
        _replyUserIDAndNameRegEx = DPRegExReplyUserIDAndName;
    }
    return _replyUserIDAndNameRegEx;
}

- (NSString *)headerRegEx {
    if (!_headerRegEx) {
        _headerRegEx = DPRegExHeader;
    }
    return _headerRegEx;
}

- (NSString *)footerRegEx {
    if (!_footerRegEx) {
        _footerRegEx = DPRegExFooter;
    }
    return _footerRegEx;
}

@end
