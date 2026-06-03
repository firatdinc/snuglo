import SwiftUI

// MARK: — DeferredContent
// Wraps a heavy view so its body is NOT built synchronously during the enclosing
// transition (e.g. a `.page` TabView scroll between tabs). EVERY time the page
// appears (or is scrolled across) it shows a lightweight LoadingView first, then —
// one short yield later, after the scroll has committed cheaply — builds the real
// content. `ready` is reset to false on disappear so re-entry always shows the
// loading state instantly instead of trying to render the heavy tree mid-scroll
// (which caused the "tap → brief freeze → page" stall).
//
// This keeps the tap feeling instant (you land on the page + see loading the moment
// you tap) and keeps horizontal tab-swipe smooth, because pages crossed during a
// scroll render only the cheap LoadingView, never the heavy tree.

struct DeferredContent<Content: View>: View {
    var message: LocalizedStringKey = "common.loading"
    @ViewBuilder var content: () -> Content

    @State private var ready = false

    var body: some View {
        LoadingGate(isReady: ready, message: message) {
            content()
        }
        .task {
            // One short yield lets the page-scroll / tab transition land before the
            // expensive view tree is built — the switch feels instant either way.
            try? await Task.sleep(for: .milliseconds(50))
            ready = true
        }
        // Reset so the next appearance shows loading immediately rather than
        // re-rendering the heavy tree during the page-scroll commit.
        .onDisappear { ready = false }
    }
}
