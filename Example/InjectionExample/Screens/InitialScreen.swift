import SwiftUI

protocol InitialViewModelProtocol: ObservableObject {

}

struct InitialScreen<ViewModel: InitialViewModelProtocol>: View {

    @StateObject var viewModel: ViewModel

    init(viewModel: ViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    static func makeViewController(viewModel: ViewModel) -> UIViewController {
        UIHostingController(rootView: InitialScreen(viewModel: viewModel))
    }

    var body: some View {
        Color.green
    }
}
