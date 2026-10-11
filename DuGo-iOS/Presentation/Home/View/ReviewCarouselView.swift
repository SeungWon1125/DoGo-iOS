//
//  ReviewCarouselView.swift
//  DuGo-iOS
//
//  Created by 김승원 on 1/10/26.
//

import SwiftData
import SwiftUI

struct ReviewCarouselView: View {
    // MARK: - Properties

    let items: [WishItem]
    let viewModel: HomeViewModel
    @State private var selectedID: UUID?
    @State private var viewportWidth: CGFloat = 320

    private let sideInset: CGFloat = 16
    private let overlap: CGFloat = 36

    private var selectedIndex: Int {
        items.firstIndex { $0.id == selectedID } ?? 0
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            carousel
                .padding(.horizontal, -sideInset)

            if items.count > 1 {
                Text("\(selectedIndex + 1) / \(items.count)")
                    .applyDuGoFont(.caption12Regular)
                    .monospacedDigit()
                    .foregroundStyle(DuGoTheme.secondary)
                    .padding(.top, -10)
            }
        }
        .onChange(
            of: items.map(\.id),
            initial: true
        ) {
            oldIDs,
            newIDs in
            if let selectedID, newIDs.contains(selectedID) {
                return
            }
            let oldIndex = oldIDs.firstIndex { $0 == selectedID } ?? 0

            selectedID = newIDs.isEmpty ? nil : newIDs[min(oldIndex, newIDs.count - 1)]
        }
    }

    // MARK: - Subviews

    private var carousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: -overlap) {
                ForEach(items) { item in
                    ReviewCardView(
                        item: item,
                        isCompact: true,
                        viewModel: viewModel
                    )
                    .frame(width: max(viewportWidth - sideInset * 2, 1))
                    .visualEffect { [overlap] content, geometry in
                        let frame = geometry.frame(in: .scrollView(axis: .horizontal))
                        let width =
                            geometry.bounds(of: .scrollView(axis: .horizontal))?.width
                            ?? geometry.size.width
                        let distance = min(
                            abs(frame.midX - width / 2) / max(geometry.size.width - overlap, 1),
                            1
                        )

                        return
                            content
                            .scaleEffect(1 - distance * 0.06, anchor: .top)
                            .offset(y: distance * 16)
                            .blur(radius: distance * 1.75)
                    }
                    .zIndex(item.id == (selectedID ?? items.first?.id) ? 1 : 0)
                    .id(item.id)
                }
            }
            .scrollTargetLayout()
            .padding(.bottom, 24)
        }
        .contentMargins(.horizontal, sideInset, for: .scrollContent)
        .scrollClipDisabled()
        .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne, anchor: .center))
        .scrollPosition(id: $selectedID, anchor: .center)
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .scrollDisabled(items.count < 2)
        .onGeometryChange(for: CGFloat.self) { geometry in
            geometry.size.width
        } action: { width in
            viewportWidth = width
        }
    }
}
