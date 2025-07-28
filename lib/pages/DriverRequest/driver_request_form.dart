import 'package:flutter/material.dart';
import 'package:flutter_user/functions/functions.dart';
import 'package:flutter_user/pages/DriverRequest/request_history.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DriverRequestScreen extends StatefulWidget {
  @override
  _DriverRequestScreenState createState() => _DriverRequestScreenState();
}

class _DriverRequestScreenState extends State<DriverRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleTypeController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _fromLocationController = TextEditingController();
  final _toLocationController = TextEditingController();
  final _noteController = TextEditingController();
  final _vehicleNumberController = TextEditingController();

  bool _nightStay = false;
  bool _foodOption = false;
  bool _isLoading = false;

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final response = await sendDriverRequest(
        vehicleType: _vehicleTypeController.text,
        startDate: _selectedStartDate != null
            ? "${_selectedStartDate!.year}-${_selectedStartDate!.month.toString().padLeft(2, '0')}-${_selectedStartDate!.day.toString().padLeft(2, '0')}"
            : '',
        endDate: _selectedEndDate != null
            ? "${_selectedEndDate!.year}-${_selectedEndDate!.month.toString().padLeft(2, '0')}-${_selectedEndDate!.day.toString().padLeft(2, '0')}"
            : '',
        fromLocation: _fromLocationController.text,
        toLocation: _toLocationController.text,
        note: _noteController.text,
        vehicleNumber: _vehicleNumberController.text,
        nightStay: _nightStay,
        foodOption: _foodOption,
        userId: userDetails['id'].toString(),
      );

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['status'] == 'success'
              ? 'Request submitted successfully'
              : response['message'] ?? response['data']['message'] ?? 'An error occurred'),
          backgroundColor: response['status'] == 'success' ? Colors.green : Colors.red,
        ),
      );

      if (response['status'] == 'success') {
        Navigator.push (
            context,
            MaterialPageRoute(
                builder: (context) => RequestList()));
      }
    }
  }

  @override
  void dispose() {
    _vehicleTypeController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _fromLocationController.dispose();
    _toLocationController.dispose();
    _noteController.dispose();
    _vehicleNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Create Request", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(_vehicleTypeController, 'Vehicle Type', Icons.directions_car),
              SizedBox(height: 15),
              _buildDateField(_startDateController, 'Start Date', isStartDate: true),
              SizedBox(height: 15),
              _buildDateField(_endDateController, 'End Date', isStartDate: false),
              SizedBox(height: 15),
              _buildTextField(_fromLocationController, 'From Location', Icons.location_on),
              SizedBox(height: 15),
              _buildTextField(_toLocationController, 'To Location', Icons.location_on),
              SizedBox(height: 15),
              _buildTextField(_vehicleNumberController, 'Vehicle Number', Icons.confirmation_number),
              SizedBox(height: 15),
              _buildTextField(_noteController, 'Additional Notes', Icons.note, maxLines: 3),
              SizedBox(height: 15),
              SwitchListTile(
                title: Text('Night Stay Required'),
                value: _nightStay,
                onChanged: (value) => setState(() => _nightStay = value),
              ),
              SwitchListTile(
                title: Text('Food Option Required'),
                value: _foodOption,
                onChanged: (value) => setState(() => _foodOption = value),
              ),
              SizedBox(height: 25),
              Container(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 1.0,
                    ),
                  )
                      : const Text(
                    "Submit",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      validator: (value) => value!.isEmpty ? 'This field is required' : null,
      maxLines: maxLines,
    );
  }

  Widget _buildDateField(TextEditingController controller, String label, {required bool isStartDate}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.calendar_today),
      ),
      readOnly: true,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          controller.text = "${date.day} ${months[date.month - 1]} ${date.year}";
          if (isStartDate) {
            _selectedStartDate = date;
          } else {
            _selectedEndDate = date;
          }
        }
      },
      validator: (value) => value!.isEmpty ? 'This field is required' : null,
    );
  }
}

Future<Map<String, dynamic>> sendDriverRequest({
  required String vehicleType,
  required String startDate,
  required String endDate,
  required String fromLocation,
  required String toLocation,
  required String note,
  required String vehicleNumber,
  required bool nightStay,
  required bool foodOption,
  required String userId,
}) async {
  try {
    final url = 'https://admin.nxtdig.in/api/v1/request/sendDriverRequest';
    final headers = {
      'Authorization': 'Bearer ${bearerToken[0].token}',
      'Content-Type': 'application/json',
    };
    final body = {
      'vehicle_type': vehicleType,
      'start_date': startDate,
      'end_date': endDate,
      'from_location': fromLocation,
      'to_location': toLocation,
      'note': note,
      'vehicle_number': vehicleNumber,
      'night_stay': nightStay,
      'food_option': foodOption,
      'user_id': userId,
    };

    print('API URL: $url');
    print('Headers: $headers');
    print('Request Parameters: $body');

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

    final data = jsonDecode(response.body);

    return data['success'] == true
        ? {'status': 'success', 'data': data['data'], 'message': data['message']}
        : {'status': 'error', 'message': data['message']};
  } catch (e) {
    print('Error: $e');
    return {'status': 'error', 'message': e.toString()};
  }
}