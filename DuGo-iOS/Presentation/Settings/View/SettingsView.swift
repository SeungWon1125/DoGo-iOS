//
//  SettingsView.swift
//  DuGo-iOS
//
//  Created by 김승원 on 8/10/26.
//

import SwiftUI
import UIKit
import UserNotifications

struct SettingsView: View {
    // MARK: - Properties

    @ObservedObject private var viewModel: HomeViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var notificationAuthorizationStatus: UNAuthorizationStatus?
    @State private var isShowingOnboarding = false
    private let reminders: ReminderManager

    // MARK: - Initializer

    init(
        viewModel: HomeViewModel,
        reminders: ReminderManager
    ) {
        self.viewModel = viewModel
        self.reminders = reminders
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
        .task {
            await refreshNotificationAuthorizationStatus()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task {
                await refreshNotificationAuthorizationStatus()
            }
        }
        .fullScreenCover(isPresented: $isShowingOnboarding) {
            onboardingReplay
        }
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
            Button {
                manageNotificationPermission()
            } label: {
                settingsRow(
                    title: "알림 설정",
                    systemImage: "bell",
                    trailingText: notificationPermissionStatusText,
                    showsChevron: true
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var helpSection: some View {
        settingsSection(title: "도움말") {
            VStack(spacing: 0) {
                NavigationLink {
                    ShareHelpView()
                } label: {
                    settingsRow(
                        title: "공유하기로 마음 담기",
                        systemImage: "square.and.arrow.up",
                        showsChevron: true
                    )
                }
                .buttonStyle(.plain)

                sectionDivider

                Button {
                    isShowingOnboarding = true
                } label: {
                    settingsRow(
                        title: "온보딩 다시 보기",
                        systemImage: "sparkles",
                        showsChevron: true
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var onboardingReplay: some View {
        ZStack(alignment: .topTrailing) {
            OnboardingView(
                completionTitle: "설정으로 돌아가기"
            ) {
                isShowingOnboarding = false
            }

            Button {
                isShowingOnboarding = false
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(DuGoTheme.ink)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.glass)
            .accessibilityLabel("온보딩 닫기")
            .padding(.top, 12)
            .padding(.trailing, 16)
        }
        .environment(\.colorScheme, .light)
        .preferredColorScheme(.light)
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

    private var notificationPermissionStatusText: String {
        switch notificationAuthorizationStatus {
        case .authorized, .provisional, .ephemeral:
            "허용됨"
        case .denied:
            "꺼짐"
        case .notDetermined:
            "설정하기"
        case nil:
            "확인 중"
        @unknown default:
            "확인 필요"
        }
    }

    // MARK: - Methods

    private func manageNotificationPermission() {
        Task {
            let status = await reminders.authorizationStatus()

            if status == .notDetermined {
                await reminders.requestPermissionIfNeeded()
                await viewModel.syncReminders()
                await refreshNotificationAuthorizationStatus()
            } else {
                openNotificationSettings()
            }
        }
    }

    private func refreshNotificationAuthorizationStatus() async {
        notificationAuthorizationStatus = await reminders.authorizationStatus()
    }

    private func openNotificationSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else {
            return
        }
        UIApplication.shared.open(url)
    }
}
