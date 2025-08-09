import 'package:flutter/material.dart';
import '../domain/connectivity_validator.dart';

class OfflineStatusScreen extends StatelessWidget {
  const OfflineStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final offlineFunctionality = ConnectivityValidator.validateOfflineFunctionality();
    final noNetworkRequests = ConnectivityValidator.validateNoNetworkRequests();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Mode Status'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: noNetworkRequests ? Colors.green[50] : Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      noNetworkRequests ? Icons.check_circle : Icons.error,
                      color: noNetworkRequests ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            noNetworkRequests 
                              ? 'Offline Mode: Active'
                              : 'Offline Mode: Issues Detected',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: noNetworkRequests ? Colors.green : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            noNetworkRequests
                              ? 'App works completely without internet'
                              : 'Some features may require network access',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Feature Availability (Offline)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            
            const SizedBox(height: 16),
            
            Expanded(
              child: ListView(
                children: offlineFunctionality.entries.map((entry) {
                  final featureName = entry.key.replaceAll('_', ' ').toUpperCase();
                  final isAvailable = entry.value;
                  
                  return ListTile(
                    leading: Icon(
                      isAvailable ? Icons.check_circle : Icons.cancel,
                      color: isAvailable ? Colors.green : Colors.red,
                    ),
                    title: Text(featureName),
                    subtitle: Text(
                      isAvailable 
                        ? 'Works offline' 
                        : 'Requires internet connection',
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            const Card(
              color: Color(0xFFF3F4F6),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privacy Notice',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This app is designed to work completely offline. No personal data is transmitted to external servers without your explicit permission.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}