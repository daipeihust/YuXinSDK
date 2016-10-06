//
//  NSString+DPExtension.m
//  YuXin
//
//  Created by Dai Pei on 16/7/17.
//  Copyright © 2016年 Dai Pei. All rights reserved.
//

#import "NSString+DPExtension.h"

@implementation NSString (DPExtension)

- (NSUInteger)indexOfLine:(NSUInteger)line {
    if (line == 1 || line == 0) {
        return 0;
    }
    NSUInteger index;
    NSUInteger i = 0;
    for (index = 0; index < self.length; index++) {
        NSRange range = NSMakeRange(index, 1);
        if ([[self substringWithRange:range] isEqualToString:@"\n"]) {
            i++;
        }
        if (i == line - 1) {
            index++;
            break;
        }
    }
    return index;
}

- (NSUInteger)indexOfLastLine:(NSUInteger)line {
    if (line == 0) {
        return self.length;
    }
    NSUInteger index;
    NSUInteger i = 0;
    for (index = self.length - 1; index > 0; index--) {
        NSRange range = NSMakeRange(index, 1);
        if ([[self substringWithRange:range] isEqualToString:@"\n"]) {
            i++;
        }
        if (i == line) {
            index++;
            break;
        }
    }
    return index;
}

- (NSString *)legalUrlString {
    return (__bridge NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self, NULL, (CFStringRef) @"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8);
}

@end
