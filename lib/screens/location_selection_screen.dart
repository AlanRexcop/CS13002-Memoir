// C:\dev\memoir\lib\screens\location_selection_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_geocoding_api/google_geocoding_api.dart';
import 'package:memoir/widgets/custom_float_button.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({super.key});

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  static const String _apiKey = "AIzaSyDcdJId1pEaYCu7DoNe9Oe6gmQFB6qDIlg";
  
  final _mapController = MapController();
  final _searchController = TextEditingController();
  late final FocusNode _searchFocusNode;

  late final GoogleGeocodingApi _geocodingApi;
  
  LatLng? _selectedPoint;
  bool _isReverseGeocoding = false;
  
  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();
    _geocodingApi = GoogleGeocodingApi(_apiKey);
    // A default starting point
    _selectedPoint = const LatLng(10.8231, 106.6297); 
  }
  
  Future<void> _getAddressFromCoordinates(LatLng point) async {
    setState(() {
      _selectedPoint = point; // Update marker position immediately
      _isReverseGeocoding = true;
    });

    try {
      final response = await _geocodingApi.reverse('${point.latitude},${point.longitude}');
      if (response.results.isNotEmpty && mounted) {
        // Update the search bar with the first (most specific) address found
        _searchController.text = response.results.first.formattedAddress;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not find address: $e')));
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or name a location.'))
      );
      return;
    }

    Navigator.of(context).pop({
      'text': displayText,
      'lat': _selectedPoint!.latitude,
      'lng': _selectedPoint!.longitude,
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Location'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: _isReverseGeocoding ? const LinearProgressIndicator() : const SizedBox.shrink(),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPoint!,
              initialZoom: 13.0,
              onTap: (tapPosition, point) {
                 _searchFocusNode.unfocus();
                 _getAddressFromCoordinates(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'dev.memoir.app',
              ),
              if (_selectedPoint != null)
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
                inputDecoration: InputDecoration(
                  hintText: "Search for a place...",
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                debounceTime: 800,
                isLatLngRequired: true,
                getPlaceDetailWithLatLng: (Prediction prediction) {
                  if (prediction.lat != null && prediction.lng != null) {
                    final lat = double.tryParse(prediction.lat!);
                    final lng = double.tryParse(prediction.lng!);
                    if (lat != null && lng != null) {
                      final point = LatLng(lat, lng);
                      setState(() {
                        _selectedPoint = point;
                      });
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        onPressed: _selectedPoint == null ? null : _confirmSelection,
        label: Text(
          'Confirm Location',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary
          ),
        ),
        icon: const Icon(Icons.check),
      ),
    );
  }
}