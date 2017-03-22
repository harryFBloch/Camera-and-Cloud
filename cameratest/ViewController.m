//
//  ViewController.m
//  CameraTest
//
//  Created by Aditya on 02/10/13.
//  Copyright (c) 2013 Aditya. All rights reserved.
//

#import "ViewController.h"
#import "Picture.h"
#import "AFNetworkReachabilityManager.h"

@interface ViewController ()


@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    [self reachability];
    self.tableData = [[NSMutableArray alloc] init];
    self.s3Util = [AmazonS3Util sharedManager];
    [self.s3Util setUpClient];
    [self loadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)loadData {
    self.s3Util = [AmazonS3Util sharedManager];
    [self.s3Util listFromBucket:[Constants uploadBucket]];
    [self.tableView reloadData];
}

- (IBAction)edit:(id)sender {
    if([self.tableView isEditing]){
        [sender setTitle:@"Edit"];
    }else{
        [sender setTitle:@"Done"];
    }
    [self.tableView setEditing:![self.tableView isEditing]];
}

- (IBAction)takePicture:(id)sender{
    
    if([self.popController isPopoverVisible]) {
        [self.popController dismissPopoverAnimated:YES];
        self.popController = nil;
        return;
    }
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    
    if( [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] ){
      
        [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
    }else
    {
        [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }
    
    [imagePicker setAllowsEditing:TRUE];
    [imagePicker setDelegate:self];
    self.popController = [[UIPopoverController alloc]initWithContentViewController:imagePicker];
    [self.popController setDelegate:self];
    
    [self.popController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    [self.popController dismissPopoverAnimated:YES];
    self.popController = nil;
    [self dismissViewControllerAnimated:self.popController completion:nil];
    [self.popController.delegate popoverControllerDidDismissPopover:self.popController];
    
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    [self.imageView setImage:image];
    //convert uiimage to
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"%f.jpg", [[NSDate date] timeIntervalSince1970 ]]];
    [UIImagePNGRepresentation(image) writeToFile:filePath atomically:YES];
    NSURL* fileUrl = [NSURL fileURLWithPath:filePath];
    NSString *fileName = [[NSString alloc] initWithFormat:@"%f.jpg", [[NSDate date] timeIntervalSince1970 ] ];
    [self.s3Util uploadData:fileUrl format:@"image/jpeg"
    bucketName:[Constants uploadBucket] withKey:fileName];
    Picture *picture = [[Picture alloc] init];
    picture.key = fileName;
    picture.image = image;
    picture.index = self.s3Util.pictureArray.count;
//    [self.tableData addObject:picture];
    [self.s3Util.pictureArray addObject:picture];
    [self.tableView reloadData];
    
}

- (void)uploadDone:(NSError *)error
{
    if(error != nil){
//        NSLog(@"Error: %@", error);
    }else
    {
//        NSLog(@"File Uploaded");
        [self loadData];
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
//    NSLog(@"Table Data Count: %lu", (unsigned long)[self.s3Util.pictureArray count]);
    return [self.s3Util.pictureArray count];
}

//[self.delegate numberofRows...



-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    Picture *picture = self.s3Util.pictureArray[indexPath.row];
    if(!cell){
        cell =
        [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UITableViewCell"];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    [[cell textLabel] setText: picture.key];
    return cell;
}

- (void)tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath {
    
    Picture *picture = self.s3Util.pictureArray[indexPath.row];
    if (picture.image) {
        self.imageView.image = picture.image;
    }else{
   [self.s3Util downloadFromBucket:[Constants uploadBucket] withKey:picture.key index:indexPath.row];
    }
}

- (void) tableView: (UITableView *)tableView  commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    Picture *picture = self.s3Util.pictureArray[indexPath.row];
    
    [self.s3Util deleteFromBucket:[Constants uploadBucket] withKey:picture.key];
    [self.s3Util.pictureArray removeObjectAtIndex:indexPath.row];
//    [self.tableData removeObjectAtIndex:indexPath.row];
    Picture *pictureZero = self.s3Util.pictureArray[0];
    self.imageView.image = pictureZero.image;
    [self.tableView reloadData];
 }

+(id)sharedManager {
    static ViewController *Manager = nil;
    @synchronized(self) {
        if (Manager == nil) {
            Manager = [[self alloc]init];
        }
    }
    return Manager;
}

-(void)reachability {
    
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status){
        
        if ([AFNetworkReachabilityManager sharedManager].reachable) {
        }else{
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"Alert" message:@"Please allow internet services" preferredStyle:UIAlertControllerStyleAlert   ];
            UIAlertAction *defualtAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){ }];
            [alertC addAction:defualtAction];
            [self presentViewController:alertC animated:YES completion:nil];
        }
    }];
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    });
}

@end
