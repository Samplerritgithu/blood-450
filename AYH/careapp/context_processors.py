"""Context processors for careapp."""
from .models import AdminNotification, Notification, DonorResponse, DelayReason


def admin_notifications(request):
    """Add admin notification count and list for staff users (for bell icon and modal)."""
    if not getattr(request, 'user', None) or not request.user.is_authenticated or not request.user.is_staff:
        return {
            'admin_notification_count': 0,
            'admin_notifications': [],
            'admin_unresolved_delay_count': 0,
        }
    qs = AdminNotification.objects.select_related('blood_request', 'donor').order_by('-created_at')[:50]
    delay_count = DelayReason.objects.filter(resolved=False).count()
    return {
        'admin_notification_count': AdminNotification.objects.count(),
        'admin_notifications': list(qs),
        'admin_unresolved_delay_count': delay_count,
    }


def donor_notification_count(request):
    """Add donor pending notification count for donor users (for bell icon in navbar)."""
    if not getattr(request, 'user', None) or not request.user.is_authenticated or request.user.is_staff:
        return {'donor_notification_count': 0}
    responded_ids = DonorResponse.objects.filter(donor=request.user).values_list('blood_request_id', flat=True)
    pending_count = Notification.objects.filter(user=request.user).exclude(
        blood_request_id__in=responded_ids
    ).count()
    return {'donor_notification_count': pending_count}
