//
//  ViewController.m
//  TYSMPolygonGLSLDemo
//
//  Created by jele lam on 23/2/2020.
//  Copyright © 2020 CookiesJ. All rights reserved.
//

#import "ViewController.h"
#import "TYSMPolygonView.h"

@interface ViewController ()
@property (nonatomic, strong) TYSMPolygonView *polygonView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.polygonView = [[TYSMPolygonView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width,self.view.frame.size.height)];
    
    [self.view addSubview:self.polygonView];
    // Do any additional setup after loading the view.
}


@end
