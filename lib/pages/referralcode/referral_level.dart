import 'package:flutter/material.dart';
import 'package:flutter_user/functions/functions.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReferralLevelScreen extends StatefulWidget {
  @override
  _ReferralLevelScreenState createState() => _ReferralLevelScreenState();
}

class _ReferralLevelScreenState extends State<ReferralLevelScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  Map<String, dynamic> _referralData = {};
  String _selectedLevel = 'Level 1';

  Future<void> _fetchReferralLevels() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('https://admin.nxtdig.in/api/v1/request/getUserReferralTree');
      final headers = {
        'Authorization': 'Bearer ${bearerToken[0].token}'
      };
      final levelNumber = int.parse(_selectedLevel.split(' ')[1]);
      final body = {
        'user_id': userDetails['id'].toString(),
        'level': levelNumber.toString(),
      };

      print('user_id: ${body['user_id']}');
      print('level: ${body['level']}');

      final response = await http.post(url, headers: headers, body: body);
      final data = json.decode(response.body);
      setState(() {
        _referralData = data;
      });
      if (data['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to fetch referral data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchReferralLevels();
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
        title: Text("Referral List", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButton<String>(
                  value: _selectedLevel,
                  isExpanded: true,
                  underline: SizedBox(),
                  icon: Icon(Icons.arrow_drop_down),
                  dropdownColor: Colors.white,
                  items: List.generate(10, (index) => 'Level ${index + 1}')
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedLevel = newValue!;
                      _fetchReferralLevels();
                    });
                  },
                ),
              ),
              SizedBox(height: 20),
              _isLoading
                  ? Container(
                height: 200,
                alignment: Alignment.center,
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(),
                ),
              )
                  : _buildSelectedLevelData(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedLevelData() {
    if (_referralData.isEmpty || _referralData['data'] == null) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.5,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 30, color: Colors.grey[400]),
            SizedBox(height: 8),
            Text('No data available',
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
      );
    }

    final levelNumber = int.parse(_selectedLevel.split(' ')[1]);
    dynamic levelData;

    if (_referralData['data'] is List) {
      final levelDataList = _referralData['data'] as List;
      levelData = levelDataList.firstWhere(
            (data) => data['level'] == levelNumber,
        orElse: () => null,
      );
    } else if (_referralData['data'] is Map) {
      final dataMap = _referralData['data'] as Map;
      if (dataMap['level'] == levelNumber) {
        levelData = dataMap;
      }
    }

    if (levelData == null || levelData['users'] == null || (levelData['users'] as List).isEmpty) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.5,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off, size: 30, color: Colors.grey[400]),
            SizedBox(height: 8),
            Text('No users found for this level',
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
      );
    }

    final users = levelData['users'] as List;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < users.length; i++)
          Container(
            margin: EdgeInsets.only(bottom: i == users.length - 1 ? 40 : 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.blue[700]),
                      SizedBox(width: 8),
                      Text(users[i]['name'] ?? 'N/A',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.email, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(users[i]['email'] ?? 'N/A',
                          style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.code, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(users[i]['refferal_code'] ?? 'N/A',
                          style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                    ],
                  ),
                  if (users[i]['referrer'] != null) ...[
                    SizedBox(height: 4),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}