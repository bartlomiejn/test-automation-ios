//
//  Navigator.swift
//  TestAutomationExample
//
//  Created by Bartomiej Nowak on 06/11/2018.
//  Copyright © 2018 Bartłomiej Nowak. All rights reserved.
//

import UIKit

enum PresentationMode: String {
    case root
    case navigationStack
    case modal
}

protocol NavigatorProtocol: AnyObject {
    func present(as mode: PresentationMode, controller: UIViewController)
    func dismiss(animated: Bool, completion: (() -> Void)?)
}

final class Navigator: NavigatorProtocol {
    
    private let application: ApplicationProtocol
    private var presentingController: UIViewController?
    
    init(application: ApplicationProtocol) {
        self.application = application
    }
    
    func present(as mode: PresentationMode, controller: UIViewController) {
        switch mode {
        case .root:
            presentAsRoot(controller)
        case .modal:
            presentAsModal(controller)
        case .navigationStack:
            presentOnNavigationStack(controller)
        }
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        presentingController?.dismiss(animated: animated, completion: completion)
    }
    
    private func presentAsRoot(_ controller: UIViewController) {
        application.keyWindow?.rootViewController = controller
        application.keyWindow?.makeKeyAndVisible()
    }
    
    private func presentAsModal(_ controller: UIViewController) {
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalTransitionStyle = .coverVertical
        topPresentedViewController()?.present(navigationController, animated: true, completion: nil)
    }
    
    private func presentOnNavigationStack(_ controller: UIViewController) {
        guard let topNavigationController = topNavigationController() else {
            return
        }
        topNavigationController.pushViewController(controller, animated: true)
    }
    
    private func topNavigationController() -> UINavigationController? {
        guard let topViewController = topPresentedViewController() else {
            return nil
        }
        switch topViewController {
        case let navigationViewController as UINavigationController:
            return navigationViewController
        case let tabBarViewController as UITabBarController:
            return tabBarViewController.selectedViewController as? UINavigationController
        default:
            return nil
        }
    }
    
    private func topPresentedViewController() -> UIViewController? {
        guard let rootViewController = application.keyWindow?.rootViewController else {
            return nil
        }
        var topViewController = rootViewController
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }
        return topViewController
    }
}
