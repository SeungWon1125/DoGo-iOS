//
//  DuGoMasonryLayout.swift
//  DuGo-iOS
//
//  Created by 김승원 on 22/9/26.
//

import SwiftUI

struct DuGoMasonryLayout: Layout {
    // MARK: - Properties

    let columns: Int
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat

    // MARK: - Layout

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let result = layout(for: proposal, subviews: subviews)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let result = layout(
            for: ProposedViewSize(width: bounds.width, height: proposal.height),
            subviews: subviews
        )

        for (index, subview) in subviews.enumerated() {
            let placement = result.placements[index]
            let x =
                bounds.minX + CGFloat(placement.column) * (result.columnWidth + horizontalSpacing)

            subview.place(
                at: CGPoint(x: x, y: bounds.minY + placement.y),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: result.columnWidth, height: placement.height)
            )
        }
    }

    // MARK: - Methods

    private func layout(for proposal: ProposedViewSize, subviews: Subviews) -> LayoutResult {
        let safeColumnCount = max(columns, 1)
        let totalSpacing = horizontalSpacing * CGFloat(safeColumnCount - 1)
        let availableWidth = max((proposal.width ?? 0) - totalSpacing, 0)
        let columnWidth = availableWidth / CGFloat(safeColumnCount)
        var columnHeights = Array(repeating: CGFloat.zero, count: safeColumnCount)
        var placements: [Placement] = []

        for subview in subviews {
            let column =
                columnHeights.indices.min(by: { columnHeights[$0] < columnHeights[$1] }) ?? 0
            let height = subview.sizeThatFits(
                ProposedViewSize(width: columnWidth, height: nil)
            ).height
            let y = columnHeights[column]

            placements.append(Placement(column: column, y: y, height: height))
            columnHeights[column] += height + verticalSpacing
        }

        let contentHeight = max((columnHeights.max() ?? 0) - verticalSpacing, 0)
        return LayoutResult(columnWidth: columnWidth, height: contentHeight, placements: placements)
    }
}

// MARK: - Supporting Types

extension DuGoMasonryLayout {
    fileprivate struct Placement {
        let column: Int
        let y: CGFloat
        let height: CGFloat
    }

    fileprivate struct LayoutResult {
        let columnWidth: CGFloat
        let height: CGFloat
        let placements: [Placement]
    }
}
