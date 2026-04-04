// HelperXPC.swift
// El helper que corre como root.
//
// Este proceso vive separado de la app principal.
// La app le manda mensajes via XPC y el helper los ejecuta con privilegios.
// Cada función aquí puede hacer cosas que la app normal no puede:
// escribir /etc/hosts, cambiar DNS, aplicar reglas de firewall.

import Foundation

// HelperXPC implementa HelperProtocol — cada función del protocolo vive aquí
final class HelperXPC: NSObject, HelperProtocol {

    // MARK: - Ping (prueba de conexión)

    func ping(reply: @escaping (String) -> Void) {
        reply("PrivilegedHelper activo")
    }

    // MARK: - /etc/hosts

    // Marca que FocusMode usa para saber qué líneas escribió
    private let hostsStartMark = "# FocusMode:START"
    private let hostsEndMark   = "# FocusMode:END"
    private let hostsPath      = "/etc/hosts"

    func applyHostsBlock(domains: [String], reply: @escaping (Error?) -> Void) {
        do {
            var content = try String(contentsOfFile: hostsPath, encoding: .utf8)

            // Si ya hay un bloque de FocusMode, lo borramos primero
            content = removeExistingBlock(from: content)

            // Construimos el bloque nuevo
            // Cada dominio se redirige a 0.0.0.0 — el navegador no puede llegar ahí
            let lines = domains.map { "0.0.0.0 \($0)" }.joined(separator: "\n")
            let block = "\n\(hostsStartMark)\n\(lines)\n\(hostsEndMark)\n"

            content += block
            try content.write(toFile: hostsPath, atomically: true, encoding: .utf8)
            reply(nil)
        } catch {
            reply(error)
        }
    }

    func removeHostsBlock(reply: @escaping (Error?) -> Void) {
        do {
            var content = try String(contentsOfFile: hostsPath, encoding: .utf8)
            content = removeExistingBlock(from: content)
            try content.write(toFile: hostsPath, atomically: true, encoding: .utf8)
            reply(nil)
        } catch {
            reply(error)
        }
    }

    // Borra todo lo que está entre las marcas de FocusMode
    private func removeExistingBlock(from content: String) -> String {
        var result = content
        while let start = result.range(of: "\n\(hostsStartMark)"),
              let end   = result.range(of: "\(hostsEndMark)\n", range: start.upperBound..<result.endIndex) {
            result.removeSubrange(start.lowerBound..<end.upperBound)
        }
        return result
    }

    // MARK: - DNS

    // Archivo donde guardamos el DNS original para poder restaurarlo
    private let savedDNSPath = "/Library/Application Support/FocusMode/original_dns.json"

    func applyCleanBrowsingDNS(reply: @escaping (Error?) -> Void) {
        do {
            // Primero guardamos el DNS actual
            try saveCurrentDNS()

            // CleanBrowsing Adult Filter — bloquea adultos y VPNs
            let primaryDNS   = "185.228.168.10"
            let secondaryDNS = "185.228.169.11"

            // Aplicamos el DNS en todas las interfaces de red activas
            let interfaces = getActiveNetworkInterfaces()
            for iface in interfaces {
                try runNetworkSetup(["-setdnsservers", iface, primaryDNS, secondaryDNS])
            }
            reply(nil)
        } catch {
            reply(error)
        }
    }

    func restoreOriginalDNS(reply: @escaping (Error?) -> Void) {
        do {
            // Leemos el DNS que guardamos antes
            let data = try Data(contentsOf: URL(fileURLWithPath: savedDNSPath))
            let saved = try JSONDecoder().decode([String: [String]].self, from: data)

            // Restauramos cada interfaz con su DNS original
            for (iface, servers) in saved {
                if servers.isEmpty {
                    // Si no tenía DNS configurado, lo dejamos en "Empty"
                    try runNetworkSetup(["-setdnsservers", iface, "Empty"])
                } else {
                    try runNetworkSetup(["-setdnsservers", iface] + servers)
                }
            }
            reply(nil)
        } catch {
            reply(error)
        }
    }

    // Lee el DNS actual de cada interfaz y lo guarda en un archivo JSON
    private func saveCurrentDNS() throws {
        let interfaces = getActiveNetworkInterfaces()
        var dns: [String: [String]] = [:]

        for iface in interfaces {
            // networksetup -getdnsservers devuelve los servidores actuales
            let output = try runNetworkSetupOutput(["-getdnsservers", iface])
            // Si dice "There aren't any DNS Servers..." significa que no hay configurado
            let servers = output
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && !$0.hasPrefix("There aren") }
            dns[iface] = servers
        }

        let folder = URL(fileURLWithPath: savedDNSPath).deletingLastPathComponent()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(dns)
        try data.write(to: URL(fileURLWithPath: savedDNSPath))
    }

    // Lista de interfaces de red activas (Wi-Fi, Ethernet, etc.)
    private func getActiveNetworkInterfaces() -> [String] {
        let output = (try? runNetworkSetupOutput(["-listallnetworkservices"])) ?? ""
        return output
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty && !$0.hasPrefix("An asterisk") && !$0.hasPrefix("*") }
            .dropFirst() // la primera línea es el encabezado
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    // Ejecuta networksetup y descarta el output
    @discardableResult
    private func runNetworkSetup(_ args: [String]) throws -> String {
        return try runNetworkSetupOutput(args)
    }

    // Ejecuta networksetup y devuelve el output como String
    private func runNetworkSetupOutput(_ args: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        process.arguments = args

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
