//
//  Param.swift
//  
//
//  Created by YuYue on 2022/7/24.
//

import Foundation

extension Route {
    
    /// Generate by open url and user info dictionary,
    /// and it will be passed to the `init(param: Route.Param)` of the routable UIViewController.
    public class Param: NSObject {
        public let sourceURL: URL
        
        public var scheme: String {
            return sourceURL.scheme ?? ""
        }
        
        var routeID: String {
            return (sourceURL.host ?? "") + sourceURL.path
        }
        
        public var host: String {
            return sourceURL.host ?? ""
        }
        
        public var path: String {
            return sourceURL.path
        }

        public var fragment: String {
            return sourceURL.fragment ?? ""
        }
        
        /// Params from url query
        public let queryParams: [String: String]
        
        /// Params from `init` method
        public let userInfo: [String: Any]
        
        /// Combination of `queryParams` and `userInfo`
        public let allParams: [String: Any]
       
        public init(url:URL, userInfo: [String: Any] = [:]) {
            self.sourceURL = url
            self.userInfo = userInfo
            self.queryParams = url.queryParameters
            self.allParams = self.userInfo + self.queryParams
        }
        
        public var fallbackURL: URL? {
            guard let urlString = allParams[Route.fallbackURLKey].string else { return nil }
            return urlString.toURL()
        }

        public var animated: Bool? {
            return !allParams[Route.noAnimationKey].bool
        }
        
        public static var `default` = Param(url: URL(string: "\(Route.defaultScheme)://")!)
    }
}
