import 'package:flutter/material.dart';
import 'package:flutter_user/functions/functions.dart';
import 'package:flutter_user/pages/DriverRequest/driver_request_form.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RequestList extends StatefulWidget {
  @override
  _RequestListState createState() => _RequestListState();
}

class _RequestListState extends State<RequestList> {
  List<Map<String, dynamic>> pendingRequests = [];
  List<Map<String, dynamic>> acceptedRequests = [];
  List<Map<String, dynamic>> confirmedRequests = [];
  List<Map<String, dynamic>> rejectedRequests = [];
  List<Map<String, dynamic>> betUpdateRequests = [];
  List<Map<String, dynamic>> completedTrips = [];
  bool isLoading = true;
  String? selectedStatus;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    selectedStatus = 'pending';
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    try {
      setState(() {
        isLoading = true;
      });

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${bearerToken[0].token}',
      };
      final body = json.encode({'user_id': userDetails['id'].toString()});

      final userRequestsResponse = await http.post(
        Uri.parse('https://admin.nxtdig.in/api/v1/request/getUserDriverRequests'),
        headers: headers,
        body: body,
      );

      if (userRequestsResponse.statusCode == 200) {
        final userRequestsData = (json.decode(userRequestsResponse.body)['data'] as List).cast<Map<String, dynamic>>();

        setState(() {
          pendingRequests = userRequestsData.where((req) => req['status'] == 'pending').toList();
          acceptedRequests = userRequestsData.where((req) => req['status'] == 'accepted').toList();
          confirmedRequests = userRequestsData.where((req) => req['status'] == 'confirmed').toList();
          rejectedRequests = userRequestsData.where((req) => req['status'] == 'rejected').toList();
          betUpdateRequests = userRequestsData.where((req) => req['status'] == 'Bet Update').toList();
          completedTrips = userRequestsData.where((req) => req['status'] == 'completed').toList();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateRequestStatus(Map<String, dynamic> request, String status) async {
    try {
      setState(() {
        _isUpdating = true;
      });

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${bearerToken[0].token}',
      };

      final body = {
        'id': request['id'].toString(),
        'status': status,
        'user_id': request['user_id'].toString(),
      };

      print('=== UPDATE REQUEST STATUS REQUEST ===');
      print('URL: https://admin.nxtdig.in/api/v1/request/respondToDriverRequest');
      print('Headers: $headers');
      print('Body: $body');

      final response = await http.post(
        Uri.parse('https://admin.nxtdig.in/api/v1/request/respondToDriverRequest'),
        headers: headers,
        body: json.encode(body),
      );

      print('=== UPDATE REQUEST STATUS RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('Response Headers: ${response.headers}');

      final message = response.statusCode == 200
          ? "Status updated successfully"
          : "Failed to update status";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      if (response.statusCode == 200) {
        await _fetchRequests();
      }
    } catch (e) {
      print('=== UPDATE REQUEST STATUS ERROR ===');
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating status")),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> completeDriverRequest({
    required int requestId,
    required int userId,
  }) async {
    try {
      setState(() {
        _isUpdating = true;
      });

      const url = 'https://admin.nxtdig.in/api/v1/request/completeDriverRequest';

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${bearerToken[0].token}',
      };

      final body = {
        'request_id': requestId,
        'user_id': userId,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      final message = response.statusCode == 200
          ? "Ride completed successfully"
          : "Failed to complete ride";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      if (response.statusCode == 200) {
        await _fetchRequests();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error completing ride")),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  void _showOptionsDialog(Map<String, dynamic> request, String status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Action"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == "accepted") ...[
              _buildOptionTile(
                icon: Icons.check_circle,
                color: Colors.green,
                label: "Confirm Ride",
                onTap: () {
                  Navigator.pop(context);
                  _updateRequestStatus(request, 'confirmed');
                },
              ),
              _buildOptionTile(
                icon: Icons.cancel,
                color: Colors.red,
                label: "Reject Ride",
                onTap: () {
                  Navigator.pop(context);
                  _updateRequestStatus(request, 'rejected');
                },
              ),
            ],
            if (status == "confirmed")
              _buildOptionTile(
                icon: Icons.done_all,
                color: Colors.green,
                label: "Complete Ride",
                onTap: () {
                  Navigator.pop(context);
                  completeDriverRequest(
                    requestId: request['id'],
                    userId: request['user_id'],
                  );
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Driver Requests", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(Icons.add_circle_rounded, color: Colors.red, size: 30),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DriverRequestScreen()),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusButton('Pending', 'pending'),
                      _buildStatusButton('Accepted', 'accepted'),
                      _buildStatusButton('Confirmed', 'confirmed'),
                      _buildStatusButton('Fare Update', 'bet_update'),
                      _buildStatusButton('Rejected', 'rejected'),
                      _buildStatusButton('Completed', 'completed'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchRequests,
                  child: _buildContentForStatus(),
                ),
              ),
            ],
          ),
          if (_isUpdating)
            Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(String label, String status) {
    final isSelected = selectedStatus == status;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFF0D47A1)),
          color: isSelected ? null : Colors.white,
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: isSelected ? Colors.white : Color(0xFF0D47A1),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          onPressed: () {
            setState(() {
              selectedStatus = status;
            });
          },
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),

    );
  }

  Widget _buildContentForStatus() {
    if (isLoading) return _buildShimmerLoader();

    final requests = selectedStatus == 'pending' ? pendingRequests
        : selectedStatus == 'accepted' ? acceptedRequests
        : selectedStatus == 'confirmed' ? confirmedRequests
        : selectedStatus == 'bet_update' ? betUpdateRequests
        : selectedStatus == 'rejected' ? rejectedRequests
        : selectedStatus == 'completed' ? completedTrips
        : [];

    if (requests.isEmpty) {
      return SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Text(
              selectedStatus == 'bet_update' ? "No fare update request" : "No ${selectedStatus} request",
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(top: 8),
      physics: AlwaysScrollableScrollPhysics(),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        return _buildRequestCard(requests[index], status: selectedStatus!);
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> data, {required String status}) {
    Color statusColor = Colors.grey;
    if (status == "pending") statusColor = Colors.orange;
    else if (status == "accepted") statusColor = Colors.blue;
    else if (status == "confirmed") statusColor = Colors.green;
    else if (status == "rejected" || status == "bet_update") statusColor = Colors.red;
    else if (status == "completed") statusColor = Colors.green;

    final endDate = DateTime.parse(data['end_date']);
    final today = DateTime.now();
    final isDateValid = endDate.isAfter(today) ||
        (endDate.year == today.year &&
            endDate.month == today.month &&
            endDate.day == today.day);
    final showStatusButton = isDateValid && (status == "accepted" || status == "confirmed");

    String formatDate(String date) {
      final parsedDate = DateTime.parse(date);
      return "${parsedDate.day} ${_monthName(parsedDate.month)} ${parsedDate.year}";
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.white,
      elevation: 0.4,
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Icon(Icons.directions_car, size: 18),
                SizedBox(width: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${data['vehicle_type']}", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    if (data['vehicle_number'] != null && data['vehicle_number'].toString().isNotEmpty)
                      Text("${data['vehicle_number']}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ]),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status == "bet_update" ? "REJECTED" : status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (status == "accepted" || status == "confirmed" || status == "bet_update") ...[
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        _showOptionsDialog(data, status == "bet_update" ? "accepted" : status);
                      },
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.more_vert, color: Colors.blue, size: 20),
                      ),
                    ),
                  ],
                ],
              ),
            ]),
            SizedBox(height: 8),
            if (data['from_location'] != null && data['from_location'].toString().isNotEmpty)
              Row(children: [
                Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                SizedBox(width: 4),
                Text("From: ${data['from_location']}", style: TextStyle(fontSize: 14)),
              ]),
            if (data['to_location'] != null && data['to_location'].toString().isNotEmpty)
              Row(children: [
                Icon(Icons.flag, size: 16, color: Colors.green),
                SizedBox(width: 4),
                Text("To: ${data['to_location']}", style: TextStyle(fontSize: 14)),
              ]),
            if (data['note'] != null && data['note'].toString().isNotEmpty) ...[
              SizedBox(height: 6),
              Row(children: [
                Icon(Icons.note, size: 16, color: Colors.blueGrey),
                SizedBox(width: 4),
                Expanded(child: Text("Requirement: ${data['note']}", style: TextStyle(fontSize: 13))),
              ]),
            ],
            if (data['night_stay'] == "true" || data['food_option'] == "true") ...[
              SizedBox(height: 6),
              Row(
                children: [
                  if (data['night_stay'] == "true")
                    Row(
                      children: [
                        Transform.scale(
                          scale: 0.7,
                          child: Checkbox(
                            value: true,
                            onChanged: null,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        Text("Night Stay", style: TextStyle(fontSize: 13)),
                        SizedBox(width: 10),
                      ],
                    ),
                  if (data['food_option'] == "true")
                    Row(
                      children: [
                        Transform.scale(
                          scale: 0.7,
                          child: Checkbox(
                            value: true,
                            onChanged: null,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        Text("Food Option", style: TextStyle(fontSize: 13)),
                      ],
                    ),
                ],
              ),
            ],
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Start: ${formatDate(data['start_date'])}", style: TextStyle(fontSize: 13, color: Colors.black87)),
                  Text("End: ${formatDate(data['end_date'])}", style: TextStyle(fontSize: 13, color: Colors.black87)),
                  if (status != "pending")
                    Text("₹${data['expected_fare']}", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        physics: AlwaysScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (_, __) => Card(
          margin: EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 120,
                      height: 20,
                      color: Colors.white,
                    ),
                    Container(
                      width: 80,
                      height: 20,
                      color: Colors.white,
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 16,
                  color: Colors.white,
                ),
                SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 16,
                  color: Colors.white,
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 16,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Container(
                      width: 60,
                      height: 16,
                      color: Colors.white,
                    ),
                    Spacer(),
                    Container(
                      width: 80,
                      height: 16,
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}