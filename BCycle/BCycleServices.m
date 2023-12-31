//
//  BCycleServices.m
//  BCycle
//
//  Created by Thomas Traylor on 9/22/14.
//  Copyright (c) 2014 Thomas Traylor. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "BCycleServices.h"


/*
 DROP TABLE IF EXISTS Stations;
 CREATE TABLE Stations (
 id integer PRIMARY KEY autoincrement NOT NULL,
 name text,
 street text,
 city text,
 state text,
 zip text,
 docks real,
 latitude real,
 longitude real,
 created DATETIME DEFAULT CURRENT_TIMESTAMP,
 updated DATETIME DEFAULT CURRENT_TIMESTAMP
 );
 */

#if !defined(METERS_PER_MILE)
#define METERS_PER_MILE 1609.344
#endif

// the ip and port of the bcycle api server
//static NSString *ipPort = @"192.168.1.175:8080";
static NSString *ipPort = @"localhost:80";

@interface BCycleServices()

- (CLLocationDistance) maxDistance:(MKCoordinateRegion)region;

@end

@implementation BCycleServices


#pragma mark - Setting

- (id)init {
    self = [super init];
    return self;
}

- (void)getStationsWithCompletion:(StationCompletionBlock)completion {
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/api/v1/stations", ipPort]];
    NSMutableURLRequest *stationRequest = [NSMutableURLRequest requestWithURL:url];
    stationRequest.HTTPMethod = @"GET";
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:stationRequest
                                            completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (error) {
            completion(nil, error);
        }
        else if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
            
            if (statusCode != 200) {
                NSError *jsonError = nil;
                NSDictionary *errMsg = [NSJSONSerialization JSONObjectWithData:data
                                                                  options:NSJSONReadingMutableContainers
                                                                    error:&jsonError];
                
                NSError *error = [[NSError alloc] initWithDomain:@"BCycle"
                                                            code:statusCode
                                                        userInfo:@{@"Error reason": errMsg[@"message"]}];
                completion(nil, error);
            }
            else {
                NSError *jsonError = nil;
                NSArray *stationData = [NSJSONSerialization JSONObjectWithData:data
                                                                       options:NSJSONReadingMutableContainers
                                                                         error:&jsonError];
                
                completion(stationData, error);
            }
        }
    }];
    
    [task resume];
}

- (void)getStationsInRegion:(MKCoordinateRegion)region withCompletion:(StationCompletionBlock)completion {
    
    CLLocationDistance distanceInMiles = [self maxDistance:region];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/api/v1/stations?latitude=%f&longitude=%f&distance=%f", ipPort, region.center.latitude, region.center.longitude, distanceInMiles]];
    NSMutableURLRequest *stationRequest = [NSMutableURLRequest requestWithURL:url];
    stationRequest.HTTPMethod = @"GET";
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:stationRequest
                                            completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
        }
        else if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
            
            if (statusCode != 200) {
                NSError *jsonError = nil;
                NSDictionary *errMsg = [NSJSONSerialization JSONObjectWithData:data
                                                                  options:NSJSONReadingMutableContainers
                                                                    error:&jsonError];
                
                NSError *error = [[NSError alloc] initWithDomain:@"BCycle"
                                                            code:statusCode
                                                        userInfo:@{@"Error reason": errMsg[@"message"]}];
                completion(nil, error);
            }
            else {
                NSError *jsonError = nil;
                NSArray *stationData = [NSJSONSerialization JSONObjectWithData:data
                                                                       options:NSJSONReadingMutableContainers
                                                                         error:&jsonError];
                
                completion(stationData, error);
            }
        }
        
    }];
    
    [task resume];
}

- (void)createStation:(BCycleStation*)station WithCompletion:(StationCompletionBlockWithResult)completion {
    
    NSError *error;
    NSDictionary *bcycle = @{@"name": station.name,
                             @"street": station.street,
                             @"city": station.city,
                             @"state": station.state,
                             @"zip": station.zip,
                             @"docks": station.docks,
                             @"latitude": [NSNumber numberWithDouble: station.location.latitude],
                             @"longitude": [NSNumber numberWithFloat: station.location.longitude]};
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/api/v1/stations", ipPort]];
    NSMutableURLRequest *stationRequest = [NSMutableURLRequest requestWithURL:url];
    stationRequest.HTTPMethod = @"POST";
    [stationRequest setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
    [stationRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    stationRequest.HTTPBody = [NSJSONSerialization dataWithJSONObject:bcycle
                                                              options:NSJSONWritingPrettyPrinted
                                                                error:&error];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:stationRequest
                                            completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            completion(nil, error);
        }
        else if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
            
            if (statusCode != 201) {
                NSError *jsonError = nil;
                NSDictionary *errMsg = [NSJSONSerialization JSONObjectWithData:data
                                                                  options:NSJSONReadingMutableContainers
                                                                    error:&jsonError];
                
                NSError *error = [[NSError alloc] initWithDomain:@"BCycle"
                                                            code:statusCode
                                                        userInfo:@{@"Error reason": errMsg[@"message"]}];
                completion(nil, error);
            }
            else {
                NSError *jsonError = nil;
                NSDictionary *stationData = [NSJSONSerialization JSONObjectWithData:data
                                                                            options:NSJSONReadingMutableContainers
                                                                              error:&jsonError];
                
                completion(stationData, error);
            }
        }
        
    }];
    
    [task resume];
    
}

#pragma mark - Private Methods

- (CLLocationDistance)maxDistance:(MKCoordinateRegion)region {
    
    CLLocation *furthest = [[CLLocation alloc] initWithLatitude: (region.center.latitude + (region.span.latitudeDelta/2))
                                                      longitude: (region.center.longitude + (region.span.longitudeDelta/2))];
    CLLocation *centerLoc = [[CLLocation alloc] initWithLatitude: region.center.latitude
                                                       longitude:region.center.longitude];
    return [centerLoc distanceFromLocation:furthest] / METERS_PER_MILE;
}

@end
