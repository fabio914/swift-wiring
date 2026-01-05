import SwiftUI

protocol SettingsViewModelProtocol: ObservableObject {
    var sessionTime: String { get }

    @MainActor
    func logOut()
}

struct SettingsScreen<ViewModel: SettingsViewModelProtocol>: View {

    @StateObject var viewModel: ViewModel

    init(viewModel: ViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    static func makeViewController(viewModel: ViewModel) -> UIViewController {
        UIHostingController(rootView: SettingsScreen(viewModel: viewModel))
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Session start time: \(viewModel.sessionTime)")

            Button(action: viewModel.logOut) {
                Text("Log out")
            }
        }
        .navigationTitle("Settings")
    }
}
