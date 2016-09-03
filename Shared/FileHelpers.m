//
//  FileHelpers.m
//  Shared
//
//  Created by Brian Bernberg on 9/17/11.
//  Copyright 2011 BB Consulting. All rights reserved.
//

#import "FileHelpers.h"

NSString *pathInDocumentDirectory(NSString *fileName) {
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [documentDirectories objectAtIndex:0];
    return [documentDirectory stringByAppendingPathComponent:fileName];
}

NSString *pathInCachesDirectory(NSString *fileName) {
    NSArray *cachesDirectories = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesDirectory = [cachesDirectories objectAtIndex:0];
    return [cachesDirectory stringByAppendingPathComponent:fileName];
    
}
