//
//  HomeView.swift
//  FocusMode
//

import SwiftUI

struct HomeView: View {

    @State private var viewModel = HomeViewModel()
    // El mismo ViewModel de listas se pasa a BlockListsView y AllowListsView
    @State private var listsViewModel = ListsViewModel()

    var body: some View {
        VStack(spacing: 0) {

            // --- Encabezado ---
            HStack {
                Text("FocusMode")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                // Botón para abrir la lista según el modo seleccionado
                listsButton
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)

            Divider()

            // --- Cuerpo ---
            VStack(spacing: 16) {

                ModePickerView(selectedMode: $viewModel.selectedMode)

                if !viewModel.sessionIsActive {
                    TimerPickerView(
                        timerInputMode: $viewModel.timerInputMode,
                        selectedHours: $viewModel.selectedHours,
                        selectedMinutes: $viewModel.selectedMinutes,
                        selectedEndDate: $viewModel.selectedEndDate
                    )
                }

                if viewModel.sessionIsActive {
                    activeSessionBanner
                }
            }
            .padding(24)

            Divider()

            // --- Botón principal ---
            Button {
                viewModel.toggleSession()
                // Sincroniza el estado de sesión con ListsViewModel
                listsViewModel.sessionIsActive = viewModel.sessionIsActive
            } label: {
                Text(viewModel.sessionIsActive ? "Cancelar sesión" : "Iniciar sesión")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(viewModel.sessionIsActive ? Color.red : Color.accentColor)
            .controlSize(.large)
            .padding(24)
        }
        .frame(width: 360)
    }

    // Botón que abre la lista correspondiente al modo actual
    @ViewBuilder
    private var listsButton: some View {
        let isBlock = viewModel.selectedMode == .block

        NavigationLink {
            if isBlock {
                BlockListsView(viewModel: listsViewModel)
            } else {
                AllowListsView(viewModel: listsViewModel)
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "list.bullet")
                Text(isBlock ? "Lista de bloqueo" : "Lista de permitidos")
                    .font(.system(size: 12))
            }
            .foregroundStyle(Color.accentColor)
        }
        .buttonStyle(.plain)
    }

    private var activeSessionBanner: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.selectedMode == .block ? "Block Mode activo" : "Allow Mode activo")
                    .font(.system(size: 13, weight: .semibold))

                Text("Termina \(viewModel.computedEndDate.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.green.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
