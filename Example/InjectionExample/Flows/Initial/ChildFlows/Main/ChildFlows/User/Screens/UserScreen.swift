import SwiftUI

protocol UserViewModelProtocol: ObservableObject {
    var userName: String { get }
}

struct UserScreen<ViewModel: UserViewModelProtocol>: View {

    @StateObject var viewModel: ViewModel

    init(viewModel: ViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    static func makeViewController(viewModel: ViewModel) -> UIViewController {
        UIHostingController(rootView: UserScreen(viewModel: viewModel))
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.fill.checkmark")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)

            Text("User: \(viewModel.userName)")
        }
        .navigationTitle("User")
    }
}
