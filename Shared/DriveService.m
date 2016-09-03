//
//  DriveService.m
//  Shared
//
//  Created by Brian Bernberg on 1/15/13.
//  Copyright (c) 2013 BB Consulting. All rights reserved.
//

#import "DriveService.h"
#import "Constants.h"
#import "GTLDrive.h"
#import "TMCache.h"
#import "SVProgressHUD.h"

static DriveService *sharedInstance = nil;

@interface DriveService()
@property (nonatomic, strong) GTLServiceDrive *gtlDriveService;
@end

@implementation DriveService

+(DriveService *)sharedInstance {
    if (!sharedInstance) {
        sharedInstance = [[DriveService alloc] init];
    }
    return sharedInstance;
}

-(id)init {
    if (self = [super init]) {
        self.folder = nil;
    }
    return self;
}

- (GTLServiceDrive *)gtlDriveService {
  if ( !_gtlDriveService ) {
    _gtlDriveService = [[GTLServiceDrive alloc] init];
    
    // Have the service object set tickets to fetch consecutive pages
    // of the feed so we do not need to manually fetch them.
    _gtlDriveService.shouldFetchNextPages = YES;
    
    // Have the service object set tickets to retry temporary error conditions
    // automatically.
    _gtlDriveService.retryEnabled = YES;
  }
  return _gtlDriveService;
}

-(BOOL)isAvailable {
    if (!self.folder) {
        return NO;
    } else {
        return YES;
    }
}

- (void)fetchDriveFolderInfo {
  if (self.folder.objectId) {
    [self.folder fetchInBackgroundWithBlock:^(PFObject *folder, NSError *error) {
      if ( !error ) {
        [DriveService sharedInstance].folder = folder;
        [[NSNotificationCenter defaultCenter] postNotificationName:kDriveFolderFetchedNotification object:nil];
      }
    }];
  }
}

- (void)getDriveFolderMetadataWithCompletionBlock:(void (^)(GTLDriveFile *file, NSError *error))handler {
  GTLQuery *query = [GTLQueryDrive queryForFilesGetWithFileId:self.folder[kDriveFolderIDKey]];
  
  [self.gtlDriveService executeQuery:query
                   completionHandler:^(GTLServiceTicket *ticket, GTLDriveFile *file, NSError *error) {
                     handler(file, error);
                   }];
}

- (void)refreshDriveFolderWithIdentifier:(NSString *)fileIdentifier completionBlock:(void (^)(GTLDriveFileList *files, NSError *))handler {
  GTLQueryDrive *query = [GTLQueryDrive queryForFilesList];
  query.q = [NSString stringWithFormat:@"'%@' IN parents", fileIdentifier];
  
  [self.gtlDriveService executeQuery:query completionHandler:^(GTLServiceTicket *ticket,
                                                               GTLDriveFileList *files,
                                                               NSError *error) {
    handler(files, error);
  }];
  
}

- (void)createDriveFolderWithName:(NSString *)folderName
                   parentFolderID:(NSString *)parentFolderID
                  completionBlock:(void (^)(GTLDriveFile *, NSError *))handler {
  GTLDriveFile *newFolder = [GTLDriveFile object];
  newFolder.title = folderName;
  newFolder.mimeType = kDriveFolderMIMEType;
  newFolder.descriptionProperty = @"Shared folder";
  if ( parentFolderID ) {
    GTLDriveParentReference *parentFolder = [GTLDriveParentReference object];
    parentFolder.identifier = parentFolderID;
    newFolder.parents = @[ parentFolder ];
  }
  
  GTLQueryDrive *query = [GTLQueryDrive queryForFilesInsertWithObject:newFolder
                                                     uploadParameters:nil];
  
  [self.gtlDriveService executeQuery:query
                   completionHandler:^(GTLServiceTicket *ticket, GTLDriveFile *insertedFolder, NSError *error) {
                     handler(insertedFolder, error);
                   }];
}

- (void)deleteFileWithIdentifier:(NSString *)fileIdentifier
                 completionBlock:(void (^)(GTLDriveFile *, NSError *))handler {
  GTLQueryDrive *deleteQuery = [GTLQueryDrive queryForFilesDeleteWithFileId:fileIdentifier];
  
  // updateQueryTicket can be used to track the status of the request.
  [self.gtlDriveService executeQuery:deleteQuery
                   completionHandler:^(GTLServiceTicket *ticket,
                                       GTLDriveFile *updatedFile,
                                       NSError *error) {
                     handler(updatedFile, error);
                    }];
  
}

- (void)updateFile:(GTLDriveFile *)file
   completionBlock:(void (^)(GTLDriveFile *, NSError *))handler {
  GTLQueryDrive *updateQuery = [GTLQueryDrive queryForFilesUpdateWithObject:file
                                                                     fileId:file.identifier
                                                           uploadParameters:nil];
  [self.gtlDriveService executeQuery:updateQuery
                   completionHandler:^(GTLServiceTicket *ticket, GTLDriveFile *updatedFile, NSError *error) {
                     handler(updatedFile, error);
                   }];
}

- (void)addPermissionForEmail:(NSString *)email
              completionBlock:(void (^)(id, NSError*))handler {
  GTLDrivePermission *newPermission = [GTLDrivePermission object];
  newPermission.value = [User currentUser].partnerGoogleDriveUserEmail;
  newPermission.type = @"user";
  newPermission.role = @"writer";
  GTLQueryDrive *query = [GTLQueryDrive queryForPermissionsInsertWithObject:newPermission fileId:self.folder[kDriveFolderIDKey]];
  [self.gtlDriveService executeQuery:query completionHandler:^(GTLServiceTicket *ticket, id object, NSError *error) {
    if (error == nil) {
      self.folder[kDriveFolderSharedKey] = @(YES);
    } else {
      self.folder[kDriveFolderSharedKey] = @(NO);
    }
    
    self.folder[kDriveFolderPartnerUserEmailKey] = [User currentUser].partnerGoogleDriveUserEmail;
    [self.folder saveInBackgroundElseEventually];
    handler(object, error);
  }];
}

- (void)uploadVideoWithData:(NSData *)videoData
                   videoName:(NSString *)videoName
  withParentFolderIdentifier:(NSString *)parentFolderIdentifier
             completionBlock:(void (^)(GTLDriveFile *, NSError *))handler {
  GTLDriveFile *newVideo = [GTLDriveFile object];
  newVideo.title = videoName;
  newVideo.mimeType = @"video/quicktime";
  
  GTLDriveParentReference *parentFolder = [GTLDriveParentReference object];
  parentFolder.identifier = parentFolderIdentifier;
  newVideo.parents = @[ parentFolder ];
  
  GTLUploadParameters *uploadParameters = [GTLUploadParameters uploadParametersWithData:videoData MIMEType:newVideo.mimeType];
  
  GTLQueryDrive *query = [GTLQueryDrive queryForFilesInsertWithObject:newVideo
                                                     uploadParameters:uploadParameters];
  
  __block UIBackgroundTaskIdentifier uploadBackgroundTaskId;
  
  [self.gtlDriveService executeQuery:query
                   completionHandler:^(GTLServiceTicket *ticket,
                                       GTLDriveFile *insertedFile, NSError *error) {
                     [[UIApplication sharedApplication] endBackgroundTask:uploadBackgroundTaskId];
                     handler(insertedFile, error);
                   }];
  uploadBackgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
    [[UIApplication sharedApplication] endBackgroundTask:uploadBackgroundTaskId];
  }];
  
}

- (void)uploadPhotoWithData:(NSData *)photoData
                  photoName:(NSString *)photoName
 withParentFolderIdentifier:(NSString *)parentFolderIdentifier
            completionBlock:(void (^)(GTLDriveFile *, NSError *))handler {
  GTLDriveFile *newPhoto = [GTLDriveFile object];
  newPhoto.title = photoName;
  newPhoto.mimeType = @"image/png";
  
  GTLDriveParentReference *parentFolder = [GTLDriveParentReference object];
  parentFolder.identifier = parentFolderIdentifier;
  newPhoto.parents = @[ parentFolder ];
  
  GTLUploadParameters *uploadParameters = [GTLUploadParameters uploadParametersWithData:photoData MIMEType:newPhoto.mimeType];
  
  GTLQueryDrive *query = [GTLQueryDrive queryForFilesInsertWithObject:newPhoto
                                                     uploadParameters:uploadParameters];
  
  __block UIBackgroundTaskIdentifier uploadBackgroundTaskId;
  [self.gtlDriveService executeQuery:query
                   completionHandler:^(GTLServiceTicket *ticket,
                                       GTLDriveFile *insertedFile, NSError *error) {
                     [[UIApplication sharedApplication] endBackgroundTask:uploadBackgroundTaskId];
                     handler(insertedFile, error);
                   }];

  uploadBackgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
    [[UIApplication sharedApplication] endBackgroundTask:uploadBackgroundTaskId];
  }];
  
}

#pragma mark file download
- (void)downloadFile:(GTLDriveFile *)file statusMessage:(NSString *)statusMessage withCompletionBlock:(void (^)(NSData *data, NSError *error))completionBlock {
  
  NSData *fileData = [[TMCache sharedCache] objectForKey:[[self class] driveCacheName:file]];
  if (fileData) {
    completionBlock(fileData, nil);
  } else {
    [SVProgressHUD showWithStatus:statusMessage];
    GTMHTTPFetcher *fetcher = [self.gtlDriveService.fetcherService fetcherWithURLString:file.downloadUrl];
    
    [fetcher beginFetchWithCompletionHandler:^(NSData *data, NSError *error) {
      [SVProgressHUD dismiss];
      if (error == nil) {
        [[TMCache sharedCache] setObject:data
                                  forKey:[[self class] driveCacheName:file]
                                   block:NULL];
        completionBlock(data, nil);
      } else {
        NSLog(@"An error occurred: %@", error);
        completionBlock(nil, error);
      }
    }];
  }
}

+(NSString *)driveCacheName:(GTLDriveFile *)file {
  return [NSString stringWithFormat:@"gd_%@_%@", file.title, file.ETag];
}

+ (void)resetDriveFolder:(PFObject *)folder {
  [folder deleteInBackgroundElseEventually];
  [User currentUser].googleDriveFolderOwner = nil;
  [User currentUser].myGoogleDriveUserEmail = nil;
  [User currentUser].partnerGoogleDriveUserEmail = nil;
  [[User currentUser] saveToNetwork];
  sharedInstance = nil;
}

@end
