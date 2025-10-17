import 'package:flutter/material.dart';

class BuyNewFastagPage extends StatefulWidget {
  const BuyNewFastagPage({super.key});

  @override
  State<BuyNewFastagPage> createState() => _BuyNewFastagPageState();
}

class _BuyNewFastagPageState extends State<BuyNewFastagPage> {
  int _currentStep = 0;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _vehicleController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String? _selectedVehicleType;
  String _paymentMethod = 'Net Banking';

  final Color electricBlue = const Color(0xFF1E90FF);
  final Color darkGray = const Color(0xFF2E2E2E);
  final Color lightGray = const Color(0xFFB0B0B0);

  List<Step> getSteps() {
    return [
      Step(
        title: const Text('Personal Details'),
        content: _buildPersonalDetailsStep(),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Vehicle Details'),
        content: _buildVehicleDetailsStep(),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Complete Application'),
        content: _buildCompleteApplicationStep(),
        isActive: _currentStep >= 2,
        state: StepState.indexed,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGray,
      appBar: AppBar(
        title: const Text('Apply for FASTag'),
        backgroundColor: electricBlue,
        foregroundColor: Colors.white,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < getSteps().length - 1) {
            setState(() {
              _currentStep++;
            });
          } else {
            // Submit application
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Application Submitted Successfully")),
            );
            Navigator.pop(context);
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() {
              _currentStep--;
            });
          } else {
            Navigator.pop(context);
          }
        },
        steps: getSteps(),
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              children: [
                if (_currentStep != 0)
                  ElevatedButton(
                    onPressed: details.onStepCancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: lightGray,
                      foregroundColor: darkGray,
                    ),
                    child: const Text('Back'),
                  ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: electricBlue,
                  ),
                  child: Text(
                    _currentStep == getSteps().length - 1 ? 'Submit & Pay ₹100' : 'Next →',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPersonalDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Apply for FASTag",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStepIndicator(1, "1"),
            _buildStepIndicator(2, "2"),
            _buildStepIndicator(3, "3"),
          ],
        ),
        const Divider(height: 30, color: Colors.white70),
        const Text(
          "Personal Details",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        const Text(
          "Full Name",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
        ),
        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter your full name",
            hintStyle: TextStyle(color: lightGray),
            border: const OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: electricBlue),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Mobile Number",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
        ),
        TextField(
          controller: _mobileController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter 10-digit mobile number",
            hintStyle: TextStyle(color: lightGray),
            border: const OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: electricBlue),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: electricBlue,
            ),
            child: const Text(
              "Send OTP",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Email Address",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
        ),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter your email",
            hintStyle: TextStyle(color: lightGray),
            border: const OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: electricBlue),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Vehicle Details",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        const Text(
          "Vehicle Number",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
        ),
        TextField(
          controller: _vehicleController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "e.g. DL01AB1234",
            hintStyle: TextStyle(color: lightGray),
            border: const OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: electricBlue),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Vehicle Type",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
        ),
        DropdownButtonFormField<String>(
          value: _selectedVehicleType,
          dropdownColor: darkGray,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Select Vehicle Type",
            hintStyle: TextStyle(color: lightGray),
            border: const OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: electricBlue),
            ),
          ),
          items: const [
            DropdownMenuItem(value: "Car", child: Text("Car")),
            DropdownMenuItem(value: "Motorcycle", child: Text("Motorcycle")),
            DropdownMenuItem(value: "Bus", child: Text("Bus")),
            DropdownMenuItem(value: "Truck", child: Text("Truck")),
          ],
          onChanged: (value) {
            setState(() {
              _selectedVehicleType = value;
            });
          },
        ),
        const SizedBox(height: 16),
        const Text(
          "Vehicle RC Document",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: BorderSide(color: electricBlue),
          ),
          child: const Column(
            children: [
              Icon(Icons.cloud_upload, size: 32, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                "Click to upload RC document",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              SizedBox(height: 4),
              Text(
                "PDF, JPG or PNG (Max 5MB)",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteApplicationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Complete Your Application",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        const Text(
          "ID Proof (Aadhaar/Driving License/Passport)",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: BorderSide(color: electricBlue),
          ),
          child: const Column(
            children: [
              Icon(Icons.cloud_upload, size: 32, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                "Click to upload ID proof",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              SizedBox(height: 4),
              Text(
                "PDF, JPG or PNG (Max 5MB)",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Divider(color: Colors.white70),
        const SizedBox(height: 16),
        const Text(
          "Delivery Address",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _addressController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter your complete address for FASTag delivery",
            hintStyle: TextStyle(color: lightGray),
            border: const OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: electricBlue),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Divider(color: Colors.white70),
        const SizedBox(height: 16),
        const Text(
          "Select Payment Method",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        _buildPaymentOption('Card', Icons.credit_card),
        _buildPaymentOption('Net Banking', Icons.account_balance),
        _buildPaymentOption('UPI', Icons.payment),
      ],
    );
  }

  Widget _buildPaymentOption(String method, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, color: electricBlue),
        title: Text(method, style: const TextStyle(color: Colors.white)),
        trailing: Radio<String>(
          value: method,
          groupValue: _paymentMethod,
          activeColor: electricBlue,
          onChanged: (value) {
            setState(() {
              _paymentMethod = value!;
            });
          },
        ),
        onTap: () {
          setState(() {
            _paymentMethod = method;
          });
        },
      ),
    );
  }

  Widget _buildStepIndicator(int stepNumber, String label) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: electricBlue,
          radius: 16,
          child: Text(label, style: const TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 4),
        Text("Step $stepNumber", style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
