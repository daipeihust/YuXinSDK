//
//  NSString+DPExtension.h
//  YuXin
//
//  Created by Dai Pei on 16/7/17.
//  Copyright © 2016年 Dai Pei. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (DPExtension)

- (NSUInteger)indexOfLine:(NSUInteger)line;
- (NSUInteger)indexOfLastLine:(NSUInteger)line;

- (NSString *)legalUrlString;



@end
