// C:\dev\memoir\lib\screens\map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';

import 'package:memoir/models/location_model.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/note_view_screen.dart';

class MapLocationEntry {
  final Location location;
  final Note parentNote;

  MapLocationEntry(this.location, this.parentNote);
}

class MapScreen extends ConsumerStatefulWidget {
  final Location? initialLocation;

  const MapScreen({super.key, this.initialLocation});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  late final PopupController _popupLayerController;

  @override
  void initState() {
    super.initState();
    _popupLayerController = PopupController();
  }

  @override
  void dispose() {
    _popupLayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allPersons = ref.watch(appProvider).persons;
    final List<MapLocationEntry> allLocations = [];
    for (var person in allPersons) {
      for (var note in [person.info, ...person.notes]) {
        for (var location in note.locations) {
          allLocations.add(MapLocationEntry(location, note));
        }
      }
    }

    late final MapOptions mapOptions;

    if (widget.initialLocation != null) {
      // If an initial location is provided, center and zoom on it.
      mapOptions = MapOptions(
        initialCenter: LatLng(widget.initialLocation!.lat, widget.initialLocation!.lng),
        initialZoom: 15.0, // A nice close-up zoom level
        onTap: (_, __) => _popupLayerController.hideAllPopups(),
      );
    } else if (allLocations.isEmpty) {
      // Default view if no locations exist at all
      mapOptions = MapOptions(
        initialCenter: const LatLng(10.8231, 106.6297),
        initialZoom: 4.0,
        onTap: (_, __) => _popupLayerController.hideAllPopups(),
      );
    } else if (allLocations.length == 1) {
      // Center on that single location with a fixed zoom level.
      mapOptions = MapOptions(
        initialCenter: LatLng(allLocations.first.location.lat, allLocations.first.location.lng),
        initialZoom: 15.0, // A nice close-up zoom level
        onTap: (_, __) => _popupLayerController.hideAllPopups(),
      );
    } else {
      // Original logic, now safe because we know there are multiple, distinct points.
      final points = allLocations.map((entry) => LatLng(entry.location.lat, entry.location.lng)).toList();
      // We add a check to handle the edge case where all locations have the same coordinate
      final bounds = LatLngBounds.fromPoints(points);
      if (bounds.northEast == bounds.southWest) {
        // All points are the same, treat as a single location
        mapOptions = MapOptions(
          initialCenter: LatLng(allLocations.first.location.lat, allLocations.first.location.lng),
          initialZoom: 15.0,
          onTap: (_, __) => _popupLayerController.hideAllPopups(),
        );
      } else {
        final cameraFit = CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50.0),
        );
        mapOptions = MapOptions(
          initialCameraFit: cameraFit,
          onTap: (_, __) => _popupLayerController.hideAllPopups(),
        );
      }
    }
    // else {
    //   // Original logic to fit all locations in bounds
    //   final points = allLocations.map((entry) => LatLng(entry.location.lat, entry.location.lng)).toList();
    //   final bounds = LatLngBounds.fromPoints(points);
    //   final cameraFit = CameraFit.bounds(
    //     bounds: bounds,
    //     padding: const EdgeInsets.all(50.0),
    //   );
    //   mapOptions = MapOptions(
    //     initialCameraFit: cameraFit,
    //     onTap: (_, __) => _popupLayerController.hideAllPopups(),
    //   );
    // }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Locations Map'),
      ),
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