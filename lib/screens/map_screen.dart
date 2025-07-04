import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:intl/intl.dart';

import 'package:memoir/models/location_model.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/note_view_screen.dart';

// Helper class to link a Location to its source Note.
class MapLocationEntry {
  final Location location;
  final Note parentNote;

  MapLocationEntry(this.location, this.parentNote);
}

// Convert to a ConsumerStatefulWidget to manage the controller's lifecycle.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  // Declare the controller here. It will be initialized in initState.
  late final PopupController _popupLayerController;

  @override
  void initState() {
    super.initState();
    // Initialize the controller when the widget is first created.
    _popupLayerController = PopupController();
  }

  @override
  void dispose() {
    // It's crucial to dispose of the controller to prevent memory leaks.
    _popupLayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The ref is available on the state object in a ConsumerStatefulWidget.
    final allPersons = ref.watch(appProvider).persons;
    final List<MapLocationEntry> allLocations = [];
    for (var person in allPersons) {
      for (var note in [person.info, ...person.notes]) {
        for (var location in note.locations) {
          allLocations.add(MapLocationEntry(location, note));
        }
      }
    }

    // This logic calculates the correct map view.
    late final MapOptions mapOptions;

    if (allLocations.isEmpty) {
      // If there are no locations, use a default centered view.
      mapOptions = MapOptions(
        initialCenter: const LatLng(51.509865, -0.118092), // Default to London
        initialZoom: 4.0,
        onTap: (_, __) => _popupLayerController.hideAllPopups(),
      );
    } else {
      // If locations exist, calculate the bounds to fit them all.
      final points = allLocations.map((entry) => LatLng(entry.location.lat, entry.location.lng)).toList();
      final bounds = LatLngBounds.fromPoints(points);

      // Create a CameraFit object using the bounds. This is the correct API.
      final cameraFit = CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50.0), // Add padding so markers aren't on the edge
      );
      
      // Create MapOptions using the `initialCameraFit` property.
      mapOptions = MapOptions(
        initialCameraFit: cameraFit,
        onTap: (_, __) => _popupLayerController.hideAllPopups(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Locations Map'),
      ),
      // Pass our dynamically created mapOptions to the FlutterMap widget.
      body: FlutterMap(
        options: mapOptions,
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'dev.memoir.app',
          ),
          PopupMarkerLayer(
            options: PopupMarkerLayerOptions(
              popupController: _popupLayerController,
              markers: _buildMarkers(allLocations),
              popupDisplayOptions: PopupDisplayOptions(
                builder: (BuildContext context, Marker marker) {
                  final entry = allLocations.firstWhere(
                    (entry) => entry.location.lat == marker.point.latitude && entry.location.lng == marker.point.longitude
                  );
                  return _buildPopupWidget(context, entry);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods now belong to the State class.
  
  List<Marker> _buildMarkers(List<MapLocationEntry> entries) {
    return entries.map((entry) {
      return Marker(
        point: LatLng(entry.location.lat, entry.location.lng),
        width: 40,
        height: 40,
        child: Icon(
          Icons.location_on,
          size: 40,
          color: Colors.red[700],
        ),
      );
    }).toList();
  }

  Widget _buildPopupWidget(BuildContext context, MapLocationEntry entry) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 250),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.location.info,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Go to Note',
                    onPressed: () {
                      _popupLayerController.hideAllPopups();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => NoteViewScreen(note: entry.parentNote),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'In: "${entry.parentNote.title}"',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (entry.parentNote.tags.isNotEmpty)
                Wrap(
                  spacing: 4.0,
                  runSpacing: 4.0,
                  children: entry.parentNote.tags.map((tag) => Chip(
                    label: Text(tag),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    labelStyle: const TextStyle(fontSize: 10),
                  )).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}