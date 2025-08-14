// lib/screens/map_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_geocoding_api/google_geocoding_api.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';

import 'package:memoir/models/location_model.dart';
import 'package:memoir/models/note_model.dart';
import 'package:memoir/providers/app_provider.dart';
import 'package:memoir/screens/note_view_screen.dart';
import 'package:memoir/screens/person_list_screen.dart';

class MapLocationEntry {
  final Location location;
  final Note parentNote;

  MapLocationEntry(this.location, this.parentNote);
}

class MapScreen extends ConsumerStatefulWidget {
  final Location? initialLocation;
  final ScreenPurpose purpose;

  const MapScreen({
    super.key,
    this.initialLocation,
    this.purpose = ScreenPurpose.view,
  });

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  late final PopupController _popupLayerController;

  static const String _apiKey = "AIzaSyDcdJId1pEaYCu7DoNe9Oe6gmQFB6qDIlg";
  final _searchController = TextEditingController();
  late final FocusNode _searchFocusNode;
  late final GoogleGeocodingApi _geocodingApi;
  LatLng? _selectedPoint;
  bool _isReverseGeocoding = false;

  @override
  void initState() {
    super.initState();
    _popupLayerController = PopupController();
    _searchFocusNode = FocusNode();
    _geocodingApi = GoogleGeocodingApi(_apiKey);

    if (widget.purpose == ScreenPurpose.select) {
      // Default starting point for selection mode
      _selectedPoint = const LatLng(10.8231, 106.6297);
    }
  }

  @override
  void dispose() {
    _popupLayerController.dispose();
    _mapController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _getAddressFromCoordinates(LatLng point) async {
    setState(() {
      _selectedPoint = point;
      _isReverseGeocoding = true;
    });

    try {
      final response = await _geocodingApi.reverse('${point.latitude},${point.longitude}');
      if (response.results.isNotEmpty && mounted) {
        _searchController.text = response.results.first.formattedAddress;
      }
    } catch (e) {
      if (mounted) {
        //print("Could not find address: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isReverseGeocoding = false);
      }
    }
  }

  void _confirmSelection() {
    if (_selectedPoint == null) return;
    final displayText = _searchController.text.trim();

    if (displayText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select or name a location.')));
      return;
    }

    Navigator.of(context).pop({
      'text': displayText,
      'lat': _selectedPoint!.latitude,
      'lng': _selectedPoint!.longitude,
    });
  }
  
  void _onMapTap(TapPosition tapPosition, LatLng point) {
    _searchFocusNode.unfocus();
    if (widget.purpose == ScreenPurpose.select) {
      _getAddressFromCoordinates(point);
    } else {
      _popupLayerController.hideAllPopups();
    }
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

    MapOptions mapOptions;

    // Case 1: A specific point is prioritized (selection mode, or an initial location was passed)
    if (widget.purpose == ScreenPurpose.select || widget.initialLocation != null) {
      final centerPoint = widget.initialLocation != null
          ? LatLng(widget.initialLocation!.lat, widget.initialLocation!.lng)
          : _selectedPoint ?? const LatLng(10.8231, 106.6297);
      
      mapOptions = MapOptions(
        initialCenter: centerPoint,
        initialZoom: 15.0,
        onTap: _onMapTap,
      );
    } 
    // Case 2: General view mode, must calculate bounds from all existing locations
    else {
      if (allLocations.isEmpty) {
        // No locations exist yet, show a default world view
        mapOptions = MapOptions(
          initialCenter: const LatLng(10.8231, 106.6297),
          initialZoom: 4.0,
          onTap: _onMapTap,
        );
      } else {
        // We have locations, so we can calculate bounds
        final points = allLocations.map((entry) => LatLng(entry.location.lat, entry.location.lng)).toList();
        final bounds = LatLngBounds.fromPoints(points);

        // Check if all points are identical (which creates a zero-area bound)
        if (bounds.northEast == bounds.southWest) {
          // All locations are in the same spot, so just center on it
          mapOptions = MapOptions(
            initialCenter: points.first,
            initialZoom: 15.0,
            onTap: _onMapTap,
          );
        } else {
          // We have different locations, so fit the map to show all of them
          final cameraFit = CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(50.0),
          );
          mapOptions = MapOptions(
            initialCameraFit: cameraFit,
            onTap: _onMapTap,
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.purpose == ScreenPurpose.select ? 'Select Location' : 'Locations Map'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: _isReverseGeocoding ? const LinearProgressIndicator() : const SizedBox.shrink(),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: mapOptions,
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'dev.memoir.app',
                errorTileCallback: (tile, error, stackTrace) {
                },
              ),
              // Vault locations with popups (VIEW mode)
              if (widget.purpose == ScreenPurpose.view)
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
              // Vault locations without popups (SELECT mode, for context)
              if (widget.purpose == ScreenPurpose.select)
                 MarkerLayer(markers: _buildMarkers(allLocations, color: Colors.deepOrange.withOpacity(0.7))),

              // The new, selectable marker (SELECT mode)
              if (widget.purpose == ScreenPurpose.select && _selectedPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint!,
                      width: 40,
                      height: 40,
                      child: Icon(Icons.location_on, size: 40, color: Theme.of(context).primaryColor),
                    ),
                  ],
                ),
            ],
          ),
          if (widget.purpose == ScreenPurpose.select || widget.purpose == ScreenPurpose.view)
            Positioned(
              top: 10,
              left: 15,
              right: 15,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(10),
                child: GooglePlaceAutoCompleteTextField(  
                  focusNode: _searchFocusNode,
                  textEditingController: _searchController,
                  googleAPIKey: _apiKey,
                  inputDecoration: const InputDecoration(
                    hintText: "Search for a place...",
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  debounceTime: 800,
                  isLatLngRequired: true,
                  getPlaceDetailWithLatLng: (Prediction prediction) {
                    if (prediction.lat != null && prediction.lng != null) {
                      final lat = double.tryParse(prediction.lat!);
                      final lng = double.tryParse(prediction.lng!);
                      if (lat != null && lng != null) {
                        final point = LatLng(lat, lng);
                        if (widget.purpose == ScreenPurpose.select) {
                          setState(() => _selectedPoint = point);
                        }
                        _mapController.move(point, 15.0);
                      }
                    }
                  },
                  itemClick: (Prediction prediction) {
                    _searchController.text = prediction.description ?? "";
                    _searchController.selection = TextSelection.fromPosition(
                      TextPosition(offset: prediction.description?.length ?? 0),
                    );
                    _searchFocusNode.unfocus();
                  },
                )
              ),
            ),
        ],
      ),
      floatingActionButton: widget.purpose == ScreenPurpose.select ? FloatingActionButton.extended(
        onPressed: _selectedPoint == null ? null : _confirmSelection,
        label: const Text('Confirm Location'),
        icon: const Icon(Icons.check),
      ) : null,
    );
  }

  List<Marker> _buildMarkers(List<MapLocationEntry> entries, {Color? color}) {
    return entries.map((entry) {
      return Marker(
        point: LatLng(entry.location.lat, entry.location.lng),
        width: 40,
        height: 40,
        child: Icon(
          Icons.location_on,
          size: 40,
          color: color ?? Colors.red[700],
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