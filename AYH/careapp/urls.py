from django.urls import path
from . import views

urlpatterns = [
    # Home redirect
    path('home/', views.home_redirect, name='home_redirect'),
    
    # Registration (donor) – do not change existing login/dashboard logic
    path('register/', views.donor_register, name='donor_register'),
    path('register/select-blood-group/', views.donor_register_select_blood_group, name='donor_register_select_blood_group'),
    
    # Admin pages
    path('dashboard/', views.admin_dashboard, name='admin_dashboard'),
    path('all-requests/', views.admin_all_requests, name='admin_all_requests'),
    path('create-request/', views.admin_create_request, name='admin_create_request'),
    path('request/<int:request_id>/edit/', views.admin_edit_request, name='admin_edit_request'),
    path('request/<int:request_id>/delete/', views.admin_delete_request, name='admin_delete_request'),
    path('notifications/delete/', views.admin_delete_notifications, name='admin_delete_notifications'),
    path('request/<int:request_id>/', views.admin_request_detail, name='admin_request_detail'),
    path('request/<int:request_id>/detail-modal/', views.admin_request_detail_modal, name='admin_request_detail_modal'),
    path('hospitals/', views.admin_hospitals, name='admin_hospitals'),
    path('hospitals/add/', views.admin_add_hospital, name='admin_add_hospital'),
    path('blood-banks/', views.admin_blood_banks, name='admin_blood_banks'),
    path('blood-banks/add/', views.admin_add_blood_bank, name='admin_add_blood_bank'),
    path('cities/', views.admin_cities, name='admin_cities'),
    path('cities/add/', views.admin_add_city, name='admin_add_city'),
    
    # Donor pages
    path('notifications/', views.donor_notifications, name='donor_notifications'),
    
    # API endpoints
    path('update-location/', views.donor_update_location, name='donor_update_location'),
    path('respond/', views.donor_respond, name='donor_respond'),
    path('submit-delay/', views.donor_submit_delay, name='donor_submit_delay'),
    path('delay/<uuid:delay_uuid>/resolve/', views.admin_resolve_delay, name='admin_resolve_delay'),
    # Real-time poll APIs
    path('api/donor/poll/', views.api_donor_poll, name='api_donor_poll'),
    path('api/admin/delays-unresolved-count/', views.api_admin_unresolved_delay_count, name='api_admin_unresolved_delay_count'),
    path('api/admin/request/<int:request_id>/delays/', views.api_admin_request_delays, name='api_admin_request_delays'),
]
