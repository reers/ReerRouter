//
//  ReerRouterLauncher.m
//  ReerRouter
//
//  Created by phoenix on 2024/9/5.
//

#import "ReerRouterLauncher.h"

@implementation ReerRouterLauncher
+ (void)load {
    [NSClassFromString(@"ReerRouter.Router") performSelector:@selector(router_load)];
}
@end
