// C:\dev\memoir\lib\screens\graph_view_screen.dart
// C:\dev\memoir\lib\screens\graph_view_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_force_directed_graph/flutter_force_directed_graph.dart';
import 'package:path/path.dart' as p;
import 'package:vector_math/vector_math.dart' as vm;

import 'package:memoir/models/person_model.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/note_view_screen.dart';

class GraphViewScreen extends ConsumerStatefulWidget {
  final String? rootNotePath;

  const GraphViewScreen({super.key, this.rootNotePath});

  @override
  ConsumerState<GraphViewScreen> createState() => _GraphViewScreenState();
}

class _GraphViewScreenState extends ConsumerState<GraphViewScreen> {
  late final ForceDirectedGraphController<String> _controller;

  List<Person>? _displayedPersons;

  Map<String, Note> _notesByPath = {};
  String? _draggingNodePath;
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = ForceDirectedGraphController<String>();

    _controller.setOnScaleChange((scale) {
      if (mounted) {
        setState(() {
          _currentScale = scale;
        });
      }
    });
  }

  void _rebuildGraph(List<Person> allPersons) {
    final oldPositions = <String, vm.Vector2>{};
    if (_displayedPersons != null) {
      for (final node in _controller.graph.nodes) {
        oldPositions[node.data] = node.position;
      }
    }

    final Map<String, Note> allNotesByPath = {};
    for (final person in allPersons) {
      for (final note in [person.info, ...person.notes]) {
        allNotesByPath[note.path] = note;
      }
    }

    List<Note> notesToDisplay;
    if (widget.rootNotePath == null) {
      notesToDisplay = allNotesByPath.values.toList();
    } else {
      final rootNote = allNotesByPath[widget.rootNotePath];
      if (rootNote == null) {
        notesToDisplay = [];
      } else {
        final localGraphNotePaths = <String>{};
        localGraphNotePaths.add(rootNote.path);
        
        if (p.basename(rootNote.path) == 'info.md') {
          try {
            final person = allPersons.firstWhere((p) => p.info.path == rootNote.path);
            for (final note in person.notes) {
              localGraphNotePaths.add(note.path);
            }
          } catch (e) { /* Person not found, do nothing. */ }
        }

        for (final note in allNotesByPath.values) {
          if (note.mentions.any((m) => p.joinAll(m.path.split('/')) == rootNote.path)) {
            localGraphNotePaths.add(note.path);
          }
          if (rootNote.mentions.any((m) => p.joinAll(m.path.split('/')) == note.path)) {
            localGraphNotePaths.add(note.path);
          }
        }
        
        final personPathsInScope = <String>{};
        for (final person in allPersons) {
           final personHasNoteInScope = [person.info, ...person.notes].any((note) => localGraphNotePaths.contains(note.path));
           if(personHasNoteInScope) {
             personPathsInScope.add(person.info.path);
           }
        }
        localGraphNotePaths.addAll(personPathsInScope);

        notesToDisplay = allNotesByPath.values
            .where((note) => localGraphNotePaths.contains(note.path))
            .toList();
      }
    }

    final Map<String, Node<String>> nodeMap = {};
    final List<Node<String>> visibleNodes = [];
    final double radius = 50.0 * sqrt(notesToDisplay.length);
    for (int i = 0; i < notesToDisplay.length; i++) {
      final note = notesToDisplay[i];
      final position = oldPositions[note.path] ??
          () {
            final angle = 2 * pi * i / notesToDisplay.length;
            return vm.Vector2(cos(angle) * radius, sin(angle) * radius);
          }();
      final nodeObj = Node<String>(note.path, position);
      visibleNodes.add(nodeObj);
      nodeMap[note.path] = nodeObj;
    }

    final List<Edge> edgesToDisplay = [];
    for (final sourceNote in notesToDisplay) {
      final sourceNode = nodeMap[sourceNote.path];
      if (sourceNode == null) continue;
      
      for (final mention in sourceNote.mentions) {
        final normalizedPath = p.joinAll(mention.path.split('/'));
        final destinationNode = nodeMap[normalizedPath];
        if (destinationNode != null && sourceNode != destinationNode) {
          edgesToDisplay.add(Edge(sourceNode, destinationNode));
        }
      }
    }
    for (final person in allPersons) {
        final personInfoNode = nodeMap[person.info.path];
        if (personInfoNode == null) continue;
        for (final note in person.notes) {
            final noteNode = nodeMap[note.path];
            if (noteNode != null) {
                edgesToDisplay.add(Edge(noteNode, personInfoNode));
            }
        }
    }

    const customConfig = GraphConfig(length: 200.0);
    final graph = ForceDirectedGraph<String>(config: customConfig);
    
    for (var node in visibleNodes) {
      graph.addNode(node);
    }
    for (var edge in edgesToDisplay) {
      try {
        graph.addEdge(edge);
      } catch (e) { /* Ignore duplicate edges */ }
    }

    setState(() {
      _notesByPath = allNotesByPath;
      _controller.graph = graph;
      _displayedPersons = allPersons;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.needUpdate();
      }
    });
  }
  
  // ... rest of the file is unchanged
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPersons = ref.watch(appProvider.select((s) => s.persons));

    if (currentPersons != _displayedPersons) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _rebuildGraph(currentPersons);
        }
      });
    }

    final String appBarTitle;
    if (widget.rootNotePath != null && _notesByPath.containsKey(widget.rootNotePath)) {
        appBarTitle = 'Local Graph: "${_notesByPath[widget.rootNotePath]!.title}"';
    } else {
        appBarTitle = 'Graph View';
    }

    if (_displayedPersons == null) {
      return Scaffold(
        appBar: AppBar(title: Text(appBarTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: ForceDirectedGraphWidget<String>(
              controller: _controller,
              onDraggingStart: (nodePath) => setState(() => _draggingNodePath = nodePath),
              onDraggingEnd: (nodePath) => setState(() => _draggingNodePath = null),
              
              nodesBuilder: (context, path) {
                final note = _notesByPath[path];
                if (note == null) return const SizedBox.shrink();

                final isInfoNote = p.basename(note.path) == 'info.md';
                final double nodeSize = isInfoNote ? 60 : 40;
                final Color nodeColor = isInfoNote ? Colors.amber[800]! : Colors.blueGrey[600]!;
                
                final bool isRootNode = path == widget.rootNotePath;
                final double borderWidth = isRootNode ? 4.0 : 2.0;
                final Color borderColor = isRootNode ? Colors.cyanAccent : Colors.white24;

                Widget nodeContent;
                if (_currentScale > 0.4) {
                  nodeContent = Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: Icon(
                          isInfoNote ? Icons.person_pin_circle_outlined : Icons.description_outlined,
                          color: Colors.white,
                          size: isInfoNote ? 24 : 18,
                        ),
                      ),
                      Positioned(
                        top: nodeSize,
                        child: Text(
                          note.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: nodeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  nodeContent = const SizedBox.shrink();
                }

                return GestureDetector(
                  onTap: () {
                    if (widget.rootNotePath == null || path == widget.rootNotePath) {
                       Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => NoteViewScreen(note: note),
                        ),
                      );
                    } else {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => GraphViewScreen(rootNotePath: path),
                        ),
                      );
                    }
                  },
                  child: Tooltip(
                    message: note.title,
                    child: Container(
                      width: nodeSize,
                      height: nodeSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: nodeColor,
                        border: Border.all(color: borderColor, width: borderWidth),
                      ),
                      child: nodeContent,
                    ),
                  ),
                );
              },
              edgesBuilder: (context, pathA, pathB, distance) {
                final isHighlighted = (pathA == _draggingNodePath || pathB == _draggingNodePath);

                return Container(
                  width: distance,
                  height: isHighlighted ? 2.0 : 1.0,
                  color: isHighlighted 
                      ? Colors.amber.withOpacity(0.8) 
                      : Theme.of(context).colorScheme.outline,
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _controller.center();
          _controller.scale = 1.0;
        },
        tooltip: 'Reset View',
        child: const Icon(Icons.center_focus_strong),
      ),
    );
  }
}