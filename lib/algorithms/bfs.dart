import '../models/graph.dart';
import 'dart:collection';

List<String> bfs(Graph graph, String start, String goal) {
  Queue<List<String>> queue = Queue();
  Set<String> visited = {};

  queue.add([start]);
  visited.add(start);

  while (queue.isNotEmpty) {
    List<String> path = queue.removeFirst();
    String current = path.last;

    if (current == goal) {
      return path;
    }

    for (String neighbor in graph.cities[current]!.keys) {
      if (!visited.contains(neighbor)) {
        visited.add(neighbor);
        List<String> newPath = List.from(path);
        newPath.add(neighbor);
        queue.add(newPath);
      }
    }
  }

  return [];
}
