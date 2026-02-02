//
//  AuthError.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 26/01/26.
//


import Foundation

enum AuthError: Error {
    case network
    case invalidCredentials
    case userNotRegistered
    case passwordMismatch
    case userExists
    case sessionExpired
    case userInactive
    case userDeleted
    case invalidPayload
    case patientAccessRequired
    case surgeryPermissionRequired
    case surgeryEditForbidden
    case surgeryFinancialForbidden
    case surgeryShareForbidden
    case surgerySharePrivilegedForbidden
    case surgeryShareListForbidden
    case surgeryRevokeForbidden
    case unauthorized
    case serverError
    case unknown

    static func from(statusCode: Int, data: Data) -> AuthError {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let error = json["error"] as? [String: Any],
            let code = error["code"] as? String
        else {
            return .unknown
        }

        let message = (error["message"] as? String)?.lowercased() ?? ""

        switch code {
        case "INVALID_CREDENTIALS":
            if message.contains("nao ha cadastro") || message.contains("não há cadastro") {
                return .userNotRegistered
            }
            if message.contains("senha nao confere") || message.contains("senha não confere") {
                return .passwordMismatch
            }
            return .invalidCredentials
        case "INVALID_TOKEN":
            return .sessionExpired
        case "TOKEN_EXPIRED":
            return .sessionExpired
        case "USER_INACTIVE":
            return .userInactive
        case "USER_DELETED":
            return .userDeleted
        case "INVALID_PAYLOAD":
            return .invalidPayload
        case "PATIENT_ACCESS_REQUIRED":
            return .patientAccessRequired
        case "SURGERY_PERMISSION_REQUIRED":
            return .surgeryPermissionRequired
        case "SURGERY_EDIT_FORBIDDEN":
            return .surgeryEditForbidden
        case "SURGERY_FINANCIAL_FORBIDDEN":
            return .surgeryFinancialForbidden
        case "SURGERY_SHARE_FORBIDDEN":
            return .surgeryShareForbidden
        case "SURGERY_SHARE_PRIVILEGED_FORBIDDEN":
            return .surgerySharePrivilegedForbidden
        case "SURGERY_SHARE_LIST_FORBIDDEN":
            return .surgeryShareListForbidden
        case "SURGERY_REVOKE_FORBIDDEN":
            return .surgeryRevokeForbidden
        case "USER_EXISTS":
            return .userExists
        case "UNAUTHORIZED":
            return .unauthorized
        case "INTERNAL_ERROR":
            return .serverError
        default:
            return .unknown
        }
    }
}

extension AuthError {
    var isRefreshable: Bool {
        switch self {
        case .sessionExpired:
            return true
        default:
            return false
        }
    }

    var isFatalSessionError: Bool {
        switch self {
        case .sessionExpired, .unauthorized, .userInactive, .userDeleted:
            return true
        default:
            return false
        }
    }

    var userMessage: String {
        switch self {
        case .userNotRegistered:
            return "Usuário não cadastrado"
        case .passwordMismatch:
            return "Senha não confere"
        case .userExists:
            return "Esse usuário já está cadastrado"
        case .invalidCredentials:
            return "Credenciais inválidas"
        case .invalidPayload:
            return "Dados inválidos"
        case .patientAccessRequired:
            return "Sem acesso ao paciente"
        case .surgeryPermissionRequired:
            return "Sem permissão na cirurgia"
        case .surgeryEditForbidden:
            return "Não pode editar cirurgia"
        case .surgeryFinancialForbidden:
            return "Não pode editar financeiro da cirurgia"
        case .surgeryShareForbidden:
            return "Não pode compartilhar cirurgia"
        case .surgerySharePrivilegedForbidden:
            return "Não pode conceder permissão privilegiada"
        case .surgeryShareListForbidden:
            return "Não pode ver compartilhamentos da cirurgia"
        case .surgeryRevokeForbidden:
            return "Não pode revogar acessos da cirurgia"
        case .sessionExpired:
            return "Sessão expirada"
        case .userInactive:
            return "Usuário inativo"
        case .userDeleted:
            return "Usuário removido"
        case .unauthorized:
            return "Não autorizado"
        case .serverError:
            return "Erro no servidor"
        case .network:
            return "Erro de rede"
        case .unknown:
            return "Erro inesperado"
        }
    }
}
