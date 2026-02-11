from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required, user_passes_test
from django.contrib.auth.models import User
from django.contrib import messages
from django.http import JsonResponse, HttpResponseRedirect
from django.urls import reverse
from django.views.decorators.http import require_http_methods
from django.views.decorators.csrf import ensure_csrf_cookie
from django.db import IntegrityError, transaction
from django.db.models import Count
from django.db.models.functions import TruncDate
from django.utils import timezone
from django.utils.dateparse import parse_date
from datetime import timedelta
from django.conf import settings as django_settings
import json
import logging

from django.contrib.auth.views import LoginView

from .models import (
    BloodRequest, DonorProfile, UserProfile, Notification, DonorResponse,
    AdminNotification, RequestTimeline, EtaTracking, DelayReason, DonorAssignment, FallbackAction,
    RadiusExpansionLog, BloodBankMaster, HospitalMaster, HospitalMetrics, DimCity,
)
from .forms import DonorRegistrationForm, DonorLoginForm
from .utils import haversine_km, donor_has_location

logger = logging.getLogger(__name__)
DEFAULT_RADIUS_KM = getattr(django_settings, 'DEFAULT_RADIUS_KM', 10)


class DonorLoginView(LoginView):
    """Login view that uses DonorLoginForm so username (email) is normalized to lowercase."""
    form_class = DonorLoginForm
    template_name = 'registration/login.html'
    redirect_authenticated_user = True


# Blood compatibility matrix - who can donate to whom
BLOOD_COMPATIBILITY = {
    'A+': ['A+', 'A-', 'O+', 'O-'],
    'A-': ['A-', 'O-'],
    'B+': ['B+', 'B-', 'O+', 'O-'],
    'B-': ['B-', 'O-'],
    'AB+': ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],  # Universal receiver
    'AB-': ['A-', 'B-', 'AB-', 'O-'],
    'O+': ['O+', 'O-'],
    'O-': ['O-'],  # Universal donor
}


def get_compatible_blood_groups(requested_blood_group):
    """
    Returns list of blood groups that can donate to the requested blood group.
    
    Args:
        requested_blood_group: The blood group needed (e.g., 'A+')
    
    Returns:
        List of compatible donor blood groups
    """
    return BLOOD_COMPATIBILITY.get(requested_blood_group, [requested_blood_group])


def is_staff_user(user):
    """Check if user is staff"""
    return user.is_staff


@login_required
def home_redirect(request):
    """Redirect user to appropriate page based on their role"""
    if request.user.is_staff:
        return redirect('admin_dashboard')
    else:
        return redirect('donor_notifications')


@login_required
@user_passes_test(is_staff_user)
@ensure_csrf_cookie
def admin_dashboard(request):
    """Admin dashboard with statistics, all requests, and master data (hospitals, blood banks, cities)."""
    # Get all blood requests
    blood_requests = BloodRequest.objects.all().prefetch_related(
        'responses', 'notifications', 'delay_reasons', 'delay_reasons__reported_by', 'delay_reasons__reported_by__donor_profile'
    ).order_by('-created_at')
    
    # Get all donors
    donors = DonorProfile.objects.all().select_related('user')
    
    # Master data counts and recent lists (saved backend data)
    total_hospitals = HospitalMaster.objects.count()
    total_blood_banks = BloodBankMaster.objects.count()
    total_cities = DimCity.objects.count()
    recent_hospitals = HospitalMaster.objects.all().order_by('hospital_name')
    recent_blood_banks = BloodBankMaster.objects.all().order_by('name')
    recent_cities = DimCity.objects.all().order_by('state', 'city')
    
    # Calculate statistics
    total_requests = blood_requests.count()
    total_donors = donors.count()
    total_accepted = DonorResponse.objects.filter(response='accepted').count()
    active_requests = blood_requests.filter(is_active=True).count()
    
    # Chart data: requests by urgency (for pie chart)
    urgency_counts = dict(
        BloodRequest.objects.values('urgency').annotate(count=Count('id')).values_list('urgency', 'count')
    )
    chart_urgency = {
        'labels': ['Critical', 'High', 'Medium'],
        'data': [
            urgency_counts.get('critical', 0),
            urgency_counts.get('high', 0),
            urgency_counts.get('medium', 0),
        ],
    }
    
    # Chart data: requests by blood group (for bar chart)
    bg_counts = list(
        BloodRequest.objects.values('blood_group').annotate(count=Count('id')).order_by('blood_group')
    )
    all_bgs = [bg[0] for bg in DonorProfile.BLOOD_GROUP_CHOICES]
    bg_map = {r['blood_group']: r['count'] for r in bg_counts}
    chart_blood_groups = {
        'labels': all_bgs,
        'data': [bg_map.get(bg, 0) for bg in all_bgs],
    }
    
    # Line/curve chart: requests per day (last 14 days)
    start_date = timezone.now().date() - timedelta(days=14)
    daily = (
        BloodRequest.objects.filter(created_at__date__gte=start_date)
        .annotate(day=TruncDate('created_at'))
        .values('day')
        .annotate(count=Count('id'))
        .order_by('day')
    )
    day_map = {r['day'].strftime('%Y-%m-%d'): r['count'] for r in daily}
    days_labels = [(start_date + timedelta(days=i)).strftime('%m/%d') for i in range(15)]
    days_data = [
        day_map.get((start_date + timedelta(days=i)).strftime('%Y-%m-%d'), 0)
        for i in range(15)
    ]
    chart_requests_over_time = {'labels': days_labels, 'data': days_data}
    
    # Scatter: request index vs response count and units needed
    response_counts = dict(
        DonorResponse.objects.values('blood_request_id')
        .annotate(count=Count('id'))
        .values_list('blood_request_id', 'count')
    )
    requests_list = list(blood_requests.values('id', 'units_needed')[:50])
    chart_scatter = {
        'x': list(range(1, len(requests_list) + 1)),
        'y_responses': [response_counts.get(r['id'], 0) for r in requests_list],
        'y_units': [r['units_needed'] for r in requests_list],
    }
    
    # Donors by blood group (2D horizontal bar)
    donor_bg = list(
        DonorProfile.objects.values('blood_group')
        .annotate(count=Count('id'))
        .order_by('blood_group')
    )
    donor_bg_map = {r['blood_group']: r['count'] for r in donor_bg}
    chart_donors_blood = {
        'labels': all_bgs,
        'data': [donor_bg_map.get(bg, 0) for bg in all_bgs],
    }
    
    # If just created a request, show summary for modal (notified / accepted donors)
    created_request_id = request.GET.get('created_request_id')
    created_notified_count = None
    created_accepted_count = None
    created_accepted_list = []
    created_request_obj = None
    if created_request_id:
        try:
            created_request_obj = BloodRequest.objects.get(id=int(created_request_id))
            created_notified_count = Notification.objects.filter(blood_request=created_request_obj).count()
            accepted = DonorResponse.objects.filter(
                blood_request=created_request_obj,
                response='accepted'
            ).select_related('donor', 'donor__donor_profile')
            created_accepted_count = accepted.count()
            created_accepted_list = [
                {'username': r.donor.username, 'blood_group': getattr(r.donor.donor_profile, 'blood_group', None)}
                for r in accepted
            ]
        except (BloodRequest.DoesNotExist, ValueError):
            created_request_id = None

    context = {
        'blood_requests': blood_requests,
        'donors': donors,
        'total_requests': total_requests,
        'total_donors': total_donors,
        'total_accepted': total_accepted,
        'active_requests': active_requests,
        'total_hospitals': total_hospitals,
        'total_blood_banks': total_blood_banks,
        'total_cities': total_cities,
        'recent_hospitals': recent_hospitals,
        'recent_blood_banks': recent_blood_banks,
        'recent_cities': recent_cities,
        'blood_groups': DonorProfile.BLOOD_GROUP_CHOICES,
        'chart_urgency': chart_urgency,
        'chart_blood_groups': chart_blood_groups,
        'chart_requests_over_time': chart_requests_over_time,
        'chart_scatter': chart_scatter,
        'chart_donors_blood': chart_donors_blood,
        'hospitals': recent_hospitals,
        'cities': list(DimCity.objects.all().order_by('state', 'city')),
        'created_request_id': created_request_id,
        'created_request_obj': created_request_obj,
        'created_notified_count': created_notified_count,
        'created_accepted_count': created_accepted_count,
        'created_accepted_list': created_accepted_list,
    }
    return render(request, 'admin_dashboard.html', context)


def _parse_float(val, default=None):
    """Parse float from POST/value; return default if empty or invalid. Accepts comma as decimal separator."""
    if val is None:
        return default
    s = str(val).strip()
    if s == '':
        return default
    # Allow comma as decimal separator (e.g. 17,47 -> 17.47)
    if ',' in s and '.' not in s:
        s = s.replace(',', '.', 1)
    try:
        return float(s)
    except (ValueError, TypeError):
        return default


@login_required
@user_passes_test(is_staff_user)
@ensure_csrf_cookie
@transaction.atomic
def admin_create_request(request):
    """Admin page to create a blood request and notify matching donors.
    If location (req_lat, req_lng) is provided, only donors within radius_km are notified.
    Donors receive a notification and can Accept or Decline (e.g. in the mobile app or donor notifications page).
    """
    if request.method == 'POST':
        blood_group = request.POST.get('blood_group')
        units_needed = request.POST.get('units_needed', 1)
        urgency = request.POST.get('urgency')
        note = request.POST.get('note', '')
        use_location = request.POST.get('use_location') == 'on'
        location_name = (request.POST.get('location_name') or '').strip() or None
        req_lat = _parse_float(request.POST.get('req_lat'))
        req_lng = _parse_float(request.POST.get('req_lng'))
        radius_km = _parse_float(request.POST.get('radius_km'), DEFAULT_RADIUS_KM) or DEFAULT_RADIUS_KM

        if use_location and (req_lat is None or req_lng is None):
            messages.error(
                request,
                'Location-based matching is enabled but latitude and/or longitude are missing. '
                'Enter request location (e.g. hospital/camp) or disable "Use location". All compatible donors will be notified.'
            )
        # Use distance-based matching only when BOTH coordinates are present
        use_distance_matching = req_lat is not None and req_lng is not None

        hospital_id = (request.POST.get('hospital_id') or '').strip() or ''
        city = (request.POST.get('city') or '').strip() or ''
        state = (request.POST.get('state') or '').strip() or ''
        source = (request.POST.get('source') or 'app').strip() or 'app'
        sla_minutes = request.POST.get('sla_minutes')
        sla_minutes = int(sla_minutes) if sla_minutes and str(sla_minutes).strip() else None

        blood_request = BloodRequest.objects.create(
            blood_group=blood_group,
            units_needed=int(units_needed) if units_needed else 1,
            units_required=int(units_needed) if units_needed else 1,
            urgency=urgency,
            urgency_level=urgency and urgency.capitalize() or '',
            status='open',
            source=source,
            hospital_id=hospital_id,
            city=city,
            state=state,
            sla_minutes=sla_minutes,
            note=note or '',
            created_by=request.user,
            location_name=location_name or '',
            req_lat=req_lat,
            req_lng=req_lng,
            radius_km=radius_km,
        )
        RequestTimeline.objects.create(
            request=blood_request,
            event_type='CREATED',
            actor='ADMIN',
            metadata={'created_by': request.user.username},
        )
        AdminNotification.objects.create(
            notification_type=AdminNotification.TYPE_REQUEST_CREATED,
            blood_request=blood_request,
        )

        compatible_blood_groups = get_compatible_blood_groups(blood_group)
        base_queryset = DonorProfile.objects.filter(
            blood_group__in=compatible_blood_groups,
            is_available=True
        ).select_related('user')

        if use_distance_matching:
            # Coerce to float so Decimal (from DB) vs float comparison is reliable
            req_lat_f = float(req_lat)
            req_lng_f = float(req_lng)
            radius_km_f = max(0.1, float(radius_km))  # ensure radius is at least 0.1 km
            donors_with_loc = [dp for dp in base_queryset if donor_has_location(dp)]
            logger.debug(
                "admin_create_request: req_lat=%.6f req_lng=%.6f radius_km=%.2f donors_with_location=%s",
                req_lat_f, req_lng_f, radius_km_f, len(donors_with_loc)
            )
            for i, dp in enumerate(donors_with_loc[:5]):
                try:
                    d = haversine_km(req_lat_f, req_lng_f, float(dp.last_lat), float(dp.last_lng))
                    logger.debug("  donor id=%s distance_km=%s", dp.user_id, d)
                except (TypeError, ValueError):
                    pass
            matched_with_distance = []
            for donor_profile in base_queryset:
                if not donor_has_location(donor_profile):
                    continue
                try:
                    donor_lat = float(donor_profile.last_lat)
                    donor_lng = float(donor_profile.last_lng)
                except (TypeError, ValueError):
                    continue
                dist = haversine_km(req_lat_f, req_lng_f, donor_lat, donor_lng)
                if dist is not None and dist <= radius_km_f:
                    matched_with_distance.append((donor_profile, round(dist, 2)))
            matching_donors = [dp for dp, _ in matched_with_distance]
            logger.debug("admin_create_request: matched_donor_ids=%s", [dp.user_id for dp in matching_donors])
        else:
            matching_donors = list(base_queryset)

        notifications_created = 0
        for donor_profile in matching_donors:
            try:
                Notification.objects.create(
                    user=donor_profile.user,
                    blood_request=blood_request
                )
                notifications_created += 1
            except IntegrityError:
                pass

        # Stay on dashboard: redirect with created_request_id so dashboard shows summary modal (no message – modal shows notified/accepted counts)
        url = reverse('admin_dashboard') + '?created_request_id=' + str(blood_request.id)
        return redirect(url)

    hospitals = HospitalMaster.objects.all().order_by('hospital_name')
    cities = DimCity.objects.all().order_by('state', 'city')
    context = {
        'blood_groups': DonorProfile.BLOOD_GROUP_CHOICES,
        'urgency_levels': BloodRequest.URGENCY_CHOICES,
        'hospitals': hospitals,
        'cities': cities,
    }
    return render(request, 'demo_admin_create_request.html', context)


@login_required
@user_passes_test(is_staff_user)
@ensure_csrf_cookie
def admin_all_requests(request):
    """List all blood requests with Edit and Delete buttons."""
    blood_requests = BloodRequest.objects.all().prefetch_related(
        'responses', 'notifications', 'delay_reasons', 'delay_reasons__reported_by', 'delay_reasons__reported_by__donor_profile'
    ).order_by('-created_at')
    context = {'blood_requests': blood_requests}
    return render(request, 'admin_all_requests.html', context)


@login_required
@user_passes_test(is_staff_user)
@require_http_methods(["POST"])
def admin_delete_request(request, request_id):
    """Delete a blood request after confirmation (confirmation done in frontend)."""
    blood_request = get_object_or_404(BloodRequest, id=request_id)
    blood_request.delete()
    messages.success(request, f'Blood request #{request_id} has been deleted.')
    return redirect('admin_all_requests')


@login_required
@user_passes_test(is_staff_user)
@ensure_csrf_cookie
@transaction.atomic
def admin_edit_request(request, request_id):
    """Edit blood request: show form pre-filled; on save update request, optional radius extension with log."""
    blood_request = get_object_or_404(BloodRequest, id=request_id)
    hospitals = HospitalMaster.objects.all().order_by('hospital_name')
    cities = DimCity.objects.all().order_by('state', 'city')

    if request.method == 'POST':
        blood_group = request.POST.get('blood_group')
        units_needed = request.POST.get('units_needed', 1)
        urgency = request.POST.get('urgency')
        note = request.POST.get('note', '')
        use_location = request.POST.get('use_location') == 'on'
        location_name = (request.POST.get('location_name') or '').strip() or None
        req_lat = _parse_float(request.POST.get('req_lat'))
        req_lng = _parse_float(request.POST.get('req_lng'))
        radius_km = _parse_float(request.POST.get('radius_km'), DEFAULT_RADIUS_KM) or DEFAULT_RADIUS_KM
        radius_extension = _parse_float(request.POST.get('radius_extension'))  # optional new radius if extending

        hospital_id = (request.POST.get('hospital_id') or '').strip() or ''
        city = (request.POST.get('city') or '').strip() or ''
        state = (request.POST.get('state') or '').strip() or ''
        source = (request.POST.get('source') or 'app').strip() or 'app'
        sla_minutes = request.POST.get('sla_minutes')
        sla_minutes = int(sla_minutes) if sla_minutes and str(sla_minutes).strip() else None

        old_radius = float(blood_request.radius_km) if blood_request.radius_km is not None else None
        new_radius = radius_km
        if radius_extension is not None and radius_extension > 0:
            new_radius = max(radius_km, float(radius_extension))

        blood_request.blood_group = blood_group
        blood_request.units_needed = int(units_needed) if units_needed else 1
        blood_request.units_required = blood_request.units_needed
        blood_request.urgency = urgency
        blood_request.urgency_level = (urgency and urgency.capitalize()) or ''
        blood_request.note = note or ''
        blood_request.location_name = location_name or ''
        blood_request.req_lat = req_lat
        blood_request.req_lng = req_lng
        blood_request.radius_km = new_radius
        blood_request.hospital_id = hospital_id
        blood_request.city = city
        blood_request.state = state
        blood_request.source = source
        blood_request.sla_minutes = sla_minutes
        blood_request.save()

        # Log radius expansion when radius was increased (old and new saved in log)
        if (radius_extension is not None and radius_extension > 0) and new_radius > (old_radius or 0):
            RadiusExpansionLog.objects.create(
                request=blood_request,
                old_radius_km=old_radius,
                new_radius_km=new_radius,
                success=True,
            )

        # If radius was extended and we have location, notify additional donors in new radius
        use_distance_matching = req_lat is not None and req_lng is not None
        notified_count = Notification.objects.filter(blood_request=blood_request).count()
        if use_distance_matching and new_radius > (old_radius or 0):
            compatible_blood_groups = get_compatible_blood_groups(blood_request.blood_group)
            already_notified_ids = set(
                Notification.objects.filter(blood_request=blood_request).values_list('user_id', flat=True)
            )
            base_queryset = DonorProfile.objects.filter(
                blood_group__in=compatible_blood_groups,
                is_available=True
            ).select_related('user').exclude(user_id__in=already_notified_ids)
            req_lat_f = float(req_lat)
            req_lng_f = float(req_lng)
            radius_km_f = max(0.1, float(new_radius))
            for donor_profile in base_queryset:
                if not donor_has_location(donor_profile):
                    continue
                try:
                    donor_lat = float(donor_profile.last_lat)
                    donor_lng = float(donor_profile.last_lng)
                except (TypeError, ValueError):
                    continue
                dist = haversine_km(req_lat_f, req_lng_f, donor_lat, donor_lng)
                if dist is not None and dist <= radius_km_f:
                    try:
                        Notification.objects.create(
                            user=donor_profile.user,
                            blood_request=blood_request,
                        )
                        notified_count += 1
                    except IntegrityError:
                        pass

        accepted_count = DonorResponse.objects.filter(
            blood_request=blood_request, response='accepted'
        ).count()
        messages.success(
            request,
            f'Request #{blood_request.id} saved. Notified: {notified_count} | Donors accepted: {accepted_count}.'
        )
        return redirect('admin_all_requests')

    # GET: pre-fill form (full page or modal fragment)
    context = {
        'blood_request': blood_request,
        'blood_groups': DonorProfile.BLOOD_GROUP_CHOICES,
        'urgency_levels': BloodRequest.URGENCY_CHOICES,
        'hospitals': hospitals,
        'cities': cities,
    }
    if request.GET.get('modal'):
        return render(request, 'admin_edit_request_form.html', context)
    return render(request, 'admin_edit_request.html', context)


@login_required
@user_passes_test(is_staff_user)
@require_http_methods(["POST"])
def admin_delete_notifications(request):
    """Delete selected admin notifications (bell modal)."""
    ids = request.POST.getlist('notification_ids')
    if ids:
        try:
            ids = [int(x) for x in ids if str(x).isdigit()]
            AdminNotification.objects.filter(id__in=ids).delete()
        except (ValueError, TypeError):
            pass
    redirect_url = request.META.get('HTTP_REFERER') or reverse('admin_dashboard')
    return redirect(redirect_url)


@login_required
@user_passes_test(is_staff_user)
def admin_request_detail(request, request_id):
    """Admin page to view blood request details, timeline, ETA, delays, assignments, notified/accepted donors."""
    blood_request = get_object_or_404(BloodRequest, id=request_id)

    notified_count = Notification.objects.filter(blood_request=blood_request).count()
    accepted_responses = DonorResponse.objects.filter(
        blood_request=blood_request,
        response='accepted'
    ).select_related('donor', 'donor__donor_profile')

    timeline_events = RequestTimeline.objects.filter(request=blood_request).order_by('event_time')
    eta_trackings = EtaTracking.objects.filter(request=blood_request).order_by('-committed_at')
    delay_reasons = DelayReason.objects.filter(request=blood_request).order_by('-identified_at')
    donor_assignments = DonorAssignment.objects.filter(request=blood_request).select_related('donor', 'donor_master').order_by('-assigned_at')
    fallback_actions = FallbackAction.objects.filter(request=blood_request).order_by('-triggered_at')

    accepted_with_distance = []
    for resp in accepted_responses:
        dist_km = None
        if blood_request.req_lat is not None and blood_request.req_lng is not None and hasattr(resp.donor, 'donor_profile'):
            prof = resp.donor.donor_profile
            if prof.last_lat is not None and prof.last_lng is not None:
                d = haversine_km(
                    blood_request.req_lat, blood_request.req_lng,
                    prof.last_lat, prof.last_lng
                )
                dist_km = round(d, 2) if d is not None else None
        accepted_with_distance.append({'response': resp, 'distance_km': dist_km})

    context = {
        'blood_request': blood_request,
        'notified_count': notified_count,
        'accepted_responses': accepted_responses,
        'accepted_with_distance': accepted_with_distance,
        'timeline_events': timeline_events,
        'eta_trackings': eta_trackings,
        'delay_reasons': delay_reasons,
        'donor_assignments': donor_assignments,
        'fallback_actions': fallback_actions,
    }
    return render(request, 'demo_admin_request_detail.html', context)


@login_required
@user_passes_test(is_staff_user)
def admin_request_detail_modal(request, request_id):
    """Returns only the inner HTML for request detail (for dashboard modal)."""
    blood_request = get_object_or_404(BloodRequest, id=request_id)
    notified_count = Notification.objects.filter(blood_request=blood_request).count()
    accepted_responses = DonorResponse.objects.filter(
        blood_request=blood_request,
        response='accepted'
    ).select_related('donor', 'donor__donor_profile')
    timeline_events = RequestTimeline.objects.filter(request=blood_request).order_by('event_time')
    eta_trackings = EtaTracking.objects.filter(request=blood_request).order_by('-committed_at')
    delay_reasons = DelayReason.objects.filter(request=blood_request).order_by('-identified_at')
    donor_assignments = DonorAssignment.objects.filter(request=blood_request).select_related('donor', 'donor_master').order_by('-assigned_at')
    fallback_actions = FallbackAction.objects.filter(request=blood_request).order_by('-triggered_at')
    accepted_with_distance = []
    for resp in accepted_responses:
        dist_km = None
        if blood_request.req_lat is not None and blood_request.req_lng is not None and hasattr(resp.donor, 'donor_profile'):
            prof = resp.donor.donor_profile
            if prof.last_lat is not None and prof.last_lng is not None:
                d = haversine_km(
                    float(blood_request.req_lat), float(blood_request.req_lng),
                    float(prof.last_lat), float(prof.last_lng)
                )
                dist_km = round(d, 2) if d is not None else None
        accepted_with_distance.append({'response': resp, 'distance_km': dist_km})
    context = {
        'blood_request': blood_request,
        'notified_count': notified_count,
        'accepted_responses': accepted_responses,
        'accepted_with_distance': accepted_with_distance,
        'timeline_events': timeline_events,
        'eta_trackings': eta_trackings,
        'delay_reasons': delay_reasons,
        'donor_assignments': donor_assignments,
        'fallback_actions': fallback_actions,
    }
    return render(request, 'admin_request_detail_modal.html', context)


@login_required
@user_passes_test(is_staff_user)
def admin_hospitals(request):
    """Admin list of hospitals (HospitalMaster)."""
    hospitals = HospitalMaster.objects.all().order_by('hospital_name')
    context = {'hospitals': hospitals}
    return render(request, 'admin_hospitals.html', context)


@login_required
@user_passes_test(is_staff_user)
def admin_blood_banks(request):
    """Admin list of blood banks (BloodBankMaster)."""
    blood_banks = BloodBankMaster.objects.all().order_by('name')
    context = {'blood_banks': blood_banks}
    return render(request, 'admin_blood_banks.html', context)


@login_required
@user_passes_test(is_staff_user)
def admin_cities(request):
    """Admin list of cities (DimCity)."""
    cities = DimCity.objects.all().order_by('state', 'city')
    context = {'cities': cities}
    return render(request, 'admin_cities.html', context)


@login_required
@user_passes_test(is_staff_user)
@require_http_methods(["GET", "POST"])
def admin_add_hospital(request):
    """Add hospital from frontend; data saved to backend and reflected on dashboard."""
    if request.method == 'POST':
        hospital_id = (request.POST.get('hospital_id') or '').strip()
        hospital_name = (request.POST.get('hospital_name') or '').strip()
        city = (request.POST.get('city') or '').strip()
        tier = (request.POST.get('tier') or '').strip()
        if not hospital_id or not hospital_name:
            messages.error(request, 'Hospital ID and Name are required.')
        else:
            try:
                hospital = HospitalMaster.objects.create(
                    hospital_id=hospital_id,
                    hospital_name=hospital_name,
                    city=city,
                    tier=tier,
                )
                # Optional: create first hospital metrics row if any metric field is provided
                m_date = request.POST.get('metrics_date')
                m_total = request.POST.get('metrics_total_requests')
                m_fulfilled = request.POST.get('metrics_fulfilled')
                m_failed = request.POST.get('metrics_failed')
                m_avg_time = request.POST.get('metrics_avg_fulfillment_time')
                m_sla_pct = request.POST.get('metrics_sla_breach_pct')
                if m_date or (m_total and m_total.strip()) or (m_fulfilled and m_fulfilled.strip()) or (m_failed and m_failed.strip()):
                    from django.utils.dateparse import parse_date
                    metrics_date = parse_date(m_date) if m_date and m_date.strip() else timezone.now().date()
                    total_requests = int(m_total) if m_total and str(m_total).strip() else 0
                    fulfilled = int(m_fulfilled) if m_fulfilled and str(m_fulfilled).strip() else 0
                    failed = int(m_failed) if m_failed and str(m_failed).strip() else 0
                    avg_ft = float(m_avg_time) if m_avg_time and str(m_avg_time).strip() else None
                    sla_pct = float(m_sla_pct) if m_sla_pct and str(m_sla_pct).strip() else None
                    HospitalMetrics.objects.update_or_create(
                        hospital=hospital,
                        date=metrics_date,
                        defaults={
                            'total_requests': total_requests,
                            'fulfilled': fulfilled,
                            'failed': failed,
                            'avg_fulfillment_time': avg_ft,
                            'sla_breach_pct': sla_pct,
                        },
                    )
                messages.success(request, f'Hospital "{hospital_name}" added.')
                next_url = request.GET.get('next') or request.POST.get('next') or 'admin_dashboard'
                return redirect(next_url)
            except IntegrityError:
                messages.error(request, f'Hospital ID "{hospital_id}" already exists.')
        # fall through to re-render with errors
    return render(request, 'admin_add_hospital.html', {})


@login_required
@user_passes_test(is_staff_user)
@require_http_methods(["GET", "POST"])
def admin_add_blood_bank(request):
    """Add blood bank from frontend; data saved to backend and reflected on dashboard."""
    if request.method == 'POST':
        blood_bank_id = (request.POST.get('blood_bank_id') or '').strip()
        name = (request.POST.get('name') or '').strip()
        city = (request.POST.get('city') or '').strip()
        reliability = request.POST.get('reliability_score')
        reliability = float(reliability) if reliability and str(reliability).strip() else None
        if not blood_bank_id or not name:
            messages.error(request, 'Blood Bank ID and Name are required.')
        else:
            try:
                BloodBankMaster.objects.create(
                    blood_bank_id=blood_bank_id,
                    name=name,
                    city=city,
                    reliability_score=reliability,
                )
                messages.success(request, f'Blood bank "{name}" added.')
                next_url = request.GET.get('next') or request.POST.get('next') or 'admin_dashboard'
                return redirect(next_url)
            except IntegrityError:
                messages.error(request, f'Blood Bank ID "{blood_bank_id}" already exists.')
    return render(request, 'admin_add_blood_bank.html', {})


@login_required
@user_passes_test(is_staff_user)
@require_http_methods(["GET", "POST"])
def admin_add_city(request):
    """Add city from frontend; data saved to backend and reflected on dashboard."""
    if request.method == 'POST':
        city = (request.POST.get('city') or '').strip()
        state = (request.POST.get('state') or '').strip()
        region = (request.POST.get('region') or '').strip()
        if not city or not state:
            messages.error(request, 'City and State are required.')
        else:
            try:
                DimCity.objects.create(city=city, state=state, region=region)
                messages.success(request, f'City "{city}, {state}" added.')
                next_url = request.GET.get('next') or request.POST.get('next') or 'admin_dashboard'
                return redirect(next_url)
            except IntegrityError:
                messages.error(request, f'City "{city}" in state "{state}" already exists.')
    return render(request, 'admin_add_city.html', {})


ELIGIBILITY_DAYS = 90


def _donor_dashboard_metrics(request_user):
    """Compute donation-based metrics for donor dashboard (like Flutter)."""
    accepted_responses = DonorResponse.objects.filter(
        donor=request_user, response='accepted'
    ).select_related('blood_request').order_by('responded_at')
    
    now = timezone.now()
    donations = [
        {'date': r.responded_at, 'urgency': r.blood_request.urgency}
        for r in accepted_responses
    ]
    
    this_month = sum(1 for d in donations if d['date'].month == now.month and d['date'].year == now.year)
    last_donation_date = donations[-1]['date'] if donations else None
    lifetime = len(donations)
    
    if last_donation_date:
        days_since = (now - last_donation_date.replace(tzinfo=now.tzinfo)).days
        days_until_eligible = max(0, ELIGIBILITY_DAYS - days_since)
        eligibility_progress = min(1.0, days_since / ELIGIBILITY_DAYS) if days_until_eligible > 0 else 1.0
    else:
        days_until_eligible = 0
        eligibility_progress = 1.0
    
    by_day = [0] * 31
    for d in donations:
        if d['date'].month == now.month and d['date'].year == now.year:
            by_day[d['date'].day - 1] += 1
    
    month_names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    by_month = []
    for i in range(12):
        rel = now.month - 1 - i
        year = now.year + (rel // 12)
        month = (rel % 12) + 1
        count = sum(1 for d in donations if d['date'].month == month and d['date'].year == year)
        label = f"{month_names[month - 1]}\n'{str(year)[2:]}"
        by_month.append({'label': label, 'count': count})
    by_month.reverse()
    
    by_type = {'critical': 0, 'high': 0, 'medium': 0}
    for d in donations:
        by_type[d['urgency']] = by_type.get(d['urgency'], 0) + 1
    
    months_with_donation = set(d['date'].year * 12 + d['date'].month for d in donations)
    sorted_months = sorted(months_with_donation, reverse=True)
    streak = 0
    current = now.year * 12 + now.month
    for m in sorted_months:
        if m == current:
            streak += 1
            current -= 1
        elif m < current:
            break
    
    badges = [lifetime >= 1, lifetime >= 5, lifetime >= 10, lifetime >= 25]
    
    chart_by_type_pie = {
        'labels': ['Emergency', 'Hospital', 'Other'],
        'data': [by_type.get('critical', 0), by_type.get('high', 0), by_type.get('medium', 0)],
    }
    return {
        'this_month_count': this_month,
        'last_donation_date': last_donation_date,
        'lifetime_count': lifetime,
        'days_until_eligible': days_until_eligible,
        'eligibility_progress': eligibility_progress,
        'chart_by_day': by_day,
        'chart_by_month': by_month,
        'chart_by_type': by_type,
        'chart_by_type_pie': chart_by_type_pie,
        'streak': streak,
        'badges': badges,
    }


@login_required
def donor_notifications(request):
    """Donor page to view their notifications and blood requests (dashboard like Flutter)."""
    try:
        donor_profile = DonorProfile.objects.get(user=request.user)
        has_profile = True
    except DonorProfile.DoesNotExist:
        has_profile = False
        donor_profile = None
    
    notifications = Notification.objects.filter(
        user=request.user
    ).select_related('blood_request').order_by('-created_at')
    
    responded_request_ids = set(
        DonorResponse.objects.filter(donor=request.user).values_list('blood_request_id', flat=True)
    )
    
    notifications_with_status = []
    accepted_count = 0
    rejected_count = 0
    for notification in notifications:
        notification.has_responded = notification.blood_request_id in responded_request_ids
        if notification.has_responded:
            response = DonorResponse.objects.get(
                donor=request.user,
                blood_request_id=notification.blood_request_id
            )
            notification.response_status = response.response
            if response.response == 'accepted':
                accepted_count += 1
            else:
                rejected_count += 1
        notifications_with_status.append(notification)
    
    total_notifications = len(notifications_with_status)
    pending_count = total_notifications - accepted_count - rejected_count
    
    metrics = _donor_dashboard_metrics(request.user)
    
    responded_list = [n for n in notifications_with_status if n.has_responded]
    resolved_delays = DelayReason.objects.filter(
        reported_by=request.user, resolved=True
    ).select_related('request').order_by('-resolved_at')[:20]
    
    context = {
        'notifications': notifications_with_status,
        'responded_list': responded_list,
        'resolved_delays': resolved_delays,
        'user': request.user,
        'has_profile': has_profile,
        'donor_profile': donor_profile,
        'total_notifications': total_notifications,
        'pending_count': pending_count,
        'accepted_count': accepted_count,
        'rejected_count': rejected_count,
        'this_month_count': metrics['this_month_count'],
        'last_donation_date': metrics['last_donation_date'],
        'lifetime_count': metrics['lifetime_count'],
        'days_until_eligible': metrics['days_until_eligible'],
        'eligibility_progress': metrics['eligibility_progress'],
        'chart_by_day': metrics['chart_by_day'],
        'chart_by_month': metrics['chart_by_month'],
        'chart_by_type': metrics['chart_by_type'],
        'chart_by_type_pie': metrics['chart_by_type_pie'],
        'streak': metrics['streak'],
        'badges': metrics['badges'],
    }
    return render(request, 'demo_donor_notifications.html', context)


@login_required
@require_http_methods(["POST"])
def donor_update_location(request):
    """Update donor's last-known location (lat/lng) from web. Enables distance-based matching."""
    try:
        donor_profile = DonorProfile.objects.get(user=request.user)
    except DonorProfile.DoesNotExist:
        return JsonResponse({'status': 'error', 'message': 'Donor profile not found'}, status=404)
    lat = _parse_float(request.POST.get('lat') or request.POST.get('last_lat'))
    lng = _parse_float(request.POST.get('lng') or request.POST.get('last_lng'))
    if lat is None or lng is None:
        return JsonResponse({'status': 'error', 'message': 'Latitude and longitude are required'}, status=400)
    from django.utils import timezone
    donor_profile.last_lat = lat
    donor_profile.last_lng = lng
    donor_profile.location_updated_at = timezone.now()
    donor_profile.save()
    return JsonResponse({
        'status': 'ok',
        'message': f'Location updated. You will be matched for requests within range.',
        'lat': float(donor_profile.last_lat),
        'lng': float(donor_profile.last_lng),
    })


@login_required
@require_http_methods(["POST"])
def donor_respond(request):
    """API endpoint for donor to accept/reject a blood request"""
    try:
        data = json.loads(request.body)
        blood_request_id = data.get('blood_request_id')
        response = data.get('response')
        
        if not blood_request_id or not response:
            return JsonResponse({'status': 'error', 'message': 'Missing required fields'}, status=400)
        
        if response not in ['accepted', 'rejected']:
            return JsonResponse({'status': 'error', 'message': 'Invalid response value'}, status=400)
        
        blood_request = get_object_or_404(BloodRequest, id=blood_request_id)
        
        # Create or update donor response
        donor_response, created = DonorResponse.objects.update_or_create(
            blood_request=blood_request,
            donor=request.user,
            defaults={'response': response}
        )
        if response == 'accepted':
            AdminNotification.objects.create(
                notification_type=AdminNotification.TYPE_DONOR_ACCEPTED,
                blood_request=blood_request,
                donor=request.user,
            )
        
        # Mark notification as read
        Notification.objects.filter(
            user=request.user,
            blood_request=blood_request
        ).update(is_read=True)
        
        return JsonResponse({
            'status': 'ok',
            'message': f'Response recorded: {response}',
            'created': created
        })
        
    except json.JSONDecodeError:
        return JsonResponse({'status': 'error', 'message': 'Invalid JSON'}, status=400)
    except Exception as e:
        return JsonResponse({'status': 'error', 'message': str(e)}, status=500)


@login_required
@require_http_methods(["POST"])
def donor_submit_delay(request):
    """Donor reports delay (can't come within time). Creates DelayReason with reported_by=donor."""
    try:
        data = json.loads(request.body)
        blood_request_id = data.get('blood_request_id')
        stage = (data.get('stage') or '').strip() or 'Acceptance'
        delay_reason = (data.get('delay_reason') or '').strip()
        delay_category = (data.get('delay_category') or '').strip() or None
        delay_minutes = data.get('delay_minutes')
        if not blood_request_id or not delay_reason:
            return JsonResponse({'status': 'error', 'message': 'blood_request_id and delay_reason are required'}, status=400)
        if stage not in dict(DelayReason.STAGE_CHOICES):
            stage = 'Acceptance'
        if delay_category and delay_category not in dict(DelayReason.CATEGORY_CHOICES):
            delay_category = None
        delay_minutes = int(delay_minutes) if delay_minutes is not None and str(delay_minutes).strip() else None
        blood_request = get_object_or_404(BloodRequest, id=blood_request_id)
        if not DonorResponse.objects.filter(blood_request=blood_request, donor=request.user, response='accepted').exists():
            return JsonResponse({'status': 'error', 'message': 'You must have accepted this request to report a delay'}, status=400)
        DelayReason.objects.create(
            request=blood_request,
            reported_by=request.user,
            stage=stage,
            delay_reason=delay_reason[:100],
            delay_category=delay_category or '',
            delay_minutes=delay_minutes,
        )
        return JsonResponse({'status': 'ok', 'message': 'Delay reason submitted'})
    except json.JSONDecodeError:
        return JsonResponse({'status': 'error', 'message': 'Invalid JSON'}, status=400)
    except Exception as e:
        return JsonResponse({'status': 'error', 'message': str(e)}, status=500)


@login_required
@require_http_methods(["GET"])
def api_donor_poll(request):
    """JSON: notifications list, counts, and resolved delays (for real-time donor dashboard). Donor only."""
    if request.user.is_staff:
        return JsonResponse({'error': 'For donors only'}, status=403)
    notifications = Notification.objects.filter(
        user=request.user
    ).select_related('blood_request').order_by('-created_at')
    responses_map = dict(
        DonorResponse.objects.filter(donor=request.user).values_list('blood_request_id', 'response')
    )
    notifications_data = []
    accepted_count = 0
    rejected_count = 0
    for n in notifications:
        status = responses_map.get(n.blood_request_id)
        has_responded = status is not None
        if has_responded:
            if status == 'accepted':
                accepted_count += 1
            else:
                rejected_count += 1
        notifications_data.append({
            'id': n.blood_request_id,
            'blood_group': n.blood_request.blood_group,
            'urgency': n.blood_request.urgency,
            'urgency_display': n.blood_request.get_urgency_display(),
            'units_needed': n.blood_request.units_needed,
            'note': n.blood_request.note or '',
            'created_at': n.blood_request.created_at.isoformat() if n.blood_request.created_at else None,
            'notification_created_at': n.created_at.isoformat() if n.created_at else None,
            'has_responded': has_responded,
            'response_status': status,
        })
    total = len(notifications_data)
    pending_count = total - accepted_count - rejected_count
    since = request.GET.get('resolved_since')
    resolved_delays = []
    qs = DelayReason.objects.filter(
        reported_by=request.user,
        resolved=True
    ).select_related('request').order_by('-resolved_at')
    if since:
        try:
            from datetime import datetime
            since_dt = timezone.make_aware(datetime.fromisoformat(since.replace('Z', '+00:00')))
            qs = qs.filter(resolved_at__gte=since_dt)
        except Exception:
            pass
    for d in qs[:50]:
        resolved_delays.append({
            'request_id': d.request_id,
            'resolved_at': d.resolved_at.isoformat() if d.resolved_at else None,
        })
    return JsonResponse({
        'notifications': notifications_data,
        'total_notifications': total,
        'pending_count': pending_count,
        'accepted_count': accepted_count,
        'rejected_count': rejected_count,
        'resolved_delays': resolved_delays,
    })


@login_required
@user_passes_test(is_staff_user)
@require_http_methods(["GET"])
def api_admin_unresolved_delay_count(request):
    """JSON: count of unresolved delay reasons (for admin navbar badge)."""
    count = DelayReason.objects.filter(resolved=False).count()
    return JsonResponse({'count': count})


@login_required
@user_passes_test(is_staff_user)
@require_http_methods(["GET"])
def api_admin_request_delays(request, request_id):
    """JSON: list of delay reasons for a blood request (for admin delay modal, live data)."""
    blood_request = get_object_or_404(BloodRequest, id=request_id)
    delays = DelayReason.objects.filter(
        request=blood_request
    ).select_related('reported_by', 'reported_by__donor_profile').order_by('-identified_at')
    out = []
    for d in delays:
        phone = ''
        if d.reported_by and hasattr(d.reported_by, 'donor_profile') and d.reported_by.donor_profile:
            phone = d.reported_by.donor_profile.phone or ''
        out.append({
            'delay_id': str(d.delay_id),
            'stage': d.stage,
            'stage_display': d.get_stage_display(),
            'delay_reason': d.delay_reason,
            'delay_category': d.delay_category or '',
            'delay_category_display': d.get_delay_category_display() if d.delay_category else '—',
            'delay_minutes': d.delay_minutes,
            'resolved': d.resolved,
            'resolved_at': d.resolved_at.isoformat() if d.resolved_at else None,
            'identified_at': d.identified_at.strftime('%b %d, %Y %H:%M') if d.identified_at else '',
            'reported_by_username': d.reported_by.username if d.reported_by else '—',
            'reported_by_phone': phone,
            'resolve_url': reverse('admin_resolve_delay', kwargs={'delay_uuid': d.delay_id}),
        })
    return JsonResponse({'delays': out})


@login_required
@user_passes_test(is_staff_user)
@require_http_methods(["POST"])
def admin_resolve_delay(request, delay_uuid):
    """Mark a delay reason as resolved (admin accepted). Sets resolved=True, resolved_at=now. Supports AJAX."""
    from django.utils import timezone
    delay = get_object_or_404(DelayReason, delay_id=delay_uuid)
    delay.resolved = True
    delay.resolved_at = timezone.now()
    delay.save()
    if request.headers.get('X-Requested-With') == 'XMLHttpRequest' or request.accepts('application/json'):
        return JsonResponse({'status': 'ok', 'message': 'Delay marked as resolved.'})
    messages.success(request, f'Delay reason marked as resolved.')
    redirect_url = request.META.get('HTTP_REFERER') or reverse('admin_dashboard')
    return redirect(redirect_url)


# ----- Donor registration (web): form -> blood group modal -> OTP -> auto login -----

def _bool_choice(val):
    if not val or val == '':
        return None
    return val.lower() == 'yes'


@require_http_methods(["GET", "POST"])
def donor_register(request):
    """Step 1: Show registration form. POST creates User (inactive) + DonorProfile, returns JSON to show blood group modal."""
    if request.method == 'GET':
        form = DonorRegistrationForm()
        err = request.GET.get('err')
        err_message = {'session_expired': 'Session expired. Please complete registration again.', 'invalid_blood_group': 'Invalid blood group. Please try again.'}.get(err, '')
        return render(request, 'registration/register.html', {'form': form, 'register_error': err_message})
    # POST (include FILES for profile_photo)
    form = DonorRegistrationForm(request.POST, request.FILES)
    if not form.is_valid():
        return JsonResponse({'success': False, 'errors': form.errors}, status=400)
    data = form.cleaned_data
    username = data['username'].strip().lower()
    mobile = data['mobile'].strip()
    # Create User, UserProfile (personal/location/health data), DonorProfile (phone only; blood_group set after selection)
    with transaction.atomic():
        user = User.objects.create_user(
            username=username,
            email='',
            password=data['password'],
            first_name=username,
            is_active=True,
        )
        UserProfile.objects.create(
            user=user,
            gender=data.get('gender') or None,
            date_of_birth=data.get('date_of_birth'),
            state=data.get('state') or '',
            city=data.get('city') or '',
            area=data.get('area') or '',
            pincode=data.get('pincode') or '',
            weight_kg=data.get('weight_kg'),
            donated_before=_bool_choice(data.get('donated_before')),
            last_donation_date=data.get('last_donation_date'),
            medical_conditions=_bool_choice(data.get('medical_conditions')),
            currently_healthy=_bool_choice(data.get('currently_healthy')),
            emergency_available=_bool_choice(data.get('emergency_available')) if data.get('emergency_available') else True,
            preferred_contact=data.get('preferred_contact') or 'call',
            consent_contact=bool(data.get('consent_contact')),
            consent_terms=bool(data.get('consent_terms')),
            alternate_mobile=data.get('alternate_mobile') or '',
            preferred_language=data.get('preferred_language') or '',
            preferred_contact_time=data.get('preferred_contact_time') or '',
            occupation=data.get('occupation') or '',
            emergency_contact_name=data.get('emergency_contact_name') or '',
            emergency_contact_number=data.get('emergency_contact_number') or '',
            profile_photo=data.get('profile_photo'),
        )
        DonorProfile.objects.create(
            user=user,
            phone=mobile,
            blood_group=None,
            phone_verified=False,
        )
    request.session['pending_verification_user_id'] = user.pk
    request.session['pending_verification_phone'] = mobile
    return JsonResponse({'success': True, 'message': 'Please select your blood group.'})


@require_http_methods(["POST"])
def donor_register_select_blood_group(request):
    """Step 2: Save blood group, then redirect to login so user signs in and gets a proper session."""
    user_id = request.session.get('pending_verification_user_id')
    if not user_id:
        return HttpResponseRedirect('/register/?err=session_expired')
    if request.content_type and 'application/json' in request.content_type and request.body:
        try:
            data = json.loads(request.body)
        except json.JSONDecodeError:
            data = {}
    else:
        data = request.POST
    blood_group = (data.get('blood_group') or '').strip()
    if blood_group not in dict(DonorProfile.BLOOD_GROUP_CHOICES):
        return HttpResponseRedirect('/register/?err=invalid_blood_group')
    user = get_object_or_404(User, pk=user_id)
    profile = get_object_or_404(DonorProfile, user=user)
    profile.blood_group = blood_group
    profile.save(update_fields=['blood_group'])
    request.session.pop('pending_verification_user_id', None)
    request.session.pop('pending_verification_phone', None)
    # Redirect to login with next=/notifications/ so user signs in and is then redirected to dashboard
    return HttpResponseRedirect('/accounts/login/?next=/notifications/&registered=1')
