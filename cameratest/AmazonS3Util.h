//
//  AmazonS3Util.h
//  CameraTest
//
//  Created by Aditya on 08/11/13.
//  Copyright (c) 2013 Aditya. All rights reserved.
//

#import <AWSS3/AWSS3.h>

@interface AmazonS3Util : NSObject

//@property (nonatomic, retain) AmazonS3Client *amazonS3Client;
@property (nonatomic, retain) id delegate;
@property (nonatomic, strong)AWSS3TransferManager *transferManager;
@property (nonatomic, strong)NSMutableArray *pictureArray;

-(void)listFromBucket:(NSString*)bucketName;
-(void)downloadFromBucket:(NSString*)bucketName withKey: (NSString*) key index:(NSInteger) index;
-(void)uploadData:(NSURL*)data format:(NSString*)format
       bucketName:(NSString*)bucketName withKey: (NSString*) key;
-(BOOL)deleteFromBucket:(NSString*)bucketName withKey:(NSString*)key;
-(void)setUpClient;
+(id)sharedManager;

@end
