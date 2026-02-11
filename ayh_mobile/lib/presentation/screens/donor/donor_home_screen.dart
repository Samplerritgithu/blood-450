import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../auth/login_screen.dart';
import 'donor_my_responses_screen.dart';
import 'donor_response_form_screen.dart';
import 'donor_profile_screen.dart';
import 'donor_notifications_screen.dart';
import '../../../data/models/notification.dart';

/// Donation record derived from accepted notification (respondedAt = donation date).
class _DonationRecord {
  final DateTime date;
  final String urgency; // critical, high, medium → used as "type" for pie

  _DonationRecord({required this.date, required this.urgency});
}

/// Donor Home: dashboard (metrics, charts, eligibility) + notifications list.
class DonorHomeScreen extends StatefulWidget {
  const DonorHomeScreen({super.key});

  @override
  State<DonorHomeScreen> createState() => _DonorHomeScreenState();
}

class _DonorHomeScreenState extends State<DonorHomeScreen> {
  static const int eligibilityDays = 90;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).loadNotifications();
    });
  }

  List<_DonationRecord> _getDonations(List<NotificationModel> notifications) {
    return notifications
        .where((n) =>
            n.hasResponded &&
            n.responseStatus == 'accepted' &&
            n.respondedAt != null)
        .map((n) => _DonationRecord(
              date: n.respondedAt!,
              urgency: n.bloodRequest.urgency,
            ))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  int _thisMonthCount(List<_DonationRecord> donations) {
    final now = DateTime.now();
    return donations.where((d) => d.date.month == now.month && d.date.year == now.year).length;
  }

  DateTime? _lastDonationDate(List<_DonationRecord> donations) {
    if (donations.isEmpty) return null;
    return donations.last.date;
  }

  int _daysUntilEligible(DateTime? lastDate) {
    if (lastDate == null) return 0;
    final daysSince = DateTime.now().difference(lastDate).inDays;
    if (daysSince >= eligibilityDays) return 0;
    return eligibilityDays - daysSince;
  }

  double _eligibilityProgress(DateTime? lastDate) {
    if (lastDate == null) return 0;
    final daysSince = DateTime.now().difference(lastDate).inDays;
    if (daysSince >= eligibilityDays) return 1.0;
    return (daysSince / eligibilityDays).clamp(0.0, 1.0);
  }

  /// Donations per day in current month (1–31).
  Map<int, int> _donationsByDayThisMonth(List<_DonationRecord> donations) {
    final now = DateTime.now();
    final map = <int, int>{};
    for (var d = 1; d <= 31; d++) map[d] = 0;
    for (final d in donations) {
      if (d.date.month == now.month && d.date.year == now.year) {
        map[d.date.day] = (map[d.date.day] ?? 0) + 1;
      }
    }
    return map;
  }

  /// Donations per month, last 12 months.
  List<({String label, int count})> _donationsByMonthLast12(List<_DonationRecord> donations) {
    final now = DateTime.now();
    final months = <({String label, int count})>[];
    for (var i = 11; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      final count = donations.where((x) => x.date.month == d.month && x.date.year == d.year).length;
      months.add((label: '${_monthShort(d.month)}\n\'${d.year % 100}', count: count));
    }
    return months;
  }

  String _monthShort(int month) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return m[month - 1];
  }

  /// By urgency for pie: Critical=Emergency, High=Hospital, Medium=Other.
  List<({String label, int count, Color color})> _donationsByType(List<_DonationRecord> donations) {
    int c = 0, h = 0, m = 0;
    for (final d in donations) {
      switch (d.urgency) {
        case 'critical': c++; break;
        case 'high': h++; break;
        default: m++; break;
      }
    }
    return [
      (label: 'Emergency', count: c, color: AppColors.urgencyCritical),
      (label: 'Hospital', count: h, color: AppColors.urgencyHigh),
      (label: 'Other', count: m, color: AppColors.urgencyMedium),
    ];
  }

  int _currentStreak(List<_DonationRecord> donations) {
    if (donations.isEmpty) return 0;
    final monthsWithDonation = <int>{};
    for (final d in donations) {
      monthsWithDonation.add(d.date.year * 12 + d.date.month);
    }
    final sorted = monthsWithDonation.toList()..sort((a, b) => b.compareTo(a));
    int streak = 0;
    final now = DateTime.now();
    int current = now.year * 12 + now.month;
    for (final m in sorted) {
      if (m == current) { streak++; current--; } else if (m < current) break;
    }
    return streak;
  }

  List<bool> _badgesUnlocked(int lifetimeCount) {
    return [
      lifetimeCount >= 1,
      lifetimeCount >= 5,
      lifetimeCount >= 10,
      lifetimeCount >= 25,
    ];
  }

  Future<void> _handleRefresh() async {
    final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
    await notifProvider.loadNotifications();
    await notifProvider.clearAcceptanceCount();
  }

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: const Text('Blood450'),
        backgroundColor: const Color.fromARGB(255, 222, 15, 15),
        foregroundColor: Colors.white,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, _) {
              final count = notifProvider.badgeCount;
              if (count > 0) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_rounded),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DonorNotificationsScreen(),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE11D48),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return IconButton(
                icon: const Icon(Icons.notifications_rounded),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DonorNotificationsScreen(),
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notifProvider, _) {
          if (notifProvider.isLoading && notifProvider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final donations = _getDonations(notifProvider.notifications);
          final thisMonth = _thisMonthCount(donations);
          final lastDate = _lastDonationDate(donations);
          final lifetime = donations.length;
          final daysUntil = _daysUntilEligible(lastDate);
          final progress = _eligibilityProgress(lastDate);
          final byDay = _donationsByDayThisMonth(donations);
          final byMonth = _donationsByMonthLast12(donations);
          final byType = _donationsByType(donations);
          final streak = _currentStreak(donations);
          final badges = _badgesUnlocked(lifetime);

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMetricCards(thisMonth, lastDate, lifetime, daysUntil),
                  const SizedBox(height: 20),
                  _buildEligibilityProgress(progress, daysUntil, lastDate),
                  const SizedBox(height: 24),
                  _buildSectionTitle('This Month', Icons.calendar_today_rounded, AppColors.info),
                  const SizedBox(height: 8),
                  _buildLineChart(byDay),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Last 12 Months', Icons.bar_chart_rounded, AppColors.accent),
                  const SizedBox(height: 8),
                  _buildBarChart(byMonth),
                  const SizedBox(height: 24),
                  _buildSectionTitle('By Type', Icons.pie_chart_rounded, const Color(0xFF0D9488)),
                  const SizedBox(height: 8),
                  _buildPieChart(byType),
                  const SizedBox(height: 24),
                  _buildStreakAndBadges(streak, badges, lifetime),
                  const SizedBox(height: 24),
                  _buildCtaSection(context),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Rewards & Offers', Icons.card_giftcard_rounded, AppColors.warning),
                  const SizedBox(height: 12),
                  _buildCouponCards(),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Your Responses', Icons.check_circle_outline_rounded, const Color(0xFF0D9488)),
                  const SizedBox(height: 8),
                  const Text(
                    'Accepted & rejected requests',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  _buildResponsesList(notifProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, [Color? color]) {
    final c = color ?? AppColors.primary;
    return Row(
      children: [
        Icon(icon, color: c, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  static const Color _teal = Color(0xFF0D9488);

  static const Color _cardTeal = Color(0xFFCCFBF1);
  static const Color _cardBlue = Color(0xFFDBEAFE);
  static const Color _cardPurple = Color(0xFFEDE9FE);
  static const Color _cardAmber = Color(0xFFFEF3C7);
  static const Color _responseCardBg = Color(0xFFF0FDF4);

  Widget _buildMetricCards(int thisMonth, DateTime? lastDate, int lifetime, int daysUntil) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _metricCard(
                'This Month',
                '$thisMonth',
                Icons.bloodtype_rounded,
                _teal,
                _cardTeal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                'Last Donation',
                lastDate != null ? _formatDate(lastDate) : '—',
                Icons.event_rounded,
                AppColors.info,
                _cardBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                'Lifetime',
                '$lifetime',
                Icons.favorite_rounded,
                AppColors.accent,
                _cardPurple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                'Eligible In',
                daysUntil == 0 ? 'Now' : '$daysUntil days',
                Icons.schedule_rounded,
                daysUntil == 0 ? AppColors.success : AppColors.warning,
                _cardAmber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color, Color backgroundColor) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: backgroundColor,
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const Color _chartText = Color(0xFF374151);

  Widget _buildEligibilityProgress(double progress, int daysUntil, DateTime? lastDate) {
    final isEligible = daysUntil == 0;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isEligible
              ? [const Color(0xFFD1FAE5), const Color(0xFFA7F3D0)]
              : [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)],
        ),
        boxShadow: [
          BoxShadow(
            color: (isEligible ? AppColors.success : AppColors.info).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: isEligible ? 1.0 : progress,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isEligible ? AppColors.success : _teal,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isEligible ? 'Now' : '$daysUntil',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        isEligible ? 'Eligible' : 'days left',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isEligible
                  ? 'You can donate now'
                  : 'Eligible in $daysUntil days (90-day gap)',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildLineChart(Map<int, int> byDay) {
    final spots = byDay.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();
    if (spots.every((s) => s.y == 0)) {
      return _emptyChart('No donations this month', const Color(0xFFDBEAFE));
    }
    final maxY = byDay.values.isEmpty ? 1.0 : byDay.values.reduce(math.max).toDouble();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFEFF6FF),
        border: Border.all(color: const Color(0xFFBFDBFE).withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.info.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 36,
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      'No. of donations',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _chartText,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: 160,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (v) => FlLine(
                            color: const Color(0xFF94A3B8).withOpacity(0.3),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (v, _) => Text(
                                v.toInt().toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _chartText,
                                ),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 24,
                              interval: 5,
                              getTitlesWidget: (v, _) => Text(
                                '${v.toInt()}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _chartText,
                                ),
                              ),
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 1,
                        maxX: 31,
                        minY: 0,
                        maxY: maxY < 1 ? 1 : maxY,
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            curveSmoothness: 0.35,
                            color: const Color(0xFF2563EB),
                            barWidth: 2.5,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, data, index) =>
                                  FlDotCirclePainter(radius: 3.5, color: const Color(0xFF2563EB)),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: const Color(0xFF2563EB).withOpacity(0.12),
                            ),
                          ),
                        ],
                      ),
                      duration: const Duration(milliseconds: 250),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Day of month',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _chartText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<({String label, int count})> byMonth) {
    if (byMonth.every((e) => e.count == 0)) {
      return _emptyChart('No donations in last 12 months', const Color(0xFFEDE9FE));
    }
    final maxY = byMonth.map((e) => e.count).reduce(math.max).toDouble();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF5F3FF),
        border: Border.all(color: const Color(0xFFC4B5FD).withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 36,
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      'No. of donations',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _chartText,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: 188,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxY < 1 ? 1 : maxY,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (v, _) => Text(
                                v.toInt().toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _chartText,
                                ),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 52,
                              getTitlesWidget: (v, meta) {
                                final i = v.toInt();
                                if (i < 0 || i >= byMonth.length) return const SizedBox();
                                final count = byMonth[i].count;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        byMonth[i].label,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: _chartText,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$count',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: _chartText,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (v) => FlLine(
                            color: const Color(0xFF94A3B8).withOpacity(0.3),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(
                          byMonth.length,
                          (i) => BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: byMonth[i].count.toDouble(),
                                color: const Color(0xFF6366F1),
                                width: 14,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ],
                            showingTooltipIndicators: [],
                          ),
                        ),
                      ),
                      duration: const Duration(milliseconds: 250),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Month',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _chartText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(List<({String label, int count, Color color})> byType) {
    final total = byType.fold<int>(0, (s, e) => s + e.count);
    if (total == 0) {
      return _emptyChart('No donations yet', const Color(0xFFFEF3C7));
    }

    final sections = byType
        .where((e) => e.count > 0)
        .map((e) => PieChartSectionData(
              value: e.count.toDouble(),
              title: '${e.count}',
              color: e.color,
              radius: 44,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ))
        .toList();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: const Color(0xFFFCD34D).withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 28,
                ),
                duration: const Duration(milliseconds: 250),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: byType
                    .where((e) => e.count > 0)
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: e.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${e.label}: ${e.count}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyChart(String message, [Color? cardColor]) {
    final bg = cardColor ?? const Color(0xFFF8FAFC);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: bg,
        border: Border.all(color: const Color(0xFF94A3B8).withOpacity(0.4)),
      ),
      child: Container(
        height: 120,
        alignment: Alignment.center,
        child: Text(
          message,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _chartText,
          ),
        ),
      ),
    );
  }

  Widget _buildStreakAndBadges(int streak, List<bool> badges, int lifetime) {
    final labels = ['First', '5', '10', '25'];
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department_rounded,
                    color: streak > 0 ? AppColors.warning : Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Streak: $streak month${streak == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Achievements',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(4, (i) {
                final unlocked = badges[i];
                return Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: unlocked
                            ? AppColors.warning.withOpacity(0.25)
                            : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        unlocked ? Icons.emoji_events_rounded : Icons.lock_rounded,
                        color: unlocked ? AppColors.warning : Colors.grey,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 12,
                        color: unlocked ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCtaSection(BuildContext context) {
    return Column(
      children: [
        _ctaCard(
          context,
          title: 'Give Response',
          subtitle: 'Submit your answer to a blood request',
          icon: Icons.edit_note_rounded,
          gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DonorResponseFormScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        _ctaCard(
          context,
          title: 'My Responses',
          subtitle: 'View your accepted & rejected requests',
          icon: Icons.history_rounded,
          gradient: const [Color(0xFF0D9488), Color(0xFF14B8A6)],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DonorMyResponsesScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _ctaCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    final primaryColor = gradient[0];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primaryColor.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 5,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: gradient,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                primaryColor.withOpacity(0.2),
                                (gradient.length > 1 ? gradient[1] : primaryColor).withOpacity(0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            icon,
                            color: primaryColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCouponCards() {
    final coupons = [
      (
        title: 'Free Health Check',
        offer: 'Complimentary health screening on your next donation',
        code: 'B450HEALTH',
        gradient: [const Color(0xFF0D9488), const Color(0xFF14B8A6)],
        icon: Icons.medical_services_rounded,
      ),
      (
        title: 'Snack Voucher',
        offer: 'Refreshments & snack after donation',
        code: 'B450SNACK',
        gradient: [const Color(0xFFF59E0B), const Color(0xFFE85D75)],
        icon: Icons.restaurant_rounded,
      ),
      (
        title: 'Donor Thank You',
        offer: 'Exclusive donor appreciation gift',
        code: 'B450THANKS',
        gradient: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
        icon: Icons.card_giftcard_rounded,
      ),
      (
        title: 'Refer a Donor',
        offer: 'Reward when your friend donates',
        code: 'B450REFER',
        gradient: [const Color(0xFF10B981), const Color(0xFF059669)],
        icon: Icons.people_rounded,
      ),
    ];
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _couponCard(coupons[0])),
            const SizedBox(width: 12),
            Expanded(child: _couponCard(coupons[1])),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _couponCard(coupons[2])),
            const SizedBox(width: 12),
            Expanded(child: _couponCard(coupons[3])),
          ],
        ),
      ],
    );
  }

  Widget _couponCard(
    ({
      String title,
      String offer,
      String code,
      List<Color> gradient,
      IconData icon,
    }) c,
  ) {
    final primaryColor = c.gradient[0];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primaryColor.withOpacity(0.35),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: c.gradient,
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    primaryColor.withOpacity(0.2),
                                    (c.gradient.length > 1
                                            ? c.gradient[1]
                                            : primaryColor)
                                        .withOpacity(0.15),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                c.icon,
                                color: primaryColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                c.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          c.offer,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              'Use code',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      primaryColor.withOpacity(0.12),
                                      primaryColor.withOpacity(0.06),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: primaryColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  c.code,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor,
                                    letterSpacing: 0.8,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsesList(NotificationProvider notifProvider) {
    final responded = notifProvider.notifications.where((n) => n.hasResponded).toList();
    if (responded.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _responseCardBg,
          border: Border.all(color: AppColors.success.withOpacity(0.4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No responses yet',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your accepted or rejected requests will appear here',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DonorNotificationsScreen()),
                  );
                },
                icon: const Icon(Icons.notifications_rounded, size: 20),
                label: const Text('View blood requests'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: responded.length,
      itemBuilder: (context, index) {
        final notification = responded[index];
        final request = notification.bloodRequest;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _responseCardBg,
            border: Border.all(color: AppColors.success.withOpacity(0.35)),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DonorNotificationsScreen()),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.getBloodGroupColor(request.bloodGroup).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          request.bloodGroup,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.getBloodGroupColor(request.bloodGroup),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.getUrgencyColor(request.urgency).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          request.urgencyDisplay.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getUrgencyColor(request.urgency),
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${request.unitsNeeded} unit(s) needed',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  if (request.note.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      request.note,
                      style: const TextStyle(color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Requested ${_formatTime(request.createdAt)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: notification.responseStatus == 'accepted'
                            ? AppColors.success.withOpacity(0.1)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            notification.responseStatus == 'accepted'
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: notification.responseStatus == 'accepted'
                                ? AppColors.success
                                : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            notification.responseStatus == 'accepted'
                                ? 'You accepted this request'
                                : 'You rejected this request',
                            style: TextStyle(
                              color: notification.responseStatus == 'accepted'
                                  ? AppColors.success
                                  : Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        );
      },
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return _formatDate(time);
  }

  Widget _buildDrawer(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.fromARGB(255, 209, 27, 27), Color.fromARGB(255, 200, 45, 10)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Blood450',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  authProvider.user?.username ?? 'Donor',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('User Profile'),
            subtitle: const Text('View your details'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DonorProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_note),
            title: const Text('Give Response'),
            subtitle: const Text('Submit response to a blood request'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DonorResponseFormScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('My Responses'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DonorMyResponsesScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              _handleLogout();
            },
          ),
        ],
      ),
    );
  }
}
