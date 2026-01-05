import SwiftUI

@MainActor
enum LoginState {
    case ready
    case loading
    case failed
}

protocol LoginViewModelProtocol: ObservableObject {
    @MainActor
    var state: LoginState { get }

    @MainActor
    func login(userName: String)

    @MainActor
    func retry()

    @MainActor
    func onDisappear()
}

struct LoginScreen<ViewModel: LoginViewModelProtocol>: View {

    @StateObject var viewModel: ViewModel
    @State var usernameText: String = ""

    init(viewModel: ViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    static func makeViewController(viewModel: ViewModel) -> UIViewController {
        UIHostingController(rootView: LoginScreen(viewModel: viewModel))
    }

    @ViewBuilder
    var login: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)

            TextField(text: $usernameText) {
                Text("Enter User Name")
            }
            .padding()

            Button(action: { viewModel.login(userName: usernameText) }) {
                Text("Login")
            }
        }
    }

    @ViewBuilder
    var failed: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)

            Text("Error")
                .font(.headline)

            Text("Login failed, please try again.")

            Button(action: viewModel.retry) {
                Text("Retry")
            }
        }
    }

    @ViewBuilder
    var content: some View {
        switch viewModel.state {
        case .ready:
            login
        case .loading:
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
        case .failed:
            failed
        }
    }

    var backButtonHidden: Bool {
        switch viewModel.state {
        case .ready, .failed:
            false
        case .loading:
            true
        }
    }

    var body: some View {
        content
            .navigationTitle("Login")
            .navigationBarBackButtonHidden(backButtonHidden)
            .onDisappear(perform: viewModel.onDisappear)
    }
}
