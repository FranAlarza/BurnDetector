//
//  MetricCardView.swift
//  Asado
//
//  Created by Fran Alarza on 5/4/26.
//

import SwiftUI

struct MetricCardView: View {
    let systemImage: String
    let title: String
    let value: String
    var action: (() -> Void)? = nil
    var tintColor: Color? = nil
    var infoMessage: String? = nil

    @State private var isInfoPopoverPresented = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 16))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            tintColor.map { AnyShapeStyle($0.opacity(0.25)) } ?? AnyShapeStyle(.quaternary),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(alignment: .topTrailing) {
            if let message = infoMessage {
                Button {
                    isInfoPopoverPresented = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                        .padding(8)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $isInfoPopoverPresented) {
                    Text(message)
                        .font(.callout)
                        .multilineTextAlignment(.leading)
                        .padding(12)
                        .frame(maxWidth: 220)
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if let action {
                Button(action: action) {
                    Image(systemName: "arrow.up.forward.app")
                        .font(.system(size: 12))
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
