//
//  SHMapViewController.m
//  Map View Controller
//
//  Created by Scott Hoyt on 3/6/14.
//  Copyright (c) 2014 Wild Onion Labs. All rights reserved.
//

#import "CenterPinMapViewController.h"

@interface CenterPinMapViewController () <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) MKPointAnnotation *centerAnnotaion;
@property (strong, nonatomic) MKPinAnnotationView *centerAnnotationView;

@end

@implementation CenterPinMapViewController

#pragma mark - Setters/Getters

- (MKPointAnnotation *)centerAnnotaion
{
    if (!_centerAnnotaion) {
        _centerAnnotaion = [[MKPointAnnotation alloc] init];
    }
    
    return _centerAnnotaion;
}

- (MKPinAnnotationView *)centerAnnotationView
{
    if (!_centerAnnotationView) {
        _centerAnnotationView = [[MKPinAnnotationView alloc] initWithAnnotation:self.centerAnnotaion
                                                                reuseIdentifier:@"centerAnnotationView"];
        _centerAnnotationView.pinColor = MKPinAnnotationColorPurple;
    }
    
    return _centerAnnotationView;
}

- (CLLocationCoordinate2D)selectedCoordinate
{
    return self.mapView.centerCoordinate;
}

- (void)setMapView:(MKMapView *)mapView
{
    // Remove ourselves as delegate to old and add to new
    if (_mapView) {
        _mapView.delegate = nil;
    }
    
    _mapView = mapView;
    
    if (_mapView) {
        mapView.delegate = self;
    }
}

#define DEFAULT_INITIAL_SIZE 5000000

- (NSUInteger)initialMapSize
{
    if (!_initialMapSize) {
        _initialMapSize = DEFAULT_INITIAL_SIZE;
    }
    
    return _initialMapSize;
}

#define DEFAULT_ZOOM_SIZE 1000

- (NSUInteger)zoomMapSize
{
    if (!_zoomMapSize) {
        _zoomMapSize = DEFAULT_ZOOM_SIZE;
    }
    
    return _zoomMapSize;
}

- (void)setDoesDisplayPointAccuracyIndicators:(BOOL)doesDisplayPointAccuracyIndicators
{
    _doesDisplayPointAccuracyIndicators = doesDisplayPointAccuracyIndicators;
    [self updatePointAccuracyIndicators];
}

-(void)setRequiredPointAccuracy:(CLLocationDistance)requiredPointAccuracy
{
    _requiredPointAccuracy = requiredPointAccuracy;
    [self updatePointAccuracyIndicators];
}

- (void)setZoomToUser:(BOOL)zoomToUser
{
    if (zoomToUser) {
        if (self.mapView.showsUserLocation && self.mapView.userLocation.location && !self.mapView.userLocation.updating) {
            [self changeRegionToCoordinate:self.mapView.userLocation.location.coordinate withSize:self.zoomMapSize];
            _zoomToUser = NO;
        } else {
            _zoomToUser = YES;
        }
    } else
    {
        _zoomToUser = NO;
    }
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.mapView addSubview:self.centerAnnotationView];
}

// Default center of the map is the geographic center of the US
#define DEFAULT_CENTER_LATTITUDE 39.8282
#define DEFAULT_CENTER_LONGITUDE -98.5795

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake(DEFAULT_CENTER_LATTITUDE, DEFAULT_CENTER_LONGITUDE),self.initialMapSize, self.initialMapSize)];
    [self metersPerViewPoint];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self moveMapAnnotationToCoordinate:self.mapView.centerCoordinate];
}

#pragma mark - main methods

// These are the constants need to offset distance between the lower left corner of
// the annotaion view and the head of the pin
#define PIN_WIDTH_OFFSET 7.75
#define PIN_HEIGHT_OFFSET 5

- (void)moveMapAnnotationToCoordinate:(CLLocationCoordinate2D) coordinate
{
    CGPoint mapViewPoint = [self.mapView convertCoordinate:coordinate toPointToView:self.mapView];
    
    // Offset the view from to account for distance from the lower left corner to the pin head
    CGFloat xoffset = CGRectGetMidX(self.centerAnnotationView.bounds) - PIN_WIDTH_OFFSET;
    CGFloat yoffset = -CGRectGetMidY(self.centerAnnotationView.bounds) + PIN_HEIGHT_OFFSET;
    
    self.centerAnnotationView.center = CGPointMake(mapViewPoint.x + xoffset,
                                                   mapViewPoint.y + yoffset);
}

- (void)changeRegionToCoordinate:(CLLocationCoordinate2D)coordinate withSize:(NSUInteger)size
{
    MKCoordinateRegion newRegion = MKCoordinateRegionMakeWithDistance(coordinate, size, size);
    [self.mapView setRegion:newRegion animated:YES];
}

- (CLLocationDistance)metersPerViewPoint
{
    CGRect comparisonRect = CGRectMake(self.mapView.center.x,
                                       self.mapView.center.y,
                                       1,
                                       1);
    MKCoordinateRegion comparisonRegion = [self.mapView convertRect:comparisonRect toRegionFromView:self.mapView];
    CLLocationCoordinate2D comparisonCoordinate1 = CLLocationCoordinate2DMake(comparisonRegion.center.latitude - comparisonRegion.span.latitudeDelta,
                                                                              comparisonRegion.center.longitude - comparisonRegion.span.longitudeDelta);
    CLLocationCoordinate2D comparisonCoordinate2 = CLLocationCoordinate2DMake(comparisonRegion.center.latitude + comparisonRegion.span.latitudeDelta,
                                                                             comparisonRegion.center.longitude + comparisonRegion.span.longitudeDelta);
    CLLocationDistance sizeInMeters = MKMetersBetweenMapPoints(MKMapPointForCoordinate(comparisonCoordinate1),
                                                                MKMapPointForCoordinate(comparisonCoordinate2));
    
    return sizeInMeters;
}

- (BOOL)mapIsAtValidZoomScale
{
    if (self.requiredPointAccuracy) {
        return [self metersPerViewPoint] <= self.requiredPointAccuracy;
    } else {
        return YES;
    }
}

#define INDICATOR_BORDER_WIDTH 5

- (void)updatePointAccuracyIndicators
{
    if (self.doesDisplayPointAccuracyIndicators && self.requiredPointAccuracy > 0) {
        if ([self mapIsAtValidZoomScale]) {
            self.mapView.layer.borderColor = [UIColor greenColor].CGColor;
            self.mapView.layer.borderWidth = INDICATOR_BORDER_WIDTH;
        } else {
            self.mapView.layer.borderColor = [UIColor redColor].CGColor;
            self.mapView.layer.borderWidth = INDICATOR_BORDER_WIDTH;
        }
    }
    else
    {
        self.mapView.layer.borderWidth = 0;
    }

}

#pragma mark - MapView Delegate methods


- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    self.centerAnnotaion.coordinate = mapView.centerCoordinate;
    [self moveMapAnnotationToCoordinate:mapView.centerCoordinate];
    
    if (self.doesDisplayPointAccuracyIndicators && self.requiredPointAccuracy > 0) {
        [self updatePointAccuracyIndicators];
    }
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if (self.zoomToUser) {
        [self changeRegionToCoordinate:userLocation.coordinate withSize:self.zoomMapSize];
        self.zoomToUser = NO;
    }
}

@end