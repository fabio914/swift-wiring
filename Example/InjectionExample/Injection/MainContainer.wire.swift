import Foundation

@Container(MainContainer)
@Bind(Dependency, SomeDependency)
@Instance(TestClass)
@Singleton(SomethingElse)
protocol MainContainerProtocol {}
