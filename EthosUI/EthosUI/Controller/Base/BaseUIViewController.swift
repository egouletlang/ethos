//
//  BaseUIViewController.swift
//  EthosUI
//
//  Created by Etienne Goulet-Lang on 4/21/19.
//  Copyright © 2019 egouletlang. All rights reserved.
//

import Foundation
import EthosUtil
import EthosText

public class BaseUIViewController: UIViewController, LifeCycleInterface, ReusableComponentInterface {
    
    public init() {
        super.init(nibName: nil, bundle: nil)
        (self as LifeCycleInterface).initialize?()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        (self as LifeCycleInterface).destroy?()
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.createLayout()
    }
    
    override public func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if self.size != view.frame.size || self.topLayout != effectiveTopLayoutGuide {
            self.size = view.frame.size
            self.topLayout = effectiveTopLayoutGuide
            frameUpdate()
        }
    }
    
    // MARK: - State variables
    fileprivate var size = CGSize.zero
    
    fileprivate var topLayout: CGFloat = 0
    
    public var effectiveTopLayoutGuide: CGFloat {
        guard self.navigationController != nil else { return 0 }
        return UIHelper.statusBarHeight + UIHelper.navigationBarHeight
    }
    
    public var effectiveBottomLayoutGuide: CGFloat {
        return self.view.frame.height - keyboardHeight
    }
    
    // MARK: - UI
    public var isVisible: Bool {
        var ret = self.view.window != nil && self.isViewLoaded
        
        #if MAIN
        ret = ret && UIApplication.shared.applicationState == .active
        #endif
        
        return ret
    }
    
    public var defaultBackgroundColor: UIColor {
        return UIColor.clear
    }
    
    override public var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    fileprivate var tableViews: [UITableView] {
        return self.view.subviews.compactMap() { $0 as? UITableView }
    }
    
    @discardableResult
    fileprivate func resignNested(view: UIView) -> Bool {
        for v in self.view.subviews {
            if v.resignFirstResponder() || resignNested(view: v) {
                return true
            }
        }
        return false
    }
    
    fileprivate func createUI() {
        self.view.backgroundColor = self.defaultBackgroundColor
    }
    
    // MARK: - Navigation Interface
    public var navigationTitle: String? {
        return nil
    }
    
    public var navigationFont: UIFont {
        return EthosTextConfig.shared.regularFont.withSize(navigationFontSize)
    }
    
    public var navigationFontSize: CGFloat {
        return EthosTextConfig.shared.fontSize + 1
    }
    
    public var navigationTint: UIColor? {
        return UIColor.white
    }
    
    public func setNavigationItem(navigationItem: BaseNavigationBarItem, left: Bool) {
        if left {
            self.navigationItem.leftBarButtonItem = navigationItem.button
        } else {
            self.navigationItem.rightBarButtonItem = navigationItem.button
        }
    }
    
    public func removeNavigationItem(left: Bool) {
        if left {
            self.navigationItem.leftBarButtonItem?.image = nil
        } else {
            self.navigationItem.rightBarButtonItems?.removeAll()
        }
    }
    
    public func buildNavigationItemDescriptor(text: String, selector: Selector,
                                              target: AnyObject? = nil) -> BaseNavigationBarItem {
        return TextNavigationBarItem(target: target ?? self, selector: selector)
            .with(label: text)
            .with(font: self.navigationFont)
            .with(tint: self.navigationTint)
    }
    
    public func buildNavigationItemDescriptor(url: String, selector: Selector,
                                       target: AnyObject? = nil) -> BaseNavigationBarItem {
        return ImageNavigationBarItem(target: target ?? self, selector: selector)
            .with(imageUri: url)
            .with(tint: self.navigationTint)
    }
    
    public func buildNavigationItemDescriptor(img: UIImage, selector: Selector,
                                       target: AnyObject? = nil) -> BaseNavigationBarItem {
        return ImageNavigationBarItem(target: target ?? self, selector: selector)
            .with(image: img)
            .with(tint: self.navigationTint)
    }
    
    fileprivate func createNavigation() {
        self.navigationItem.title = self.navigationTitle
        
        var attr = [NSAttributedString.Key: Any]()
        attr.set(NSAttributedString.Key.font, navigationFont.withSize(navigationFontSize), allowNil: false)
        self.navigationController?.navigationBar.titleTextAttributes = attr
        
    }
    
    // MARK: - Dismiss
    public enum DismissType {
        case none
        case text
        case image
    }
    
    public var dismissType: DismissType {
        if dismissImageUri != nil || dismissImage != nil {
            return .image
        } else if dismissTitle != nil {
            return .text
        }
        
        return .none
    }
    
    public var dismissTitle: String? {
        return nil
    }
    
    public var dismissImageUri: String? {
        return nil
    }
    
    public var dismissImage: UIImage? {
        return nil
    }
    
    public var dismissTint: UIColor? {
        return UIColor.white
    }
    
    fileprivate func createDismiss() {
        switch (dismissType) {
        case .image:
            if let url = self.dismissImageUri {
                let desc = buildNavigationItemDescriptor(url: url,
                                                         selector: #selector(BaseUIViewController.selector_dismiss))
                self.setNavigationItem(navigationItem: desc, left: true)
            } else if let img = self.dismissImage {
                let desc = buildNavigationItemDescriptor(img: img,
                                                         selector: #selector(BaseUIViewController.selector_dismiss))
                self.setNavigationItem(navigationItem: desc, left: true)
            }
        case .text:
            if let text = self.dismissTitle {
                let desc = buildNavigationItemDescriptor(text: text,
                                                         selector: #selector(BaseUIViewController.selector_dismiss))
                self.setNavigationItem(navigationItem: desc, left: true)
            }
        default:
            break
        }
    }
    
    @objc func selector_dismiss() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Touch Interface
    public func addTap(_ view: UIView, selector: Selector) {
        let tapGesture = UITapGestureRecognizer(target: self, action: selector)
        tapGesture.numberOfTapsRequired = 1
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Keyboard
    public var addKeyboardEvents: Bool {
        return false
    }
    
    public var addTapToDismissKeyboard: Bool {
        return true
    }
    
    var keyboardHeight: CGFloat = 0
    
    public var temporarilyIgnoreKeyboardChanges = false
    
    fileprivate func createKeyboard() {
        guard addKeyboardEvents else { return }
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(BaseUIViewController.selector_keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(BaseUIViewController.selector_keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        
        if addTapToDismissKeyboard {
            self.addTap(view, selector: #selector(BaseUIViewController.selector_dismissKeyboard))
        }
    }
    
    @objc func selector_dismissKeyboard() {
        self.resignNested(view: self.view)
    }
    
    @objc func selector_keyboardWillShow(_ notification: NSNotification) {
        guard !temporarilyIgnoreKeyboardChanges, isVisible else { return }
        
        guard let keyboardInfo = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        
        let keyboardHeight = keyboardInfo.cgSizeValue.height
        
        self.tableViews.forEach() { $0.contentInset.bottom = keyboardHeight }
        
        if self.tableViews.count == 0 {
            self.keyboardHeight = keyboardHeight
            UIView.animate(withDuration: 0.3) {
                self.frameUpdate()
            }
        }
    }
    
    @objc func selector_keyboardWillHide(_ notification: NSNotification) {
        guard !temporarilyIgnoreKeyboardChanges, isVisible else { return }
        
        self.tableViews.forEach() { $0.contentInset.bottom = 0 }
        
        if self.tableViews.count == 0 {
            self.keyboardHeight = 0
            UIView.animate(withDuration: 0.3) {
                self.frameUpdate()
            }
        }
    }
    
    // MARK: - LifeCycleInterface Methods
    public func initialize() {
        
    }
    
    public func createLayout() {
        createUI()
        createNavigation()
        createDismiss()
        createKeyboard()
    }
    
    public func frameUpdate() {
        
    }
    
    public func cleanUp() {
        self.view.subviews.forEach() { ($0 as? LifeCycleInterface)?.cleanUp?() }
    }
    
    public func destroy() {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - ReusableComponentInterface Methods
    fileprivate var hasAppeared = false
    
    fileprivate var hasDisappeared = false
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.willAppear(first: !hasAppeared)
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.didAppear(first: !hasAppeared)
        self.hasAppeared = true
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.willDisappear(first: !hasDisappeared)
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.didDisappear(first: !hasDisappeared)
        self.hasDisappeared = true
    }
    
    public func willAppear(first: Bool) {}
    
    public func didAppear(first: Bool) {}
    
    public func willDisappear(first: Bool) {}
    
    public func didDisappear(first: Bool) {}
    
}
