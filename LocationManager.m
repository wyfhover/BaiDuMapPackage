//
//  LocationManager.m
//  portal
//
//  Created by apple on 16/3/24.
//  Copyright © 2016年 yantian. All rights reserved.
//

#import "LocationManager.h"
#import "Constants.h"

static LocationManager *$location;

@interface LocationManager() <BMKLocationServiceDelegate, BMKGeoCodeSearchDelegate, BMKSuggestionSearchDelegate, BMKPoiSearchDelegate>

@end


@implementation LocationManager {
    NSString *_baseCity;
    
    BMKMapManager *_mapManager;
    
    BMKLocationService *_locationService;
    BOOL _isReverse;
    BOOL _isOnceLocationGet;
    void (^_locationServiceBlock)(BMKReverseGeoCodeResult *result);
    void (^ _locationServiceWithoutReverseBlock)(BMKUserLocation *result);
    
    
    BMKGeoCodeSearch *_geoCodeSearch;
    BMKGeoCodeSearchOption *_geoCodeSearchOption;
    BMKReverseGeoCodeOption *_reverseGeoCodeSearchOption;
    void (^ _geoCodeSearchBlock)(BMKGeoCodeResult *geoCodeResult);
    void (^ _reverseGeoCodeSearchBlock)(BMKReverseGeoCodeResult *geoCodeResult);
    
    BMKSuggestionSearch *_suggestionSearch;
    BMKSuggestionSearchOption *_suggestionSearchOption;
    void (^ _suggestionSearchBlock)(BMKSuggestionResult *suggestionResult);
    
    BMKPoiSearch *_poiSearch;
    BMKNearbySearchOption *_poiSearchOption;
    int _poiSearchIndex;
    void (^ _poiSearchBlock)(BMKPoiResult *poiResult);
    
}

- (void)dealloc {
    [self stopManager];
}


+ (instancetype __nonnull) sharedManager {
    
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            $location = [[LocationManager alloc] init];
        });
        
    return $location;
}

- (void)didFailToLocateUserWithError:(NSError *)error {
    [UIViewHelper changeProgressHub:@"自动定位失败，请手动查询" andView: [[UIImageView alloc] initWithImage: [UIImage imageNamed:@"error"]]];
    [UIViewHelper disactionProgressHubDelay:1.8];
    if (_isOnceLocationGet) {
        [_locationService stopUserLocationService];
    }
}

- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation {
    if (_locationServiceWithoutReverseBlock) {
        _locationServiceWithoutReverseBlock(userLocation);
        if (_isOnceLocationGet) {
            [_locationService stopUserLocationService];
            [_locationService setDelegate:nil];
            _locationService = nil;
            
            _locationServiceWithoutReverseBlock = nil;
        }
    }
    if (_locationServiceBlock && _geoCodeSearch) {
        _reverseGeoCodeSearchOption.reverseGeoPoint = userLocation.location.coordinate;
        [_geoCodeSearch reverseGeoCode:_reverseGeoCodeSearchOption];
    }
}

- (void)location:(_locationBlock)block {
    self.block = block;
}

- (void)didUpdateUserHeading:(BMKUserLocation *)userLocation {
    if (self.block) {
        self.block(userLocation);
    }
}

-(void) onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKReverseGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error{
    if (error == BMK_SEARCH_NO_ERROR) {
        if (_locationServiceBlock) {
            _locationServiceBlock(result);
        }
        if (_reverseGeoCodeSearchBlock) {
            _reverseGeoCodeSearchBlock(result);
        }
    } else {
        if (_locationServiceBlock) {
            _locationServiceBlock(nil);
        }
        if (_reverseGeoCodeSearchBlock) {
            _reverseGeoCodeSearchBlock(result);
        }
    }
    if (_isOnceLocationGet && _locationService) {
        [_locationService stopUserLocationService];
        [_locationService setDelegate: nil];
        _locationService = nil;
        _locationServiceBlock = nil;
    }
    _reverseGeoCodeSearchBlock = nil;
}

- (void)onGetSuggestionResult:(BMKSuggestionSearch*)searcher result:(BMKSuggestionResult*)result errorCode:(BMKSearchErrorCode)error{
    if (error == BMK_SEARCH_NO_ERROR) {
        if (_suggestionSearchBlock) {
            _suggestionSearchBlock(result);
        }
    } else {
        if (_suggestionSearchBlock) {
            _suggestionSearchBlock(nil);
        }
    }
    _suggestionSearchBlock = nil;
}

- (void)onGetPoiResult:(BMKPoiSearch*)searcher result:(BMKPoiResult*)poiResultList errorCode:(BMKSearchErrorCode)error{
    if (error == BMK_SEARCH_NO_ERROR) {
        if (_poiSearchBlock) {
            if (poiResultList.pageIndex + 1 >= poiResultList.pageNum) {
                _poiSearchIndex = poiResultList.pageNum;
            } else {
                _poiSearchIndex = poiResultList.pageIndex + 1;
            }
            _poiSearchBlock(poiResultList);
        }
    } else {
        if (_poiSearchBlock) {
            _poiSearchBlock(nil);
        }
    }
    _poiSearchBlock = nil;
}

- (void)onGetGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error{
    if (error == BMK_SEARCH_NO_ERROR) {
        if (_geoCodeSearchBlock) {
            _geoCodeSearchBlock(result);
        }
    } else {
        if (_geoCodeSearchBlock) {
            _geoCodeSearchBlock(nil);
        }
    }
    _geoCodeSearchBlock = nil;
}

- (void) startManager {
    _baseCity = @"深圳市";
    if (_mapManager == nil) {
        _mapManager =  [[BMKMapManager alloc] init];
        [_mapManager start:BAIDU_MAP_AK generalDelegate:self];
    }
}


- (void) stopManager {
    if (_mapManager) {
        [_mapManager stop];
        _mapManager = nil;
    }
}


- (void) startService {
    _poiSearchIndex = 0;
    
    if (_locationService == nil) {
        _locationService = [[BMKLocationService alloc] init];
        [_locationService setDelegate: self];
    }
    
    if (_geoCodeSearch == nil) {
        _geoCodeSearch = [[BMKGeoCodeSearch alloc] init];
        _geoCodeSearchOption = [[BMKGeoCodeSearchOption alloc] init];
        _reverseGeoCodeSearchOption = [[BMKReverseGeoCodeOption alloc] init];
        [_geoCodeSearch setDelegate:self];
        [_geoCodeSearchOption setCity: _baseCity];
    }
    
    if (_suggestionSearch == nil) {
        _suggestionSearch = [[BMKSuggestionSearch alloc] init];
        _suggestionSearchOption = [[BMKSuggestionSearchOption alloc] init];
        [_suggestionSearch setDelegate:self];
        [_suggestionSearchOption setCityname: _baseCity];
    }
    
    if (_poiSearch == nil) {
        _poiSearch = [[BMKPoiSearch alloc] init];
        _poiSearchOption = [[BMKNearbySearchOption alloc] init];
        [_poiSearch setDelegate:self];
        [_poiSearchOption setPageIndex:_poiSearchIndex];
    }
}


- (void) stopService {
    if (_poiSearch) {
        _poiSearchIndex = 0;
    }
    
    if (_locationService) {
        [_locationService stopUserLocationService];
        [_locationService setDelegate: nil];
        _locationService = nil;
        _locationServiceBlock = nil;
    }
    
    if (_geoCodeSearch) {
        [_geoCodeSearch setDelegate: nil];
        _geoCodeSearch = nil;
        _geoCodeSearchOption = nil;
        _geoCodeSearchBlock = nil;
    }
    
    if (_suggestionSearch) {
        [_suggestionSearch setDelegate: nil];
        _suggestionSearch = nil;
        _suggestionSearchOption = nil;
        _suggestionSearchBlock = nil;
    }
    
    if (_poiSearch) {
        [_poiSearch setDelegate:nil];
        _poiSearch = nil;
        _poiSearchOption = nil;
        _poiSearchBlock = nil;
    }

}

- (void) startGetUserLocation {
    if (_locationService) {
        [_locationService startUserLocationService];
    }
}

- (void) stopGetUserLocation {
    if (_locationService) {
        [_locationService stopUserLocationService];
    }
}


- (void) getUserLocationAlways:(void (^ _Nonnull)(BMKUserLocation * _Nullable result)) block {
    if (_locationService == nil) {
        _locationService = [[BMKLocationService alloc] init];
        [_locationService startUserLocationService];
        [_locationService setDelegate: self];
    }
    _isOnceLocationGet = NO;
    _locationServiceWithoutReverseBlock = block;
    [_locationService startUserLocationService];
}

- (void) getUserLocationWithoutReverse:(void (^)(BMKUserLocation *result)) block {
    if (_locationService == nil) {
        _locationService = [[BMKLocationService alloc] init];
        [_locationService startUserLocationService];
        [_locationService setDelegate: self];
    }
    _isOnceLocationGet = YES;
    _locationServiceWithoutReverseBlock = block;
    [_locationService startUserLocationService];
}

- (void) getUserLocation:(void (^)(BMKReverseGeoCodeResult *result)) block {
    if (_locationService == nil) {
        _locationService = [[BMKLocationService alloc] init];
        [_locationService startUserLocationService];
        [_locationService setDelegate: self];
    }
    _isOnceLocationGet = YES;
    _locationServiceBlock = block;
    [_locationService startUserLocationService];
}


- (void) getSuggestionResult:(void (^)(BMKSuggestionResult *suggestionResult)) block withKeyword:(NSString *) keyword {
    
    if (_suggestionSearch == nil) {
        _suggestionSearch = [[BMKSuggestionSearch alloc] init];
        _suggestionSearchOption = [[BMKSuggestionSearchOption alloc] init];
        [_suggestionSearch setDelegate:self];
        [_suggestionSearchOption setCityname: _baseCity];
    }
    _suggestionSearchBlock = block;
    [_suggestionSearchOption setKeyword:keyword];
    
    [_suggestionSearch suggestionSearch:_suggestionSearchOption];
    
}


- (void) getPoiResult:(void (^)(BMKPoiResult *poiResult)) block withKeyword:(NSString *) keyword andCenterCoordinate:(CLLocationCoordinate2D) coordinate {
    if (_poiSearch == nil) {
        _poiSearch = [[BMKPoiSearch alloc] init];
        _poiSearchOption = [[BMKNearbySearchOption alloc] init];
        [_poiSearch setDelegate:self];
        [_poiSearchOption setPageIndex:_poiSearchIndex];
        _poiSearchIndex = 0;
    }
    _poiSearchBlock = block;
    [_poiSearchOption setPageIndex: _poiSearchIndex];
    [_poiSearchOption setLocation:coordinate];
    [_poiSearchOption setKeyword:keyword];
    
    [_poiSearch poiSearchNearBy:_poiSearchOption];
}


- (void) getGeoCodeResult:(void (^)(BMKGeoCodeResult *geoCodeResult)) block withGeoAddressDescription:(NSString *) geoAddressDescription {
    if (_geoCodeSearch == nil) {
        _geoCodeSearch = [[BMKGeoCodeSearch alloc] init];
        _geoCodeSearchOption = [[BMKGeoCodeSearchOption alloc] init];
        _reverseGeoCodeSearchOption = [[BMKReverseGeoCodeOption alloc] init];
        [_geoCodeSearch setDelegate:self];
        [_geoCodeSearchOption setCity: _baseCity];
    }
    _geoCodeSearchBlock = block;
    [_geoCodeSearchOption setAddress:geoAddressDescription];
    
    [_geoCodeSearch geoCode:_geoCodeSearchOption];
}


- (void) getReverseGeoCodeResult:(void (^ _Nonnull)(BMKReverseGeoCodeResult * _Nullable reverseGeoCodeResult)) block withLocationCoordinate:(CLLocationCoordinate2D) locationCoordinate {
    if (_geoCodeSearch == nil) {
        _geoCodeSearch = [[BMKGeoCodeSearch alloc] init];
        _geoCodeSearchOption = [[BMKGeoCodeSearchOption alloc] init];
        _reverseGeoCodeSearchOption = [[BMKReverseGeoCodeOption alloc] init];
        [_geoCodeSearch setDelegate:self];
        [_geoCodeSearchOption setCity: _baseCity];
    }
    _reverseGeoCodeSearchBlock = block;
    _reverseGeoCodeSearchOption.reverseGeoPoint = locationCoordinate;
    
    [_geoCodeSearch reverseGeoCode:_reverseGeoCodeSearchOption];
}

- (void) openBaiduMapAppDirectionFrom:(CLLocationCoordinate2D) start  to:(CLLocationCoordinate2D) end far:(BOOL) far{
    //初始化调启导航时的参数管理类
    BMKNaviPara *para = [[BMKNaviPara alloc]init];
    BMKPlanNode *startNode = [[BMKPlanNode alloc]init];
    [startNode setPt:start];
    BMKPlanNode *endNode = [[BMKPlanNode alloc]init];
    [endNode setPt:end];
    
    [para setStartPoint:startNode];
    [para setEndPoint:endNode];
    
    para.appScheme = @"baidumapsdk://mapsdk.baidu.com";
    
    if (far) {
        [BMKNavigation openBaiduMapNavigation:para];
    } else {
        [BMKNavigation openBaiduMapWalkNavigation:para];
    }
}

- (void) openBaiduMapAppRouteFrom: (CLLocationCoordinate2D) start to:(CLLocationCoordinate2D) end far:(BOOL) far {
    if (far) {
        BMKOpenDrivingRouteOption *opt = [[BMKOpenDrivingRouteOption alloc] init];
        opt.appScheme = @"baidumapsdk://mapsdk.baidu.com";
        //初始化起点节点
        BMKPlanNode* startNode = [[BMKPlanNode alloc]init];
        [startNode setPt:start];
        opt.startPoint = startNode;
        
        BMKPlanNode *endNode = [[BMKPlanNode alloc]init];
        [endNode setPt:end];
        opt.endPoint = endNode;
        
        [BMKOpenRoute openBaiduMapDrivingRoute:opt];
    } else {
        
        BMKOpenWalkingRouteOption *opt = [[BMKOpenWalkingRouteOption alloc] init];
        opt.appScheme = @"baidumapsdk://mapsdk.baidu.com";
        //初始化起点节点
        BMKPlanNode* startNode = [[BMKPlanNode alloc]init];
        [startNode setPt:start];
        opt.startPoint = startNode;
        
        BMKPlanNode *endNode = [[BMKPlanNode alloc]init];
        [endNode setPt:end];
        opt.endPoint = endNode;
        
        [BMKOpenRoute openBaiduMapWalkingRoute:opt];
    }
}

@end
