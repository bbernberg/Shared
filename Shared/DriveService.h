//
//  SharedDriveFolder.h
//  Shared
//
//  Created by Brian Bernberg on 1/15/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import "GTLDrive.h"

@interface DriveService : NSObject
@property (nonatomic, strong) PFObject *folder;
@property (nonatomic, readonly) GTLServiceDrive *gtlDriveService;

+ (DriveService *)sharedInstance;
- (BOOL)isAvailable;
- (void)fetchDriveFolderInfo;
- (void)getDriveFolderMetadataWithCompletionBlock:(void (^)(GTLDriveFile *, NSError *))handler;
- (void)refreshDriveFolderWithIdentifier:(NSString *)fileIdentifier completionBlock:(void (^)(GTLDriveFileList *files, NSError *))handler;
- (void)createDriveFolderWithName:(NSString *)folderName
                   parentFolderID:(NSString *)parentFolderID
                  completionBlock:(void (^)(GTLDriveFile *, NSError *))handler;
- (void)deleteFileWithIdentifier:(NSString *)fileIdentifier
                 completionBlock:(void (^)(GTLDriveFile *, NSError *))handler;
- (void)updateFile:(GTLDriveFile *)file
   completionBlock:(void (^)(GTLDriveFile *, NSError *))handler;
- (void)addPermissionForEmail:(NSString *)email
              completionBlock:(void (^)(id, NSError*))handler;
- (void)uploadVideoWithData:(NSData *)videoData
                  videoName:(NSString *)videoName
 withParentFolderIdentifier:(NSString *)parentFolderIdentifier
            completionBlock:(void (^)(GTLDriveFile *, NSError *))handler;
- (void)uploadPhotoWithData:(NSData *)photoData
                  photoName:(NSString *)photoName
 withParentFolderIdentifier:(NSString *)parentFolderIdentifier
            completionBlock:(void (^)(GTLDriveFile *, NSError *))handler;
- (void)downloadFile:(GTLDriveFile *)file
       statusMessage:(NSString *)statusMessage
 withCompletionBlock:(void (^)(NSData *data, NSError *error))completionBlock;
+(NSString *)driveCacheName:(GTLDriveFile *)file;
+ (void)resetDriveFolder:(PFObject *)folder;

@end
