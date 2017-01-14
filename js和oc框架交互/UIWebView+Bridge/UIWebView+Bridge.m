//
//  UIWebView+Bridge.m
//  Bridge
//
//  Created by ljb on 16/6/17.
//  Copyright © 2016年 ljb. All rights reserved.
//

#import "UIWebView+Bridge.h"
#import <objc/runtime.h>


#define kBridgeScheme                     @"bridge"
#define kUIWebViewBridgeRegisteredMethods @"kUIWebViewBridgeRegisteredMethods"

@interface NSString (Params)

- (NSDictionary *)params;

@end

@implementation NSString (Params)

- (NSDictionary *)params {
    NSArray *params = [self componentsSeparatedByString:@"&"];
    
    NSMutableDictionary *paramsDict = [NSMutableDictionary dictionary];
    for (NSString *query in params) {
        NSArray *paramComp = [query componentsSeparatedByString:@"="];
        if(paramComp.count > 1) {
            NSString *val = [paramComp[1] stringByRemovingPercentEncoding];
            NSData* data = [val dataUsingEncoding:NSUTF8StringEncoding];
            if(data) {
                NSDictionary *valDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
                [paramsDict setObject:valDict forKey:paramComp[0]];
            }
            
        }
    }
    return paramsDict;
}

@end

@interface UIWebView ()

@property (nonatomic,strong) NSMutableDictionary    *registeredMethods;

@end

@implementation UIWebView (Bridge)

#pragma mark - 公共方法 -
/**
 *  是否是一个JS函数
 *
 *  @param jsFunctionName js函数名
 *
 *  @return 是函数返回YES
 */
- (BOOL)isJSFunction:(NSString *)jsFunctionName {
    NSString *result = [self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"%@&&typeof(%@)==\"function\"",jsFunctionName,jsFunctionName]];
    if([result isEqualToString:@"true"]) {
        return YES;
    }
    return NO;
}

/**
 *  是否存在js变量
 *
 *  @param jsVariableName 变量名
 *
 *  @return 是否存在
 */
- (BOOL)isJSVariable:(NSString *)jsVariableName {
    NSString *result = [self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"typeof(%@) == \"undefined\"",jsVariableName]];
    if([result isEqualToString:@"false"]) {
        return YES;
    }
    return NO;
}

/**
 *  向UIWebview注册名称空间
 *
 *  @param nameSpace 名称空间
 */
- (void)createJSNameSpace:(NSString *)nameSpace {
    
    /*
    // 对应的js代码
    var Namespace = new Object();
    Namespace.register = function(path){
        var arr = path.split(".");
        var ns = "";
        for (var i = 0; i < arr.length; i++) {
            if (i > 0) {
                ns += ".";
            }
            ns += arr[i];
            eval("if(typeof(" + ns + ") == 'undefined') " + ns + " = new Object();");
        }
    }
    */
    if(![self isJSVariable:@"Namespace"]) {
        [self stringByEvaluatingJavaScriptFromString:@"var Namespace = new Object();"];
    }
    if(![self isJSFunction:@"Namespace.register"]) {
        
        [self stringByEvaluatingJavaScriptFromString:
         @"var Namespace = new Object();Namespace.register = function(path){var arr = path.split(\".\");var ns = \"\";for (var i = 0; i < arr.length; i++) {if (i > 0) {ns += \".\";}ns += arr[i];eval(\"if(typeof(\" + ns + \") == 'undefined') \" + ns + \" = new Object();\");}}"];
    }
    
    if(nameSpace != nil) {
        [self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"Namespace.register(\"%@\")",nameSpace]];
    }
}


#pragma mark - 注册方法缓存 -
- (NSMutableDictionary *)registeredMethods {
    NSMutableDictionary *registeredMethods = objc_getAssociatedObject(self, kUIWebViewBridgeRegisteredMethods);
    if(registeredMethods == nil) {
        registeredMethods = [NSMutableDictionary dictionary];
        [self setRegisteredMethods:registeredMethods];
    }
    return registeredMethods;
}

- (void)setRegisteredMethods:(NSMutableDictionary *)registeredMethods {
    objc_setAssociatedObject(self, kUIWebViewBridgeRegisteredMethods, registeredMethods, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - 清空缓存注册方法 -
- (void)clear {
    [[self registeredMethods] removeAllObjects];
}

#pragma mark - 注册方法 -
- (void)registerJSMethod:(NSString *)jsMethod target:(id)target method:(SEL)method {
    //缓存方法
    NSMethodSignature *signature = [[target class] instanceMethodSignatureForSelector:method];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    
    invocation.target = target;
    invocation.selector = method;
    
    NSMutableDictionary *registeredMethods = self.registeredMethods;
    [registeredMethods setObject:invocation forKey:jsMethod];
    
    //设置回调函数缓存
    if(![self isJSVariable:@"__CallbackCaches__"]) {
        [self stringByEvaluatingJavaScriptFromString:@"var __CallbackCaches__ = new Object();"];
    }
    
    //运行时植入js代码，使js拥有js回调能力
    if(![self isJSFunction:jsMethod]) {
        NSString *js = [NSString stringWithFormat:@"%@ = function(params,callback){__CallbackCaches__[\"%@\"]=callback;window.location.href=\"%@://%@?params=\"+encodeURIComponent(JSON.stringify(params));}",jsMethod,jsMethod,kBridgeScheme,jsMethod];
        [self stringByEvaluatingJavaScriptFromString:js];
    }
    
}

#pragma mark - 注册url进行调用OC和js -

- (BOOL)dispatchURL:(NSURL *)url {
    if([url.scheme isEqualToString:kBridgeScheme]) {
        NSString *jsMethod = url.host;
        NSDictionary *invokeParams = [url.query params][@"params"];
        NSInvocation *invocation = [[self registeredMethods] objectForKey:jsMethod];
        [invocation setArgument:&invokeParams atIndex:2];
        __autoreleasing NSDictionary *result = nil;
        [invocation invoke];
        [invocation getReturnValue:&result];
    
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted error:nil];
        if(jsonData) {
            NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            NSString *js = [NSString stringWithFormat:@"__CallbackCaches__[\"%@\"](JSON.parse(decodeURIComponent(\"%@\")))",jsMethod,[jsonString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
            [self stringByEvaluatingJavaScriptFromString:js];
        }
        [self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"__CallbackMap__[\"%@\"]=NULL;",jsMethod]];
        return YES;
    }
    return NO;
}

@end
