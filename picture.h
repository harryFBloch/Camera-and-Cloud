//
//  picture.h
//  CameraTest
//
//  Created by harry bloch on 4/6/16.
//  Copyright © 2016 Aditya. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Picture : NSObject

@property(nonatomic, strong)NSString *key;
@property(nonatomic, strong)UIImage *image;
@property(nonatomic)NSInteger index;

@end
