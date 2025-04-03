import 'package:flutter/material.dart';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:paisa_track/data/services/update_service.dart';
import 'package:paisa_track/presentation/widgets/common/custom_app_bar.dart';
import 'package:paisa_track/presentation/widgets/settings_section.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateSettingsScreen extends StatefulWidget {
  const UpdateSettingsScreen({Key? key}) : super(key: key);

  @override
  State<UpdateSettingsScreen> createState() => _UpdateSettingsScreenState();
}

class _UpdateSettingsScreenState extends State<UpdateSettingsScreen> {
  bool _isLoading = true;
  String _currentVersion = '';
  String _githubUsername = '';
  String _githubRepo = '';
  bool _updatesEnabled = true;
  bool _isVerifyingRepo = false;
  String _statusMessage = '';
  bool _showStatusMessage = false;
  bool _isCheckingForUpdates = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get app version
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version;

      // Get GitHub details
      _githubUsername = await UpdateService.getGithubUsername();
      _githubRepo = await UpdateService.getGithubRepo();
      
      // Get update settings
      _updatesEnabled = await UpdateService.areUpdateChecksEnabled();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error loading settings: $e';
        _showStatusMessage = true;
      });
    }
  }

  Future<void> _verifyRepository() async {
    final usernameController = TextEditingController(text: _githubUsername);
    final repoController = TextEditingController(text: _githubRepo);
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('GitHub Repository Settings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configure the GitHub repository to use for update checks.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'GitHub Username',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Anishddc',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: repoController,
                decoration: const InputDecoration(
                  labelText: 'Repository Name',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., paisa_track',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'The app will look for releases in:\nhttps://github.com/[username]/[repo]/releases',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Verify'),
            onPressed: () async {
              final newUsername = usernameController.text.trim();
              final newRepo = repoController.text.trim();
              
              if (newUsername.isEmpty || newRepo.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Username and repository name cannot be empty'),
                    backgroundColor: ColorConstants.errorColor,
                  ),
                );
                return;
              }
              
              setState(() {
                _isVerifyingRepo = true;
              });
              
              // Save the new values
              await UpdateService.saveGithubDetails(newUsername, newRepo);
              
              // Update local variables
              _githubUsername = newUsername;
              _githubRepo = newRepo;
              
              // Verify the repository
              final isValid = await UpdateService.verifyGithubRepository();
              
              setState(() {
                _isVerifyingRepo = false;
              });
              
              if (context.mounted) {
                if (isValid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Repository verified successfully'),
                      backgroundColor: ColorConstants.successColor,
                    ),
                  );
                  Navigator.of(context).pop();
                  
                  setState(() {
                    _statusMessage = 'Repository verified successfully';
                    _showStatusMessage = true;
                  });
                  
                  // Refresh the UI
                  setState(() {});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Repository could not be verified. Please check the details and try again.'),
                      backgroundColor: ColorConstants.errorColor,
                    ),
                  );
                  
                  setState(() {
                    _statusMessage = 'Repository verification failed. Please check the details.';
                    _showStatusMessage = true;
                  });
                }
              }
            },
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () async {
              final newUsername = usernameController.text.trim();
              final newRepo = repoController.text.trim();
              
              if (newUsername.isEmpty || newRepo.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Username and repository name cannot be empty'),
                    backgroundColor: ColorConstants.errorColor,
                  ),
                );
                return;
              }
              
              // Save the new values
              await UpdateService.saveGithubDetails(newUsername, newRepo);
              
              // Update local variables
              setState(() {
                _githubUsername = newUsername;
                _githubRepo = newRepo;
              });
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('GitHub repository settings saved'),
                    backgroundColor: ColorConstants.successColor,
                  ),
                );
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingForUpdates = true;
      _showStatusMessage = false;
    });

    try {
      await UpdateService.checkForUpdates(context, force: true);
      setState(() {
        _isCheckingForUpdates = false;
      });
    } catch (e) {
      setState(() {
        _isCheckingForUpdates = false;
        _statusMessage = 'Error checking for updates: $e';
        _showStatusMessage = true;
      });
    }
  }

  Future<void> _openGithubReleases() async {
    final url = await UpdateService.getGithubReleaseUrl();
    final Uri uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open URL: $url'),
            backgroundColor: ColorConstants.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Update Settings',
        showBackButton: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadSettings,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_showStatusMessage)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: _statusMessage.contains('Error') || _statusMessage.contains('failed')
                              ? ColorConstants.errorColor.withOpacity(0.1)
                              : ColorConstants.successColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                            color: _statusMessage.contains('Error') || _statusMessage.contains('failed')
                                ? ColorConstants.errorColor
                                : ColorConstants.successColor,
                          ),
                        ),
                      ),
                    
                    // Current version info
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'App Information',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            ListTile(
                              title: const Text('Current Version'),
                              subtitle: Text(_currentVersion),
                              leading: Icon(
                                Icons.tag,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Update settings
                    SettingsSection(
                      title: 'Update Configuration',
                      children: [
                        SwitchListTile(
                          title: const Text('Automatic Update Checks'),
                          subtitle: const Text('Check for updates when app starts'),
                          value: _updatesEnabled,
                          onChanged: (value) async {
                            await UpdateService.setUpdateChecksEnabled(value);
                            setState(() {
                              _updatesEnabled = value;
                            });
                            
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    value 
                                      ? 'Automatic updates enabled' 
                                      : 'Automatic updates disabled'
                                  ),
                                  backgroundColor: ColorConstants.successColor,
                                ),
                              );
                            }
                          },
                          secondary: Icon(
                            Icons.sync,
                            color: colorScheme.primary,
                          ),
                        ),
                        
                        ListTile(
                          title: const Text('GitHub Repository'),
                          subtitle: Text('$_githubUsername/$_githubRepo'),
                          trailing: const Icon(Icons.edit),
                          leading: Icon(
                            Icons.cloud,
                            color: colorScheme.primary,
                          ),
                          onTap: _verifyRepository,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Actions
                    SettingsSection(
                      title: 'Update Actions',
                      children: [
                        ListTile(
                          title: const Text('Check for Updates Now'),
                          subtitle: const Text('Force check for new version'),
                          trailing: _isCheckingForUpdates 
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.arrow_forward_ios, size: 16),
                          leading: Icon(
                            Icons.update,
                            color: colorScheme.primary,
                          ),
                          onTap: _isCheckingForUpdates ? null : _checkForUpdates,
                        ),
                        
                        ListTile(
                          title: const Text('View Release Page'),
                          subtitle: const Text('Open GitHub releases in browser'),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          leading: Icon(
                            Icons.open_in_browser,
                            color: colorScheme.primary,
                          ),
                          onTap: _openGithubReleases,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Troubleshooting
                    if (_showStatusMessage)
                      SettingsSection(
                        title: 'Troubleshooting',
                        children: [
                          ListTile(
                            title: const Text('Clear Update Message'),
                            subtitle: const Text('Hide the status message above'),
                            trailing: const Icon(Icons.clear),
                            leading: Icon(
                              Icons.message,
                              color: colorScheme.primary,
                            ),
                            onTap: () {
                              setState(() {
                                _showStatusMessage = false;
                              });
                            },
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