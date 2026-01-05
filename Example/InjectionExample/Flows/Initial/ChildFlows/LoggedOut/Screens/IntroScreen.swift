import SwiftUI

protocol IntroViewModelProtocol: ObservableObject {
    @MainActor
    func navigateToLogin()
}

struct IntroScreen<ViewModel: IntroViewModelProtocol>: View {

    @StateObject var viewModel: ViewModel

    init(viewModel: ViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    static func makeViewController(viewModel: ViewModel) -> UIViewController {
        UIHostingController(rootView: IntroScreen(viewModel: viewModel))
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "app.connected.to.app.below.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)

            Text("Swift Wiring Demo")
                .font(.headline)

            Button(action: viewModel.navigateToLogin) {
                Text("Login")
            }
        }
        .navigationTitle("Intro")
    }
}
