//
//  UpdateCheckerService.swift
//  Asado
//
//  Created by Fran Alarza
//

import Foundation

protocol UpdateCheckerServiceProtocol: Sendable {
    func fetchLatestVersion() async -> String?
}

struct UpdateCheckerService: UpdateCheckerServiceProtocol {

    private let repoReleasesURL = URL(string: "https://api.github.com/repos/FranAlarza/Asado/releases/latest")!

    func fetchLatestVersion() async -> String? {
        guard let (data, _) = try? await URLSession.shared.data(from: repoReleasesURL) else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tagName = json["tag_name"] as? String else { return nil }
        return tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
    }
}
