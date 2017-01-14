//
//  ViewController.m
//  js和oc框架交互
//
//  Created by 李江波 on 2017/1/14.
//  Copyright © 2017年 lijiangbo. All rights reserved.
//

#import "ViewController.h"
#import "UIWebView+Bridge.h"

@interface ViewController ()<UIWebViewDelegate>
@property(nonatomic ,strong) UIWebView *webView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.webView = [[UIWebView alloc]initWithFrame:self.view.bounds];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"js" withExtension:@"html"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    [self.webView loadRequest:request];
    self.webView.delegate = self;
    
    [self.view addSubview:self.webView];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{

    // 1. 框架使用第一步 拦截跳转
    return [webView dispatchURL:request.URL] == NO;
}
-(void)webViewDidFinishLoad:(UIWebView *)webView{
// 2. 注册 定义JS和OC之间的通讯函数 => 绑定 JS 函数 和 OC 函数
    //一：js和oc互调
//    [webView registerJSMethod:@"myfun1" target:self method:@selector(myfun1:)];
//    //二：js调oc
//    [webView registerJSMethod:@"myfun2" target:self method:@selector(myfun2:)];
//    //三：oc调js
    [webView registerJSMethod:@"myfun3" target:self method:@selector(myfun3:)];
}
//3.
// params 参数表示JS调用的时候传递给OC对象的
// 返回值是表示 OC对象把数据返回给JS调用


-(NSDictionary *)myfun1:(NSDictionary *)params{
    
    NSLog(@"params: %@",params);
    return @{@"myfunCallback":@"😑😑"};
}
-(NSDictionary *)myfun2:(NSDictionary *)params{
    
    NSLog(@"params: %@",params);
    return @{};
}
-(NSDictionary *)myfun3:(NSDictionary *)params{
    
    return @{@"myfunCallback3":@"😑😑😁😁😁"};
}


@end













