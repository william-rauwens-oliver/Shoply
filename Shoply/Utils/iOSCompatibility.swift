//
//  iOSCompatibility.swift
//  Shoply
//
//  Utilitaires de compatibilité iOS pour gérer les différences entre iOS 16.6 et iOS 17.0+
//

import SwiftUI
import PhotosUI

// MARK: - Modifier pour onChange avec oldValue et newValue

struct OnChangeModifier<Value: Equatable>: ViewModifier {
    let value: Value
    let action: (Value, Value) -> Void
    @State private var previousValue: Value?
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                previousValue = value
            }
            .onChange(of: value) { newValue in
                if let oldValue = previousValue {
                    action(oldValue, newValue)
                }
                previousValue = newValue
            }
    }
}

extension View {
    /// Compatibilité iOS 16.6+ pour onChange avec oldValue et newValue
    func onChange<Value: Equatable>(of value: Value, perform action: @escaping (Value, Value) -> Void) -> some View {
        self.modifier(OnChangeModifier(value: value, action: action))
    }
}

// MARK: - Modifier pour PhotosPickerItem onChange

struct OnChangePhotosPickerModifier: ViewModifier {
    let selectedPhoto: PhotosPickerItem?
    @Binding var selectedImage: UIImage?
    @State private var previousPhoto: PhotosPickerItem?
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                previousPhoto = selectedPhoto
            }
            .onChange(of: selectedPhoto) { newValue in
                Task {
                    if let newValue = newValue {
                        if let data = try? await newValue.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await MainActor.run {
                                selectedImage = image
                            }
                        }
                    } else {
                        selectedImage = nil
                    }
                }
                previousPhoto = newValue
            }
    }
}

extension View {
    /// Compatibilité iOS 16.6+ pour onChange de PhotosPickerItem
    func onChangePhotosPicker(selectedPhoto: PhotosPickerItem?, selectedImage: Binding<UIImage?>) -> some View {
        self.modifier(OnChangePhotosPickerModifier(selectedPhoto: selectedPhoto, selectedImage: selectedImage))
    }
}

// MARK: - Modifier pour symbolEffect (déjà défini dans FloatingChatButton.swift)
// Utiliser SymbolEffectModifier de FloatingChatButton.swift

