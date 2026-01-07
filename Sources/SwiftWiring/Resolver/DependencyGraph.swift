import Foundation

final class DependencyGraph<T> where T: Hashable & Sendable {

    enum DependencyGraphError: Error {
        case cycleDetected([T])
    }

    private struct NodeWithIterator {
        let node: T
        var iterator: IndexingIterator<[T]>

        init(node: T, neighbours: Set<T>?) {
            self.node = node
            self.iterator = Array(neighbours ?? []).makeIterator()
        }
    }

    private(set) var graph: [T: Set<T>]

    init() {
        graph = [:]
    }

    @discardableResult
    func add(_ from: T, to target: T) -> Self {
        graph[from, default: []].insert(target)
        return self
    }

    func verifyCycle() -> Result<Void, DependencyGraphError> {
        var visited = Set<T>()
        var visiting = Set<T>()
        var parent: [T: T] = [:] // to: from

        for startNode in graph.keys where !visiting.contains(startNode) {
            var stack: [NodeWithIterator] = []

            visited.insert(startNode)
            visiting.insert(startNode)
            stack.append(.init(node: startNode, neighbours: graph[startNode]))

            while let top = stack.popLast() {
                var mutatingTop = top

                if let neighbour = mutatingTop.iterator.next() {
                    stack.append(mutatingTop)

                    if visiting.contains(neighbour) {
                        return .failure(
                            DependencyGraphError.cycleDetected(
                                generatePath(parent: parent, node: top.node, neighbour: neighbour)
                            )
                        )
                    }

                    if !visited.contains(neighbour) {
                        visited.insert(neighbour)
                        visiting.insert(neighbour)
                        parent[neighbour] = top.node
                        stack.append(.init(node: neighbour, neighbours: graph[neighbour]))
                    }
                } else {
                    visiting.remove(top.node)
                }
            }
        }

        return .success(())
    }

    private func generatePath(parent: [T: T], node: T, neighbour: T) -> [T] {
        var cycle = [neighbour]
        var current = node

        while current != neighbour {
            cycle.append(current)

            guard let previous = parent[current] else { break }
            current = previous
        }

        cycle.append(neighbour)
        cycle.reverse()
        return cycle
    }
}
