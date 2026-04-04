//
//  BlockListsView.swift
//  FocusMode
//

import SwiftUI

struct BlockListsView: View {

    @Bindable var viewModel: ListsViewModel

    @State private var newWeb: String = ""
    @State private var showingAppPicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // --- Apps bloqueadas ---
                VStack(alignment: .leading, spacing: 0) {

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apps bloqueadas")
                            .font(.system(size: 13, weight: .semibold))
                        Text("La app se cierra automáticamente mientras la sesión está activa.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 10)

                    // Lista de apps agregadas
                    ForEach(viewModel.lists.blockApps, id: \.self) { item in
                        HStack {
                            Text(item)
                                .font(.system(size: 12, design: .monospaced))
                            Spacer()
                            if !viewModel.sessionIsActive {
                                Button {
                                    if let i = viewModel.lists.blockApps.firstIndex(of: item) {
                                        viewModel.removeBlockApp(at: IndexSet(integer: i))
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(Color.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        Divider().padding(.leading, 16)
                    }

                    // Botón de agregar app — visible y claro
                    if !viewModel.sessionIsActive {
                        Button {
                            showingAppPicker = true
                        } label: {
                            Label("Agregar app", systemImage: "plus.circle.fill")
                                .font(.system(size: 13, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    } else {
                        lockedLabel
                    }
                }

                Divider()

                // --- Webs bloqueadas ---
                VStack(alignment: .leading, spacing: 0) {

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Webs bloqueadas")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Escribe solo el dominio. FocusMode bloquea todas las URLs de ese sitio, incluyendo redirecciones.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 10)

                    // Lista de webs agregadas
                    ForEach(viewModel.lists.blockWebs, id: \.self) { item in
                        HStack {
                            Text(item)
                                .font(.system(size: 12, design: .monospaced))
                            Spacer()
                            if !viewModel.sessionIsActive {
                                Button {
                                    if let i = viewModel.lists.blockWebs.firstIndex(of: item) {
                                        viewModel.removeBlockWeb(at: IndexSet(integer: i))
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(Color.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        Divider().padding(.leading, 16)
                    }

                    // Campo de agregar web — con etiqueta explícita
                    if !viewModel.sessionIsActive {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Agregar dominio")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 16)

                            HStack(spacing: 8) {
                                TextField("instagram.com", text: $newWeb)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 12, design: .monospaced))
                                    .onSubmit { addWeb() }

                                Button("Agregar") { addWeb() }
                                    .disabled(newWeb.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.vertical, 10)
                    } else {
                        lockedLabel
                    }
                }
            }
        }
        .navigationTitle("Block Mode")
        .sheet(isPresented: $showingAppPicker) {
            AppPickerView { bundleID in
                viewModel.addBlockApp(bundleID)
            }
        }
    }

    private func addWeb() {
        viewModel.addBlockWeb(newWeb)
        newWeb = ""
    }

    private var lockedLabel: some View {
        Label("Las listas no se pueden editar durante una sesión activa.", systemImage: "lock.fill")
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
    }
}

#Preview {
    let vm = ListsViewModel()
    vm.lists.blockApps = ["com.instagram.instagram"]
    vm.lists.blockWebs = ["reddit.com"]
    return BlockListsView(viewModel: vm)
        .frame(width: 360)
}
