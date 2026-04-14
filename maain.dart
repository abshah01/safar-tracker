import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // We will initialize Firebase here later with your specific keys
  await Firebase.initializeApp();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(primarySwatch: Colors.green),
    home: FamilyLogin(),
  ));
}

class FamilyLogin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("🕋 Hajj Family Tracker")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['Abba', 'Amma', 'Me'].map((name) => 
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: Size(200, 50)),
                child: Text("I am $name"),
                onPressed: () => Navigator.push(context, 
                  MaterialPageRoute(builder: (context) => MapScreen(userName: name)))
              ),
            )
          ).toList(),
        ),
      ),
    );
  }
}

class MapScreen extends StatefulWidget {
  final String userName;
  MapScreen({required this.userName});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Location location = Location();
  DatabaseReference dbRef = FirebaseDatabase.instance.ref("locations");
  Map<MarkerId, Marker> markers = {};
  GoogleMapController? mapController;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
    _listenForFamily();
  }

  // Sends YOUR location to Firebase
  _startLocationTracking() async {
    bool _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) _serviceEnabled = await location.requestService();

    PermissionStatus _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
    }

    location.onLocationChanged.listen((locData) {
      if (locData.latitude != null && locData.longitude != null) {
        dbRef.child(widget.userName).set({
          "lat": locData.latitude,
          "lng": locData.longitude,
          "timestamp": ServerValue.timestamp,
        });
      }
    });
  }

  // Receives FAMILY locations from Firebase
  _listenForFamily() {
    dbRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          data.forEach((key, value) {
            final marker = Marker(
              markerId: MarkerId(key),
              position: LatLng(value['lat'], value['lng']),
              infoWindow: InfoWindow(title: key, snippet: "Family Member"),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                key == widget.userName ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueRed
              ),
            );
            markers[MarkerId(key)] = marker;
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Live Map: ${widget.userName}")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: LatLng(21.4225, 39.8262), zoom: 15),
        markers: Set<Marker>.of(markers.values),
        myLocationEnabled: true,
        onMapCreated: (controller) => mapController = controller,
      ),
    );
  }
}