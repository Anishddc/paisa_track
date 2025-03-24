import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:paisa_track/core/constants/color_constants.dart';

class UpdateService {
  // TODO: Update these with your actual GitHub repository details
  static const String _githubUsername = 'Anishddc';
  static const String _githubRepo = 'paisa_track';
  
  static String get _githubApiUrl => 'https://api.github.com/repos/$_githubUsername/$_githubRepo/releases';
  static String get _githubReleaseUrl => 'https://github.com/$_githubUsername/$_githubRepo/releases';
  
  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      // First check internet connectivity
      try {
        final result = await InternetAddress.lookup('google.com');
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          if (context.mounted) {
            _showErrorDialog(context, 'No internet connection available. Please check your connection and try again.');
          }
          return;
        }
      } on SocketException catch (_) {
        if (context.mounted) {
          _showErrorDialog(context, 'No internet connection available. Please check your connection and try again.');
        }
        return;
      }

      // Get current app version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;
      
      // Get releases from GitHub with timeout and headers
      final response = await http.get(
        Uri.parse(_githubApiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'PaisaTrack-App',
        },
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final List<dynamic> releases = json.decode(response.body);
        
        if (releases.isEmpty) {
          if (context.mounted) {
            _showNoReleasesDialog(context);
          }
          return;
        }
        
        // Find the latest version including beta releases
        String? latestVersion;
        String? latestReleaseUrl;
        
        for (final release in releases) {
          final tagName = release['tag_name'].toString();
          final downloadUrl = release['html_url'].toString();
          
          // Skip if tag name is empty
          if (tagName.isEmpty) continue;
          
          // Remove 'v' prefix if present
          final version = tagName.startsWith('v') ? tagName.substring(1) : tagName;
          
          if (latestVersion == null || _compareVersions(version, latestVersion) > 0) {
            latestVersion = version;
            latestReleaseUrl = downloadUrl;
          }
        }
        
        if (latestVersion != null) {
          // Compare versions
          if (_compareVersions(latestVersion, currentVersion) > 0) {
            // Show update dialog
            if (context.mounted) {
              _showUpdateDialog(context, latestVersion, latestReleaseUrl!);
            }
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You are using the latest version'),
                backgroundColor: ColorConstants.successColor,
              ),
            );
          }
        }
      } else if (response.statusCode == 404) {
        debugPrint('No releases found in repository: $_githubUsername/$_githubRepo');
        if (context.mounted) {
          _showNoReleasesDialog(context);
        }
      } else {
        debugPrint('GitHub API response status: ${response.statusCode}');
        debugPrint('GitHub API response body: ${response.body}');
        if (context.mounted) {
          _showErrorDialog(
            context, 
            'Failed to check for updates (Status: ${response.statusCode}). Please try again later.'
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      if (context.mounted) {
        if (e is TimeoutException) {
          _showErrorDialog(context, 'Update check timed out. Please check your internet connection and try again.');
        } else if (e is SocketException) {
          _showErrorDialog(context, 'Network error. Please check your internet connection and try again.');
        } else {
          _showErrorDialog(context, 'Failed to check for updates: ${e.toString()}');
        }
      }
    }
  }
  
  static int _compareVersions(String v1, String v2) {
    try {
      // Handle beta versions
      final v1Parts = v1.split('-')[0].split('.').map(int.parse).toList();
      final v2Parts = v2.split('-')[0].split('.').map(int.parse).toList();
      
      // Ensure both lists have at least 3 elements
      while (v1Parts.length < 3) v1Parts.add(0);
      while (v2Parts.length < 3) v2Parts.add(0);
      
      for (int i = 0; i < 3; i++) {
        if (v1Parts[i] > v2Parts[i]) return 1;
        if (v1Parts[i] < v2Parts[i]) return -1;
      }
      
      // If versions are equal, check for beta/pre-release
      final v1IsBeta = v1.contains('-beta') || v1.contains('-alpha');
      final v2IsBeta = v2.contains('-beta') || v2.contains('-alpha');
      
      if (!v1IsBeta && v2IsBeta) return 1; // Non-beta is newer than beta
      if (v1IsBeta && !v2IsBeta) return -1; // Beta is older than non-beta
      
      return 0;
    } catch (e) {
      debugPrint('Error comparing versions: $e');
      return 0;
    }
  }
  
  static Future<void> _showUpdateDialog(BuildContext context, String latestVersion, String downloadUrl) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('New Update Available'),
          content: Text('A new version ($latestVersion) is available. Would you like to update now?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Later'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Update'),
              onPressed: () async {
                try {
                  if (await canLaunchUrl(Uri.parse(downloadUrl))) {
                    await launchUrl(Uri.parse(downloadUrl));
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
                        content: Text('Could not open update page: ${e.toString()}'),
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