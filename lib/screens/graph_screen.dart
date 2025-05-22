import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import '../services/mongo_service.dart';

class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  final Graph graph = Graph();

  final builder =
      BuchheimWalkerConfiguration()
        ..siblingSeparation = (20)
        ..levelSeparation = (30)
        ..subtreeSeparation = (30)
        ..orientation = BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT;

  @override
  void initState() {
    super.initState();
    _loadGraph();
  }

  Future<void> _loadGraph() async {
    final db = MongoService();
    await db.connect();
    final connections = await db.fetchConnections();

    Map<String, Node> nodes = {};
    for (var conn in connections) {
      final from = conn['from'];
      final to = conn['to'];

      nodes[from] ??= Node.Id(from);
      nodes[to] ??= Node.Id(to);

      graph.addEdge(nodes[from]!, nodes[to]!);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Grafiksel Yönlendirme")),
      body: InteractiveViewer(
        constrained: false,
        boundaryMargin: const EdgeInsets.all(100),
        minScale: 0.01,
        maxScale: 5.6,
        child: GraphView(
          graph: graph,
          algorithm: BuchheimWalkerAlgorithm(
            builder,
            TreeEdgeRenderer(builder),
          ),
          builder: (Node node) {
            String label = node.key!.value as String;
            return rectangleWidget(label);
          },
        ),
      ),
    );
  }

  Widget rectangleWidget(String text) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.blue.shade300,
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}
