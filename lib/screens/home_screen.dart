import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/dev_tools.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _input = TextEditingController(text: '{"name":"devhub","tools":9}');
  DevTool _tool = DevTool.jsonFormat;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = runTool(_tool, _input.text);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Devhub')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final t in DevTool.values)
                ChoiceChip(
                  label: Text(t.label),
                  selected: _tool == t,
                  onSelected: (_) => setState(() => _tool = t),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('tool-input'),
            controller: _input,
            minLines: 3,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: 'Input',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Output', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              IconButton(
                tooltip: 'Copy output',
                icon: const Icon(Icons.copy),
                onPressed: result.isOk
                    ? () {
                        Clipboard.setData(ClipboardData(text: result.output));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied')),
                        );
                      }
                    : null,
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Semantics(
              liveRegion: true,
              label: result.isOk ? 'Output' : 'Error',
              child: SelectableText(
                result.isOk ? result.output : result.error!,
                key: const Key('tool-output'),
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: result.isOk ? null : colors.error,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
