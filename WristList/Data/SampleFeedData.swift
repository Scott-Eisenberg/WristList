//
//  SampleFeedData.swift
//  WristList
//

import Foundation

enum SampleFeedData {
    static let novaBloom = Festival(
        id: "nova-bloom",
        name: "Nova Bloom",
        city: "Austin, TX",
        dateRange: "Apr 17-19",
        genreTags: ["Indie", "Electronic", "Alt Pop"],
        palette: .sunset
    )

    static let lunarPier = Festival(
        id: "lunar-pier",
        name: "Lunar Pier",
        city: "Long Beach, CA",
        dateRange: "May 2-4",
        genreTags: ["House", "Disco", "Funk"],
        palette: .violet
    )

    static let desertCircuit = Festival(
        id: "desert-circuit",
        name: "Desert Circuit",
        city: "Phoenix, AZ",
        dateRange: "May 22-24",
        genreTags: ["Techno", "Bass", "Live"],
        palette: .electric
    )

    static let harborGlow = Festival(
        id: "harbor-glow",
        name: "Harbor Glow",
        city: "Seattle, WA",
        dateRange: "Jun 12-14",
        genreTags: ["Electronic", "Ambient", "Pop"],
        palette: .lagoon
    )

    static let emberFields = Festival(
        id: "ember-fields",
        name: "Ember Fields",
        city: "Nashville, TN",
        dateRange: "Jul 10-12",
        genreTags: ["Americana", "Rock", "Soul"],
        palette: .ember
    )

    static let upcomingFestivals: [Festival] = [
        novaBloom,
        lunarPier,
        desertCircuit,
        harborGlow,
        emberFields
    ]

    static let reviews: [FestivalReview] = [
        FestivalReview(
            id: "review-maya-nova",
            user: FeedUser(id: "maya", name: "Maya Chen", handle: "@maya.wav", initials: "MC", palette: .violet),
            festival: novaBloom,
            attendedOn: "Weekend 1, 2026",
            overallScore: 9.2,
            reviewText: "The sunset main stage run was unreal. Easy entry, tight sound, and enough smaller tents to keep the whole weekend moving.",
            categoryScores: [
                ReviewCategoryScore(id: "maya-lineup", name: "Lineup", score: 9.5),
                ReviewCategoryScore(id: "maya-production", name: "Production", score: 9.0),
                ReviewCategoryScore(id: "maya-venue", name: "Venue", score: 8.8),
                ReviewCategoryScore(id: "maya-value", name: "Value", score: 9.1)
            ],
            likes: 128,
            comments: 24,
            isSaved: true
        ),
        FestivalReview(
            id: "review-jordan-lunar",
            user: FeedUser(id: "jordan", name: "Jordan Ellis", handle: "@jellis", initials: "JE", palette: .sunset),
            festival: lunarPier,
            attendedOn: "May 2026",
            overallScore: 8.7,
            reviewText: "Best dance crowd I have been in all year. Food lines dragged on Saturday, but the pier stage after midnight made up for it.",
            categoryScores: [
                ReviewCategoryScore(id: "jordan-lineup", name: "Lineup", score: 8.9),
                ReviewCategoryScore(id: "jordan-production", name: "Production", score: 9.3),
                ReviewCategoryScore(id: "jordan-venue", name: "Venue", score: 8.6),
                ReviewCategoryScore(id: "jordan-value", name: "Value", score: 7.8)
            ],
            likes: 92,
            comments: 13,
            isSaved: false
        ),
        FestivalReview(
            id: "review-alex-desert",
            user: FeedUser(id: "alex", name: "Alex Rivera", handle: "@alexafterdark", initials: "AR", palette: .electric),
            festival: desertCircuit,
            attendedOn: "Memorial Day 2026",
            overallScore: 8.9,
            reviewText: "Huge sound, clean layout, and a surprisingly strong late-night live stage. Bring shade, because the walk between stages is no joke.",
            categoryScores: [
                ReviewCategoryScore(id: "alex-lineup", name: "Lineup", score: 9.0),
                ReviewCategoryScore(id: "alex-production", name: "Production", score: 9.4),
                ReviewCategoryScore(id: "alex-venue", name: "Venue", score: 8.0),
                ReviewCategoryScore(id: "alex-value", name: "Value", score: 8.4)
            ],
            likes: 76,
            comments: 18,
            isSaved: true
        )
    ]
}
