import 'package:document_companion/local_database/models/tag_model.dart';
import 'package:document_companion/modules/home/bloc/image_bloc.dart';
import 'package:document_companion/modules/home/bloc/tag_bloc.dart';
import 'package:document_companion/modules/home/models/date_filter_model.dart';
import 'package:flutter/material.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  DateFilter? _selectedFilter;
  final Set<String> _selectedTagIds = {};

  @override
  void initState() {
    super.initState();
    _selectedFilter = imageBloc.currentDateFilter;
    _selectedTagIds.addAll(imageBloc.selectedTagIds);
    tagBloc.fetchTags();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter by Date',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (_selectedFilter?.isActive == true ||
                      _selectedTagIds.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedFilter = DateFilter.all();
                          _selectedTagIds.clear();
                        });
                        imageBloc.clearDateFilter();
                        imageBloc.clearTagFilter();
                        Navigator.pop(context);
                      },
                      child: const Text('Clear All'),
                    ),
                ],
              ),
            ),
            const Divider(),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Date Filter',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _FilterOption(
                    title: 'All Documents',
                    icon: Icons.all_inclusive_rounded,
                    isSelected: _selectedFilter?.type == DateFilterType.all,
                    onTap: () {
                      setState(() {
                        _selectedFilter = DateFilter.all();
                      });
                      imageBloc.applyDateFilter(DateFilter.all());
                      Navigator.pop(context);
                    },
                  ),
                  _FilterOption(
                    title: 'Today',
                    icon: Icons.today_rounded,
                    isSelected: _selectedFilter?.type == DateFilterType.today,
                    onTap: () {
                      setState(() {
                        _selectedFilter = DateFilter.today();
                      });
                      imageBloc.applyDateFilter(DateFilter.today());
                      Navigator.pop(context);
                    },
                  ),
                  _FilterOption(
                    title: 'This Week',
                    icon: Icons.view_week_rounded,
                    isSelected: _selectedFilter?.type == DateFilterType.thisWeek,
                    onTap: () {
                      setState(() {
                        _selectedFilter = DateFilter.thisWeek();
                      });
                      imageBloc.applyDateFilter(DateFilter.thisWeek());
                      Navigator.pop(context);
                    },
                  ),
                  _FilterOption(
                    title: 'This Month',
                    icon: Icons.calendar_month_rounded,
                    isSelected: _selectedFilter?.type == DateFilterType.thisMonth,
                    onTap: () {
                      setState(() {
                        _selectedFilter = DateFilter.thisMonth();
                      });
                      imageBloc.applyDateFilter(DateFilter.thisMonth());
                      Navigator.pop(context);
                    },
                  ),
                  _FilterOption(
                    title: 'Custom Range',
                    icon: Icons.date_range_rounded,
                    isSelected: _selectedFilter?.type == DateFilterType.customRange,
                    onTap: () => _showCustomDateRangePicker(context),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Filter by Tags',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  StreamBuilder<List<TagModel>>(
                    stream: tagBloc.tagsStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        final tags = snapshot.data!;
                        return Column(
                          children: tags.map((tag) {
                            final isSelected = _selectedTagIds.contains(tag.id);
                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedTagIds.add(tag.id);
                                  } else {
                                    _selectedTagIds.remove(tag.id);
                                  }
                                });
                                imageBloc.applyTagFilter(_selectedTagIds);
                              },
                              title: Text(tag.name),
                              secondary: Builder(
                                builder: (context) {
                                  final color = _parseColor(tag.color);
                                  return Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No tags available',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _showCustomDateRangePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedFilter?.type == DateFilterType.customRange &&
              _selectedFilter?.startDate != null &&
              _selectedFilter?.endDate != null
          ? DateTimeRange(
              start: _selectedFilter!.startDate!,
              end: _selectedFilter!.endDate!,
            )
          : null,
    );

    if (picked != null) {
      final filter = DateFilter.customRange(
        DateTime(picked.start.year, picked.start.month, picked.start.day),
        DateTime(picked.end.year, picked.end.month, picked.end.day)
            .add(const Duration(days: 1)),
      );
      setState(() {
        _selectedFilter = filter;
      });
      imageBloc.applyDateFilter(filter);
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  Color _parseColor(String hex) {
    return Color(int.parse(hex.replaceAll('#', '0xFF')));
  }
}

class _FilterOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: isSelected
          ? const Icon(Icons.check_rounded, color: Colors.blue)
          : null,
      selected: isSelected,
      onTap: onTap,
    );
  }
}

