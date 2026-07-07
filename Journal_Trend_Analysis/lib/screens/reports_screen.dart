import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/report_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user != null) {
        context.read<ReportProvider>().loadReports(auth.user!.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('My Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Generate Report',
            onPressed: () => _showGenerateDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final auth = context.read<AuthProvider>();
              if (auth.user != null) {
                context.read<ReportProvider>().loadReports(auth.user!.userId);
              }
            },
          ),
        ],
      ),
      body: Consumer<ReportProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text(provider.error!, style: TextStyle(color: colorScheme.error)),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      final auth = context.read<AuthProvider>();
                      if (auth.user != null) {
                        provider.loadReports(auth.user!.userId);
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined, size: 64, color: colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'No reports yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colorScheme.outline),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _showGenerateDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Generate Report'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.reports.length,
            itemBuilder: (context, index) {
              final report = provider.reports[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(Icons.picture_as_pdf, color: colorScheme.primary),
                  ),
                  title: Text(report.reportType ?? 'Trend Report'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (report.createdAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Created: ${_formatDate(report.createdAt!)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                  trailing: report.fileUrl != null
                      ? IconButton(
                          icon: Icon(Icons.download, color: colorScheme.primary),
                          onPressed: () => _openUrl(report.fileUrl!),
                        )
                      : const Icon(Icons.hourglass_empty, size: 20),
                  onTap: report.fileUrl != null
                      ? () => _openUrl(report.fileUrl!)
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showGenerateDialog(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    final queryController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var isGenerating = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Generate Report'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter a topic to search — the backend will compute the '
                  'publication trend, top authors and top journals for '
                  'matching papers and generate a PDF.',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: queryController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Topic / search term',
                    hintText: 'e.g. Artificial Intelligence',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                if (isGenerating) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isGenerating ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isGenerating
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isGenerating = true);
                      try {
                        final provider = context.read<ReportProvider>();
                        await provider.generateReport(
                          userId: auth.user!.userId,
                          query: queryController.text.trim(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (_) {
                        setDialogState(() => isGenerating = false);
                      }
                    },
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report generated!')),
      );
    } else if (result != true && mounted) {
      final error = context.read<ReportProvider>().error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate report: $error')),
        );
      }
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
