import SwiftUI
import UIKit
import WebKit

private let voiceURL = URL(string: "https://voice.hertz.page")!

final class WebViewStore: ObservableObject {
    weak var webView: WKWebView?
    @Published var isLoading = false
    @Published var canGoBack = false
    @Published var canGoForward = false

    func attach(_ webView: WKWebView) {
        self.webView = webView
    }

    func goBack() {
        webView?.goBack()
    }

    func goForward() {
        webView?.goForward()
    }

    func reload() {
        webView?.reload()
    }
}

struct ContentView: View {
    @StateObject private var store = WebViewStore()

    var body: some View {
        VStack(spacing: 0) {
            if store.isLoading {
                ProgressView()
                    .progressViewStyle(.linear)
            }
            WebView(url: voiceURL, store: store)
            Divider()
            HStack(spacing: 20) {
                Button("Back") {
                    store.goBack()
                }
                .disabled(!store.canGoBack)

                Button("Forward") {
                    store.goForward()
                }
                .disabled(!store.canGoForward)

                Button("Reload") {
                    store.reload()
                }
            }
            .padding(.vertical, 10)
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    @ObservedObject var store: WebViewStore

    func makeCoordinator() -> Coordinator {
        Coordinator(store: store)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.websiteDataStore = .default()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        store.attach(webView)
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    private let store: WebViewStore

    init(store: WebViewStore) {
        self.store = store
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        store.isLoading = true
        updateNavigationState(webView)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        store.isLoading = false
        updateNavigationState(webView)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        store.isLoading = false
        updateNavigationState(webView)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        store.isLoading = false
        updateNavigationState(webView)
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if let url = navigationAction.request.url, let scheme = url.scheme?.lowercased() {
            if scheme == "http" || scheme == "https" {
                decisionHandler(.allow)
                return
            }
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }

    private func updateNavigationState(_ webView: WKWebView) {
        store.canGoBack = webView.canGoBack
        store.canGoForward = webView.canGoForward
    }
}
