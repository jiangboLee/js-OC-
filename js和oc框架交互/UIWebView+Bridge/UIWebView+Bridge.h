//
//  UIWebView+Bridge.h
//  Bridge
//
//  Created by ljb on 16/6/17.
//  Copyright © 2016年 ljb. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  标准方式桥接js
 */
@interface UIWebView (Bridge)

#pragma mark - JS工具方法 -
/**
 *  是否是一个JS函数
 *
 *  @param jsFunctionName js函数名
 *
 *  @return 是函数返回YES
 */
- (BOOL)isJSFunction:(NSString *)jsFunctionName;

/**
 *  是否存在js变量
 *
 *  @param jsVariableName 变量名
 *
 *  @return 是否存在
 */
- (BOOL)isJSVariable:(NSString *)jsVariableName;

/**
 *  向UIWebview注册名称空间
 *
 *  @param nameSpace 名称空间
 */
- (void)createJSNameSpace:(NSString *)nameSpace;

#pragma mark - 操作方法 -
 
/**
 *  清空已注册的方法
 */
- (void)clear;

/**
 *  js方法和oc方法之间桥接注册
 *
 *  @param jsMethod js方法名称
 *  @param target   oc消息发送者
 *  @param method   oc消息
 */
- (void)registerJSMethod:(NSString *)jsMethod target:(id)target method:(SEL)method;

/**
 *  url转发，用于js回调
 *
 *  @param url url跳转回调
 *
 *  @return 返回YES表示跳转成功，并且桥接调用OC代码，返回NO表示失败
 */
- (BOOL)dispatchURL:(NSURL *)url;

@end
