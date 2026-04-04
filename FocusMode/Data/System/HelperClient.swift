// HelperClient.swift
// La app principal usa esto para hablar con el PrivilegedHelper via XPC.
//
// HelperClient abre la conexión, manda el mensaje, y devuelve el resultado.
// Toda la comunicación es async — la app no se congela esperando al helper.

import Foundation
import ServiceManagement  // para SMJobBless (instalar el helper)

final class HelperClient {

    // Conexión XPC al helper — se crea al primer uso
    private var connection: NSXPCConnection?

    // MARK: - Instalación del helper

    // Instala el helper como daemon privilegiado via SMJobBless.
    // macOS muestra un diálogo pidiendo la contraseña del administrador.
    // Funciona con Apple ID gratis (Personal Team) — no requiere $99/año.
    func installHelperIfNeeded() throws {
        // Primero verificamos si el helper ya está instalado y actualizado
        let helperURL = URL(fileURLWithPath: "/Library/PrivilegedHelperTools/com.andresdiazpp.focusmode.helper")
        if FileManager.default.fileExists(atPath: helperURL.path) {
            // Ya instalado — verificar que la versión coincide con la del bundle
            // (por ahora asumimos que está actualizado)
            return
        }

        // Crear la autorización con el derecho de instalar helpers privilegiados
        var authRef: AuthorizationRef?
        var authItem = AuthorizationItem(
            name: kSMRightBlessPrivilegedHelper,
            valueLength: 0,
            value: nil,
            flags: 0
        )
        var authRights = AuthorizationRights(count: 1, items: &authItem)
        let authFlags: AuthorizationFlags = [.interactionAllowed, .extendRights, .preAuthorize]

        let authStatus = AuthorizationCreate(&authRights, nil, authFlags, &authRef)
        guard authStatus == errAuthorizationSuccess else {
            throw HelperClientError.authorizationFailed
        }
        defer { if let ref = authRef { AuthorizationFree(ref, []) } }

        // SMJobBless copia el helper a /Library/PrivilegedHelperTools/ y lo registra en launchd
        var cfError: Unmanaged<CFError>?
        let success = SMJobBless(
            kSMDomainSystemLaunchd,
            "com.andresdiazpp.focusmode.helper" as CFString,
            authRef,
            &cfError
        )

        if !success {
            if let error = cfError?.takeRetainedValue() {
                throw error
            }
            throw HelperClientError.installFailed
        }
    }

    // MARK: - Conexión

    // Devuelve la conexión activa o crea una nueva
    private func getConnection() -> NSXPCConnection {
        if let existing = connection {
            return existing
        }

        let conn = NSXPCConnection(machServiceName: helperMachServiceName, options: .privileged)
        conn.remoteObjectInterface = NSXPCInterface(with: HelperProtocol.self)

        // Si la conexión se cae, la limpiamos para reconectar en el próximo uso
        conn.invalidationHandler = { [weak self] in
            self?.connection = nil
        }
        conn.resume()
        connection = conn
        return conn
    }

    // Devuelve el proxy del helper — el objeto con el que mandamos mensajes
    private func helper() throws -> HelperProtocol {
        let conn = getConnection()
        guard let proxy = conn.remoteObjectProxyWithErrorHandler({ [weak self] error in
            print("[HelperClient] Error XPC: \(error)")
            self?.connection = nil
        }) as? HelperProtocol else {
            throw HelperClientError.connectionFailed
        }
        return proxy
    }

    // MARK: - Operaciones

    func ping() async throws -> String {
        return try await withCheckedThrowingContinuation { cont in
            do {
                try helper().ping { message in
                    cont.resume(returning: message)
                }
            } catch {
                cont.resume(throwing: error)
            }
        }
    }

    func applyHostsBlock(domains: [String]) async throws {
        return try await withCheckedThrowingContinuation { cont in
            do {
                try helper().applyHostsBlock(domains: domains) { error in
                    if let error { cont.resume(throwing: error) }
                    else { cont.resume() }
                }
            } catch {
                cont.resume(throwing: error)
            }
        }
    }

    func removeHostsBlock() async throws {
        return try await withCheckedThrowingContinuation { cont in
            do {
                try helper().removeHostsBlock { error in
                    if let error { cont.resume(throwing: error) }
                    else { cont.resume() }
                }
            } catch {
                cont.resume(throwing: error)
            }
        }
    }

    func applyCleanBrowsingDNS() async throws {
        return try await withCheckedThrowingContinuation { cont in
            do {
                try helper().applyCleanBrowsingDNS { error in
                    if let error { cont.resume(throwing: error) }
                    else { cont.resume() }
                }
            } catch {
                cont.resume(throwing: error)
            }
        }
    }

    func restoreOriginalDNS() async throws {
        return try await withCheckedThrowingContinuation { cont in
            do {
                try helper().restoreOriginalDNS { error in
                    if let error { cont.resume(throwing: error) }
                    else { cont.resume() }
                }
            } catch {
                cont.resume(throwing: error)
            }
        }
    }
}

// Errores propios del cliente XPC
enum HelperClientError: Error {
    case connectionFailed       // no se pudo conectar al helper
    case authorizationFailed    // no se pudo crear la autorización
    case installFailed          // SMJobBless falló sin error específico
}
