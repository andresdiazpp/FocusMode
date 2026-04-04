//
//  AllowListsView.swift
//  FocusMode
//

import SwiftUI

struct AllowListsView: View {

    @Bindable var viewModel: ListsViewModel

    @State private var newWeb: String = ""
    @State private var showingAppPicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // --- Apps permitidas ---
                VStack(alignment: .leading, spacing: 0) {

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apps permitidas")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Solo estas apps pueden usarse. Todo lo demás se cierra automáticamente.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 10)

                    ForEach(viewModel.lists.allowApps, id: \.self) { item in
                        HStack {
                            Text(item)
                                .font(.system(size: 12, design: .monospaced))
                            Spacer()
                            if !viewModel.sessionIsActive {
                                Button {
                                    if let i = viewModel.lists.allowApps.firstIndex(of: item) {
                                        viewModel.removeAllowApp(at: IndexSet(integer: i))
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

                    if viewModel.lists.allowApps.isEmpty {
                        VStack(spacing: 4) {
                            Text("Todavía no hay apps permitidas.")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                            Text("Agrega las apps que necesitas para trabajar.")
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 12)
                    }

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

                // --- Webs permitidas ---
                VStack(alignment: .leading, spacing: 0) {

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Webs permitidas")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Escribe solo el dominio. FocusMode permite todas las URLs de ese sitio, incluyendo redirecciones.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 10)

                    ForEach(viewModel.lists.allowWebs, id: \.self) { item in
                        HStack {
                            Text(item)
                                .font(.system(size: 12, design: .monospaced))
                            Spacer()
                            if !viewModel.sessionIsActive {
                                Button {
                                    if let i = viewModel.lists.allowWebs.firstIndex(of: item) {
                                        viewModel.removeAllowWeb(at: IndexSet(integer: i))
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

                    if viewModel.lists.allowWebs.isEmpty {
                        VStack(spacing: 4) {
                            Text("Todavía no hay webs permitidas.")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                            Text("Agrega los sitios que necesitas, como notion.so o github.com.")
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 12)
                    }

                    if !viewModel.sessionIsActive {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Agregar dominio")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 16)

                            HStack(spacing: 8) {
                                TextField("notion.so", text: $newWeb)
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
        .navigationTitle("Allow Mode")
        .sheet(isPresented: $showingAppPicker) {
            AppPickerView { bundleID in
                viewModel.addAllowApp(bundleID)
            }
        }
    }

    private func addWeb() {
        viewModel.addAllowWeb(newWeb)
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
    return AllowListsView(viewModel: vm)
        .frame(width: 360)
}
