//
//  GenericWebViewController.m
//  Shared
//
//  Created by Brian Bernberg on 5/11/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "GenericWebViewController.h"

@interface GenericWebViewController ()
@property NSString *path;
@property NSString *navTitle;
@end

@implementation GenericWebViewController

- (id)initWithPath:(NSString *)path title:(NSString *)title
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        // Custom initialization
        self.path = path;
        self.navTitle = title;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.path]]];
    webView.scalesPageToFit = YES;
    [self.view addSubview:webView];
    
    self.title = self.navTitle;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
