//
//  WishDetailView.swift
//  DuGo-iOS
//
//  Created by 김승원 on 19/9/26.
//

import SwiftData
import SwiftUI

struct WishDetailView: View {
    private enum HistorySortOrder: Equatable {
        case newestFirst
        case oldestFirst

        var title: String {
            switch self {
            case .newestFirst: "최신순"
            case .oldestFirst: "오래된순"
            }
        }

        var symbol: String {
            switch self {
            case .newestFirst: "arrow.down"
            case .oldestFirst: "arrow.up"
            }
        }

        mutating func toggle() {
            self = self == .newestFirst ? .oldestFirst : .newestFirst
        }
    }

    private enum HistoryEntry: Identifiable {
        case record(DecisionRecord)
        case initial(Date)

        var id: String {
            switch self {
            case .record(let record): "record-\(record.id.uuidString)"
            case .initial: "initial"
            }
        }

        var date: Date {
            switch self {
            case .record(let record): record.createdAt
            case .initial(let date): date
            }
        }
    }

    // MARK: - Properties

    let item: WishItem
    @ObservedObject private var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingEdit = false
    @State private var confirmingDelete = false
    @State private var confirmingRestore = false
    @State private var showingHistory = false
    @State private var showingLinkReturnPrompt = false
    @State private var showingReview = false
    @State private var shouldOpenReviewAfterPrompt = false
    @State private var isWaitingForProductLinkReturn = false
    @State private var didLeaveForProductLink = false
    @State private var historySortOrder: HistorySortOrder = .newestFirst

    // MARK: - Initializer

    init(item: WishItem, viewModel: HomeViewModel) {
        self.item = item
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                wishImageSection

                informationSection

                divider

                mindFlowSection

                VStack(alignment: .leading, spacing: 24) {
                    divider

                    historySection
                }
            }
            .padding(.bottom, 48)
        }
        .navigationTitle("담아둔 마음")
        .navigationBarTitleDisplayMode(.inline)
        .dugoScreen()
        .dugoErrorToast(message: $viewModel.errorMessage)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarVisibility(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("수정", systemImage: "pencil") { showingEdit = true }
                    Button("삭제", systemImage: "trash", role: .destructive) {
                        confirmingDelete = true
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(DuGoTheme.ink)
                        .frame(width: 44, height: 44)
                }
                .tint(DuGoTheme.ink)
                .disabled(viewModel.isWorking)
            }
        }
        .sheet(isPresented: $showingEdit) {
            NavigationStack {
                WishEditorView(
                    viewModel: viewModel,
                    item: item,
                    onCancel: { showingEdit = false },
                    onSaved: { showingEdit = false }
                )
            }
        }
        .sheet(isPresented: $showingHistory) {
            historySheet
        }
        .sheet(
            isPresented: $showingLinkReturnPrompt,
            onDismiss: openReviewAfterPromptIfNeeded
        ) {
            productLinkReturnSheet
        }
        .navigationDestination(isPresented: $showingReview) {
            ReviewView(item: item, viewModel: viewModel)
        }
        .dugoConfirmationAlert(
            title: "이 마음과 관련된 기록을 삭제할까요?",
            message: "알림 예약도 제거되며 되돌릴 수 없어요",
            confirmTitle: "삭제",
            isPresented: $confirmingDelete
        ) {
            Task {
                if await viewModel.delete(item) {
                    dismiss()
                }
            }
        }
        .dugoConfirmationAlert(
            title: "이 마음을 다시 담을까요?",
            message: "보관함으로 돌아가고 다시 천천히 살펴볼 수 있어요",
            confirmTitle: "다시 담기",
            isPresented: $confirmingRestore
        ) {
            Task {
                _ = await viewModel.decide(
                    item,
                    decision: .restore,
                    feeling: "",
                    note: ""
                )
            }
        }
        .onAppear { viewModel.errorMessage = nil }
        .onChange(of: scenePhase) { _, phase in
            handleScenePhaseChange(phase)
        }
    }

    // MARK: - Subviews

    private var divider: some View {
        Rectangle()
            .frame(maxWidth: .infinity)
            .frame(height: 10)
            .foregroundStyle(.duGoInk)
            .opacity(0.05)
    }

    private var wishImageSection: some View {
        ZStack(alignment: .bottomLeading) {
            FitWishImage(item: item, cornerRadius: 13)
                .dugoShadow(.card)

            Text(item.categoryRaw)
                .applyDuGoFont(.caption14Regular)
                .foregroundStyle(.duGoInk)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .dugoRoundedSurface(lineWidth: 0)
                .opacity(0.5)
                .dugoShadow(.subtle)
                .padding(12)
        }
        .padding(.horizontal, 16)
    }

    private var informationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 3) {
                Image(systemName: "clock")
                    .applyDuGoFont(.body14Medium)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(item.status == .keeping ? item.storedDescription : item.status.title)")
                    .applyDuGoFont(.body14Medium)
            }
            .foregroundStyle(DuGoTheme.accent)
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .applyDuGoFont(.display24SemiBold)
                    .foregroundStyle(DuGoTheme.ink)
                    .multilineTextAlignment(.leading)

                if let price = item.price {
                    Text(price.dugoFormattedPrice)
                        .applyDuGoFont(.title18SemiBold)
                        .foregroundStyle(DuGoTheme.ink)
                }
            }

            if item.status != .keeping {
                DuGoPrimaryButton(
                    title: "다시 담기",
                    isEnabled: !viewModel.isWorking,
                    height: 50,
                    font: .button14Medium
                ) {
                    confirmingRestore = true
                }
                .padding(.top, 20)
            } else if URL(string: item.link) != nil {
                DuGoPrimaryButton(
                    title: "상품 보러가기",
                    height: 50,
                    font: .button14Medium,
                    action: openProductLink
                )
                .padding(.top, 20)
            }
        }
        .padding(.horizontal, 16)
    }

    private var productLinkReturnSheet: some View {
        DuGoActionSheet(
            height: .medium,
            heading: "지금 마음도 한번 살펴볼까요?",
            message: "상품을 보고 난 뒤의 마음이 어떤지 가볍게 확인해보세요",
            primaryTitle: "내 마음 다시 보기"
        ) {
            shouldOpenReviewAfterPrompt = true
            showingLinkReturnPrompt = false
        } closeAction: {
            showingLinkReturnPrompt = false
        }
    }

    private var mindFlowSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("마음의 흐름")
                .applyDuGoFont(.title18SemiBold)
                .foregroundStyle(DuGoTheme.ink)

            VStack(alignment: .leading, spacing: 0) {
                flowStep(title: "처음 담은 마음") {
                    Text(item.createdAt.dugoFormattedDate())
                        .applyDuGoFont(.body14Medium)
                        .foregroundStyle(DuGoTheme.ink)
                }

                flowStep(
                    title: meetingTimeTitle,
                    isLast: item.status != .keeping
                ) {
                    if let date = meetingTimeDate {
                        Text(date.dugoFormattedDate(includingTime: false))
                            .applyDuGoFont(.body14Medium)
                            .foregroundStyle(DuGoTheme.ink)

                        if item.status == .keeping {
                            Text(reviewMessage(for: date))
                                .applyDuGoFont(.body14Regular)
                                .foregroundStyle(DuGoTheme.secondary)

                            if let message = viewModel.reminderNotice {
                                ReminderNoticeView(text: message)
                            }
                        } else {
                            Text(completedMeetingMessage)
                                .applyDuGoFont(.body14Regular)
                                .foregroundStyle(DuGoTheme.secondary)
                        }
                    } else {
                        Text(
                            item.status == .keeping
                                ? "다시 볼 날짜를 정하지 않았어요"
                                : "다시 만난 날짜를 확인할 수 없어요"
                        )
                        .applyDuGoFont(.body14Regular)
                        .foregroundStyle(DuGoTheme.secondary)
                    }
                }

                if item.status == .keeping {
                    currentMindActionStep
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func flowStep<Content: View>(
        title: String,
        isLast: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            flowIndicator(isLast: isLast)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .applyDuGoFont(.body14Regular)
                    .foregroundStyle(DuGoTheme.secondary)

                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: isLast ? 0 : 60, alignment: .topLeading)
            .padding(.bottom, isLast ? 0 : 28)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func flowIndicator(
        isLast: Bool,
        color: Color = DuGoTheme.border
    ) -> some View {
        VStack(spacing: 0) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .padding(.vertical, 6)

            if !isLast {
                Rectangle()
                    .fill(DuGoTheme.border)
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: 20)
    }

    private var currentMindActionStep: some View {
        HStack(alignment: .top, spacing: 12) {
            flowIndicator(isLast: true, color: DuGoTheme.accent)

            NavigationLink {
                ReviewView(item: item, viewModel: viewModel)
            } label: {
                Text("지금의 마음 확인하러 가기 →")
                    .underline()
                    .applyDuGoFont(.button16Medium)
                    .foregroundStyle(DuGoTheme.accent)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            historyHeader

            VStack(alignment: .center, spacing: 12) {
                ForEach(historyEntries.prefix(4)) { entry in
                    historyCard(entry)
                }
            }

            if historyEntries.count > 4 {
                Button {
                    showingHistory = true
                } label: {
                    HStack(spacing: 4) {
                        Text("전체보기")
                            .applyDuGoFont(.caption12Medium)

                        Image(systemName: "chevron.up")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .foregroundStyle(DuGoTheme.secondary)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
    }

    private var historySheet: some View {
        DuGoSheet(
            height: .large,
            scrollsContent: true,
            closeAction: { showingHistory = false },
            content: {
                LazyVStack(alignment: .leading, spacing: 12) {
                    historyHeader
                        .padding(.bottom, 2)

                    ForEach(historyEntries) { entry in
                        historyCard(entry)
                    }
                }
            }
        )
    }

    private var historyHeader: some View {
        HStack(alignment: .center) {
            Text("이 마음의 기록")
                .applyDuGoFont(.title18SemiBold)
                .foregroundStyle(DuGoTheme.ink)

            Spacer()

            historySortButton
        }
        .frame(maxWidth: .infinity)
    }

    private func historyCard(_ record: DecisionRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 3) {
                DuGoDecisionIcon(
                    decision: record.decision,
                    size: 18,
                    color: DuGoTheme.ink
                )
                .frame(width: 24, height: 24)

                Text(historyTitle(for: record.decision))
                    .applyDuGoFont(.body14Medium)
                    .foregroundStyle(DuGoTheme.ink)

                Spacer()

                Text(record.createdAt.dugoFormattedDate())
                    .applyDuGoFont(.caption12Regular)
                    .foregroundStyle(DuGoTheme.secondary)
            }

            if !record.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(record.note)
                    .applyDuGoFont(.caption14Regular)
                    .foregroundStyle(DuGoTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dugoRoundedSurface(cornerRadius: 18)
    }

    @ViewBuilder
    private func historyCard(_ entry: HistoryEntry) -> some View {
        switch entry {
        case .record(let record):
            historyCard(record)
        case .initial:
            initialHistoryCard
        }
    }

    private var initialHistoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 3) {
                Image(systemName: "bookmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(DuGoTheme.ink)
                    .frame(width: 24, height: 24)
                    .fixedSize(horizontal: false, vertical: true)

                Text("처음 담아뒀어요")
                    .applyDuGoFont(.body14Medium)
                    .foregroundStyle(DuGoTheme.ink)

                Spacer()

                Text(item.createdAt.dugoFormattedDate())
                    .applyDuGoFont(.caption12Regular)
                    .foregroundStyle(DuGoTheme.secondary)
            }

            if !item.reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(item.reason)
                    .applyDuGoFont(.caption14Regular)
                    .foregroundStyle(DuGoTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dugoRoundedSurface(cornerRadius: 18)
    }

    private func historyTitle(for decision: WishDecision) -> String {
        switch decision {
        case .purchase:
            "구매하기로 했어요"
        case .wait:
            "조금 더 기다려요"
        case .release:
            "마음을 보내줬어요"
        case .restore:
            "다시 담아뒀어요"
        }
    }

    private var historyRecords: [DecisionRecord] {
        viewModel.records
            .filter { $0.itemID == item.id }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private var historyEntries: [HistoryEntry] {
        let entries = historyRecords.map(HistoryEntry.record) + [.initial(item.createdAt)]

        return entries.sorted {
            switch historySortOrder {
            case .newestFirst:
                $0.date > $1.date
            case .oldestFirst:
                $0.date < $1.date
            }
        }
    }

    private var historySortButton: some View {
        Button {
            var transaction = Transaction()
            transaction.animation = nil

            withTransaction(transaction) {
                historySortOrder.toggle()
            }
        } label: {
            HStack(spacing: 4) {
                Text(historySortOrder.title)
                    .applyDuGoFont(.caption12Medium)

                Image(systemName: historySortOrder.symbol)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(DuGoTheme.secondary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(nil, value: historySortOrder)
    }

    private var meetingTimeTitle: String {
        item.status == .keeping ? "다시 만나는 날" : "다시 만났던 날"
    }

    private var meetingTimeDate: Date? {
        guard item.status != .keeping else { return item.reviewAt }
        return completedDecisionRecord?.createdAt
    }

    private var completedDecisionRecord: DecisionRecord? {
        let decision: WishDecision

        switch item.status {
        case .purchased:
            decision = .purchase
        case .released:
            decision = .release
        case .keeping:
            return nil
        }

        return
            historyRecords
            .filter { $0.decision == decision }
            .max { $0.createdAt < $1.createdAt }
    }

    private var completedMeetingMessage: String {
        switch item.status {
        case .purchased:
            "이날 구매하기로 마음을 정했어요"
        case .released:
            "이날 마음을 보내주기로 정했어요"
        case .keeping:
            ""
        }
    }

    // MARK: - Methods

    private func openProductLink() {
        guard let url = URL(string: item.link),
            let scheme = url.scheme?.lowercased(),
            ["https", "http"].contains(scheme),
            url.host != nil
        else {
            viewModel.errorMessage = "상품 링크를 열 수 없어요 저장된 링크를 확인해주세요"
            return
        }

        shouldOpenReviewAfterPrompt = false
        didLeaveForProductLink = false
        isWaitingForProductLinkReturn = true

        openURL(url) { accepted in
            if !accepted {
                isWaitingForProductLinkReturn = false
                didLeaveForProductLink = false
                viewModel.errorMessage = "상품 링크를 열지 못했어요 다시 시도해주세요"
            }
        }
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        guard isWaitingForProductLinkReturn else { return }

        if phase != .active {
            didLeaveForProductLink = true
            return
        }

        guard didLeaveForProductLink else { return }
        isWaitingForProductLinkReturn = false
        didLeaveForProductLink = false

        guard item.status == .keeping else { return }
        shouldOpenReviewAfterPrompt = false
        showingLinkReturnPrompt = true
    }

    private func openReviewAfterPromptIfNeeded() {
        guard shouldOpenReviewAfterPrompt else { return }
        shouldOpenReviewAfterPrompt = false
        guard item.status == .keeping else { return }
        showingReview = true
    }

    private func reviewMessage(for date: Date) -> String {
        if date <= .now {
            return "다시 살펴볼 날이에요"
        }

        if item.wantsReminder {
            return viewModel.scheduledIDs.contains(item.id)
                ? "알림이 예약되어 있어요"
                : "알림이 예약되지 않았어요"
        }

        return "알림을 받지 않아요"
    }
}
