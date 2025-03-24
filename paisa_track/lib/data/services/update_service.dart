import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateService {
  // TODO: Update these with your actual GitHub repository details
  static const String _githubUsername = 'Anishddc';
  static const String _githubRepo = 'paisa_track';
  
  static String get _githubApiUrl => 'https://api.github.com/repos/$_githubUsername/$_githubRepo/releases';
  static String get _githubReleaseUrl => 'https://github.com/$_githubUsername/$_githubRepo/releases';
  
  static const Duration _timeout = Duration(seconds: 10);
  static const String _lastCheckKey = 'last_update_check';

  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      // Check if we should perform the update check
      if (!await _shouldCheckForUpdates()) {
        return;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = packageInfo.buildNumber;

      final response = await http.get(Uri.parse(_githubApiUrl))
          .timeout(_timeout, onTimeout: () {
        throw TimeoutException('Update check timed out');
      });

      if (response.statusCode == 200) {
        final List<dynamic> releases = json.decode(response.body);
        if (releases.isEmpty) {
          return;
        }

        // Find the latest release (including beta releases)
        final latestRelease = releases.first;
        final latestVersion = latestRelease['tag_name'].toString().replaceAll('v', '');
        final latestUrl = latestRelease['html_url'];

        // Compare versions
        if (_compareVersions(latestVersion, currentVersion) > 0) {
          if (context.mounted) {
            _showUpdateDialog(context, latestUrl);
          }
        }
      } else if (response.statusCode == 404) {
        // No releases found, this is normal for new repositories
        return;
      }
    } catch (e) {
      // Log the error but don't show it to the user
      print('Update check failed: $e');
    } finally {
      // Save the last check time regardless of success or failure
      await _saveLastCheckTime();
    }
  }

  static Future<bool> _shouldCheckForUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = DateTime.fromMillisecondsSinceEpoch(
      prefs.getInt(_lastCheckKey) ?? 0
    );
    final now = DateTime.now();
    
    // Check once per day
    return now.difference(lastCheck).inDays >= 1;
  }

  static Future<void> _saveLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);
  }

  static int _compareVersions(String v1, String v2) {
    final v1Parts = v1.split('.');
    final v2Parts = v2.split('.');
    
    for (int i = 0; i < 3; i++) {
      final v1Num = int.parse(v1Parts[i]);
      final v2Num = int.parse(v2Parts[i]);
      
      if (v1Num > v2Num) return 1;
      if (v1Num < v2Num) return -1;
    }
    
    return 0;
  }

  static Future<void> _showUpdateDialog(BuildContext context, String url) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Available'),
          content: const Text('A new version of Paisa Track is available. Would you like to update now?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url));
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update Now'),
            ),
          ],
        );
      },
    );
  }

  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Check Failed'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static void _showNoReleasesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('No Updates Available'),
          content: const Text('No releases have been published yet. Check back later for updates.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('View Repository'),
              onPressed: () async {
                try {
                  if (await canLaunchUrl(Uri.parse(_githubReleaseUrl))) {
                    await launchUrl(Uri.parse(_githubReleaseUrl));
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  } else {
                    throw Exception('Could not launch URL');
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not open repository: ${e.toString()}'),
                        backgroundColor: ColorConstants.errorColor,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
} 