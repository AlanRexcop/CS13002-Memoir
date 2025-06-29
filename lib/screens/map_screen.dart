import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';

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

// 1. Change from ConsumerWidget to ConsumerStatefulWidget
class MapScreen extends ConsumerStatefulWidget {
  // 2. The constructor can now be properly const because it has no fields.
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

// 3. Create the accompanying State class.
class _MapScreenState extends ConsumerState<MapScreen> {
  // 4. Declare the controller here. It's not final because it's initialized in initState.
  late final PopupController _popupLayerController;

  @override
  void initState() {
    super.initState();
    // 5. Initialize the controller when the widget is first created.
    _popupLayerController = PopupController();
  }

  @override
  void dispose() {
    // 6. It's crucial to dispose of the controller to prevent memory leaks.
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

    final LatLng initialCenter = allLocations.isNotEmpty
        ? LatLng(allLocations.first.location.lat, allLocations.first.location.lng)
        : const LatLng(51.509865, -0.118092);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Locations Map'),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: initialCenter,
          initialZoom: allLocations.isNotEmpty ? 13.0 : 4.0,
          onTap: (_, __) => _popupLayerController.hideAllPopups(),
        ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.location.info,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'In: "${entry.parentNote.title}"',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
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
      ),
    );
  }
}