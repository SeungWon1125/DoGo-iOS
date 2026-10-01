//
//  ShareComposerView.swift
//  ShareExtension
//

import Combine
import SwiftUI
import UIKit

@MainActor
final class ShareComposerModel: ObservableObject {
    // MARK: - Properties

    @Published var link = ""
    @Published var title = ""
    @Published var price = ""
    @Published var reason = ""
    @Published var category = "미분류"
    @Published var hasReviewDate = true
    @Published var reviewDate =
        Calendar.current.date(
            byAdding: .day,
            value: 3,
            to: Calendar.current.startOfDay(for: .now)
        ) ?? .now
    @Published var wantsReminder = false
    @Published var imageData: Data?
    @Published var isReadingLink = false
    @Published var isLoadingPreview = false
    @Published var previewedLink: String?
    @Published var highlightedFields: Set<AutofilledField> = []
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let previewService = LinkPreviewService()

    // MARK: - Computed Properties

    var validURL: URL? {
        guard let url = URL(string: link.trimmingCharacters(in: .whitespacesAndNewlines)),
            let scheme = url.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            url.host != nil
        else { return nil }
        return url
    }

    // MARK: - Types

    enum AutofilledField: Hashable {
        case image, title, price
    }

    // MARK: - Methods

    func preparePreview() {
        isLoadingPreview = false
        previewedLink = nil
        highlightedFields = []
        imageData = nil
        title = ""
        price = ""
    }

    func loadPreview(animate: Bool) async {
        guard validURL != nil else { return }
        let requestedLink = link
        isLoadingPreview = true

        do {
            let preview = try await previewService.fetch(from: requestedLink)
            guard !Task.isCancelled, link == requestedLink else { return }
            if let image = preview.imageData {
                withAnimation(animate ? .easeInOut(duration: 0.28) : nil) {
                    imageData = image
                    highlightedFields.insert(.image)
                }
            }
            if animate {
                try? await Task.sleep(for: .milliseconds(150))
            }
            guard !Task.isCancelled, link == requestedLink else { return }

            if title.isEmpty, let previewTitle = preview.title {
                withAnimation(animate ? .easeInOut(duration: 0.28) : nil) {
                    title = previewTitle
                    highlightedFields.insert(.title)
                }
            }
            if animate {
                try? await Task.sleep(for: .milliseconds(150))
            }
            guard !Task.isCancelled, link == requestedLink else { return }

            if price.isEmpty, let amount = preview.price {
                withAnimation(animate ? .easeInOut(duration: 0.28) : nil) {
                    price = String(amount)
                    highlightedFields.insert(.price)
                }
            }
        } catch {
        }
        guard !Task.isCancelled, link == requestedLink else { return }
        isLoadingPreview = false
        previewedLink = requestedLink

        if !highlightedFields.isEmpty {
            try? await Task.sleep(for: .milliseconds(500))
            withAnimation(animate ? .easeOut(duration: 0.35) : nil) {
                highlightedFields = []
            }
        }
    }

    func save() throws {
        guard let url = validURL else { throw ShareError.invalidLink }
        let amount = price.replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "원", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedPrice: Int?
        if amount.isEmpty {
            parsedPrice = nil
        } else if let value = Int(amount), value >= 0 {
            parsedPrice = value
        } else {
            throw ShareError.invalidPrice
        }
        if hasReviewDate && reviewDate <= .now {
            throw ShareError.pastDate
        }

        let wish = PendingSharedWish(
            id: UUID(),
            createdAt: .now,
            link: url.absoluteString,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? (url.host ?? url.absoluteString)
                : title.trimmingCharacters(in: .whitespacesAndNewlines),
            categoryRaw: category,
            price: parsedPrice,
            reason: reason.trimmingCharacters(in: .whitespacesAndNewlines),
            reviewAt: hasReviewDate ? reviewDate : nil,
            wantsReminder: hasReviewDate && wantsReminder,
            imageData: imageData
        )
        try SharedLinkInbox.enqueue(wish)
    }

    // MARK: - Private Types

    private enum ShareError: LocalizedError {
        case invalidLink, invalidPrice, pastDate

        var errorDescription: String? {
            switch self {
            case .invalidLink: "http 또는 https 상품 링크를 넣어주세요"
            case .invalidPrice: "가격은 0 이상의 숫자로 입력해주세요"
            case .pastDate: "다시 볼 날짜를 미래로 정해주세요"
            }
        }
    }
}

struct ShareComposerView: View {
    // MARK: - Properties

    @ObservedObject var model: ShareComposerModel
    let onCancel: () -> Void
    let onSaved: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isLinkFocused: Bool
    @State private var visibleErrorMessage: String?
    @State private var errorDismissTask: Task<Void, Never>?
    private let reviewDayOptions = [1, 3, 5, 7, 10]

    // MARK: - Computed Properties

    private var categories: [String] {
        let defaults = UserDefaults(suiteName: "group.won.DoGo-iOS")
        let saved = defaults?.stringArray(forKey: "wishCategories.v1")
        return saved?.isEmpty == false
            ? saved ?? ["미분류"]
            : ["디지털", "패션", "생활", "취미", "미분류"]
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    section("상품 링크", optional: false) {
                        TextField("https://…", text: $model.link)
                            .font(.system(size: 16))
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($isLinkFocused)
                            .frame(minHeight: 48)
                            .onSubmit {
                                presentInvalidLinkErrorIfNeeded()
                                isLinkFocused = false
                            }
                    }

                    if model.isReadingLink {
                        editorCard {
                            HStack(spacing: 10) {
                                ProgressView()
                                Text("공유한 링크를 읽고 있어요")
                                    .font(.system(size: 14))
                                    .foregroundStyle(themeSecondary)
                            }
                        }
                    }

                    if showsDetails {
                        section("상품 정보", optional: false) {
                            if isShowingProductLoading {
                                HStack(spacing: 10) {
                                    ProgressView()
                                    Text("상품 정보를 불러오는 중이에요")
                                        .font(.system(size: 14))
                                        .foregroundStyle(themeSecondary)
                                }
                                .frame(minHeight: 54)
                            } else {
                                VStack(spacing: 0) {
                                    productImage
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 16)
                                        .background { autofillBackground(for: .image) }

                                    cardDivider

                                    TextField("상품 이름", text: $model.title)
                                        .font(.system(size: 16))
                                        .frame(minHeight: 54)
                                        .background { autofillBackground(for: .title) }

                                    cardDivider

                                    TextField("가격 (원)", text: $model.price)
                                        .font(.system(size: 16))
                                        .keyboardType(.numberPad)
                                        .frame(minHeight: 54)
                                        .background { autofillBackground(for: .price) }

                                    cardDivider

                                    HStack {
                                        Text("카테고리")
                                            .font(.system(size: 16))
                                            .foregroundStyle(themeInk)

                                        Spacer()

                                        Picker("카테고리", selection: $model.category) {
                                            ForEach(categories, id: \.self) { category in
                                                Text(category).tag(category)
                                            }
                                        }
                                        .labelsHidden()
                                        .pickerStyle(.menu)
                                        .tint(themeInk)
                                    }
                                    .frame(minHeight: 54)
                                }
                            }
                        } footer: {
                            if !model.isLoadingPreview,
                                model.previewedLink == model.link
                            {
                                Text("상품 정보를 채웠어요 가격이 맞는지 확인해주세요")
                            }
                        }
                        .transition(revealTransition)

                        if showsAdditionalDetails {
                            Group {
                                section("사고 싶은 이유") {
                                    TextField("어떤 순간에 필요할까요?", text: $model.reason, axis: .vertical)
                                        .font(.system(size: 16))
                                        .lineLimit(4...7)
                                        .frame(minHeight: 96, alignment: .topLeading)
                                }

                                section("다시 만나는 날") {
                                    VStack(alignment: .leading, spacing: 16) {
                                        Toggle("다시 볼 날짜 정하기", isOn: $model.hasReviewDate)
                                            .font(.system(size: 16, weight: .medium))
                                            .tint(themeAccent)

                                        if model.hasReviewDate {
                                            cardDivider

                                            reviewDateChips
                                                .padding(.horizontal, -16)

                                            cardDivider

                                            Toggle("알림 받기", isOn: $model.wantsReminder)
                                                .font(.system(size: 16, weight: .medium))
                                                .tint(themeAccent)
                                        }
                                    }
                                } footer: {
                                    if model.hasReviewDate && model.wantsReminder {
                                        Text("선택한 날 오후 1시에 알림을 보내드려요")
                                    }
                                }
                            }
                            .transition(revealTransition)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 48)
                .animation(revealAnimation, value: showsDetails)
                .animation(revealAnimation, value: showsAdditionalDetails)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(themeBackground)
            .navigationTitle("마음 담기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소", action: onCancel)
                        .tint(themeInk)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("저장") {
                        model.isSaving = true
                        defer { model.isSaving = false }
                        do {
                            try model.save()
                            onSaved()
                        } catch {
                            model.errorMessage = error.localizedDescription
                        }
                    }
                    .tint(themeAccent)
                    .fontWeight(.semibold)
                    .disabled(model.validURL == nil || model.isSaving)
                }
            }
            .overlay(alignment: .top) {
                if let visibleErrorMessage {
                    shareErrorToast(visibleErrorMessage)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .transition(
                            reduceMotion
                                ? .opacity
                                : .move(edge: .top).combined(with: .opacity)
                        )
                        .allowsHitTesting(false)
                        .zIndex(10)
                }
            }
            .onChange(of: isLinkFocused) { wasFocused, isFocused in
                if wasFocused && !isFocused {
                    presentInvalidLinkErrorIfNeeded()
                }
            }
            .onChange(of: model.errorMessage, initial: true) { _, message in
                guard let message, !message.isEmpty else { return }
                presentErrorToast(message)
            }
            .onDisappear { errorDismissTask?.cancel() }
            .task(id: model.link) {
                model.preparePreview()
                guard model.validURL != nil else { return }
                try? await Task.sleep(for: .milliseconds(350))
                guard !Task.isCancelled else { return }
                await model.loadPreview(animate: !reduceMotion)
            }
        }
    }

    // MARK: - Subviews

    private var productImage: some View {
        Group {
            if let data = model.imageData, let image = UIImage(data: data) {
                HStack(spacing: 14) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("대표 사진을 가져왔어요")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(themeInk)

                        Button {
                            Task { await model.loadPreview(animate: !reduceMotion) }
                        } label: {
                            Text("다시 불러오기")
                                .font(.system(size: 12))
                                .foregroundStyle(themeSecondary)
                                .underline()
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                Text("대표 사진을 찾지 못했어요")
                    .font(.system(size: 14))
                    .foregroundStyle(themeSecondary)
                    .frame(minHeight: 54)
            }
        }
    }

    private func section<Content: View, Footer: View>(
        _ title: String,
        optional: Bool = true,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(title, optional: optional)

            let verticalSpacing: CGFloat = {
                switch title {
                case "상품 링크": return 6
                case "상품 정보": return 0
                default: return 16
                }
            }()

            editorCard(verticalSpacing: verticalSpacing) {
                content()
            }
            footer()
                .font(.system(size: 12))
                .foregroundStyle(themeSecondary)
        }
    }

    private func section<Content: View>(
        _ title: String,
        optional: Bool = true,
        @ViewBuilder content: () -> Content
    ) -> some View {
        section(title, optional: optional, content: content) { EmptyView() }
    }

    private func sectionTitle(_ title: String, optional: Bool) -> some View {
        Text(title)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(themeInk)
            .overlay(alignment: .topTrailing) {
                if !optional {
                    Circle()
                        .fill(themeAccent)
                        .frame(width: 6, height: 6)
                        .offset(x: 8, y: -2)
                }
            }
    }

    private func editorCard<Content: View>(
        verticalSpacing: CGFloat = 16,
        horizontalSpacing: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .padding(.vertical, verticalSpacing)
            .padding(.horizontal, horizontalSpacing)
            .frame(maxWidth: .infinity, alignment: .leading)
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .background {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(themeSurface)
                    .shadow(color: themeShadowColor, radius: 5)
            }
    }

    private var cardDivider: some View {
        Rectangle()
            .fill(themeBorder.opacity(0.65))
            .frame(height: 1)
            .padding(.horizontal, -16)
    }

    private var reviewDateChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(reviewDayOptions, id: \.self) { days in
                    let isSelected = selectedReviewDays == days

                    Button {
                        selectReviewDay(days)
                    } label: {
                        Text(days == 1 ? "내일" : "\(days)일 뒤")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(isSelected ? themeOnAccent : themeSecondary)
                            .padding(.horizontal, 16)
                            .frame(height: 40)
                            .background {
                                Capsule()
                                    .fill(isSelected ? themeAccent : themeSurface)
                                    .shadow(color: themeShadowColor, radius: 4)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
        }
        .frame(height: 44)
    }

    private var selectedReviewDays: Int? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let selectedDay = calendar.startOfDay(for: model.reviewDate)
        return calendar.dateComponents([.day], from: today, to: selectedDay).day
    }

    // MARK: - Methods

    private func selectReviewDay(_ days: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        model.reviewDate = calendar.date(byAdding: .day, value: days, to: today) ?? today
    }

    // MARK: - Computed Properties

    private var showsDetails: Bool { model.validURL != nil }

    private var showsAdditionalDetails: Bool {
        model.previewedLink == model.link
    }

    private var isShowingProductLoading: Bool {
        model.isLoadingPreview || (showsDetails && model.previewedLink != model.link)
    }

    private var revealAnimation: Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.28)
    }

    private var revealTransition: AnyTransition {
        reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity)
    }

    // MARK: - Methods

    private func presentInvalidLinkErrorIfNeeded() {
        let trimmed = model.link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, model.validURL == nil else { return }
        model.errorMessage = "http 또는 https로 시작하는 상품 링크를 넣어주세요"
    }

    private func presentErrorToast(_ message: String) {
        errorDismissTask?.cancel()

        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
            visibleErrorMessage = message
        }

        errorDismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }

            withAnimation(reduceMotion ? nil : .easeIn(duration: 0.2)) {
                if visibleErrorMessage == message {
                    visibleErrorMessage = nil
                }
            }

            if model.errorMessage == message {
                model.errorMessage = nil
            }
        }
    }

    private func shareErrorToast(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))

            Text(message)
                .font(.system(size: 14, weight: .medium))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(themeBackground)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: 560, alignment: .leading)
        .background(
            themeInk,
            in: RoundedRectangle(cornerRadius: 13, style: .continuous)
        )
        .shadow(color: Color.black.opacity(0.14), radius: 12, y: 5)
    }

    private func autofillBackground(for field: ShareComposerModel.AutofilledField) -> some View {
        Rectangle()
            .fill(themeAccent.opacity(0.12))
            .opacity(model.highlightedFields.contains(field) ? 1 : 0)
            .padding(.horizontal, -16)
            .allowsHitTesting(false)
    }

    // MARK: - Theme

    private var themeBackground: Color {
        colorScheme == .dark
            ? Color(red: 18 / 255, green: 18 / 255, blue: 18 / 255)
            : Color(red: 251 / 255, green: 251 / 255, blue: 251 / 255)
    }
    private var themeSurface: Color {
        colorScheme == .dark ? Color(red: 34 / 255, green: 34 / 255, blue: 34 / 255) : .white
    }
    private var themeInk: Color {
        colorScheme == .dark
            ? Color(red: 245 / 255, green: 245 / 255, blue: 245 / 255)
            : Color(red: 32 / 255, green: 33 / 255, blue: 36 / 255)
    }
    private var themeSecondary: Color {
        colorScheme == .dark
            ? Color(red: 176 / 255, green: 176 / 255, blue: 176 / 255)
            : Color(red: 117 / 255, green: 117 / 255, blue: 117 / 255)
    }
    private var themeBorder: Color {
        colorScheme == .dark
            ? Color(red: 56 / 255, green: 56 / 255, blue: 56 / 255)
            : Color(red: 233 / 255, green: 233 / 255, blue: 233 / 255)
    }
    private var themeShadowColor: Color {
        .black.opacity(colorScheme == .dark ? 0.12 : 0.04)
    }
    private var themeAccent: Color {
        Color(red: 245 / 255, green: 90 / 255, blue: 116 / 255)
    }
    private var themeOnAccent: Color {
        colorScheme == .dark
            ? Color(red: 41 / 255, green: 41 / 255, blue: 41 / 255)
            : Color(red: 247 / 255, green: 247 / 255, blue: 250 / 255)
    }
}
