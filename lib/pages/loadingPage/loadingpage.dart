import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../styles/styles.dart';
import '../../functions/functions.dart';
import 'package:http/http.dart' as http;
import '../../widgets/widgets.dart';
import '../login/login.dart';
import '../noInternet/noInternet.dart';
import '../onTripPage/booking_confirmation.dart';
import '../onTripPage/invoice.dart';
import '../onTripPage/map_page.dart';
import 'loading.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  String dot = '.';
  bool updateAvailable = false;
  dynamic _package;
  dynamic _version;
  bool _error = false;
  bool _isLoading = false;
  bool _prefsInitialized = false;
  static const String appVersion = '1.3';

  @override
  void initState() {
    choosenLanguage = 'en';
    languageDirection = 'ltr';
    checkVersion();
    super.initState();
  }

  Future<void> checkVersion() async {
    try {
      final response = await http.get(Uri.parse('https://admin.nxtdig.in/api/v1/version'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final apiVersion = data['data']['app_version'].toString();
        if (apiVersion != appVersion) {
          setState(() => updateAvailable = true);
          _showUpdateDialog();
          return;
        }
      }
      await _initializeApp();
    } catch (e) {
      await _initializeApp();
    }
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.system_update_alt,
                size: 48,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                'New update detected',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please update to the latest version to continue using the app',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        side: const BorderSide(color: Colors.blue),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        SystemNavigator.pop();
                      },
                      child: const Text(
                        'CANCEL',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: () {
                        openBrowser('https://play.google.com/store/apps/details?id=com.ondemand.user&pcampaignid=web_share');
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'DOWNLOAD',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _initializeApp() async {
    try {
      pref = await SharedPreferences.getInstance();
      await pref.setString('languageDirection', languageDirection);
      await pref.setString('choosenLanguage', choosenLanguage);
      setState(() => _prefsInitialized = true);

      await getemailmodule();
      await getLandingImages();
      await checkVersionAndNavigate();
    } catch (e) {
      setState(() => _error = true);
    }
  }

  void navigate1() {
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => BookingConfirmation()));
  }

  void naviagteridewithoutdestini() {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => BookingConfirmation(
              type: 2,
            )));
  }

  void naviagterental() {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => BookingConfirmation(
              type: 1,
            )));
  }

  Future<void> navigate() async {
    if (userRequestData.isNotEmpty && userRequestData['is_completed'] == 1) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Invoice()),
              (route) => false);
    } else if (userDetails['metaRequest'] != null) {
      addressList.clear();
      userRequestData = userDetails['metaRequest']['data'];
      addressList.add(AddressList(
          id: '1',
          type: 'pickup',
          address: userRequestData['pick_address'],
          pickup: true,
          latlng:
          LatLng(userRequestData['pick_lat'], userRequestData['pick_lng']),
          name: userDetails['name'],
          number: userDetails['mobile']));
      if (userRequestData['requestStops']['data'].isNotEmpty) {
        for (var i = 0;
        i < userRequestData['requestStops']['data'].length;
        i++) {
          addressList.add(AddressList(
              id: userRequestData['requestStops']['data'][i]['id'].toString(),
              type: 'drop',
              address: userRequestData['requestStops']['data'][i]['address'],
              latlng: LatLng(
                  userRequestData['requestStops']['data'][i]['latitude'],
                  userRequestData['requestStops']['data'][i]['longitude']),
              name: '',
              number: '',
              instructions: null,
              pickup: false));
        }
      }

      if (userRequestData['drop_address'] != null &&
          userRequestData['requestStops']['data'].isEmpty) {
        addressList.add(AddressList(
            id: '2',
            type: 'drop',
            pickup: false,
            address: userRequestData['drop_address'],
            latlng: LatLng(
                userRequestData['drop_lat'], userRequestData['drop_lng'])));
      }

      ismulitipleride = true;
      var val = await getUserDetails(id: userRequestData['id']);

      if (val == true) {
        setState(() {
          _isLoading = false;
        });
        if (userRequestData['is_rental'] == true) {
          naviagterental();
        } else if (userRequestData['is_rental'] == false &&
            userRequestData['drop_address'] == null) {
          naviagteridewithoutdestini();
        } else {
          navigate1();
        }
      }
    } else {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Maps()),
              (route) => false);
    }
  }

  Future<void> checkVersionAndNavigate() async {
    if (!_prefsInitialized) return;

    try {
      _package = await PackageInfo.fromPlatform();
      _version = await FirebaseDatabase.instance
          .ref()
          .child(platform == TargetPlatform.android
          ? 'user_android_version'
          : 'user_ios_version')
          .get();

      if (_version.value != null) {
        final version = _version.value.toString().split('.');
        final package = _package.version.toString().split('.');

        for (var i = 0; i < version.length || i < package.length; i++) {
          if (i < version.length && i < package.length) {
            if (int.parse(package[i]) < int.parse(version[i])) {
              setState(() => updateAvailable = true);
              return;
            } else if (int.parse(package[i]) > int.parse(version[i])) {
              break;
            }
          } else if (i < version.length && i >= package.length) {
            setState(() => updateAvailable = true);
            return;
          }
        }
      }

      await getDetailsOfDevice();
      if (internet == true) {
        final val = await getLocalData();

        if (val == '3') {
          await navigate();
        } else {
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Login()),
            );
          });
        }
      }
    } catch (e) {
      if (internet == true && _error == false) {
        setState(() => _error = true);
        await checkVersionAndNavigate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Material(
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              height: media.height * 1,
              width: media.width * 1,
              decoration: const BoxDecoration(
                color:  Color(0xffffffff),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(media.width * 0.01),
                    width: media.width * 0.5,
                    height: media.width * 0.6,
                    decoration: const BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage('assets/images/logo.png'),
                            fit: BoxFit.contain)),
                  ),
                  SizedBox(height: media.width * 0.01),
                  const Center(
                    child: Text(
                      'Onecall',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const Center(
                    child: Text(
                      'Highlighting ease and simplicity',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_isLoading && internet == true)
              const Positioned(top: 0, child: Loading()),

            if (internet == false)
              Positioned(
                  top: 0,
                  child: NoInternet(
                    onTap: () {
                      setState(() {
                        internetTrue();
                        checkVersionAndNavigate();
                      });
                    },
                  )),
          ],
        ),
      ),
    );
  }
}

