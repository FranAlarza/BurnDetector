import Foundation
import Testing
@testable import Asado

struct DiskMonitoringServiceTests {

    @Test
    func freeDiskSpaceReturnsPositiveValue() {
        let sut = DiskMonitoringService()
        let result = sut.freeDiskSpaceGB()

        #expect(result != nil)
        if let gb = result {
            #expect(gb > 0)
        }
    }
}
