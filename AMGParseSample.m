//
//  AMGParseSample.m
//  parseApp
//
//  Created by Alan Morales on 1/9/15.
//  Copyright (c) 2015 Facebook Inc. All rights reserved.
//

#import "AMGParseSample.h"
#import "AMGParseSampleSource.h"

@implementation AMGParseSample

- (instancetype)init {
    return [self initWithName:@"Default Sample Name"];
}

- (instancetype)initWithName:(NSString *)name {
    self = [super init];
    
    if (self) {
        _sampleName = name;
    }
    
    return self;
}

// TODO: Execute logic here, for now calling AMGParseSampleSource
- (void)execute:(NSInteger)sampleIndex {
    [[AMGParseSampleSource sharedSource] executeSample:sampleIndex];
}
@end
