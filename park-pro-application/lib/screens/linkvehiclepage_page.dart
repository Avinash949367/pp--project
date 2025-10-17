import 'package:flutter/material.dart';

class LinkVehiclePage extends StatefulWidget {
  const LinkVehiclePage({super.key});

  @override
  State<LinkVehiclePage> createState() => _LinkVehiclePageState();
}

class _LinkVehiclePageState extends State<LinkVehiclePage> {
  final TextEditingController _vehicleNumberController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _fastagNumberController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  String _vehicleType = 'Car';
  String _state = 'Select State';
  String _fastagProvider = 'SBI';
  String _vehicleColor = 'White';
  String _vehicleModel = '';

  List<Map<String, String>> linkedVehicles = [];

  final Color darkGray = const Color(0xFF2E2E2E);
  final Color electricBlue = const Color(0xFF1E90FF);
  final Color lightGray = const Color(0xFFB0B0B0);

  void _linkVehicle() {
    String vehicleNumber = _vehicleNumberController.text.trim();
    String ownerName = _ownerNameController.text.trim();

    if (vehicleNumber.isEmpty || ownerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter all required fields")),
      );
      return;
    }

    setState(() {
      linkedVehicles.add({
        'vehicleNumber': vehicleNumber,
        'vehicleType': _vehicleType,
        'state': _state,
        'ownerName': ownerName,
        'fastagNumber': _fastagNumberController.text.trim(),
        'fastagProvider': _fastagProvider,
        'vehicleColor': _vehicleColor,
        'vehicleModel': _vehicleModel,
        'mobile': _mobileController.text.trim(),
      });

      _vehicleNumberController.clear();
      _ownerNameController.clear();
      _fastagNumberController.clear();
      _mobileController.clear();
      _vehicleType = 'Car';
      _state = 'Select State';
      _fastagProvider = 'SBI';
      _vehicleColor = 'White';
      _vehicleModel = '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Vehicle linked successfully")),
    );
  }

  void _removeVehicle(int index) {
    setState(() {
      linkedVehicles.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Vehicle removed")),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: lightGray),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: electricBlue),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: electricBlue, width: 2),
      ),
      prefixIcon: Icon(icon, color: electricBlue),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGray,
      appBar: AppBar(
        title: const Text("Link Vehicle"),
        backgroundColor: electricBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Vehicle Details",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),

            // Vehicle Number
            TextField(
              controller: _vehicleNumberController,
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration("Vehicle Number", Icons.directions_car),
            ),
            const SizedBox(height: 12),

            // Owner Name
            TextField(
              controller: _ownerNameController,
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration("Owner Name", Icons.person),
            ),
            const SizedBox(height: 12),

            // Vehicle Type
            DropdownButtonFormField<String>(
              value: _vehicleType,
              dropdownColor: darkGray,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Vehicle Type",
                labelStyle: TextStyle(color: lightGray),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: electricBlue, width: 2),
                ),
              ),
              items: ['Car', 'Bike', 'Truck', 'Bus']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white))))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _vehicleType = val!;
                });
              },
            ),
            const SizedBox(height: 12),

            // State
            DropdownButtonFormField<String>(
              value: _state,
              dropdownColor: darkGray,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Registration State",
                labelStyle: TextStyle(color: lightGray),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: electricBlue, width: 2),
                ),
              ),
              items: [
                'Select State',
                'Andhra Pradesh',
                'Delhi',
                'Karnataka',
                'Maharashtra',
                'Tamil Nadu'
              ]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white))))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _state = val!;
                });
              },
            ),
            const SizedBox(height: 12),

            // Vehicle Model
            TextField(
              onChanged: (val) => _vehicleModel = val,
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration("Vehicle Model", Icons.directions_car_filled),
            ),
            const SizedBox(height: 12),

            // Vehicle Color
            DropdownButtonFormField<String>(
              value: _vehicleColor,
              dropdownColor: darkGray,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Vehicle Color",
                labelStyle: TextStyle(color: lightGray),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: electricBlue, width: 2),
                ),
              ),
              items: ['White', 'Black', 'Blue', 'Red', 'Silver', 'Other']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white))))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _vehicleColor = val!;
                });
              },
            ),
            const SizedBox(height: 12),

            // FASTag Number
            TextField(
              controller: _fastagNumberController,
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration("FASTag Number (Optional)", Icons.confirmation_number),
            ),
            const SizedBox(height: 12),

            // FASTag Provider
            DropdownButtonFormField<String>(
              value: _fastagProvider,
              dropdownColor: darkGray,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "FASTag Provider",
                labelStyle: TextStyle(color: lightGray),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: electricBlue, width: 2),
                ),
              ),
              items: ['SBI', 'HDFC', 'ICICI', 'Paytm', 'Axis Bank']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white))))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _fastagProvider = val!;
                });
              },
            ),
            const SizedBox(height: 12),

            // Mobile Number
            TextField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: _buildInputDecoration("Mobile Number", Icons.phone),
            ),
            const SizedBox(height: 20),

            // Link Vehicle Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _linkVehicle,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: electricBlue,
                ),
                child: const Text(
                  "Link Vehicle",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Linked Vehicles List
            if (linkedVehicles.isNotEmpty)
              const Text(
                "Linked Vehicles",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            const SizedBox(height: 12),

            ...linkedVehicles.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, String> vehicle = entry.value;
              return Card(
                color: darkGray,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: electricBlue, width: 1),
                ),
                child: ListTile(
                  leading: Icon(
                    vehicle['vehicleType'] == 'Car'
                        ? Icons.directions_car
                        : vehicle['vehicleType'] == 'Bike'
                        ? Icons.motorcycle
                        : Icons.local_shipping,
                    color: electricBlue,
                  ),
                  title: Text(vehicle['vehicleNumber']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    "${vehicle['ownerName']} • ${vehicle['fastagProvider']}",
                    style: TextStyle(color: lightGray),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _removeVehicle(index),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
