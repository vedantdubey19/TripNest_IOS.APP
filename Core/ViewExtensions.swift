import SwiftUI

extension View {
    @ViewBuilder
    func navigationBarTitleDisplayModeInline() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayModeInline()
        #else
        self
        #endif
    }
}
