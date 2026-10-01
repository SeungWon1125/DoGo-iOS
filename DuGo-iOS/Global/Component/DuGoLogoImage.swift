//
//  DuGoLogoImage.swift
//  DuGo-iOS
//
//  Created by 김승원 on 10/1/26.
//

import SwiftUI

struct DuGoLogoImage: View {
    // MARK: - Properties

    let width: CGFloat
    let height: CGFloat

    // MARK: - Initializer

    init(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
    }

    // MARK: - Body

    var body: some View {
        Image(.logoIcon)
            .resizable()
            .renderingMode(.template)
            .frame(width: width, height: height)
    }
}
