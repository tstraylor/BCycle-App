//
//  StationInformationViewController.m
//  BCycle
//
//  Created by Thomas Traylor on 12/22/14.
//  Copyright (c) 2014 Thomas Traylor. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "StationInformationViewController.h"

@interface StationInformationViewController ()

@property (nonatomic, strong) BCycleStation *station;
@property (weak, nonatomic) IBOutlet UIImageView *satelliteImage;
@property (weak, nonatomic) IBOutlet UILabel *stationName;
@property (weak, nonatomic) IBOutlet UILabel *streetAddress;
@property (weak, nonatomic) IBOutlet UILabel *cityStateZip;

@end

@implementation StationInformationViewController

#pragma mark - ViewController Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance([self.station location], 125.0f, 125.0f);
    
    MKMapSnapshotOptions *options = [[MKMapSnapshotOptions alloc] init];
    options.region  = region;
    //options.mapType = MKMapTypeSatellite;
    options.mapType = MKMapTypeHybrid;
    options.scale = 1.0;
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        options.size = CGSizeMake(728.0, 436.0);
    else
        options.size = CGSizeMake(320.0, 240.0);
    
    options.showsPointsOfInterest = YES;
    
    MKMapSnapshotter *snapShotter = [[MKMapSnapshotter alloc] initWithOptions:options];
    [snapShotter startWithCompletionHandler:^(MKMapSnapshot *snapshot, NSError *error) {
        
        //NSLog(@"[%@ %@] snap shotter", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
        if(error)
            NSLog(@"[%@ %@] %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error.localizedDescription);
        
        self.satelliteImage.image = snapshot.image;
        
        NSShadow *bg = [[NSShadow alloc] init];
        bg.shadowColor = [UIColor blackColor];
        bg.shadowOffset = CGSizeMake(1.5, 1.5);
        
    }];
    
    self.stationName.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    self.stationName.text = self.station.name;
    self.streetAddress.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.streetAddress.text = self.station.street;
    self.cityStateZip.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.cityStateZip.text = [NSString stringWithFormat:@"%@, %@ %@", self.station.city, self.station.state, self.station.zip];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
