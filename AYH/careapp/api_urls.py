"""
API URL Configuration for Blood Donation System
REST API endpoints for Flutter mobile app
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView

from . import api_views

# Create router for ViewSets
router = DefaultRouter()
router.register(r'donors', api_views.DonorProfileViewSet, basename='donor')
router.register(r'blood-requests', api_views.BloodRequestViewSet, basename='blood-request')
router.register(r'notifications', api_views.NotificationViewSet, basename='notification')

# API URL patterns
urlpatterns = [
    # ==============================================================================
    # AUTHENTICATION ENDPOINTS
    # ==============================================================================
    path('auth/login/', api_views.login_view, name='api-login'),
    path('auth/register/', api_views.register_view, name='api-register'),
    path('auth/logout/', api_views.logout_view, name='api-logout'),
    path('auth/me/', api_views.current_user_view, name='api-current-user'),
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='api-token-refresh'),
    
    # ==============================================================================
    # DONOR RESPONSE ENDPOINT
    # ==============================================================================
    path('respond/', api_views.respond_to_request, name='api-respond'),
    
    # ==============================================================================
    # DASHBOARD ENDPOINT
    # ==============================================================================
    path('dashboard/', api_views.admin_dashboard, name='api-dashboard'),
    
    # ==============================================================================
    # ROUTER ENDPOINTS (ViewSets)
    # ==============================================================================
    # Includes:
    # - /api/donors/
    # - /api/blood-requests/
    # - /api/notifications/
    path('', include(router.urls)),
]
