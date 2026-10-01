//
//  WishRow.swift
//  DuGo-iOS
//
//  Created by 김승원 on 19/9/26.
//

import SwiftUI

struct FillWishImage: View {
    // MARK: - Properties

    let item: WishItem
    let size: CGFloat

    // MARK: - Body

    var body: some View {
        Group {
            if let data = item.imageData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
            } else {
                DuGoTheme.surface
                    .aspectRatio(1.12, contentMode: .fit)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct FitWishImage: View {
    // MARK: - Properties

    let item: WishItem
    let cornerRadius: CGFloat

    // MARK: - Initializer

    init(item: WishItem, cornerRadius: CGFloat = 10) {
        self.item = item
        self.cornerRadius = cornerRadius
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let data = item.imageData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .background(DuGoTheme.surface)
            } else {
                DuGoTheme.surface
                    .aspectRatio(1.12, contentMode: .fit)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct WishCardView: View {
    // MARK: - Properties

    let item: WishItem

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            VStack(alignment: .leading, spacing: 8) {
                FitWishImage(item: item)

                VStack(alignment: .leading, spacing: 7) {
                    Text(item.title)
                        .applyDuGoFont(.body14Medium)
                        .foregroundStyle(DuGoTheme.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if let price = item.price {
                        Text(price.dugoFormattedPrice)
                            .applyDuGoFont(.body14Regular)
                            .foregroundStyle(DuGoTheme.ink)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.bottom, 2)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .dugoRoundedSurface(cornerRadius: 12)
            .contentShape(RoundedRectangle(cornerRadius: 12))

            Text("\(item.categoryRaw) · \(item.storedDescription) ")
                .applyDuGoFont(.caption12Regular)
                .foregroundStyle(DuGoTheme.secondary)
                .padding(.leading, 4)
        }
    }
}

struct ReminderNoticeView: View {
    // MARK: - Properties

    let text: String

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(text, systemImage: "bell.badge")
                .applyDuGoFont(.body14Regular)
                .foregroundStyle(DuGoTheme.ink)

            if let url = URL(string: UIApplication.openSettingsURLString) {
                Link("알림 설정 열기", destination: url)
                    .applyDuGoFont(.body14Medium)
                    .foregroundStyle(DuGoTheme.accent)
            }
        }
    }
}
