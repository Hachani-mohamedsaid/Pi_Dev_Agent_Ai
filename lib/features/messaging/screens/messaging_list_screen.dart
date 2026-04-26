import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../injection_container.dart';
import '../models/conversation_model.dart';
import '../providers/messaging_provider.dart';
import '../widgets/conversation_tile.dart';

class MessagingListScreen extends StatefulWidget {
  const MessagingListScreen({super.key});

  @override
  State<MessagingListScreen> createState() => _MessagingListScreenState();
}

class _MessagingListScreenState extends State<MessagingListScreen> {
  String _filter = 'all'; // all|direct|group

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(() {
      if (!mounted) return;
      context.read<MessagingProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.primaryDark : const Color(0xFFF3F8FC);
    final meIdFuture = InjectionContainer.instance.authLocalDataSource.getUserId();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: bg,
        foregroundColor: isDark ? Colors.white : const Color(0xFF12263A),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showNewDmSheet(context),
            icon: const Icon(Icons.edit),
            tooltip: 'New message',
          ),
        ],
      ),
      body: FutureBuilder<String?>(
        future: meIdFuture,
        builder: (context, snap) {
          final meId = snap.data ?? '';
          return Consumer<MessagingProvider>(
            builder: (context, p, _) {
              final list = p.conversations.where((c) {
                if (_filter == 'direct') return c.type == 'direct';
                if (_filter == 'group') return c.type == 'group';
                return true;
              }).toList();

              if (p.isLoading && list.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.cyan500),
                );
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: _FilterRow(
                      value: _filter,
                      onChanged: (v) => setState(() => _filter = v),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final conv = list[i];
                        return ConversationTile(
                          conversation: conv,
                          meId: meId,
                          onTap: () {
                            context.push(
                              '/messaging/${conv.id}',
                              extra: conv,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showNewDmSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NewDmSheet(),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(String v, String label) {
      final active = value == v;
      return Expanded(
        child: InkWell(
          onTap: () => onChanged(v),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: active
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.cyan500, AppColors.blue500],
                    )
                  : null,
              color: active ? null : AppColors.primaryDark.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.cyan500.withValues(alpha: active ? 0.0 : 0.18),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : AppColors.textCyan200.withValues(alpha: 0.8),
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('all', 'All'),
        const SizedBox(width: 10),
        chip('direct', 'Direct'),
        const SizedBox(width: 10),
        chip('group', 'Groups'),
      ],
    );
  }
}

class _NewDmSheet extends StatefulWidget {
  const _NewDmSheet();

  @override
  State<_NewDmSheet> createState() => _NewDmSheetState();
}

class _NewDmSheetState extends State<_NewDmSheet> {
  final _controller = TextEditingController();
  List<ParticipantModel> _results = const [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final q = v.trim();
      if (q.length < 2) {
        if (mounted) setState(() => _results = const []);
        return;
      }
      setState(() => _loading = true);
      final res = await context.read<MessagingProvider>().searchUsers(q);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _results = res;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primaryDarker,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'New message',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                onChanged: _onChanged,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search users…',
                  hintStyle: TextStyle(color: AppColors.textCyan200.withValues(alpha: 0.55)),
                  filled: true,
                  fillColor: AppColors.primaryDark.withValues(alpha: 0.6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.cyan500.withValues(alpha: 0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.cyan500.withValues(alpha: 0.2)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator(color: AppColors.cyan500)),
                ),
              if (!_loading)
                ..._results.map((u) {
                  return ListTile(
                    onTap: () async {
                      final conv = await context.read<MessagingProvider>().createDirect(u.id);
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      if (conv != null) {
                        context.push('/messaging/${conv.id}', extra: conv);
                      }
                    },
                    leading: CircleAvatar(
                      backgroundColor: AppColors.cyan500.withValues(alpha: 0.18),
                      backgroundImage: (u.avatarUrl != null && u.avatarUrl!.isNotEmpty)
                          ? NetworkImage(u.avatarUrl!)
                          : null,
                      child: (u.avatarUrl == null || u.avatarUrl!.isEmpty)
                          ? Text(
                              u.name.isNotEmpty ? u.name.substring(0, 1).toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                            )
                          : null,
                    ),
                    title: Text(u.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      u.role ?? '',
                      style: TextStyle(color: AppColors.textCyan200.withValues(alpha: 0.6)),
                    ),
                  );
                }),
              const SizedBox(height: 6),
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.cyan400,
                    side: const BorderSide(color: AppColors.cyan500, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

