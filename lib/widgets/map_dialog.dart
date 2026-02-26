import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:user_app/services/location_service.dart';
import 'package:user_app/extensions/context_translate_ext.dart';

class MapDialog extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapDialog({super.key, this.initialLat, this.initialLng});

  @override
  State<MapDialog> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapDialog> {
  final String _baseUrl = "https://europe-west1-freequick.cloudfunctions.net";
  
  late GoogleMapController _mapController;
  late LatLng _pickedLocation;
  String _currentAddress = "Wyszukiwanie adresu...";
  bool _isLoading = false;
  List<dynamic> _suggestions = [];

  void _getSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    try {
      final url = "$_baseUrl/googleMapsAutocomplete?input=${Uri.encodeComponent(input)}";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          _suggestions = json.decode(response.body)['predictions'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Autocomplete error: $e");
    }
  }

  void _handleSuggestionClick(String placeId) async {
    try {
      final url = "$_baseUrl/googleMapsDetails?placeId=$placeId";
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final lat = data['result']['geometry']['location']['lat'];
        final lng = data['result']['geometry']['location']['lng'];
        final newPos = LatLng(lat, lng);

        _mapController.animateCamera(CameraUpdate.newLatLngZoom(newPos, 16));

        setState(() {
          _suggestions = [];
          _pickedLocation = newPos;
          _currentAddress = data['result']['formatted_address'];
        });

        _getAddress(newPos);
      }
    } catch (e) {
      debugPrint("Details error: $e");
    }
  }

  void _getAddress(LatLng location) async {
    setState(() => _isLoading = true);
    try {      
      final result = await LocationService.getUserLocationAddressFromGoogle(
        location.latitude, 
        location.longitude, 
      );
      
      setState(() {
        _currentAddress = result['fullAddress'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _currentAddress = "Couldn't find the address";
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _pickedLocation = LatLng(
      widget.initialLat ?? 37.4220, 
      widget.initialLng ?? -122.0841,
    );
    _getAddress(_pickedLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: _pickedLocation, zoom: 15),
              onMapCreated: (controller) => _mapController = controller,
              onCameraMove: (position) => _pickedLocation = position.target,
              onCameraIdle: () => _getAddress(_pickedLocation),
              myLocationEnabled: true,
              zoomControlsEnabled: false,
            ),

            const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 35),
                child: Icon(Icons.location_on, size: 45, color: Colors.red),
              ),
            ),

            Positioned(
              top: 70, left: 15, right: 15,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: context.t.searchAddress,
                        prefixIcon: const Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(15),
                      ),
                      onChanged: (value) => _getSuggestions(value),
                    ),
                  ),
                  
                  if (_suggestions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 250),
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: _suggestions.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              return ListTile(
                                leading: const Icon(Icons.location_on, color: Colors.blueGrey),
                                title: Text(
                                  _suggestions[index]['description'],
                                  style: const TextStyle(fontSize: 14, color: Colors.black),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  _handleSuggestionClick(_suggestions[index]['place_id']);
                                  setState(() {
                                    _suggestions = [];
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.map, color: Colors.blueGrey, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _isLoading ? "Pobieranie adresu..." : _currentAddress,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    height: 55,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline, size: 24),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      onPressed: _isLoading ? null : () => Navigator.pop(context, {
                        "address": _currentAddress,
                        "latitude": _pickedLocation.latitude,
                        "longitude": _pickedLocation.longitude,
                      }),
                      label: const Text(
                        "POTWIERDŹ ADRES", 
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.1)
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}