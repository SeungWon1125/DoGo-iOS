//
//  ReviewDatePicker.swift
//  DuGo-iOS
//

import SwiftUI

struct ReviewDatePicker: View {
    // MARK: - Properties

    @Binding private var reviewDate: Date
    @State private var selectedDays: Int?

    private let calendar = Calendar.current
    private let dayOptions = [1, 3, 5, 7, 10]

    // MARK: - Initializer

    init(reviewDate: Binding<Date>) {
        _reviewDate = reviewDate
    }

    // MARK: - Body

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(dayOptions, id: \.self) { days in
                    dayChip(days)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
        }
        .frame(height: 44)
        .onAppear(perform: configureInitialSelection)
        .onChange(of: reviewDate) { _, _ in
            updateSelectedDays()
        }
    }

    // MARK: - Subviews

    private func dayChip(_ days: Int) -> some View {
        let isSelected = selectedDays == days

        return Button {
            var transaction = Transaction()
            transaction.animation = nil
            transaction.disablesAnimations = true

            withTransaction(transaction) {
                selectedDays = days
                reviewDate = reviewDate(after: days)
            }
        } label: {
            Text(days == 1 ? "내일" : "\(days)일 뒤")
                .applyDuGoFont(.body14Medium)
                .foregroundStyle(isSelected ? DuGoTheme.onAccent : DuGoTheme.secondary)
                .padding(.horizontal, 16)
                .frame(height: 40)
                .background {
                    Capsule()
                        .fill(isSelected ? DuGoTheme.accent : DuGoTheme.surface)
                        .dugoShadow(.subtle)
                }
        }
        .buttonStyle(.plain)
        .animation(nil, value: isSelected)
    }

    // MARK: - Methods

    private func reviewDate(after days: Int) -> Date {
        let today = calendar.startOfDay(for: .now)
        return calendar.date(byAdding: .day, value: days, to: today) ?? today
    }

    private func configureInitialSelection() {
        updateSelectedDays()

        let days = selectedDays ?? 3
        selectedDays = days
        reviewDate = reviewDate(after: days)
    }

    private func updateSelectedDays() {
        let today = calendar.startOfDay(for: .now)
        let selectedDay = calendar.startOfDay(for: reviewDate)
        let days = calendar.dateComponents([.day], from: today, to: selectedDay).day
        selectedDays = dayOptions.contains(days ?? -1) ? days : nil
    }
}
