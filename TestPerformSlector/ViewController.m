//
//  ViewController.m
//  TestPerformSlector
//
//  Created by liujing on 2018/8/24.
//  Copyright © 2018年 jean. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
{
    NSArray * titleArray;
    dispatch_queue_t subQueue;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    titleArray = @[@"Main:PerformSelector",@"Main:PerformSelectorONMain_Wait",@"Main:PerformSelectorONMain_NoWait",@"Main:PerformSelectorDelay_0",@"Main:PerformSelectorDelay_3",@"Sub:PerformSelector",@"Sub:PerformSelectorONMain_Wait",@"Sub:PerformSelectorONMain_NoWait",@"Sub:PerformSelectorDelay",@"Sub:dispatch_after",@"Sub:PerformSelectorDelay_InRunloop",@"Sub:DelayPerform_InNewTrdWithloop_Wait",@"Sub:DelayPerform_InNewTrdWithloop_NoWait"];
     subQueue = dispatch_queue_create("sub queue", DISPATCH_QUEUE_CONCURRENT);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return titleArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
   static NSString * identifier = @"cell";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    cell.textLabel.text = titleArray[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0:{
             NSLog(@"start0 in currentThread: %@", [NSThread currentThread]);
             [self testPerformSelector:@"main"];//同步阻塞 自己走完再走后面的
             NSLog(@"over0 in currentThread: %@",[NSThread currentThread]);
        }
            break;
            
        case 1:{
             NSLog(@"start0 in currentThread: %@", [NSThread currentThread]);
             [self testPerformSelectorONMainWithObject:@"main" Wait:YES];//同步阻塞 自己走完再走后面的 同上面的效果一样
             NSLog(@"over0 in currentThread: %@",[NSThread currentThread]);
        }
           
            break;
            
        case 2:{
            NSLog(@"start0 in currentThread: %@", [NSThread currentThread]);
            [self testPerformSelectorONMainWithObject:@"main" Wait:NO]; //异步非阻塞 over1打印完(即此didselect方法走完)才走此方法
            NSLog(@"over0 in currentThread: %@",[NSThread currentThread]);
        }
            break;
            
        case 3:{
             NSLog(@"start0 in currentThread: %@", [NSThread currentThread]);
            [self testPerformSelectorDelayWithObject:@"main" Delay:0];//异步非阻塞 over1打印完了才走 同上面的效果一样
            NSLog(@"over0 in currentThread: %@",[NSThread currentThread]);
        }
            break;
            
        case 4:{
             NSLog(@"start0 in currentThread: %@", [NSThread currentThread]);
            [self testPerformSelectorDelayWithObject:@"main" Delay:3];//异步非阻塞 over1 打印完了再过3秒才走
            NSLog(@"over0 in currentThread: %@",[NSThread currentThread]);
        }
            break;
      
        //case5之后 异步block被加入到一个并行队列 会开辟一个新的线程， 非阻塞 直接return 即over1走完再走block里面方法
        case 5:{
            dispatch_async(subQueue, ^{
                NSLog(@"start2 in currentThread: %@", [NSThread currentThread]);
                [self testPerformSelector:@"sub queue"]; //同步阻塞当前线程 自己走完再走后面的
                NSLog(@"over2 in currentThread: %@",[NSThread currentThread]);
            });
        }
            break;
            
        case 6:{
            dispatch_async(subQueue, ^{
                NSLog(@"start2 in currentThread: %@", [NSThread currentThread]);
                [self testPerformSelectorONMainWithObject:@"sub queue" Wait:YES]; //在主线程上执行 且阻塞当前线程 即这个走完了才继续over2
                NSLog(@"over2 in currentThread: %@",[NSThread currentThread]);
            });
        }
            break;
            
        case 7:{
            dispatch_async(subQueue, ^{
                NSLog(@"start2 in currentThread: %@", [NSThread currentThread]);
                [self testPerformSelectorONMainWithObject:@"sub queue" Wait:NO]; //在主线程上执行 但不阻塞当前线程 即over2完了再走这个
                NSLog(@"over2 in currentThread: %@",[NSThread currentThread]);
            });
        }
            break;
            
        case 8:{
            dispatch_async(subQueue, ^{
                NSLog(@"start2 in currentThread: %@", [NSThread currentThread]);
                //子线程不能直接调performSelector:withObject:afterDelay:
                //也不能直接调scheduledTimerWithTimeInterval 如果没有一个runloop的话
                //下面的代码相当于无效代码
                [self testPerformSelectorDelayWithObject:@"sub queue" Delay:0];//delay:3
                [NSTimer scheduledTimerWithTimeInterval:2 repeats:NO block:^(NSTimer * _Nonnull timer) {
                    [self testPerformSelector:@"sub queue"];
                }];
                //-------------
                NSLog(@"over2 in currentThread: %@",[NSThread currentThread]);
            });
        }
            break;
        case 9:{
            //直接在子线程中delay或者用nstimer都不行因没有runloop 而dispatch_after可以！
            //但是delay函数可以用cancelPreviousPerformRequestsWithTarget取消 而dispatch_after没有提供取消方法！！
            dispatch_async(subQueue, ^{
                NSLog(@"start2 in currentThread: %@", [NSThread currentThread]);
                //相当于performSelector:withObject:afterDelay 3秒后执行doSomething
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), subQueue, ^{
                    [self testPerformSelector:@"sub queue"];
                });
                NSLog(@"over2 in currentThread: %@",[NSThread currentThread]);
            });
        }
            break;
            
        case 10:{
            dispatch_async(subQueue, ^{
                NSLog(@"start2 in currentThread: %@", [NSThread currentThread]);
              
                [self testPerformSelectorDelayWithRunloop];
                //[runLoop run] 执行之后此线程一直处于while循环等待中，故[runLoop run]要放在此线程你想做的所有事情后面去写，不然就会执行不到，比如over2如放[runLoop run]后面就不会打印了
                NSLog(@"over2 in currentThread: %@",[NSThread currentThread]);
                NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
                [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
                [runLoop run];
            });
        }
            break;
            
        case 11:{
            dispatch_async(subQueue, ^{
                NSLog(@"start2 in currentThread: %@", [NSThread currentThread]);
                //执行在一个新的有runloop的线程 新线程里执行
                [self testNewthreadRunloopWait:YES];
                NSLog(@"over2 in currentThread: %@",[NSThread currentThread]);
            });
        }
            break;
            
        case 12:{
            dispatch_async(subQueue, ^{
                NSLog(@"start2 in currentThread: %@", [NSThread currentThread]);
                //执行在一个新的有runloop的线程 新线程里执行
                [self testNewthreadRunloopWait:NO];
                NSLog(@"over2 in currentThread: %@",[NSThread currentThread]);
            });
        }
            break;
            
        default:
            break;
    }
     NSLog(@"over1 in currentThread: %@",[NSThread currentThread]);
}


#pragma mark - testPerformSelector
//同步在当前线程执行 会阻塞当前线程(自己)
- (void)testPerformSelector:(NSString *)obj {
    [self performSelector:@selector(doSomething:) withObject:obj];
}

#pragma mark - OnMainThread Wait
//此方法可以在主线程或者子线程去调 但selector方法运行在主线程
- (void)testPerformSelectorONMainWithObject:(NSString *)obj Wait:(BOOL)wait {
    [self performSelectorOnMainThread:@selector(doSomething:) withObject:obj waitUntilDone:wait];
}

#pragma mark - afterDelay
//此方法是异步!! 不能在子线程直接调 在子线程直接调的话 不会生效 等于白写
- (void)testPerformSelectorDelayWithObject:(NSString *)obj Delay:(NSTimeInterval)delay {
    [self performSelector:@selector(doSomething:) withObject:obj afterDelay:delay];
}

#pragma mark - add runLoop
//此方法给当前线程加一个runloop
//子线程不同于主线程不会自动创建runloop，导致定时器没有工作 故而需要加runLoop 或者用dispatch_after去延时
- (void)testPerformSelectorDelayWithRunloop {
    //在启动RunLoop之前，必须添加监听的输入源事件或者定时源事件，否则调用[runloop run]会直接返回，而不会进入循环让线程长驻。
    //如果没有添加任何输入源事件或Timer事件，线程会一直在无限循环空转中，会一直占用CPU时间片，没有实现资源的合理分配。
    //没有while循环且没有添加任何输入源或Timer的线程，线程会直接完成，被系统回收。
    
    //1
    [self testPerformSelectorDelayWithObject:@"sub queue" Delay:0];//delay:3
   
    //2
    [NSTimer scheduledTimerWithTimeInterval:2 repeats:NO block:^(NSTimer * _Nonnull timer) {
        [self testPerformSelector:@"sub queue"];
    }];

    //3
    NSTimer *timer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:2 target:self selector:@selector(test) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (void)test {
    NSLog(@"jean test方法");
}

#pragma mark - a new thread with runloop
//类方法加_标识来区别
//此方法创建一个新的NSThread 其有个runloop  把doSomething这个操作放到一个有runloop的子线程里
- (void)testNewthreadRunloopWait:(BOOL)wait{
    [self performSelector:@selector(doSomething:) onThread:[[self class] _newThread] withObject:nil waitUntilDone:wait modes:@[NSDefaultRunLoopMode]];
}


+ (void)_addRunLoop:(NSThread *)thread{
    @autoreleasepool {
        [[NSThread currentThread] setName:@"com.jean.testThread"];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

+ (NSThread *)_newThread{
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(_addRunLoop:) object:nil];
//    [NSThread sleepForTimeInterval:1];
    [thread start];
    return thread;
}

//---------------------------------------------
- (void)doSomething:(NSString *)aStr {
    NSLog(@"doSomething:__传过来的str为%@__, currentThread = %@", aStr, [NSThread currentThread]);
    sleep(2);
    NSLog(@"doSomething sleep over");
}
@end
