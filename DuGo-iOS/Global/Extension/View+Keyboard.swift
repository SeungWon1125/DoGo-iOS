//
//  View+Keyboard.swift
//  DuGo-iOS
//
//  Created by 김승원 on 20/9/26.
//

import SwiftUI
import UIKit

extension View {
    func dismissKeyboardOnBackgroundTap() -> some View {
        background {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                }
        }
    }
}
