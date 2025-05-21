import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  void initState() {
    super.initState();
    _facilityLocation = LatLng(widget.latitude, widget.longitude);
    _markers = {
      Marker(
        markerId: const MarkerId('facility'),
        position: _facilityLocation,
        infoWindow: InfoWindow(title: widget.facilityName),
      ),
    };
  }

  Future<void> _openInGoogleMaps() async {
    if (!mounted) return;

    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _facilityLocation,
                zoom: 15,
              ),
              markers: _markers,
              mapType: MapType.normal,
              zoomControlsEnabled: false,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _openInGoogleMaps,
          icon: const Icon(Icons.map),
          label: const Text('Open in Google Maps'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }
}
