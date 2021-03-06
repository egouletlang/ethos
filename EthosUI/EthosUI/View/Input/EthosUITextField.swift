//
//  EthosUITextField.swift
//  EthosUI
//
//  Created by Etienne Goulet-Lang on 4/20/19.
//  Copyright © 2019 egouletlang. All rights reserved.
//

import Foundation

open class EthosUITextField: BaseUIView {
    
    // MARK: - UI Components
    private let textField = UITextField(frame: CGRect.zero)
    
    // MARK: - LifeCycleInterface Methods
    @discardableResult
    override open func createLayout() -> LifeCycleInterface {
        super.createLayout()
        self.addSubview(textField)
        self.padding = Rect<CGFloat>(8, 2, 8, 2)
        return self
    }
    
    open override func frameUpdate() {
        super.frameUpdate()
        self.textField.frame = self.bounds.insetBy(padding: padding)
    }
    
}
