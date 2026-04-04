//
//  AppPickerView.swift
//  FocusMode
//

import SwiftUI
import AppKit

// Representa una app instalada en el sistema
struct InstalledApp: Identifiable {
    let id = UUID()
    let name: String
    let bundleID: String
    let icon: NSImage
}

// AppPickerView muestra todas las apps instaladas en /Applications.
// El usuario elige una y se agrega su bundle ID a la lista automáticamente.
struct AppPickerView: View {

    // Qué hacer cuando el usuario elige una app
    let onSelect: (String) -> Void
    // Cerrar el sheet
    @Environment(\.dismiss) private var dismiss

    @State private var apps: [InstalledApp] = []
    @State private var search: String = ""

    // Apps filtradas por lo que el usuario escribe en el buscador
    private var filtered: [InstalledApp] {
        if search.isEmpty { return apps }
        return apps.filter {
            $0.name.localizedCaseInsensitiveContains(search) ||
            $0.bundleID.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        VStack(spacing: 0) {

            // --- Encabezado ---
            HStack {
                Text("Elegir app")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Button("Cancelar") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
            }
            .padding(16)

            Divider()

            // --- Buscador ---
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Buscar app...", text: $search)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // --- Lista de apps ---
            if apps.isEmpty {
                ProgressView("Cargando apps...")
                    .padding(40)
            } else if filtered.isEmpty {
                Text("Sin resultados")
                    .foregroundStyle(.secondary)
                    .padding(40)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filtered) { app in
                            Button {
                                onSelect(app.bundleID)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    // Ícono de la app
                                    Image(nsImage: app.icon)
                                        .resizable()
                                        .frame(width: 28, height: 28)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(app.name)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(Color.primary)
                                        // Bundle ID — lo que se guarda en la lista
                                        Text(app.bundleID)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .background(Color(NSColor.controlBackgroundColor).opacity(0.001)) // hace toda la fila clickeable

                            Divider().padding(.leading, 56)
                        }
                    }
                }
            }
        }
        .frame(width: 360, height: 480)
        .task {
            apps = loadInstalledApps()
        }
    }

    // Lee todas las apps de /Applications y extrae nombre, bundle ID e ícono
    private func loadInstalledApps() -> [InstalledApp] {
        let fm = FileManager.default
        let appDirs = ["/Applications", "/Applications/Utilities"]

        var result: [InstalledApp] = []

        for dir in appDirs {
            let url = URL(fileURLWithPath: dir)
            guard let contents = try? fm.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: nil
            ) else { continue }

            for appURL in contents where appURL.pathExtension == "app" {
                guard
                    let bundle = Bundle(url: appURL),
                    let bundleID = bundle.bundleIdentifier,
                    let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                        ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
                else { continue }

                let icon = NSWorkspace.shared.icon(forFile: appURL.path)
                result.append(InstalledApp(name: name, bundleID: bundleID, icon: icon))
            }
        }

        // Ordena alfabéticamente por nombre
        return result.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }
}

#Preview {
    AppPickerView(onSelect: { print($0) })
}
