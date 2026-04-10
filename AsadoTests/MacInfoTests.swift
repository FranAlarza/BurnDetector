//
//  MacInfoTests.swift
//  Asado
//
//  Created by Fran Alarza on 11/4/26.
//

import Testing
@testable import Asado

struct MacInfoTests {

    // MARK: - MacType symbolName

    @Test
    func macBookSymbolName() {
        #expect(MacType.macBook.symbolName == "laptopcomputer")
    }

    @Test
    func macMiniSymbolName() {
        #expect(MacType.macMini.symbolName == "macmini")
    }

    @Test
    func iMacSymbolName() {
        #expect(MacType.iMac.symbolName == "desktopcomputer")
    }

    @Test
    func macProSymbolName() {
        #expect(MacType.macPro.symbolName == "macpro.gen3")
    }

    @Test
    func macStudioSymbolName() {
        #expect(MacType.macStudio.symbolName == "macstudio")
    }

    // MARK: - MacInfo subtitleLabel

    @Test
    func subtitleLabelWithChipAndRAM() {
        let info = MacInfo(modelName: "MacBook Pro", chipName: "Apple M2 Pro", totalRAMGB: 16, macType: .macBook)
        #expect(info.subtitleLabel == "Apple M2 Pro · 16 GB")
    }

    @Test
    func subtitleLabelWithoutChip() {
        let info = MacInfo(modelName: "Mac", chipName: "", totalRAMGB: 8, macType: .generic)
        #expect(info.subtitleLabel == "8 GB")
    }

    @Test
    func subtitleLabelZeroRAMWithChip() {
        let info = MacInfo(modelName: "Mac mini", chipName: "Apple M2", totalRAMGB: 0, macType: .macMini)
        #expect(info.subtitleLabel == "Apple M2 · 0 GB")
    }
}
