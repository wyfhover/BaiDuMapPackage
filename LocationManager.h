//
//  LocationManager.h
//  portal
//
//  Created by apple on 16/3/24.
//  Copyright © 2016年 yantian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BaiduMapAPI_Base/BMKBaseComponent.h>
#import <BaiduMapAPI_Map/BMKMapComponent.h>
#import <BaiduMapAPI_Location/BMKLocationComponent.h>
#import <BaiduMapAPI_Map/BMKMapView.h>
#import <BaiduMapAPI_Map/BMKPointAnnotation.h>
#import <BaiduMapAPI_Map/BMKPinAnnotationView.h>
#import <BaiduMapAPI_Search/BMKSearchComponent.h>
#import <BaiduMapAPI_Utils/BMKUtilsComponent.h>
#import "UIViewHelper.h"

typedef void (^_locationBlock)(BMKUserLocation *__nullable userLocation);

@interface LocationManager : NSObject
@property (copy, nonatomic, null_unspecified) _locationBlock block;
- (void)location:(__nullable _locationBlock)block;
/**
 *  获取对象
 *
 *  @return
 */
+ (instancetype __nonnull) sharedManager;

/**
 *  开始管理
 *
 *  @param logout 是否需要打印日志
 
 */
- (void) startManager;

/**
 *  停止管理
 */
- (void) stopManager;

/**
 *  开始服务
 */
- (void) startService;

/**
 *  结束服务
 */
- (void) stopService;

/**
 *  开启获取用户定位，配合getUserLocationAlways:使用
 */
- (void) startGetUserLocation;

/**
 *  关闭获取用户定位，配合getUserLocationAlways:使用
 */
- (void) stopGetUserLocation;

/**
 *  不间断获取用户地址
 *
 *  @param block 获取结果反馈
 */
- (void) getUserLocationAlways:(void (^ _Nonnull)(BMKUserLocation * _Nullable result)) block;

/**
 *  仅获取一次用户地址
 *
 *  @param block 获取结果反馈
 */
- (void) getUserLocation:(void (^ _Nonnull)(BMKReverseGeoCodeResult * _Nullable result)) block;

/**
 *  获取关键词查询建议
 *
 *  @param block
 *  @param keyword
 */
- (void) getSuggestionResult:(void (^ _Nonnull)(BMKSuggestionResult * _Nullable suggestionResult)) block withKeyword:(NSString * _Nonnull) keyword;

/**
 *  获取关键词查询poi
 *
 *  @param block
 *  @param keyword
 *  @param coordinate
 */
- (void) getPoiResult:(void (^ _Nonnull)(BMKPoiResult * _Nullable poiResult)) block withKeyword:(NSString * _Nonnull) keyword andCenterCoordinate:(CLLocationCoordinate2D) coordinate;

/**
 *  获取地理信息地址描述对应的地理信息值
 *
 *  @param block  
 *  @param geoAddressDescription
 */
- (void) getGeoCodeResult:(void (^ _Nonnull)(BMKGeoCodeResult * _Nullable geoCodeResult)) block withGeoAddressDescription:(NSString * _Nonnull) geoAddressDescription;

/**
 *  获取地理信息地址反查结果
 *
 *  @param block
 *  @param locationCoordinate
 */
- (void) getReverseGeoCodeResult:(void (^ _Nonnull)(BMKReverseGeoCodeResult * _Nullable reverseGeoCodeResult)) block withLocationCoordinate:(CLLocationCoordinate2D) locationCoordinate;

/**
 *  仅获取一次用户地址，不逆向求解地址
 *
 *  @param block 
 */
- (void) getUserLocationWithoutReverse:(void (^ _Nonnull)(BMKUserLocation * _Nullable result)) block;

/**
 *  打开百度地图导航
 *
 *  @param start
 *  @param end
 *  @param walk  是否步行
 *
 */
- (void) openBaiduMapAppDirectionFrom:(CLLocationCoordinate2D) start  to:(CLLocationCoordinate2D) end far:(BOOL) walk;

/**
 *  打开百度地图路线规划
 *
 *  @param start start
 *  @param end   end
 *  @param walk  是否步行
 */
- (void) openBaiduMapAppRouteFrom: (CLLocationCoordinate2D) start to:(CLLocationCoordinate2D) end far:(BOOL) walk;
@end