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

public class BaseUIViewController: UIViewController, LifeCycleInterface {
    
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
    
    var state = [String: Any]()
    
    // MARK: - Layout Information -
    fileprivate var currSize = CGSize.zero
    
    fileprivate var currTopLayout: CGFloat = 0
    
    public var effectiveTopLayoutGuide: CGFloat {
        guard self.navigationController != nil else { return 0 }
        return UIHelper.statusBarHeight + UIHelper.navigationBarHeight
    }
    
    public var effectiveBottomLayoutGuide: CGFloat {
        return self.view.frame.height - keyboardHeight
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.createLayout()
    }
    
    override public func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if self.currSize != view.frame.size || self.currTopLayout != effectiveTopLayoutGuide {
            self.currSize = view.frame.size
            self.currTopLayout = effectiveTopLayoutGuide
            frameUpdate()
        }
    }
    
    // MARK: - LifeCycleInterface Methods
    public func initialize() {
        
    }
    
    public func createLayout() {
        configure()
        createNavigationTitle()
        createDismissButton()
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
    
}

// MARK: - Configuration
public extension BaseUIViewController {
    
    var isVisible: Bool {
        var ret = self.view.window != nil && self.isViewLoaded
        
        #if MAIN
        ret = ret && UIApplication.shared.applicationState == .active
        #endif
        
        return ret
    }
    
    var defaultBackgroundColor: UIColor {
        return UIColor.clear
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    fileprivate var tableViews: [UITableView] {
        return self.view.subviews.compactMap() { $0 as? UITableView }
    }
    
    @discardableResult fileprivate func resignNested(view: UIView) -> Bool {
        for v in self.view.subviews {
            if v.resignFirstResponder() || resignNested(view: v) {
                return true
            }
        }
        return false
    }
    
    fileprivate func configure() {
        self.view.backgroundColor = self.defaultBackgroundColor
    }
    
}

// MARK: - Navigation Interface
public extension BaseUIViewController {
    
    var navigationTitle: String? {
        return nil
    }
    
    var navigationFont: UIFont {
        return EthosTextConfig.shared.regularFont.withSize(navigationFontSize)
    }
    
    var navigationFontSize: CGFloat {
        return EthosTextConfig.shared.fontSize + 1
    }
    
    var navigationTint: UIColor? {
        return UIColor.white
    }
    
    func setNavigationItem(navigationItem: BaseNavigationBarItem, left: Bool) {
        if left {
            self.navigationItem.leftBarButtonItem = navigationItem.button
        } else {
            self.navigationItem.rightBarButtonItem = navigationItem.button
        }
    }
    
    func removeNavigationItem(left: Bool) {
        if left {
            self.navigationItem.leftBarButtonItem?.image = nil
        } else {
            self.navigationItem.rightBarButtonItems?.removeAll()
        }
    }
    
    func buildNavigationItemDescriptor(text: String, selector: Selector,
                                       target: AnyObject? = nil) -> BaseNavigationBarItem {
        return TextNavigationBarItem(target: target ?? self, selector: selector)
                    .with(label: text)
                    .with(font: self.navigationFont)
                    .with(tint: self.navigationTint)
    }
    
    func buildNavigationItemDescriptor(url: String, selector: Selector,
                                       target: AnyObject? = nil) -> BaseNavigationBarItem {
        return ImageNavigationBarItem(target: target ?? self, selector: selector)
                    .with(imageUri: url)
                    .with(tint: self.navigationTint)
    }
    
    func buildNavigationItemDescriptor(img: UIImage, selector: Selector,
                                       target: AnyObject? = nil) -> BaseNavigationBarItem {
        return ImageNavigationBarItem(target: target ?? self, selector: selector)
                    .with(image: img)
                    .with(tint: self.navigationTint)
    }
    
    fileprivate func createNavigationTitle() {
        self.navigationItem.title = self.navigationTitle
        
        var attr = [NSAttributedString.Key: Any]()
        attr.set(NSAttributedString.Key.font, navigationFont.withSize(navigationFontSize), allowNil: false)
        self.navigationController?.navigationBar.titleTextAttributes = attr
    }
}

// MARK: - Touch Interface
public extension BaseUIViewController {
    
    func addTap(_ view: UIView, selector: Selector) {
        let tapGesture = UITapGestureRecognizer(target: self, action: selector)
        tapGesture.numberOfTapsRequired = 1
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tapGesture)
    }

}

// MARK: - Dismiss Interface
public extension BaseUIViewController {
    
    enum DismissType {
        case none
        case text
        case image
    }
    
    var dismissType: DismissType {
        if dismissImageUri != nil || dismissImage != nil {
            return .image
        } else if dismissTitle != nil {
            return .text
        }
        
        return .none
    }
    
    // Text dismiss parameters
    var dismissTitle: String? {
        return nil
    }
    
    var dismissImageUri: String? {
        return nil
    }
    
    var dismissImage: UIImage? {
        return nil
    }
    
    var dismissTint: UIColor? {
        return UIColor.white
    }
    
    fileprivate func createDismissButton() {
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
    
    // MARK: - Selector
    @objc func selector_dismiss() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - Keyboard Interface
public extension BaseUIViewController {
    
    fileprivate static let DEFAULT_KEYBOARD_HEIGHT: CGFloat = 0
    
    fileprivate static let DEFAULT_TEMP_DISABLE_KEYBOARD = false
    
    fileprivate static let STATE_KEY_KEYBOARD_HEIGHT = "keyboard_height"
    
    fileprivate static let STATE_KEY_TEMP_DISABLE_KEYBOARD = "temp_disable_keyboard"

    var addKeyboardEvents: Bool {
        return false
    }
    
    var addTapToDismissKeyboard: Bool {
        return true
    }
    
    var keyboardHeight: CGFloat {
        get {
            return self.state.get(BaseUIViewController.STATE_KEY_KEYBOARD_HEIGHT) { () -> Any? in
                return BaseUIViewController.DEFAULT_KEYBOARD_HEIGHT
            } as! CGFloat
        }
        set {
            self.state.set(BaseUIViewController.STATE_KEY_KEYBOARD_HEIGHT, newValue)
        }
    }
    
    var temporarilyIgnoreKeyboardChanges: Bool {
        get {
            return self.state.get(BaseUIViewController.STATE_KEY_TEMP_DISABLE_KEYBOARD) { () -> Any? in
                return BaseUIViewController.DEFAULT_TEMP_DISABLE_KEYBOARD
            } as! Bool
        }
        set {
            self.state.set(BaseUIViewController.STATE_KEY_TEMP_DISABLE_KEYBOARD, newValue)
        }
    }
    
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
    
    // MARK: - Selector
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
    
}

// MARK: - ReusableComponentInterface
extension BaseUIViewController: ReusableComponentInterface {
    
    fileprivate static let DEFAULT_HAS_APPEARED = false
    
    fileprivate static let DEFAULT_HAS_DISAPPEARED = false
    
    fileprivate static let STATE_KEY_HAS_APPEARED = "has_appeared"
    
    fileprivate static let STATE_KEY_HAS_DISAPPEARED = "has_disappeared"
    
    fileprivate var hasAppeared: Bool {
        return self.state.get(BaseUIViewController.STATE_KEY_HAS_APPEARED) { () -> Any? in
            return BaseUIViewController.DEFAULT_HAS_APPEARED
        } as! Bool
    }
    
    fileprivate var hasDisappeared: Bool {
        return self.state.get(BaseUIViewController.STATE_KEY_HAS_DISAPPEARED) { () -> Any? in
            return BaseUIViewController.DEFAULT_HAS_DISAPPEARED
        } as! Bool
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.willAppear(first: !hasAppeared)
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.didAppear(first: !hasAppeared)
        self.state.set(BaseUIViewController.STATE_KEY_HAS_APPEARED, true)
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.willDisappear(first: !hasDisappeared)
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.didDisappear(first: !hasDisappeared)
        self.state.set(BaseUIViewController.STATE_KEY_HAS_DISAPPEARED, true)
    }
    
    public func willAppear(first: Bool) {
        
    }
    
    public func didAppear(first: Bool) {
        
    }
    
    public func willDisappear(first: Bool) {
    
    }
    
    public func didDisappear(first: Bool) {
        
    }
    
}

