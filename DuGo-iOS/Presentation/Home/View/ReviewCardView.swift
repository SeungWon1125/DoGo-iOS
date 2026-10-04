//
//  ReviewCardView.swift
//  DuGo-iOS
//

import SwiftUI

struct ReviewCardView: View {
    // MARK: - Properties

    let item: WishItem
    var isCompact = false
    private let viewModel: HomeViewModel?
    @State private var isReviewPresented = false

    // MARK: - Initializer

    init(
        item: WishItem,
        isCompact: Bool = false,
        viewModel: HomeViewModel? = nil
    ) {
        self.item = item
        self.isCompact = isCompact
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            itemSummaryLink

            reviewActionButton
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(DuGoTheme.ink)
        .dugoRoundedSurface(cornerRadius: 13, shadowStyle: .card)
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Subviews

    @ViewBuilder
    private var itemSummaryLink: some View {
        if let viewModel {
            NavigationLink {
                WishDetailView(item: item, viewModel: viewModel)
            } label: {
                itemSummary
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            itemSummary
        }
    }

    private var reviewActionButton: some View {
        DuGoPrimaryButton(
            title: "내 마음 다시 보기",
            height: 48,
            font: .button14Medium
        ) {
            guard viewModel != nil else { return }
            isReviewPresented = true
        }
        .navigationDestination(isPresented: $isReviewPresented) {
            if let viewModel {
                ReviewView(item: item, viewModel: viewModel)
            }
        }
    }

    private var itemSummary: some View {
        HStack(alignment: .top, spacing: 12) {
            FillWishImage(item: item, size: 100)

            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                header
                description
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 3) {
            Image(systemName: "clock")
                .applyDuGoFont(.caption12Medium)
                .fixedSize(horizontal: false, vertical: true)

            Text(item.reviewDueDescription)
                .applyDuGoFont(.caption12Medium)
        }
        .foregroundStyle(DuGoTheme.accent)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var description: some View {
        Text(item.title)
            .applyDuGoFont(.title18SemiBold)
            .lineLimit(2, reservesSpace: true)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.leading)
    }
}
