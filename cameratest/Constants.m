
#import "Constants.h"

@implementation Constants


+(NSString *)uploadBucket
{
    return [[NSString stringWithFormat:@"%@", BUCKET] lowercaseString];
}

@end

