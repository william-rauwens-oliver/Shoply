//
//  ChatGPTConnectionWebView.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI
import WebKit
import AuthenticationServices

/// WebView pour connecter le compte ChatGPT et extraire la clé API
struct ChatGPTConnectionWebView: View {
    @Environment(\.dismiss) var dismiss
    let onConnected: (String) -> Void
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            ChatGPTWebViewRepresentable(onKeyFound: { key in
                onConnected(key)
                dismiss()
            })
        }
        .navigationTitle("Connexion ChatGPT")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Fermer") {
                    dismiss()
                }
            }
        }
    }
}

struct ChatGPTWebViewRepresentable: UIViewRepresentable {
    let onKeyFound: (String) -> Void
    
    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(onKeyFound: onKeyFound)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(context.coordinator, name: "apiKeyExtractor")
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        
        // Charger la page de connexion OpenAI
        if let url = URL(string: "https://platform.openai.com/api-keys") {
            webView.load(URLRequest(url: url))
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Pas de mise à jour nécessaire
    }
}

class WebViewCoordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    let onKeyFound: (String) -> Void
    
    init(onKeyFound: @escaping (String) -> Void) {
        self.onKeyFound = onKeyFound
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Attendre un peu pour que la page se charge complètement
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Injecter du JavaScript pour détecter les clés API
            let script = """
            (function() {
                // Surveiller les changements dans le DOM pour détecter les clés API affichées
                const observer = new MutationObserver(function(mutations) {
                    const text = document.body.innerText || document.body.textContent || '';
                    // Chercher un pattern de clé API (sk- suivi d'alphanumériques)
                    const apiKeyPattern = /sk-[a-zA-Z0-9]{20,}/g;
                    const matches = text.match(apiKeyPattern);
                    
                    if (matches && matches.length > 0) {
                        // Prendre la première clé trouvée qui semble valide
                        for (let match of matches) {
                            if (match.startsWith('sk-') && match.length > 30) {
                                window.webkit.messageHandlers.apiKeyExtractor.postMessage(match);
                                break;
                            }
                        }
                    }
                });
                
                observer.observe(document.body, {
                    childList: true,
                    subtree: true
                });
                
                // Vérifier immédiatement
                const text = document.body.innerText || document.body.textContent || '';
                const apiKeyPattern = /sk-[a-zA-Z0-9]{20,}/g;
                const matches = text.match(apiKeyPattern);
                if (matches && matches.length > 0) {
                    for (let match of matches) {
                        if (match.startsWith('sk-') && match.length > 30) {
                            window.webkit.messageHandlers.apiKeyExtractor.postMessage(match);
                            break;
                        }
                    }
                }
                
                // Surveiller aussi les inputs et textareas qui pourraient contenir la clé
                const checkInputs = function() {
                    const inputs = document.querySelectorAll('input[type="text"], input[type="password"], textarea');
                    inputs.forEach(input => {
                        if (input.value && input.value.startsWith('sk-') && input.value.length > 30) {
                            window.webkit.messageHandlers.apiKeyExtractor.postMessage(input.value);
                        }
                    });
                };
                
                // Vérifier les inputs périodiquement
                setInterval(checkInputs, 1000);
                checkInputs();
            })();
            """
            
            webView.evaluateJavaScript(script, completionHandler: { result, error in
                if let error = error {
                    print("⚠️ Erreur injection JavaScript: \(error.localizedDescription)")
                }
            })
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Permettre toutes les navigations
        decisionHandler(.allow)
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "apiKeyExtractor",
           let apiKey = message.body as? String,
           apiKey.hasPrefix("sk-") && apiKey.count > 30 {
            onKeyFound(apiKey)
        }
    }
}

#Preview {
    ChatGPTConnectionWebView { key in
        print("Clé trouvée: \(key)")
    }
}
