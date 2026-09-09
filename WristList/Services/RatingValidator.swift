//
//  RatingValidator.swift
//  WristList
//

import Foundation

struct ReviewDraft: Equatable {
    var festivalID: String?
    var status: AttendanceStatus
    var attendedDate: Date?
    var overallScore: Double
    var lineupScore: Double
    var productionScore: Double
    var venueScore: Double
    var organizationScore: Double
    var valueScore: Double
    var reviewText: String
    var favoritePerformances: [String]
    var isVisibleToFriends: Bool

    static let blank = ReviewDraft(
        festivalID: nil,
        status: .attended,
        attendedDate: .now,
        overallScore: 8,
        lineupScore: 8,
        productionScore: 8,
        venueScore: 8,
        organizationScore: 8,
        valueScore: 8,
        reviewText: "",
        favoritePerformances: [],
        isVisibleToFriends: true
    )
}

enum ReviewValidationIssue: Error, Equatable, Identifiable {
    case missingFestival
    case missingAttendanceState
    case missingAttendedDate
    case invalidScore(String)

    var id: String { message }

    var message: String {
        switch self {
        case .missingFestival:
            "Choose a festival before saving."
        case .missingAttendanceState:
            "Choose whether this festival is attended or want-to-go."
        case .missingAttendedDate:
            "Add the date you attended this festival."
        case .invalidScore(let label):
            "\(label) must be between 0 and 10."
        }
    }
}

enum RatingValidator {
    static func validationIssues(for draft: ReviewDraft) -> [ReviewValidationIssue] {
        var issues: [ReviewValidationIssue] = []

        if draft.festivalID == nil {
            issues.append(.missingFestival)
        }

        if draft.status == .none || draft.status == .saved {
            issues.append(.missingAttendanceState)
        }

        if draft.status == .attended && draft.attendedDate == nil {
            issues.append(.missingAttendedDate)
        }

        let scores = [
            ("Overall score", draft.overallScore),
            ("Lineup", draft.lineupScore),
            ("Production", draft.productionScore),
            ("Venue", draft.venueScore),
            ("Organization", draft.organizationScore),
            ("Value", draft.valueScore)
        ]

        for score in scores where !(0...10).contains(score.1) {
            issues.append(.invalidScore(score.0))
        }

        return issues
    }

    static func validate(_ draft: ReviewDraft) throws {
        if let firstIssue = validationIssues(for: draft).first {
            throw firstIssue
        }
    }
}
