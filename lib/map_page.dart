import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox/utils.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage();

  @override
  State createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  MapboxMap? mapboxMap;
  PointAnnotationManager? pointAnnotationManager;
  PolylineAnnotationManager? polylineAnnotationManager;
  Uint8List? markerImage;

  TextEditingController searchController = TextEditingController();
  List<dynamic> suggestions = [];
  bool isSearching = false;

  var isLight = true;

  PointAnnotation? pointAnnotation;

  @override
  void initState() {
    super.initState();
    _loadMarkerImage();
  }

  Future<void> _loadMarkerImage() async {
    final ByteData bytes = await rootBundle.load('assets/custom-icon.png');
    setState(() {
      markerImage = bytes.buffer.asUint8List();
    });
  }

  _onMapCreated(MapboxMap mapboxMap) {
    this.mapboxMap = mapboxMap;
    mapboxMap.style;

    mapboxMap.annotations
        .createPointAnnotationManager()
        .then((manager) => pointAnnotationManager = manager);
  }

  _onTap(MapContentGestureContext context) {
    pointAnnotationManager?.create(
      PointAnnotationOptions(
        geometry: Point(
            coordinates: Position(
                context.point.coordinates.lng, context.point.coordinates.lat)),
        image: markerImage,
        iconSize: 1.5,
      ),
    );
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        suggestions = [];
      });
      return;
    }

    setState(() {
      isSearching = true;
    });

    try {
      final results = await fetchSearchResults(query);
      setState(() {
        suggestions = results;
      });
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        isSearching = false;
      });
    }
  }

  void _selectPlace(dynamic suggestion) {
    final coordinates = suggestion['geometry']['coordinates'];
    final lat = coordinates[1];
    final lng = coordinates[0];

    // Clear suggestions
    setState(() {
      suggestions = [];
    });

    // Move map to the selected location
    mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        zoom: 14.0,
      ),
      MapAnimationOptions(
        duration: 2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey("mapWidget"),
            cameraOptions: CameraOptions(
                center: Point(coordinates: Position(106.8456, -6.2088)),
                zoom: 8.0),
            styleUri: MapboxStyles.MAPBOX_STREETS,
            textureView: true,
            onMapCreated: _onMapCreated,
            onTapListener: _onTap,
          ),
          Positioned(
            top: 36.0,
            left: 16.0,
            right: 16.0,
            child: Column(
              children: [
                Material(
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(8.0),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search Places",
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 16.0),
                      suffixIcon: isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                height: 20.0, // Match size with Icon
                                width: 20.0, // Match size with Icon
                                child: CircularProgressIndicator(
                                  strokeWidth:
                                      2.0, // Set stroke width for consistent appearance
                                ),
                              ),
                            )
                          : const Icon(Icons.search),
                    ),
                    onChanged: _searchPlaces,
                  ),
                ),
                const SizedBox(
                  height: 8.0,
                ),
                if (suggestions.isNotEmpty)
                  Positioned(
                    top: 1.0,
                    left: 16.0,
                    right: 16.0,
                    child: Material(
                      elevation: 5.0,
                      borderRadius: BorderRadius.circular(8.0),
                      child: Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height *
                              0.4, // Limit height
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: suggestions.length,
                          itemBuilder: (context, index) {
                            final suggestion = suggestions[index];
                            return ListTile(
                              title: Text(suggestion['place_name']),
                              onTap: () => _selectPlace(suggestion),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
