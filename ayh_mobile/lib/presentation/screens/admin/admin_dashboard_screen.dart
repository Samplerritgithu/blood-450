import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/blood_request_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/admin_request_detail_sheet.dart';
import '../auth/login_screen.dart';
import 'create_request_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).loadDashboardStats();
    });
  }

  Future<void> _handleRefresh() async {
    await Provider.of<DashboardProvider>(context, listen: false).loadDashboardStats();
  }

  Future<void> _openRequestDetail(BuildContext context, int requestId) async {
    final bloodRequestProvider = Provider.of<BloodRequestProvider>(context, listen: false);
    await bloodRequestProvider.loadRequestDetail(requestId);
    if (!context.mounted) return;
    final request = bloodRequestProvider.selectedRequest;
    if (request != null) {
      AdminRequestDetailSheet.show(
        context,
        request: request,
        acceptedDonors: request.acceptedDonors,
      );
    }
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
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
          ).then((_) => _handleRefresh());
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Request'),
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, dashProvider, _) {
          if (dashProvider.isLoading && dashProvider.stats == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (dashProvider.stats == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    dashProvider.error ?? 'Failed to load dashboard',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _handleRefresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final stats = dashProvider.stats!;

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Statistics Cards
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Requests',
                        value: '${stats.totalRequests}',
                        icon: Icons.bloodtype,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: 'Active',
                        value: '${stats.activeRequests}',
                        icon: Icons.pending_actions,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Donors',
                        value: '${stats.totalDonors}',
                        icon: Icons.people,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: 'Available',
                        value: '${stats.availableDonors}',
                        icon: Icons.check_circle_outline,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Accepted',
                        value: '${stats.totalAccepted}',
                        icon: Icons.check_circle,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: 'Critical',
                        value: '${stats.criticalRequests}',
                        icon: Icons.warning,
                        color: AppColors.urgencyCritical,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Recent Requests
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Requests',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: _handleRefresh,
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                if (stats.recentRequests.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No requests yet',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  ...stats.recentRequests.map((request) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _openRequestDetail(context, request.id),
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.getBloodGroupColor(request.bloodGroup).withOpacity(0.2),
                            child: Text(
                              request.bloodGroup,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.getBloodGroupColor(request.bloodGroup),
                              ),
                            ),
                          ),
                          title: Text('${request.unitsNeeded} unit(s) - ${request.urgencyDisplay}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (request.locationName != null && request.locationName!.isNotEmpty) ...[
                                Row(
                                  children: [
                                    Icon(Icons.place, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        request.locationName!,
                                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                              ],
                              if (request.note.isNotEmpty)
                                Text(
                                  request.note,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              Text(
                                '${request.notifiedCount} notified, ${request.acceptedCount} accepted — Tap to view',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (request.acceptedCount > 0)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${request.acceptedCount} accepted',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: request.isActive
                                      ? AppColors.success.withOpacity(0.2)
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  request.isActive ? 'ACTIVE' : 'CLOSED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: request.isActive ? AppColors.success : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
