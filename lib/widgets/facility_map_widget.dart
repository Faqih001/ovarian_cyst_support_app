import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ovarian_cyst_support_app/utils/maps_helper.dart';

class FacilityMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String facilityName;

  const FacilityMapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.facilityName,
  });

  @override
  State<FacilityMapWidget> createState() => _FacilityMapWidgetState();
}

class _FacilityMapWidgetState extends State<FacilityMapWidget> {
  late final LatLng _facilityLocation;
  late final Set<Marker> _markers;
  GoogleMapController? _mapController;

  // Map state tracking
  bool _isMapLoaded = false;
  bool _hasMapError = false;

  @override
  void initState() {
    super.initState();
    _initializeMapData();
  }

  void _initializeMapData() {
    // Validate coordinates
    if (widget.latitude != 0 && widget.longitude != 0) {
      _facilityLocation = LatLng(widget.latitude, widget.longitude);
      _markers = {
        Marker(
          markerId: const MarkerId('facility'),
          position: _facilityLocation,
          infoWindow: InfoWindow(title: widget.facilityName),
        ),
      };
    } else {
      // Default to Nairobi if coordinates are invalid
      _facilityLocation = const LatLng(
        -1.286389,
        36.817223,
      ); // Nairobi coordinates
      _markers = {};
    }
  }

  @override
  void dispose() {
    if (_mapController != null) {
      _mapController!.dispose();
    }
    super.dispose();
  }

  Future<void> _openInGoogleMaps() async {
    if (!mounted) return;

    // Check if coordinates are valid
    if (widget.latitude == 0 && widget.longitude == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location coordinates not available')),
        );
      }
      return;
    }

    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}',
    );

    // Try to search by facility name if coordinates aren't available
    final nameSearchUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(widget.facilityName)}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(nameSearchUrl)) {
      // Fallback to searching by name if coordinates don't work
      await launchUrl(nameSearchUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Check if the map loads correctly by trying to get the visible region
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      controller
          .getVisibleRegion()
          .then((bounds) {
            // If we got here, the map loaded successfully
            if (mounted) {
              setState(() {
                _isMapLoaded = true;
                _hasMapError = false;
              });
            }
          })
          .catchError((error) {
            // Map failed to load properly
            if (mounted) {
              setState(() {
                _hasMapError = true;
                _isMapLoaded = true; // Consider it "loaded" even if with error
              });
              // Show help dialog
              MapsHelper.showMapConfigurationHelp(context);
            }
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasValidLocation = widget.latitude != 0 && widget.longitude != 0;

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: hasValidLocation
                ? Stack(
                    children: [
                      // The actual map
                      _buildMapContent(),

                      // Loading indicator overlay
                      if (!_isMapLoaded)
                        Container(
                          color: Colors.white70,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  )
                : _buildLocationNotAvailableMessage(),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: hasValidLocation ? _openInGoogleMaps : null,
          icon: const Icon(Icons.map),
          label: Text(
            hasValidLocation ? 'Open in Google Maps' : 'Location Not Available',
          ),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: hasValidLocation
                ? Theme.of(context).primaryColor
                : Colors.grey,
            disabledForegroundColor: Colors.white70,
            disabledBackgroundColor: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildMapContent() {
    if (_hasMapError) {
      return _buildMapErrorMessage();
    }

    try {
      return GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _facilityLocation,
          zoom: 15,
        ),
        markers: _markers,
        mapType: MapType.normal,
        zoomControlsEnabled: true,
        onMapCreated: _onMapCreated,
        // Explicitly disable lite mode for better rendering
        liteModeEnabled: false,
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        compassEnabled: true,
        mapToolbarEnabled: true,
        // Disable rotation to prevent rendering issues
        rotateGesturesEnabled: true,
        tiltGesturesEnabled: false,
      );
    } catch (e) {
      // Handle any exceptions during map creation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasMapError) {
          setState(() {
            _hasMapError = true;
            _isMapLoaded = true;
          });
          // Show configuration help
          MapsHelper.showMapConfigurationHelp(context);
        }
      });
      return _buildMapErrorMessage();
    }
  }

  Widget _buildLocationNotAvailableMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'Location Not Available',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This facility does not have location coordinates in our database.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildMapErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.amber[700]),
          const SizedBox(height: 8),
          Text(
            'Map Loading Issue',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unable to display the map. Please check your Google Maps configuration.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => MapsHelper.showMapConfigurationHelp(context),
            child: const Text('View Setup Instructions'),
          ),
        ],
      ),
    );
  }
}
