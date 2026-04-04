//
//  ListsViewModel.swift
//  FocusMode
//

import SwiftUI

// ListsViewModel maneja las 4 listas del usuario.
// Las carga desde disco al arrancar y las guarda cada vez que cambian.
@Observable
final class ListsViewModel {

    // Las 4 listas
    var lists: FocusLists = FocusLists()

    // Si hay sesión activa, el usuario no puede editar las listas
    var sessionIsActive: Bool = false

    private let store = FocusStore()

    init() {
        lists = store.loadLists()
    }

    // Persiste las listas en disco después de cada cambio
    private func save() {
        try? store.saveLists(lists)
    }

    // MARK: - Block Apps

    func addBlockApp(_ bundleID: String) {
        let trimmed = bundleID.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !lists.blockApps.contains(trimmed) else { return }
        lists.blockApps.append(trimmed)
        save()
    }

    func removeBlockApp(at offsets: IndexSet) {
        lists.blockApps.remove(atOffsets: offsets)
        save()
    }

    // MARK: - Block Webs

    func addBlockWeb(_ domain: String) {
        let trimmed = domain.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty, !lists.blockWebs.contains(trimmed) else { return }
        lists.blockWebs.append(trimmed)
        save()
    }

    func removeBlockWeb(at offsets: IndexSet) {
        lists.blockWebs.remove(atOffsets: offsets)
        save()
    }

    // MARK: - Allow Apps

    func addAllowApp(_ bundleID: String) {
        let trimmed = bundleID.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !lists.allowApps.contains(trimmed) else { return }
        lists.allowApps.append(trimmed)
        save()
    }

    func removeAllowApp(at offsets: IndexSet) {
        lists.allowApps.remove(atOffsets: offsets)
        save()
    }

    // MARK: - Allow Webs

    func addAllowWeb(_ domain: String) {
        let trimmed = domain.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty, !lists.allowWebs.contains(trimmed) else { return }
        lists.allowWebs.append(trimmed)
        save()
    }

    func removeAllowWeb(at offsets: IndexSet) {
        lists.allowWebs.remove(atOffsets: offsets)
        save()
    }
}
