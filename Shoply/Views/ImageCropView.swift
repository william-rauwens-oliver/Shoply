//
//  ImageCropView.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI
import UIKit

struct ImageCropView: View {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero
    
    private let cropSize: CGFloat = 300
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let image = image {
                    GeometryReader { geometry in
                        ZStack {
                            // Image avec zoom et pan
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .scaleEffect(scale)
                                .offset(offset)
                                .gesture(
                                    SimultaneousGesture(
                                        MagnificationGesture()
                                            .onChanged { value in
                                                scale = lastScale * value
                                            }
                                            .onEnded { _ in
                                                lastScale = scale
                                                // Limiter le zoom
                                                if scale < 1.0 {
                                                    withAnimation {
                                                        scale = 1.0
                                                        lastScale = 1.0
                                                    }
                                                } else if scale > 3.0 {
                                                    withAnimation {
                                                        scale = 3.0
                                                        lastScale = 3.0
                                                    }
                                                }
                                            },
                                        DragGesture()
                                            .onChanged { value in
                                                offset = CGSize(
                                                    width: lastOffset.width + value.translation.width,
                                                    height: lastOffset.height + value.translation.height
                                                )
                                            }
                                            .onEnded { _ in
                                                lastOffset = offset
                                            }
                                    )
                                )
                            
                            // Overlay avec cercle de recadrage
                            CropOverlay(cropSize: cropSize)
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                }
            }
            .navigationTitle("Recadrer la photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Valider") {
                        cropImage()
                    }
                }
            }
        }
    }
    
    private func cropImage() {
        guard let originalImage = image else { return }
        
        // Calculer le rectangle de recadrage en coordonnées de l'image
        let imageSize = originalImage.size
        let screenSize = UIScreen.main.bounds.size
        
        // Calculer le facteur d'échelle pour convertir les coordonnées de l'écran vers l'image
        let imageAspectRatio = imageSize.width / imageSize.height
        let screenAspectRatio = screenSize.width / screenSize.height
        
        var displaySize: CGSize
        if imageAspectRatio > screenAspectRatio {
            // L'image est plus large que l'écran
            displaySize = CGSize(width: screenSize.width, height: screenSize.width / imageAspectRatio)
        } else {
            // L'image est plus haute que l'écran
            displaySize = CGSize(width: screenSize.height * imageAspectRatio, height: screenSize.height)
        }
        
        let scaleFactor = imageSize.width / displaySize.width
        
        // Centre de l'écran
        let centerX = screenSize.width / 2
        let centerY = screenSize.height / 2
        
        // Position du cercle de recadrage (centré)
        let cropCenterX = centerX + offset.width
        let cropCenterY = centerY + offset.height
        
        // Convertir en coordonnées de l'image
        let imageCropCenterX = (cropCenterX - (screenSize.width - displaySize.width) / 2) * scaleFactor
        let imageCropCenterY = (cropCenterY - (screenSize.height - displaySize.height) / 2) * scaleFactor
        
        // Taille du recadrage en coordonnées de l'image
        let cropSizeInImage = cropSize * scaleFactor * scale
        
        // Rectangle de recadrage
        let cropRect = CGRect(
            x: max(0, imageCropCenterX - cropSizeInImage / 2),
            y: max(0, imageCropCenterY - cropSizeInImage / 2),
            width: min(cropSizeInImage, imageSize.width),
            height: min(cropSizeInImage, imageSize.height)
        )
        
        // Recadrer l'image
        if let cgImage = originalImage.cgImage?.cropping(to: cropRect) {
            image = UIImage(cgImage: cgImage, scale: originalImage.scale, orientation: originalImage.imageOrientation)
        }
        
        dismiss()
    }
}

struct CropOverlay: View {
    let cropSize: CGFloat
    
    var body: some View {
        ZStack {
            // Masque sombre autour
            Color.black.opacity(0.6)
                .mask(
                    Rectangle()
                        .fill(Color.black)
                        .overlay(
                            Circle()
                                .frame(width: cropSize, height: cropSize)
                                .blendMode(.destinationOut)
                        )
                )
            
            // Cercle de recadrage
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: cropSize, height: cropSize)
        }
    }
}

