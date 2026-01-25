//
//  APIErrorResponse.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 24/01/26.
//


import Foundation

struct APIErrorResponse: Codable {
    let error: APIErrorDetail
}

struct APIErrorDetail: Codable {
    let code: String
    let message: String
}