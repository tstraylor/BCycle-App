//
//  BCycleStationsViewController.m
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

#import <MapKit/MapKit.h>
#import "BCycleStationsViewController.h"
#import "BCycleServices.h"
#import "StationInformationViewController.h"

#if !defined(METERS_PER_MILE)
#define METERS_PER_MILE 1609.344
#endif

@interface BCycleStationsViewController ()


@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic, strong) CLPlacemark *currentPlacemark;
@property (nonatomic, strong) BCycleServices *bCycleServices;
@property (nonatomic) BOOL userInteractionCausedRegionChange;
@property (nonatomic) MKMapRect currentSearchRect;
@property (nonatomic) MKCoordinateSpan currentSearchSpan;

- (void)addAnnotationsForRegion:(MKCoordinateRegion)region;
- (MKMapRect)createRectForRegion:(MKCoordinateRegion)region;
- (MKCoordinateRegion)createSearchRegionForLocation:(CLLocationCoordinate2D)coordinate andDistance:(CLLocationDistance)distance;
- (MKCoordinateRegion)createViewableRegionForLocation:(CLLocationCoordinate2D)coordinate andDistance:(CLLocationDistance)distance;
- (MKCoordinateRegion)createNewSearchRegionForRegion:(MKCoordinateRegion)region;

@end

@implementation BCycleStationsViewController

#pragma mark - Setters

- (CLLocationManager*)locationManager {
    if (_locationManager == nil) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.distanceFilter = kCLDistanceFilterNone;
        _locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        _locationManager.activityType = CLActivityTypeOtherNavigation;
    }
    
    return _locationManager;
}

- (BCycleServices*)bCycleServices {
    if (_bCycleServices == nil) {
        _bCycleServices = [[BCycleServices alloc] init];
    }
    
    return _bCycleServices;
}

#pragma  mark - ViewController Life Cycle

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.title = @"BCycle";
    
    self.userInteractionCausedRegionChange = NO;
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
    self.mapView.pitchEnabled = YES;
    self.mapView.zoomEnabled = YES;
    self.mapView.rotateEnabled = YES;
    self.navigationController.navigationBar.tintColor = [UIColor redColor];
    
    NSDictionary *textAttributes = @{NSForegroundColorAttributeName : [UIColor redColor]};
    self.navigationController.navigationBar.titleTextAttributes = textAttributes;

    [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager startUpdatingLocation];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    self.currentLocation = [locations lastObject];
    
    // once we know where we are, we don't need to keep the location services running,
    // so stop it
    [self.locationManager stopUpdatingLocation];
    
    // save our current Placemark.
    CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
    [geoCoder reverseGeocodeLocation:self.currentLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        if(error == nil) {
            self.currentPlacemark = placemarks[0];
        }
    }];
    
    // remove the annotations if there are any
    [self.mapView removeAnnotations:self.mapView.annotations];
    // center the map
    [self.mapView setCenterCoordinate:self.currentLocation.coordinate animated:YES];
    
    // create the initial search area
    MKCoordinateRegion searchRegion = [self createSearchRegionForLocation:self.currentLocation.coordinate andDistance:1.0f];
    
    // fetch the data for the annotations
    [self addAnnotationsForRegion:searchRegion];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
    if(error)
        NSLog(@"[%@ %@] error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [error localizedDescription]);
    
    if ([error code] != kCLErrorLocationUnknown) {
        [self.locationManager stopUpdatingLocation];
        // since we only have data for Denver, we'll center the map there
        self.mapView.centerCoordinate = CLLocationCoordinate2DMake(39.758202, -105.001359);
    }
    
}

-(void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager {
    
    switch (self.locationManager.authorizationStatus) {
            
        case kCLAuthorizationStatusNotDetermined:
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            [self.locationManager startUpdatingLocation];
            break;
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied:
            [self.locationManager stopUpdatingLocation];
            break;
            
    }
}

#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    MKCoordinateRegion region = [self createViewableRegionForLocation:userLocation.coordinate andDistance:0.5f];
    if (self.userInteractionCausedRegionChange == NO) {
        [self addAnnotationsForRegion:region];
    }
    [self.mapView setRegion:region animated:YES];
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    UIView* view = mapView.subviews.firstObject;
    // check to see if the user is interacting with the map
    for(UIGestureRecognizer* recognizer in view.gestureRecognizers) {
        if(recognizer.state == UIGestureRecognizerStateBegan || recognizer.state == UIGestureRecognizerStateEnded) {
            self.userInteractionCausedRegionChange = YES;
            break;
        }
    }
}

-(void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    if(self.userInteractionCausedRegionChange) {
        self.userInteractionCausedRegionChange = NO;
        MKMapPoint mapPoint = MKMapPointForCoordinate(mapView.region.center);
        if (MKMapRectContainsPoint(self.currentSearchRect, mapPoint)) {
            MKMapRect viewableRect = [self createRectForRegion:mapView.region];
            if (!MKMapRectContainsRect(self.currentSearchRect, viewableRect)) {
                // the user has zoomed out but the viewable region's center point is still
                // within the current search map rect. We will use the current region center
                // and increase the span by some percentage to create a new search region (map rect)
                MKCoordinateRegion region = [self createNewSearchRegionForRegion:mapView.region];
                [self addAnnotationsForRegion:region];
            }
        }
        else {
            // the user may have zoomed out, but nonetheless the region center is outside the
            // current search map rect. We will use the current region center and increase
            // the span by some percentage to create a new search region (map rect)
            MKCoordinateRegion region = [self createNewSearchRegionForRegion:mapView.region];
            [self addAnnotationsForRegion:region];
        }
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    // the mkannotationview we'll return
    MKAnnotationView *view = nil;
    
    //if the annotation is a user location
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        view = nil;
    }
    else {
        view = [mapView dequeueReusableAnnotationViewWithIdentifier:NSStringFromClass([annotation class])];
        
        if(!view) {
            MKMarkerAnnotationView *marker = [[MKMarkerAnnotationView alloc] initWithAnnotation:annotation
                                                                             reuseIdentifier:NSStringFromClass([annotation class])];
            marker.canShowCallout = YES;
            marker.enabled = YES;
            marker.draggable = NO;
            marker.markerTintColor = [UIColor redColor];
            
            if([mapView.delegate respondsToSelector:@selector(mapView:annotationView:calloutAccessoryControlTapped:)]) {
                marker.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            }
            
            view = marker;
        }
        else {
            // set the annotation for the view
            view.annotation = annotation;
        }
    }
    
    return view;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    [self performSegueWithIdentifier:@"StationInformation" sender:view];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"StationInformation"]) {
        if ([sender isKindOfClass:[MKAnnotationView class]]) {
            MKAnnotationView *aView = sender;
            if ([aView.annotation isKindOfClass:[BCycleStation class]]) {
                BCycleStation *station = (id) aView.annotation;
                if ([segue.destinationViewController respondsToSelector:@selector(setStation:)]) {
                    [segue.destinationViewController performSelector:@selector(setStation:)
                                                          withObject:station];
                }
            }
        }
    }
    else if ([segue.identifier isEqualToString:@"AddStation"]) {
        if ([segue.destinationViewController respondsToSelector:@selector(setCurrentPlacemark:)]) {
            [segue.destinationViewController performSelector:@selector(setCurrentPlacemark:)
                                                  withObject:self.currentPlacemark];
        }
    }
}

#pragma mark - Private Methods

- (void)addAnnotationsForRegion:(MKCoordinateRegion)region
{
    [self.bCycleServices getStationsInRegion:region withCompletion:^(NSArray *result, NSError *error) {
        
        if(result.count > 0) {
            dispatch_queue_t geoQue = dispatch_queue_create("geoQue", (dispatch_queue_attr_t) 0);
            dispatch_async(geoQue, ^{
                
                NSMutableArray *bikes = [[NSMutableArray alloc] init];
                for (NSDictionary *station in result) {
                    CLLocationDegrees latitude = [[station valueForKey:@"latitude"] floatValue];
                    CLLocationDegrees longitude = [[station valueForKey:@"longitude"] floatValue];
                    CLLocationCoordinate2D location = CLLocationCoordinate2DMake(latitude, longitude);
                    
                    BCycleStation *bc = [[BCycleStation alloc] initWithCoordinate:location];
                    [bc setName:[station valueForKey:@"name"]];
                    [bc setStreet:[station valueForKey:@"street"]];
                    [bc setCity:[station valueForKey:@"city"]];
                    [bc setState:[station valueForKey:@"state"]];
                    [bc setZip:[station valueForKey:@"zip"]];
                    
                    [bikes addObject:bc];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [self.mapView addAnnotations:bikes];
                    
                });
            });
        }
    }];
}

#pragma mark - Map Regions

- (MKMapRect)createRectForRegion:(MKCoordinateRegion)region {
    
    MKMapPoint a = MKMapPointForCoordinate(CLLocationCoordinate2DMake(region.center.latitude + region.span.latitudeDelta / 2.0,
                                                                      region.center.longitude - region.span.longitudeDelta / 2.0));
    MKMapPoint b = MKMapPointForCoordinate(CLLocationCoordinate2DMake(region.center.latitude - region.span.latitudeDelta / 2.0,
                                                                      region.center.longitude + region.span.longitudeDelta / 2.0));
    
    return MKMapRectMake(MIN(a.x,b.x), MIN(a.y,b.y), ABS(a.x-b.x), ABS(a.y-b.y));
}

- (MKCoordinateRegion)createSearchRegionForLocation:(CLLocationCoordinate2D)coordinate andDistance:(CLLocationDistance)distance {
    CLLocationDirection latInMeters = distance*METERS_PER_MILE;
    CLLocationDirection longInMeters = distance*METERS_PER_MILE;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinate, latInMeters, longInMeters);
    
    self.currentSearchSpan = region.span;
    self.currentSearchRect = [self createRectForRegion:region];
    
    return region;
}

- (MKCoordinateRegion)createViewableRegionForLocation:(CLLocationCoordinate2D)coordinate andDistance:(CLLocationDistance)distance {
    CLLocationDirection latInMeters = distance*METERS_PER_MILE;
    CLLocationDirection longInMeters = distance*METERS_PER_MILE;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinate, latInMeters, longInMeters);
    
    return region;
}

- (MKCoordinateRegion)createNewSearchRegionForRegion:(MKCoordinateRegion)region {
    MKCoordinateSpan span = region.span;
    if(span.latitudeDelta < self.currentSearchSpan.latitudeDelta) {
        // since the viewable span's latitude delta is less than
        // the search span latitude delta we'll add the diff of the two
        // to the current viewable span
        span.latitudeDelta = self.currentSearchSpan.latitudeDelta + (self.currentSearchSpan.latitudeDelta - span.latitudeDelta);
    }
    else {
        // since the viewable span's latitude delta is larger than the search span
        // latitude delta we'll add 50% to the viewable region
        span.latitudeDelta += (span.latitudeDelta * 0.5f);
    }
    
    MKCoordinateRegion newRegion = MKCoordinateRegionMake(region.center, span);
    self.currentSearchSpan = newRegion.span;
    self.currentSearchRect = [self createRectForRegion:newRegion];
    return newRegion;
}

@end
