//
//  AsaEnum.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 05/02/26.
//
import SwiftUI

public enum ASAClassification: String, Codable, CaseIterable {
    case I
    case II
    case III
    case IV
    case V
    case VI
    case Ie
    case IIe
    case IIIe
    case IVe
    case Ve
    
    var displayName: String {
        switch self {
        case .I: return "ASA I"
        case .II: return "ASA II"
        case .III: return "ASA III"
        case .IV: return "ASA IV"
        case .V: return "ASA V"
        case .VI: return "ASA VI"
        case .Ie: return "ASA Ie"
        case .IIe: return "ASA IIe"
        case .IIIe: return "ASA IIIe"
        case .IVe: return "ASA IVe"
        case .Ve: return "ASA Ve"
        
        }
    }

    var tintColor: Color {
        switch self {
        case .I: return Color.green
        case .II: return Color.yellow
        case .III: return Color.orange
        case .IV: return Color.red
        case .V: return Color.purple
        case .VI: return Color.gray
        case .Ie: return Color.green.opacity(0.7)
        case .IIe: return Color.yellow.opacity(0.7)
        case .IIIe: return Color.orange.opacity(0.7)
        case .IVe: return Color.red.opacity(0.7)
        case .Ve: return Color.purple.opacity(0.7)
        }
    }
    @ViewBuilder
    var badgeView: some View {
        Text(displayName)
            .foregroundStyle(tintColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tintColor.opacity(0.15))
            .clipShape(Capsule())
    }
}
