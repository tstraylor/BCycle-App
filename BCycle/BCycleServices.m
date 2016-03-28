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
 Name text,
 Street text,
 City text,
 State text,
 Zip text,
 Docks real,
 Latitude real,
 Longitude real,
 Created DATETIME DEFAULT CURRENT_TIMESTAMP,
 Updated DATETIME DEFAULT CURRENT_TIMESTAMP
 );
 */

// the ip and port of the bcycle api server
static NSString *ipPort = @"192.168.99.100:8080";

@implementation BCycleServices


#pragma mark - Setting

- (id)init
{
    self = [super init];
    return self;
}

- (void)getStationsWithCompletion:(StationCompletionBlock)completion
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/api/station", ipPort]];
    NSMutableURLRequest *stationRequest = [NSMutableURLRequest requestWithURL:url];
    stationRequest.HTTPMethod = @"GET";
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:stationRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(data.length > 0 && !error)
        {
            NSError *jsonError = nil;
            NSArray *stationData = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:NSJSONReadingMutableContainers
                                                                     error:&jsonError];
            completion(stationData, error);
            
        }
        else
            completion(nil, error);
    }];
    
    [task resume];
}

- (void)getStationsInRegion:(MKCoordinateRegion)region withCompletion:(StationCompletionBlock)completion
{
    NSNumber *lat1 = [NSNumber numberWithDouble:(region.center.latitude - region.span.latitudeDelta)];
    NSNumber *lat2 = [NSNumber numberWithDouble:(region.center.latitude + region.span.latitudeDelta)];
    NSNumber *long1 = [NSNumber numberWithDouble:(region.center.longitude - region.span.longitudeDelta)];
    NSNumber *long2 = [NSNumber numberWithDouble:(region.center.longitude + region.span.longitudeDelta)];

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/api/station?start_lat=%@&end_lat=%@&start_lon=%@&end_lon=%@", ipPort, lat1, lat2, long1, long2]];
    NSMutableURLRequest *stationRequest = [NSMutableURLRequest requestWithURL:url];
    stationRequest.HTTPMethod = @"GET";
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:stationRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(data.length > 0 && !error)
        {
            NSError *jsonError = nil;
            NSArray *stationData = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:NSJSONReadingMutableContainers
                                                                     error:&jsonError];
            completion(stationData, error);
            
        }
        else
            completion(nil, error);
    }];
    
    [task resume];
}

@end
