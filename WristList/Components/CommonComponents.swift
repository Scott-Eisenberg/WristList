//
//  CommonComponents.swift
//  WristList
//

import SwiftUI

struct HeaderIconButton: View {
    let systemImage: String
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 42, height: 42)
                .background(.ultraThinMaterial, in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

struct AvatarButton: View {
    let initials: String
    let palette: FestivalPalette
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(initials)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(WristlistTheme.gradient(for: palette), in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(Color.white.opacity(0.30), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open profile")
    }
}

struct WristbandTag: View {
    let text: String
    let palette: FestivalPalette

    var body: some View {
        Text(text.uppercased())
            .font(.caption2.weight(.bold))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(.white)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(WristlistTheme.gradient(for: palette), in: Capsule())
            .accessibilityLabel(text)
    }
}

struct ScoreBadge: View {
    let score: Double
    let palette: FestivalPalette

    var body: some View {
        VStack(spacing: 0) {
            Text(score, format: .number.precision(.fractionLength(1)))
                .font(.system(size: 24, weight: .black, design: .rounded))
                .monospacedDigit()
            Text("/10")
                .font(.caption2.weight(.bold))
                .opacity(0.78)
        }
        .foregroundStyle(.white)
        .frame(width: 64, height: 58)
        .background(WristlistTheme.gradient(for: palette), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityLabel("Overall score \(score, specifier: "%.1f") out of 10")
    }
}

struct FestivalArtworkView: View {
    let festival: Festival

    var body: some View {
        ZStack {
            WristlistTheme.gradient(for: festival.palette)

            VStack(spacing: 10) {
                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Color.white.opacity(index.isMultiple(of: 2) ? 0.75 : 0.35))
                            .frame(width: 22, height: 74)
                            .rotationEffect(.degrees(Double(index - 2) * 7))
                    }
                }

                Image(systemName: "waveform.path.ecg.rectangle")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white.opacity(0.88))
            }
        }
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 3) {
                Text(festival.name)
                    .font(.headline.weight(.bold))
                    .lineLimit(2)
                Text(festival.city)
                    .font(.caption.weight(.semibold))
                    .opacity(0.84)
            }
            .foregroundStyle(.white)
            .padding(12)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Festival artwork for \(festival.name) in \(festival.city)")
    }
}
