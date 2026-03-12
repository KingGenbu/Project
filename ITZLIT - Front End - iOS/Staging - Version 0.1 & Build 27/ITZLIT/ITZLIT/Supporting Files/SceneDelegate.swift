//
//  SceneDelegate.swift
//  ITZLIT
//
//  Adopted as part of iOS 13+ scene-based lifecycle modernisation.
//  Each UIWindowScene instance owns its own UIWindow; this replaces the
//  `var window: UIWindow?` that previously lived in AppDelegate.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    // MARK: - Connection

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        // The storyboard-based window is created automatically from
        // UIMainStoryboardFile in Info.plist; nothing extra needed here.
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {}

    // MARK: - Foreground / Background transitions

    func sceneDidBecomeActive(_ scene: UIScene) {
        ILSocketManager.shared.resumeConnection()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    func sceneWillResignActive(_ scene: UIScene) {}

    func sceneWillEnterForeground(_ scene: UIScene) {}

    func sceneDidEnterBackground(_ scene: UIScene) {
        ILSocketManager.shared.pauseConnection()
    }
}
