//
//  ShareHelpView.swift
//  DuGo-iOS
//
//  Created by 김승원 on 8/10/26.
//

import SwiftUI

struct ShareHelpView: View {
    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                hero

                stepsSection

                moreSection

                manualEntrySection
            }
            .frame(maxWidth: 620)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 40)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("공유하기로 마음 담기")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarVisibility(.visible, for: .navigationBar)
        .dugoScreen()
    }

    // MARK: - Subviews

    private var hero: some View {
        VStack(spacing: 22) {
            HStack(spacing: 10) {
                flowNode(
                    systemImage: "bag",
                    title: "상품"
                )

                flowArrow

                flowNode(
                    systemImage: "square.and.arrow.up",
                    title: "공유"
                )

                flowArrow

                dugoFlowNode
            }

            VStack(spacing: 8) {
                Text("발견한 순간, 바로 두고에")
                    .applyDuGoFont(.display24SemiBold)
                    .foregroundStyle(DuGoTheme.ink)
                    .multilineTextAlignment(.center)

                Text("쇼핑 앱을 나가지 않고 공유 버튼 한 번으로\n상품 링크와 정보를 담을 수 있어요")
                    .applyDuGoFont(.body14Regular)
                    .foregroundStyle(DuGoTheme.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private var flowArrow: some View {
        Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(DuGoTheme.secondary.opacity(0.55))
    }

    private var dugoFlowNode: some View {
        VStack(spacing: 8) {
            DuGoLogoImage(width: 26, height: 26)
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(DuGoTheme.accent, in: Circle())
                .dugoShadow(.subtle)

            Text("두고")
                .applyDuGoFont(.caption12Medium)
                .foregroundStyle(DuGoTheme.ink)
        }
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("이렇게 담아보세요")

            stepCard(
                number: 1,
                title: "상품 페이지에서 공유를 눌러요",
                description: "사용 중인 쇼핑 앱이나 Safari의 공유 버튼을 찾아주세요"
            ) {
                productPagePreview
            }

            stepConnector

            stepCard(
                number: 2,
                title: "공유 목록에서 두고를 선택해요",
                description: "앱 아이콘 목록을 옆으로 넘기면 두고를 찾을 수 있어요"
            ) {
                shareSheetPreview
            }

            stepConnector

            stepCard(
                number: 3,
                title: "정보를 확인하고 저장해요",
                description: "다시 볼 날을 고르면 두고에 바로 저장돼요"
            ) {
                savePreview
            }
        }
    }

    private var productPagePreview: some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(DuGoTheme.secondary.opacity(0.18))
                    .frame(width: 8, height: 8)

                RoundedRectangle(cornerRadius: 4)
                    .fill(DuGoTheme.secondary.opacity(0.16))
                    .frame(width: 72, height: 8)

                Spacer()

                Image(systemName: "square.and.arrow.up")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(DuGoTheme.accent)
                    .frame(width: 38, height: 38)
                    .background(DuGoTheme.accent.opacity(0.13), in: Circle())
            }

            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(DuGoTheme.secondary.opacity(0.12))
                    .frame(width: 90, height: 76)
                    .overlay {
                        Image(systemName: "tshirt")
                            .font(.title2)
                            .foregroundStyle(DuGoTheme.secondary.opacity(0.7))
                    }

                VStack(alignment: .leading, spacing: 9) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DuGoTheme.ink.opacity(0.8))
                        .frame(width: 132, height: 10)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(DuGoTheme.secondary.opacity(0.2))
                        .frame(width: 96, height: 8)

                    Text("39,000원")
                        .applyDuGoFont(.body14Medium)
                        .foregroundStyle(DuGoTheme.ink)
                }

                Spacer(minLength: 0)
            }
        }
        .padding(14)
        .background(
            DuGoTheme.surfaceInset,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    private var shareSheetPreview: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("공유")
                    .applyDuGoFont(.body14Medium)
                    .foregroundStyle(DuGoTheme.ink)

                Spacer()

                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DuGoTheme.secondary)
            }

            HStack(spacing: 18) {
                shareOption(
                    systemImage: "message.fill",
                    title: "메시지"
                )

                shareOption(
                    systemImage: "link",
                    title: "복사"
                )

                dugoShareOption

                shareOption(
                    systemImage: "ellipsis",
                    title: "더보기"
                )
            }
            .frame(maxWidth: .infinity)
        }
        .padding(14)
        .background(
            DuGoTheme.surfaceInset,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    private var dugoShareOption: some View {
        VStack(spacing: 7) {
            DuGoLogoImage(width: 20, height: 20)
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(DuGoTheme.accent, in: RoundedRectangle(cornerRadius: 12))
                .dugoShadow(.subtle)

            Text("두고")
                .applyDuGoFont(.caption12Medium)
                .foregroundStyle(DuGoTheme.accent)
        }
    }

    private var savePreview: some View {
        VStack(spacing: 13) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(DuGoTheme.secondary.opacity(0.12))
                    .frame(width: 58, height: 58)
                    .overlay {
                        Image(systemName: "tshirt")
                            .foregroundStyle(DuGoTheme.secondary)
                    }

                VStack(alignment: .leading, spacing: 6) {
                    Text("상품 정보를 불러왔어요")
                        .applyDuGoFont(.caption12Medium)
                        .foregroundStyle(DuGoTheme.accent)

                    Text("마음에 담아둔 상품")
                        .applyDuGoFont(.body14Medium)
                        .foregroundStyle(DuGoTheme.ink)

                    Text("39,000원")
                        .applyDuGoFont(.caption12Regular)
                        .foregroundStyle(DuGoTheme.secondary)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                dateChip("내일", isSelected: false)
                dateChip("3일 뒤", isSelected: true)
                dateChip("5일 뒤", isSelected: false)
            }

            Text("두고에 저장")
                .applyDuGoFont(.button14Medium)
                .foregroundStyle(DuGoTheme.onAccent)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    DuGoTheme.accent,
                    in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                )
        }
        .padding(14)
        .background(
            DuGoTheme.surfaceInset,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    private var stepConnector: some View {
        Image(systemName: "arrow.down")
            .font(.caption.weight(.semibold))
            .foregroundStyle(DuGoTheme.accent.opacity(0.7))
            .frame(maxWidth: .infinity)
            .frame(height: 12)
    }

    private var moreSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("공유 목록에 두고가 없다면")

            VStack(alignment: .leading, spacing: 16) {
                Text("공유 목록 끝에서 아래 순서로 설정해 주세요")
                    .applyDuGoFont(.body14Regular)
                    .foregroundStyle(DuGoTheme.secondary)

                HStack(spacing: 8) {
                    pathChip(systemImage: "ellipsis", title: "더보기")

                    pathArrow

                    pathChip(systemImage: "pencil", title: "편집")

                    pathArrow

                    pathChip(systemImage: "star", title: "즐겨찾기")
                }

                HStack(spacing: 10) {
                    DuGoLogoImage(width: 18, height: 18)
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(DuGoTheme.accent, in: RoundedRectangle(cornerRadius: 9))

                    Text("두고를 즐겨찾기에 추가하면 다음부터 더 빠르게 찾을 수 있어요")
                        .applyDuGoFont(.body14Medium)
                        .foregroundStyle(DuGoTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
            .dugoRoundedSurface(cornerRadius: 18)
        }
    }

    private var manualEntrySection: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "pencil.line")
                .font(.body.weight(.medium))
                .foregroundStyle(DuGoTheme.accent)
                .frame(width: 38, height: 38)
                .background(DuGoTheme.accent.opacity(0.1), in: Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text("상품 정보를 불러오지 못해도 괜찮아요")
                    .applyDuGoFont(.body16Medium)
                    .foregroundStyle(DuGoTheme.ink)

                Text("쇼핑몰에 따라 이름이나 사진, 가격이 비어 있을 수 있어요 상품 링크는 유지되며 필요한 정보만 직접 입력할 수 있어요")
                    .applyDuGoFont(.body14Regular)
                    .foregroundStyle(DuGoTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .dugoRoundedSurface(cornerRadius: 18)
    }

    private func flowNode(
        systemImage: String,
        title: String
    ) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title3.weight(.medium))
                .foregroundStyle(DuGoTheme.ink)
                .frame(width: 58, height: 58)
                .background(DuGoTheme.surface, in: Circle())
                .dugoShadow(.subtle)

            Text(title)
                .applyDuGoFont(.caption12Medium)
                .foregroundStyle(DuGoTheme.ink)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .applyDuGoFont(.body14Regular)
            .foregroundStyle(DuGoTheme.secondary)
            .padding(.horizontal, 4)
    }

    private func stepCard<Preview: View>(
        number: Int,
        title: String,
        description: String,
        @ViewBuilder preview: () -> Preview
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Text("\(number)")
                    .applyDuGoFont(.caption12Medium)
                    .foregroundStyle(DuGoTheme.onAccent)
                    .frame(width: 28, height: 28)
                    .background(DuGoTheme.accent, in: Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .applyDuGoFont(.body16Medium)
                        .foregroundStyle(DuGoTheme.ink)

                    Text(description)
                        .applyDuGoFont(.body14Regular)
                        .foregroundStyle(DuGoTheme.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            preview()
        }
        .padding(16)
        .dugoRoundedSurface(cornerRadius: 18)
    }

    private func shareOption(
        systemImage: String,
        title: String
    ) -> some View {
        VStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.body.weight(.medium))
                .foregroundStyle(DuGoTheme.ink)
                .frame(width: 46, height: 46)
                .background(DuGoTheme.surface, in: RoundedRectangle(cornerRadius: 12))

            Text(title)
                .applyDuGoFont(.caption12Regular)
                .foregroundStyle(DuGoTheme.secondary)
        }
    }

    private func dateChip(
        _ title: String,
        isSelected: Bool
    ) -> some View {
        Text(title)
            .applyDuGoFont(.caption12Medium)
            .foregroundStyle(isSelected ? DuGoTheme.onAccent : DuGoTheme.secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .background(
                isSelected ? DuGoTheme.accent : DuGoTheme.surface,
                in: Capsule()
            )
    }

    private func pathChip(
        systemImage: String,
        title: String
    ) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))

            Text(title)
                .applyDuGoFont(.caption12Medium)
        }
        .foregroundStyle(DuGoTheme.ink)
        .padding(.horizontal, 10)
        .frame(height: 34)
        .background(DuGoTheme.surfaceInset, in: Capsule())
    }

    private var pathArrow: some View {
        Image(systemName: "chevron.right")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(DuGoTheme.secondary.opacity(0.6))
    }
}
