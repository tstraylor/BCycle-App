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

// the ip and port of the station api server
static NSString *ipPort = @"192.168.1.143:8080";

@interface BCycleServices()

@property(strong, nonatomic) NSOperationQueue *stationQueue;

@end

@implementation BCycleServices

@synthesize stationQueue = _stationQueue;

#pragma mark - Setting

- (NSOperationQueue *)stationQueue
{
    if (!_stationQueue) {
        _stationQueue = [[NSOperationQueue alloc] init];
    }
    
    return _stationQueue;
}

- (id)init
{
    self = [super init];
    return self;
}

- (void)getStationsWithCompletion:(StationCompletionBlock)completion
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/api/stations", ipPort]];
    NSMutableURLRequest *stationRequest = [NSMutableURLRequest requestWithURL:url];
    stationRequest.HTTPMethod = @"GET";
    [NSURLConnection sendAsynchronousRequest:stationRequest
                                       queue:self.stationQueue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               //NSLog(@"[%@ %@] data: %s", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [data bytes]);
                               if(data.length > 0 && !connectionError)
                               {
                                   NSError *jsonError = nil;
                                   NSArray *stationData = [NSJSONSerialization JSONObjectWithData:data
                                                                                          options:NSJSONReadingMutableContainers
                                                                                            error:&jsonError];
                                   completion(stationData, connectionError);
                                   
                               }
                               else
                                   completion(nil, connectionError);
                           }];

}

- (void)getStationsInRegion:(MKCoordinateRegion)region withCompletion:(StationCompletionBlock)completion
{
    NSNumber *lat1 = [NSNumber numberWithDouble:(region.center.latitude - region.span.latitudeDelta)];
    NSNumber *lat2 = [NSNumber numberWithDouble:(region.center.latitude + region.span.latitudeDelta)];
    NSNumber *long1 = [NSNumber numberWithDouble:(region.center.longitude - region.span.longitudeDelta)];
    NSNumber *long2 = [NSNumber numberWithDouble:(region.center.longitude + region.span.longitudeDelta)];
    
    NSDictionary *data = @{@"StartLat": lat1,
                           @"EndLat": lat2,
                           @"StartLong": long1,
                           @"EndLong": long2};

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/api/stationInRegion", ipPort]];
    NSMutableURLRequest *stationRequest = [NSMutableURLRequest requestWithURL:url];
    stationRequest.HTTPMethod = @"POST";
    [stationRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    stationRequest.HTTPBody = [NSJSONSerialization dataWithJSONObject:data options:0 error:nil];
    
    [NSURLConnection sendAsynchronousRequest:stationRequest
                                       queue:self.stationQueue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               //NSLog(@"[%@ %@] data: %s", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [data bytes]);
                               if(data.length > 0 && !connectionError)
                               {
                                   NSError *jsonError = nil;
                                   NSArray *stationData = [NSJSONSerialization JSONObjectWithData:data
                                                                                          options:NSJSONReadingMutableContainers
                                                                                            error:&jsonError];
                                   completion(stationData, connectionError);
                                   
                               }
                               else
                                   completion(nil, connectionError);
                           }];
        
}

@end
