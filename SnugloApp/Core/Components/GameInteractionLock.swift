import SwiftUI
import UIKit

// MARK: — GameInteractionLock
// SwiftUI's `.scrollDisabled` does NOT stop a `.page`-style TabView from swiping
// between tabs, and `.navigationBarBackButtonHidden` does not reliably disable the
// edge swipe-back. So while the game is on screen we reach into UIKit and turn both
// off directly — the parent paged UIScrollView and the NavigationController's
// interactive-pop gesture. The game can then only be left via the Back button.
//
// Place as an invisible `.background` of the game root. It restores both gestures
// when removed (Back / pop), so the rest of the app swipes normally again.

struct GameInteractionLock: UIViewRepresentable {

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIView {
        let probe = ProbeView()
        probe.isUserInteractionEnabled = false
        probe.backgroundColor = .clear
        probe.onAttach = { [weak probe] in
            guard let probe else { return }
            Self.lock(from: probe, coordinator: context.coordinator)
        }
        return probe
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Re-assert after SwiftUI layout passes (which can re-enable the scroll).
        DispatchQueue.main.async { Self.lock(from: uiView, coordinator: context.coordinator) }
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.restore()
    }

    // MARK: — Lock

    private static func lock(from view: UIView, coordinator: Coordinator) {
        // 1) Parent paged scroll view (the TabView carousel).
        var ancestor: UIView? = view.superview
        while let cur = ancestor {
            if let scroll = cur as? UIScrollView {
                if coordinator.scroll == nil {
                    coordinator.scroll = scroll
                    coordinator.scrollWasEnabled = scroll.isScrollEnabled
                    coordinator.panWasEnabled = scroll.panGestureRecognizer.isEnabled
                }
                scroll.isScrollEnabled = false
                scroll.panGestureRecognizer.isEnabled = false
                break
            }
            ancestor = cur.superview
        }
        // 2) NavigationController interactive pop (edge swipe-back).
        var responder: UIResponder? = view
        while let r = responder {
            if let nav = (r as? UIViewController)?.navigationController {
                if coordinator.nav == nil {
                    coordinator.nav = nav
                    coordinator.popWasEnabled = nav.interactivePopGestureRecognizer?.isEnabled ?? true
                }
                nav.interactivePopGestureRecognizer?.isEnabled = false
                break
            }
            responder = r.next
        }
    }

    // MARK: — Coordinator

    final class Coordinator {
        weak var scroll: UIScrollView?
        var scrollWasEnabled = true
        var panWasEnabled = true
        weak var nav: UINavigationController?
        var popWasEnabled = true

        func restore() {
            if let scroll {
                scroll.isScrollEnabled = scrollWasEnabled
                scroll.panGestureRecognizer.isEnabled = panWasEnabled
            }
            nav?.interactivePopGestureRecognizer?.isEnabled = popWasEnabled
        }
    }

    /// Fires `onAttach` once it joins the window — when the ancestor chain (and the
    /// paged scroll view) is guaranteed to exist.
    private final class ProbeView: UIView {
        var onAttach: (() -> Void)?
        override func didMoveToWindow() {
            super.didMoveToWindow()
            if window != nil { onAttach?() }
        }
    }
}
