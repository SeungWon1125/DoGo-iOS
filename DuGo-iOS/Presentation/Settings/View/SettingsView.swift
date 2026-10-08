//
//  SettingsView.swift
//  DuGo-iOS
//
//  Created by 김승원 on 8/10/26.
//

import SwiftUI

struct SettingsView: View {
    // MARK: - Properties

    @ObservedObject private var viewModel: HomeViewModel

    // MARK: - Initializer

    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                managementSection

                permissionSection

                helpSection

                appInformationSection
            }
            .frame(maxWidth: 620)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 40)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("설정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarVisibility(.visible, for: .navigationBar)
        .dugoScreen()
    }

    // MARK: - Subviews

    private var managementSection: some View {
        settingsSection(title: "관리") {
            NavigationLink {
                CategoryManagementView(viewModel: viewModel)
            } label: {
                settingsRow(
                    title: "카테고리 관리",
                    systemImage: "tag",
                    showsChevron: true
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var permissionSection: some View {
        settingsSection(title: "권한") {
            settingsRow(
                title: "알림 설정",
                systemImage: "bell",
                showsChevron: true
            )
        }
    }

    private var helpSection: some View {
        settingsSection(title: "도움말") {
            VStack(spacing: 0) {
                settingsRow(
                    title: "두고 사용 방법",
                    systemImage: "book.closed",
                    showsChevron: true
                )

                sectionDivider

                settingsRow(
                    title: "공유하기로 마음 담기",
                    systemImage: "square.and.arrow.up",
                    showsChevron: true
                )

                sectionDivider

                settingsRow(
                    title: "온보딩 다시 보기",
                    systemImage: "sparkles",
                    showsChevron: true
                )
            }
        }
    }

    private var appInformationSection: some View {
        settingsSection(title: "앱 정보") {
            VStack(spacing: 0) {
                settingsRow(
                    title: "현재 버전",
                    systemImage: "info.circle",
                    trailingText: appVersion
                )

                sectionDivider

                settingsRow(
                    title: "업데이트 확인",
                    systemImage: "arrow.triangle.2.circlepath",
                    showsChevron: true
                )

                sectionDivider

                settingsRow(
                    title: "개인정보 처리방침",
                    systemImage: "hand.raised",
                    showsChevron: true
                )

                sectionDivider

                settingsRow(
                    title: "이용약관",
                    systemImage: "doc.text",
                    showsChevron: true
                )
            }
        }
    }

    private var sectionDivider: some View {
        Divider()
            .overlay(DuGoTheme.border.opacity(0.5))
    }

    private func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .applyDuGoFont(.body14Regular)
                .foregroundStyle(DuGoTheme.secondary)
                .padding(.horizontal, 4)

            content()
                .dugoRoundedSurface(cornerRadius: 18, clipsContent: true)
        }
    }

    private func settingsRow(
        title: String,
        systemImage: String,
        trailingText: String? = nil,
        showsChevron: Bool = false
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.body.weight(.medium))
                .foregroundStyle(DuGoTheme.ink)
                .frame(width: 24, height: 24)

            Text(title)
                .applyDuGoFont(.body16Medium)
                .foregroundStyle(DuGoTheme.ink)

            Spacer(minLength: 12)

            if let trailingText {
                Text(trailingText)
                    .applyDuGoFont(.body14Regular)
                    .foregroundStyle(DuGoTheme.secondary)
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DuGoTheme.secondary.opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 60)
        .contentShape(Rectangle())
    }

    // MARK: - Computed Properties

    private var appVersion: String {
        Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "-"
    }
}
