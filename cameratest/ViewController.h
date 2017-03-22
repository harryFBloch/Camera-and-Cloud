//
//  ViewController.h
//  CameraTest
//
//  Created by Aditya on 02/10/13.
//  Copyright (c) 2013 Aditya. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AmazonS3Util.h"
#import "Constants.h"


@interface ViewController : UIViewController
<UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIPopoverControllerDelegate,
UITableViewDelegate, UITableViewDataSource>

@property(strong,nonatomic)NSString *urlStr;
@property(strong,nonatomic)UIPopoverController *popController;
@property(strong,nonatomic) NSMutableArray *tableData;

@property (nonatomic, retain) AmazonS3Util *s3Util;
@property (nonatomic,weak) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;


- (void)loadData;
- (IBAction)takePicture:(id)sender;
- (IBAction)edit:(id)sender;

+(id)sharedManager;

@end
