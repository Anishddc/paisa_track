import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateService {
  // TODO: Update these with your actual GitHub repository details
  static const String _githubUsername = 'Anishddc';
  static const String _githubRepo = 'paisa_track';
  
  static String get _githubApiUrl => 'https://api.github.com/repos/$_githubUsername/$_githubRepo/releases';
  static String get _githubReleaseUrl => 'https://github.com/$_githubUsername/$_githubRepo/releases';
  
  // Cooldown period for update checks (24 hours)
  static const Duration _updateCheckCooldown = Duration(hours: 24);
  
  // Key for storing last update check time
  static const String _lastUpdateCheckKey = 'last_update_check_time';
  
  static Future<bool> shouldCheckForUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheckTime = DateTime.fromMillisecondsSinceEpoch(
      prefs.getInt(_lastUpdateCheckKey) ?? 0
    );
    
    final now = DateTime.now();
    return now.difference(lastCheckTime) > _updateCheckCooldown;
  }
  
  static Future<void> updateLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastUpdateCheckKey, DateTime.now().millisecondsSinceEpoch);
  }
  
  static Future<void> checkForUpdates(BuildContext context, {bool force = false}) async {
    try {
      debugPrint('Starting update check. Force=${force}');
      
      // Check if we should perform the update check
      if (!force && !await shouldCheckForUpdates()) {
        debugPrint('Skipping update check - cooldown period not elapsed');
        return;
      }

      // First check internet connectivity
      try {
        debugPrint('Checking internet connectivity...');
        final result = await InternetAddress.lookup('google.com');
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          debugPrint('No internet connection available');
          if (context.mounted) {
            _showErrorDialog(context, 'No internet connection available. Please check your connection and try again.');
          }
          return;
        }
        debugPrint('Internet connection available');
      } on SocketException catch (_) {
        debugPrint('Socket exception when checking internet connectivity');
        if (context.mounted) {
          _showErrorDialog(context, 'No internet connection available. Please check your connection and try again.');
        }
        return;
      }

      // Get current app version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;
      debugPrint('Current app version: $currentVersion');
      
      // Get releases from GitHub with timeout and headers
      debugPrint('Fetching releases from GitHub API: $_githubApiUrl');
      final response = await http.get(
        Uri.parse(_githubApiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'PaisaTrack-App',
        },
      ).timeout(const Duration(seconds: 15));
      
      debugPrint('GitHub API response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> releases = json.decode(response.body);
        debugPrint('Number of releases found: ${releases.length}');
        
        if (releases.isEmpty) {
          debugPrint('No releases found in the repository');
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
          final isPrerelease = release['prerelease'] ?? false;
          
          debugPrint('Processing release: tag=$tagName, prerelease=$isPrerelease, url=$downloadUrl');
          
          // Skip if tag name is empty
          if (tagName.isEmpty) {
            debugPrint('Skipping release with empty tag name');
            continue;
          }
          
          // Remove 'v' prefix if present
          final version = tagName.startsWith('v') ? tagName.substring(1) : tagName;
          debugPrint('Processed version string: $version');
          
          if (latestVersion == null || _compareVersions(version, latestVersion) > 0) {
            debugPrint('Found newer version: $version > $latestVersion');
            latestVersion = version;
            latestReleaseUrl = downloadUrl;
          } else {
            debugPrint('Not newer version: $version <= $latestVersion');
          }
        }
        
        if (latestVersion != null) {
          debugPrint('Latest version found: $latestVersion. Comparing with current: $currentVersion');
          // Compare versions
          final int comparisonResult = _compareVersions(latestVersion, currentVersion);
          debugPrint('Version comparison result: $comparisonResult (>0 means update available)');
          
          if (comparisonResult > 0) {
            // Show update dialog
            debugPrint('Update available: $latestVersion > $currentVersion');
            if (context.mounted) {
              _showUpdateDialog(context, latestVersion, latestReleaseUrl!);
            }
          } else if (context.mounted) {
            debugPrint('No update available: $latestVersion <= $currentVersion');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You are using the latest version'),
                backgroundColor: ColorConstants.successColor,
              ),
            );
          }
        } else if (context.mounted) {
          debugPrint('No valid release version found');
          _showNoReleasesDialog(context);
        }
        
        // Update last check time only if the check was successful
        await updateLastCheckTime();
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
      debugPrint('Comparing versions: v1=$v1, v2=$v2');
      
      // Check if either version contains beta or alpha
      final bool v1IsBeta = v1.contains('-beta') || v1.contains('-alpha');
      final bool v2IsBeta = v2.contains('-beta') || v2.contains('-alpha');
      
      // Split into version parts and beta/alpha parts
      final List<String> v1Split = v1.split('-');
      final List<String> v2Split = v2.split('-');
      
      // Get the version numbers (e.g., "1.0.0")
      final String v1Version = v1Split[0];
      final String v2Version = v2Split[0];
      
      // Parse version parts
      final v1Parts = v1Version.split('.').map(int.parse).toList();
      final v2Parts = v2Version.split('.').map(int.parse).toList();
      
      // Ensure both lists have at least 3 elements
      while (v1Parts.length < 3) v1Parts.add(0);
      while (v2Parts.length < 3) v2Parts.add(0);
      
      // Compare major.minor.patch versions
      for (int i = 0; i < 3; i++) {
        if (v1Parts[i] > v2Parts[i]) {
          debugPrint('v1 > v2 based on version parts at position $i: ${v1Parts[i]} > ${v2Parts[i]}');
          return 1; // v1 is newer
        }
        if (v1Parts[i] < v2Parts[i]) {
          debugPrint('v1 < v2 based on version parts at position $i: ${v1Parts[i]} < ${v2Parts[i]}');
          return -1; // v2 is newer
        }
      }
      
      // If we get here, the major.minor.patch versions are equal
      // Now handle beta/alpha versions

      // Non-beta is newer than beta
      if (!v1IsBeta && v2IsBeta) {
        debugPrint('v1 > v2 because v1 is not beta but v2 is beta');
        return 1;
      }
      
      // Beta is older than non-beta
      if (v1IsBeta && !v2IsBeta) {
        debugPrint('v1 < v2 because v1 is beta but v2 is not beta');
        return -1;
      }
      
      // If both are beta, compare beta numbers
      if (v1IsBeta && v2IsBeta) {
        // Extract beta numbers like "beta.2" -> 2
        try {
          int v1BetaNumber = 0;
          int v2BetaNumber = 0;
          
          if (v1Split.length > 1 && v1Split[1].startsWith('beta.')) {
            v1BetaNumber = int.parse(v1Split[1].substring(5));
          } else if (v1Split.length > 1 && v1Split[1].startsWith('beta')) {
            v1BetaNumber = int.parse(v1Split[1].substring(4));
          }
          
          if (v2Split.length > 1 && v2Split[1].startsWith('beta.')) {
            v2BetaNumber = int.parse(v2Split[1].substring(5));
          } else if (v2Split.length > 1 && v2Split[1].startsWith('beta')) {
            v2BetaNumber = int.parse(v2Split[1].substring(4));
          }
          
          debugPrint('Comparing beta numbers: v1Beta=$v1BetaNumber, v2Beta=$v2BetaNumber');
          
          if (v1BetaNumber > v2BetaNumber) {
            debugPrint('v1 > v2 based on beta numbers: $v1BetaNumber > $v2BetaNumber');
            return 1; // v1 is newer beta
          }
          if (v1BetaNumber < v2BetaNumber) {
            debugPrint('v1 < v2 based on beta numbers: $v1BetaNumber < $v2BetaNumber');
            return -1; // v2 is newer beta
          }
        } catch (e) {
          debugPrint('Error comparing beta numbers: $e');
        }
      }
      
      // If we get here, versions are equal
      debugPrint('Versions are equal');
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
                  final Uri url = Uri.parse(downloadUrl);
                  if (!await launchUrl(
                    url,
                    mode: LaunchMode.externalApplication,
                    webOnlyWindowName: '_blank',
                  )) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Could not open browser. Please visit the releases page manually.'),
                          backgroundColor: ColorConstants.errorColor,
                          duration: const Duration(seconds: 5),
                          action: SnackBarAction(
                            label: 'Copy URL',
                            textColor: Colors.white,
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: downloadUrl));
                            },
                          ),
                        ),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not open update page: ${e.toString()}'),
                        backgroundColor: ColorConstants.errorColor,
                        duration: const Duration(seconds: 5),
                        action: SnackBarAction(
                          label: 'Copy URL',
                          textColor: Colors.white,
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: downloadUrl));
                          },
                        ),
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
                  final Uri url = Uri.parse(_githubReleaseUrl);
                  if (!await launchUrl(
                    url,
                    mode: LaunchMode.externalApplication,
                    webOnlyWindowName: '_blank',
                  )) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Could not open browser. Please visit the repository manually.'),
                          backgroundColor: ColorConstants.errorColor,
                          duration: const Duration(seconds: 5),
                          action: SnackBarAction(
                            label: 'Copy URL',
                            textColor: Colors.white,
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _githubReleaseUrl));
                            },
                          ),
                        ),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not open repository: ${e.toString()}'),
                        backgroundColor: ColorConstants.errorColor,
                        duration: const Duration(seconds: 5),
                        action: SnackBarAction(
                          label: 'Copy URL',
                          textColor: Colors.white,
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _githubReleaseUrl));
                          },
                        ),
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