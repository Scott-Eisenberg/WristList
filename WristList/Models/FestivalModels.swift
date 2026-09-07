//
//  FestivalModels.swift
//  WristList
//

import Foundation

struct Festival: Identifiable, Hashable {
    let id: String
    let name: String
    let city: String
    let dateRange: String
    let genreTags: [String]
    let palette: FestivalPalette
}

enum FestivalPalette: String, CaseIterable, Hashable {
    case sunset
    case violet
    case electric
    case lagoon
    case ember
}

struct FestivalReview: Identifiable, Hashable {
    let id: String
    let user: FeedUser
    let festival: Festival
    let attendedOn: String
    let overallScore: Double
    let reviewText: String
    let categoryScores: [ReviewCategoryScore]
    let likes: Int
    let comments: Int
    let isSaved: Bool
}

struct FeedUser: Identifiable, Hashable {
    let id: String
    let name: String
    let handle: String
    let initials: String
    let palette: FestivalPalette
}

struct ReviewCategoryScore: Identifiable, Hashable {
    let id: String
    let name: String
    let score: Double
}
