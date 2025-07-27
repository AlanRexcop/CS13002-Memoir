// lib/screens/local_vault_browser_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoir/providers/local_vault_provider.dart';
import 'package:memoir/screens/local_person_detail_screen.dart';

class LocalVaultBrowserScreen extends ConsumerWidget {
  const LocalVaultBrowserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This provider now returns an AsyncValue<List<Person>>
    final localPersonsAsync = ref.watch(localVaultNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Vault Browser'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Local Vault',
            onPressed: () {
              ref.invalidate(localVaultNotifierProvider);
            },
          )
        ],
      ),
      body: localPersonsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error loading local vault:\n$err', textAlign: TextAlign.center),
          ),
        ),
        data: (persons) {
          if (persons.isEmpty) {
            return const Center(child: Text('No people found in your local vault.'));
          }

          return ListView.builder(
            itemCount: persons.length,
            itemBuilder: (context, index) {
              final person = persons[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.person_outline, size: 40),
                  title: Text(person.info.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${person.notes.length} associated notes'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to the new detail screen for the selected person
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LocalPersonDetailScreen(person: person),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}