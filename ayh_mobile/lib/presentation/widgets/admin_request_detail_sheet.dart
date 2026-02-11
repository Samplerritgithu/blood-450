import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/blood_request.dart';

/// Bottom sheet showing blood request detail and accepted donors (for admin).
class AdminRequestDetailSheet extends StatelessWidget {
  final BloodRequest request;
  final List<AcceptedDonor>? acceptedDonors;

  const AdminRequestDetailSheet({
    super.key,
    required this.request,
    this.acceptedDonors,
  });

  static Future<void> show(
    BuildContext context, {
    required BloodRequest request,
    List<AcceptedDonor>? acceptedDonors,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AdminRequestDetailSheet(
        request: request,
        acceptedDonors: acceptedDonors ?? request.acceptedDonors,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accepted = acceptedDonors ?? request.acceptedDonors ?? [];
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + MediaQuery.of(context).padding.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.getBloodGroupColor(
                      request.bloodGroup,
                    ).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.getUrgencyColor(
                      request.urgency,
                    ).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
                      color: request.isActive
                          ? AppColors.success
                          : Colors.grey[700],
                    ),
                  ),
                ),
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
              ),
            ],
            if (request.locationName != null &&
                request.locationName!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.place, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      request.locationName!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ),
                  if (request.reqLat != null && request.reqLng != null)
                    Text(
                      ' (${request.reqLat!.toStringAsFixed(4)}, ${request.reqLng!.toStringAsFixed(4)})',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                ],
              ),
              if (request.reqLat != null && request.reqLng != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Within ${request.radiusKm.toStringAsFixed(1)} km',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 8),
            Text(
              '${request.notifiedCount} notified · ${request.acceptedCount} accepted',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            Text(
              'Notified Donors',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (request.notifiedDonors == null ||
                request.notifiedDonors!.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No donors notified.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              )
            else
              ...(request.notifiedDonors!.map((d) {
                final parts = <String>[];
                if (d.bloodGroup != null) parts.add(d.bloodGroup!);
                if (d.distanceKm != null)
                  parts.add('${d.distanceKm!.toStringAsFixed(1)} km');
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.info.withOpacity(0.2),
                      child: Icon(
                        Icons.person,
                        color: AppColors.info,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      d.username,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: parts.isEmpty
                        ? null
                        : Text(
                            parts.join(' · '),
                            style: const TextStyle(fontSize: 12),
                          ),
                    trailing: d.distanceKm != null
                        ? Text(
                            '${d.distanceKm!.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                );
              })),
            const SizedBox(height: 16),
            Text(
              'Accepted Donors',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (accepted.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No donors have accepted yet.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              ...accepted.map((d) {
                final parts = <String>[];
                if (d.phone != null && d.phone!.isNotEmpty) parts.add(d.phone!);
                if (d.bloodGroup != null) parts.add(d.bloodGroup!);
                if (d.distanceKm != null)
                  parts.add('${d.distanceKm!.toStringAsFixed(1)} km away');
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.success.withOpacity(0.2),
                      child: Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 20,
                      ),
                    ),
                    title: Text(d.username),
                    subtitle: Text(parts.join(' · ')),
                    trailing: Text(
                      _formatTime(d.respondedAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }
}
