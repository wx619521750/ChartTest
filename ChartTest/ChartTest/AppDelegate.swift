//
//  AppDelegate.swift
//  ChartTest
//
//  Created by Carlo on 1/13/26.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window:UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window = UIWindow.init()
        window?.makeKeyAndVisible()
        window?.rootViewController = ViewController()
        return true
    }

}

