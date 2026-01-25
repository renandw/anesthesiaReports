//
//  JSONDecoder.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 25/01/26.
//

import Foundation

extension JSONDecoder {

    /// Decoder padrão para respostas do backend
    /// - Datas em ISO-8601
    /// - Alinhado com API REST
    static let backend: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
