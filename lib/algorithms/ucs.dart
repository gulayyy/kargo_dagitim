import '../models/graph.dart';
import 'package:collection/collection.dart';

List<String> ucs(Graph graph, String start, String goal) {
  // Öncelikli kuyruk (maliyet, yol)
  final queue = PriorityQueue<MapEntry<int, List<String>>>(
    (a, b) => a.key.compareTo(b.key),
  );
  final visited = <String>{};

  queue.add(MapEntry(0, [start]));

  while (queue.isNotEmpty) {
    final entry = queue.removeFirst();
    final cost = entry.key;
    final path = entry.value;
    final current = path.last;

    if (current == goal) {
      return path;
    }

    if (visited.contains(current)) {
      continue;
    }

    visited.add(current);

    for (final neighbor in graph.cities[current]!.keys) {
      if (!visited.contains(neighbor)) {
        final newCost = cost + graph.cities[current]![neighbor]!;
        final newPath = List<String>.from(path)..add(neighbor);
        queue.add(MapEntry(newCost, newPath));
      }
    }
  }

  return [];
}

int _pathCost(Graph graph, List<String> path) {
  int total = 0;
  for (int i = 0; i < path.length - 1; i++) {
    total += graph.cities[path[i]]?[path[i + 1]] ?? 0;
  }
  return total;
}
