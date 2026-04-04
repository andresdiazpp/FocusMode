// BlocklistFetcher.swift
// Descarga una blocklist remota, la parsea y la guarda en disco.
//
// Formato de entrada: archivo hosts de StevenBlack.
// Cada línea relevante tiene la forma: "0.0.0.0 dominio.com"
// Las líneas que empiezan con "#" son comentarios — se ignoran.
// El resultado es un array de strings con solo los dominios.

import Foundation

final class BlocklistFetcher {

    // URL de la blocklist de StevenBlack (solo porn)
    static let stevenBlackURL = URL(string: "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/porn/hosts")!

    // Carpeta base de la app en Application Support
    private static let appSupport: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = base.appendingPathComponent("FocusMode")
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }()

    // Archivo donde se guarda la lista ya procesada (un dominio por línea)
    static let cacheURL = appSupport.appendingPathComponent("blocklist_stevenblack.txt")

    // Descarga la lista, la parsea y la guarda en disco.
    // Devuelve los dominios extraídos.
    // Lanza error si la descarga o la escritura falla.
    @discardableResult
    func fetchAndPersist() async throws -> [String] {
        // 1. Descarga el archivo hosts crudo
        let (data, _) = try await URLSession.shared.data(from: Self.stevenBlackURL)

        // 2. Convierte los bytes a texto
        guard let raw = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }

        // 3. Parsea: extrae dominios de líneas "0.0.0.0 dominio.com"
        let domains = Self.parse(raw)

        // 4. Guarda un dominio por línea en disco
        let content = domains.joined(separator: "\n")
        try content.write(to: Self.cacheURL, atomically: true, encoding: .utf8)

        return domains
    }

    // Lee la lista guardada en disco.
    // Devuelve array vacío si no existe el archivo todavía.
    func loadCached() -> [String] {
        guard let content = try? String(contentsOf: Self.cacheURL, encoding: .utf8) else {
            return []
        }
        // Parte por saltos de línea y filtra líneas vacías
        return content.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
    }

    // MARK: - Parsing

    // Recibe el texto crudo del archivo hosts y devuelve solo los dominios.
    // Regla: línea válida empieza con "0.0.0.0 " seguido del dominio.
    // Se descartan: comentarios (#), la línea "0.0.0.0 0.0.0.0" y dominios vacíos.
    static func parse(_ raw: String) -> [String] {
        var domains: [String] = []

        for line in raw.split(separator: "\n", omittingEmptySubsequences: true) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Ignorar comentarios y líneas que no empiezan con "0.0.0.0 "
            guard trimmed.hasPrefix("0.0.0.0 ") else { continue }

            // El dominio es todo lo que viene después de "0.0.0.0 "
            // Se descarta cualquier comentario inline (texto después de #)
            let afterPrefix = trimmed.dropFirst("0.0.0.0 ".count)
            let domainPart  = afterPrefix.split(separator: "#").first ?? afterPrefix[...]
            let domain      = domainPart.trimmingCharacters(in: .whitespaces)

            // Descartar "0.0.0.0" a sí mismo y cadenas vacías
            guard !domain.isEmpty, domain != "0.0.0.0" else { continue }

            domains.append(domain)
        }

        return domains
    }
}
