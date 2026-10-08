//
//  DuGoTabActionHandler.swift
//  DuGo-iOS
//
//  Created by 김승원 on 1/10/26.
//

import SwiftUI
import UIKit

@MainActor
final class DuGoTabActionHandler: NSObject, UITabBarControllerDelegate {
    // MARK: - Properties

    private let actionTabIndex: Int
    private weak var tabController: UITabBarController?
    private weak var originalDelegate: (any UITabBarControllerDelegate)?
    private var lastReselectedTabIndex: Int?
    private var lastReselectionTime: TimeInterval = 0
    var onAction: () -> Void = {}
    var onReselect: (Int) -> Void = { _ in }

    // MARK: - Initializer

    init(actionTabIndex: Int) {
        self.actionTabIndex = actionTabIndex
        super.init()
    }

    // MARK: - Methods

    func install(on controller: UITabBarController) {
        guard controller.delegate !== self else { return }

        if tabController !== controller, tabController?.delegate === self {
            tabController?.delegate = originalDelegate
        }

        tabController = controller
        originalDelegate = controller.delegate
        controller.delegate = self
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelectTab tab: UITab)
        -> Bool
    {
        guard let index = tabBarController.tabs.firstIndex(where: { $0 === tab }) else {
            return originalDelegate?.tabBarController?(tabBarController, shouldSelectTab: tab)
                ?? true
        }

        if index == actionTabIndex {
            onAction()
            return false
        }

        let shouldSelect =
            originalDelegate?.tabBarController?(tabBarController, shouldSelectTab: tab) ?? true
        if shouldSelect, tabBarController.selectedIndex == index {
            notifyReselection(of: index)
        }
        return shouldSelect
    }

    func tabBarController(
        _ tabBarController: UITabBarController,
        shouldSelect viewController: UIViewController
    ) -> Bool {
        guard
            let index = tabBarController.viewControllers?.firstIndex(where: {
                $0 === viewController
            })
        else {
            return originalDelegate?.tabBarController?(
                tabBarController,
                shouldSelect: viewController
            ) ?? true
        }

        if index == actionTabIndex {
            onAction()
            return false
        }

        let shouldSelect =
            originalDelegate?.tabBarController?(tabBarController, shouldSelect: viewController)
            ?? true
        if shouldSelect, tabBarController.selectedIndex == index {
            notifyReselection(of: index)
        }
        return shouldSelect
    }

    private func notifyReselection(of index: Int) {
        let now = ProcessInfo.processInfo.systemUptime
        guard index != lastReselectedTabIndex || now - lastReselectionTime > 0.15 else { return }

        lastReselectedTabIndex = index
        lastReselectionTime = now
        onReselect(index)
    }

    override func responds(to aSelector: Selector!) -> Bool {
        super.responds(to: aSelector) || (originalDelegate?.responds(to: aSelector) ?? false)
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if originalDelegate?.responds(to: aSelector) == true {
            return originalDelegate
        }
        return super.forwardingTarget(for: aSelector)
    }
}

struct DuGoTabActionInstaller: UIViewControllerRepresentable {
    // MARK: - Properties

    let handler: DuGoTabActionHandler
    let onAction: () -> Void
    let onReselect: (Int) -> Void

    // MARK: - UIViewControllerRepresentable

    func makeUIViewController(context: Context) -> InstallerViewController {
        handler.onAction = onAction
        handler.onReselect = onReselect
        return InstallerViewController(handler: handler)
    }

    func updateUIViewController(_ controller: InstallerViewController, context: Context) {
        handler.onAction = onAction
        handler.onReselect = onReselect
        controller.installHandler()
    }

    final class InstallerViewController: UIViewController {
        // MARK: - Properties

        private let handler: DuGoTabActionHandler

        // MARK: - Initializer

        init(handler: DuGoTabActionHandler) {
            self.handler = handler
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) { nil }

        // MARK: - Lifecycle

        override func loadView() {
            view = UIView()
            view.isUserInteractionEnabled = false
        }

        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            installHandler()
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            installHandler()
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            installHandler()
        }

        // MARK: - Methods

        func installHandler() {
            if let tabBarController {
                handler.install(on: tabBarController)
            }
        }
    }
}
