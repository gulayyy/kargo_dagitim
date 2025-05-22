import '../models/graph.dart';

List<String> dfs(Graph graph, String start, String goal) {
  Set<String> visited = {};
  List<String> path = [];
  
  bool _dfsHelper(String current) {
    visited.add(current);
    path.add(current);
    
    if (current == goal) {
      return true;
    }
    
    for (String neighbor in graph.cities[current]!.keys) {
      if (!visited.contains(neighbor)) {
        if (_dfsHelper(neighbor)) {
          return true;
        }
      }
    }
    
    path.removeLast();
    return false;
  }
  
  _dfsHelper(start);
  return path;
}
