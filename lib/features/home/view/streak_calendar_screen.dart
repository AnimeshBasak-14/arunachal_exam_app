import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/services/streak_service.dart';

class StreakCalendarScreen extends ConsumerStatefulWidget {
  const StreakCalendarScreen({super.key});

  @override
  ConsumerState<StreakCalendarScreen> createState() => _StreakCalendarScreenState();
}

class _StreakCalendarScreenState extends ConsumerState<StreakCalendarScreen> {
  late StreakService _streakService;
  int _currentStreak = 0;
  int _longestStreak = 0;
  List<String> _activeDates = [];
  
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    _streakService = StreakService(prefs);
    _currentStreak = _streakService.getCurrentStreak();
    _longestStreak = _streakService.getLongestStreak();
    _activeDates = _streakService.getActiveDatesHistory();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  void _previousMonth() {
    final now = DateTime.now();
    final minAllowed = DateTime(now.year - 1, now.month);
    final newMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    
    if (newMonth.isAfter(minAllowed) || (newMonth.year == minAllowed.year && newMonth.month == minAllowed.month)) {
      setState(() {
        _selectedMonth = newMonth;
      });
    }
  }

  void _nextMonth() {
    final now = DateTime.now();
    final newMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    
    if (newMonth.isBefore(now) || (newMonth.year == now.year && newMonth.month == now.month)) {
      setState(() {
        _selectedMonth = newMonth;
      });
    }
  }
  
  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Study Streak Calendar'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroCard(),
            const SizedBox(height: AppSpacing.l),
            _buildCalendarHeader(),
            const SizedBox(height: AppSpacing.s),
            _buildCalendarGrid(),
            const SizedBox(height: AppSpacing.l),
            const Text('Achievements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.s),
            _buildAchievements(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    final now = DateTime.now();
    final isCurrentMonth = _selectedMonth.year == now.year && _selectedMonth.month == now.month;
    final minAllowed = DateTime(now.year - 1, now.month);
    final isMinMonth = _selectedMonth.year == minAllowed.year && _selectedMonth.month == minAllowed.month;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: isMinMonth ? null : _previousMonth,
        ),
        Text(
          '${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: isCurrentMonth ? null : _nextMonth,
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 48)),
          const SizedBox(height: AppSpacing.s),
          Text(
            '$_currentStreak Day Streak',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.m),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildHeroStat('Longest Streak', '$_longestStreak'),
              Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
              _buildHeroStat('Total Active', '${_activeDates.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);
    final firstDayOffset = DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday - 1;
    final totalCells = daysInMonth + firstDayOffset;
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('Mon'), Text('Tue'), Text('Wed'), Text('Thu'),
              Text('Fri'), Text('Sat'), Text('Sun'),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: totalCells,
            itemBuilder: (context, index) {
              if (index < firstDayOffset) {
                return const SizedBox();
              }
              
              final day = index - firstDayOffset + 1;
              final dateStr = '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
              final isActive = _activeDates.contains(dateStr);
              final isToday = now.year == _selectedMonth.year && now.month == _selectedMonth.month && now.day == day;
              
              return Container(
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.shade500 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday ? Border.all(color: Colors.blue, width: 2) : null,
                  boxShadow: isActive ? [
                    BoxShadow(
                      color: Colors.green.shade400.withValues(alpha: 0.6),
                      blurRadius: 6,
                      spreadRadius: 1,
                    )
                  ] : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey.shade600,
                    fontWeight: (isActive || isToday) ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    return Column(
      children: [
        _buildAchievementTile('3-Day Starter', '🏅', 3),
        _buildAchievementTile('7-Day Novice', '🥉', 7),
        _buildAchievementTile('14-Day Warrior', '🥈', 14),
        _buildAchievementTile('30-Day APSSB Master', '🥇', 30),
      ],
    );
  }

  Widget _buildAchievementTile(String title, String emoji, int requiredStreak) {
    final isUnlocked = _longestStreak >= requiredStreak;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.orange.shade50 : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked ? Colors.orange.shade200 : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? Colors.orange.shade900 : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Reach a $requiredStreak-day streak',
                  style: TextStyle(
                    fontSize: 12,
                    color: isUnlocked ? Colors.orange.shade700 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isUnlocked)
            const Icon(Icons.check_circle_rounded, color: Colors.orange)
          else
            Icon(Icons.lock_rounded, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}
