//
//  AmazonS3Util.m
//  CameraTest
//
//  Created by Aditya on 08/11/13.
//  Copyright (c) 2013 Aditya. All rights reserved.
//

#import "AmazonS3Util.h"
#import "ViewController.h"
#import "Picture.h"

@implementation AmazonS3Util

+(id)sharedManager{
    static AmazonS3Util *Manager = nil;
    @synchronized(self) {
        if (Manager == nil) {
            Manager = [[self alloc]init];
        }
    }
    return Manager;
}

-(void)setUpClient{
 self.transferManager = [AWSS3TransferManager defaultS3TransferManager];
}


-(void)listFromBucket:(NSString*)bucketName
{
    self.pictureArray = [[NSMutableArray alloc] init];
    
    AWSS3 *s3 = [AWSS3 defaultS3];
    
    AWSS3ListObjectsRequest *listObjectsRequest = [[AWSS3ListObjectsRequest alloc]init];
    listObjectsRequest.bucket = bucketName;
    [[s3 listObjects:listObjectsRequest] continueWithBlock:^id(AWSTask *task) {
        if (task.error) {
//            NSLog(@"listObjects failed: [%@]", task.error);
        } else {
            AWSS3ListObjectsOutput *listObjectsOutput = task.result;
            NSMutableArray *array = [listObjectsOutput.contents valueForKey:@"key"];
            ViewController *viewController = [ViewController sharedManager];
            for (int i =0; i<array.count; i++) {
                Picture *picture = [[Picture alloc]init];
                picture.key = array[i];
                picture.index = i;
                [self.pictureArray addObject:picture];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                viewController.tableData = self.pictureArray;
                [viewController.tableView reloadData];
            });
            return self.pictureArray;
        }
        return nil;
    }];
}

-(void)downloadFromBucket:(NSString*)bucketName withKey: (NSString*) key index:(NSInteger) index{
    
    @try{
        self.transferManager = [AWSS3TransferManager defaultS3TransferManager];
        // Construct the NSURL for the download location.
        NSString *downloadingFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"downloaded-myImage.png"];
        NSURL *downloadingFileURL = [NSURL fileURLWithPath:downloadingFilePath];
        // Construct the download request.
        AWSS3TransferManagerDownloadRequest *downloadRequest = [AWSS3TransferManagerDownloadRequest new];
        
        downloadRequest.bucket = bucketName;
        downloadRequest.key = key;
        downloadRequest.downloadingFileURL = downloadingFileURL;
        // Download the file.
        [[self.transferManager download:downloadRequest] continueWithExecutor:[AWSExecutor mainThreadExecutor]
                                                               withBlock:^id(AWSTask *task) {
                                                                   if (task.error){
                                                                       if ([task.error.domain isEqualToString:AWSS3TransferManagerErrorDomain]) {
                                                                           switch (task.error.code) {
                                                                               case AWSS3TransferManagerErrorCancelled:
                                                                               case AWSS3TransferManagerErrorPaused:
                                                                                   break;
                                                                                   
                                                                               default:
//                                                                                   NSLog(@"first Error: %@", task.error);
                                                                                   break;
                                                                           }
                                                                       } else {
                                                                           // Unknown error.
//                                                                           NSLog(@"second Error: %@", task.error);
                                                                       }
                                                                   }
                                                                   if (task.result) {
                                                                       AWSS3TransferManagerDownloadOutput *downloadOutput = task.result;
                                                                       //File downloaded successfully.
//                                                                       NSLog(@"Success");
                                                                       UIImage *image = [UIImage imageWithContentsOfFile:downloadingFilePath];
                                                                       Picture *picture = self.pictureArray[index];
                                                                       picture.image = image;
                                                                       [self.pictureArray replaceObjectAtIndex:picture.index withObject:picture];
                                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                                           // code here
                                                                           ViewController *viewController = [ViewController sharedManager];
                                                                           viewController.imageView.image = image;
                                                                       });
                                                                       return image;
                                                                   }
                                                                   return nil;
                                                               }];
    }@catch (NSException *exception) {
        NSLog(@"Cannot Load S3 Object %@",exception);
    }
}

-(void)uploadData:(NSURL*)data format:(NSString*)format
         bucketName:(NSString*)bucketName withKey: (NSString*) key
{
    //Upload a photo
    AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
    uploadRequest.bucket = bucketName;
    uploadRequest.key = key;
    NSURL *url = data;
    uploadRequest.body = url;
    [[self.transferManager upload:uploadRequest] continueWithExecutor:[AWSExecutor mainThreadExecutor]
                                                       withBlock:^id(AWSTask *task) {
                                                           if (task.error) {
                                                               if ([task.error.domain isEqualToString:AWSS3TransferManagerErrorDomain]) {
                                                                   switch (task.error.code) {
                                                                       case AWSS3TransferManagerErrorCancelled:
                                                                       case AWSS3TransferManagerErrorPaused:
                                                                           break;
                                                                
                                                                       default:
                                                                           NSLog(@"first upload Error: %@", task.error);
                                                                           break;
                                                                   }
                                                               } else {
                                                                   // Unknown error.
                                                                   NSLog(@" second upload Error: %@", task.error);
                                                               }
                                                           }
                                                           if (task.result) {
                                                               AWSS3TransferManagerUploadOutput *uploadOutput = task.result;
                                                               // The file uploaded successfully.
                                                               NSLog(@"upload succses");
                                                           }
                                                           return nil;
                                                       }];
}

- (void)uploadDone:(NSError *)error
{
    @try{
    [[self delegate] uploadDone:error];
    }@catch (NSException *exception) {
        NSLog(@"uploadDone Exception : %@",exception);
    }
}


-(BOOL)deleteFromBucket:(NSString*)bucketName withKey:(NSString*)key
{
    @try{
          AWSS3 *s3 = [AWSS3 defaultS3];
        //Delete Object
        AWSS3DeleteObjectRequest *deleteObjectRequest = [AWSS3DeleteObjectRequest new];
        deleteObjectRequest.bucket = bucketName;
        deleteObjectRequest.key = key;
        
        [[s3 deleteObject:deleteObjectRequest] continueWithBlock:^id(AWSTask *task) {
            NSLog(@"deleted");
            
            return nil;
        }];
        return TRUE;
    }@catch (NSException *exception) {
        NSLog(@"Cannot Delete S3 Object %@",exception);
        return FALSE;
    }
}

- (void)dealloc {
//    self.amazonS3Client = nil;
    self.delegate = nil;
    NSLog(@"Deallocation Done");
}

@end
