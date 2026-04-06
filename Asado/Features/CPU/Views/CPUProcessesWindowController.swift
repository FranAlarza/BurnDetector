//
//  CPUProcessesWindowController.swift
//  Asado
//
//  Created by Fran Alarza on 6/4/26.
//

import AppKit
import SwiftUI

@MainActor
final class CPUProcessesWindowController: NSObject, NSWindowDelegate {

    // MARK: - Private

    private var window: NSWindow?

    // MARK: - Public

    func show(viewModel: MenuBarViewModel) {
        guard window == nil else {
            window?.makeKeyAndOrderFront(nil)
            return
        }

        let newWindow = NSWindow(
            contentRect: .zero,
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        newWindow.title = "Top Processes"
        newWindow.contentView = NSHostingView(rootView: CPUProcessesView(viewModel: viewModel))
        newWindow.delegate = self
        newWindow.setContentSize(NSSize(width: 380, height: 320))
        newWindow.center()
        newWindow.orderFrontRegardless()
        self.window = newWindow
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}
