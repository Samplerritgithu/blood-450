# careapp/forms.py
from django import forms
from django.contrib.auth.models import User
from django.contrib.auth.forms import AuthenticationForm
from django.contrib.auth import authenticate
from django.core.exceptions import ValidationError
from django.utils.translation import gettext_lazy as _
from .models import DonorProfile, UserProfile


class DonorLoginForm(AuthenticationForm):
    """Login form that normalizes username (email) to lowercase so it matches registration.
    For superuser accounts, performs case-insensitive lookup to find the actual username."""
    def clean_username(self):
        value = self.cleaned_data.get('username', '')
        if not value:
            return value
        
        value = value.strip()
        
        # Try to find user case-insensitively first
        # This handles superusers created with mixed case usernames
        try:
            user = User.objects.get(username__iexact=value)
            # Return the actual username from database (preserves case)
            return user.username
        except User.DoesNotExist:
            # User doesn't exist, return lowercase for donor accounts
            # This will allow the authentication to fail with proper error message
            return value.lower()
    
    def clean(self):
        """Override clean to handle case-insensitive authentication.
        clean_username() already returns the correct username from database,
        so we just need to authenticate with it."""
        username = self.cleaned_data.get('username')
        password = self.cleaned_data.get('password')
        
        if username is None:
            # Username field validation failed, don't proceed
            return self.cleaned_data
        
        if password:
            # clean_username() already found the user case-insensitively
            # and returned the actual username from database
            # Now authenticate with that username
            user = authenticate(
                request=self.request,
                username=username,
                password=password
            )
            
            if user is None:
                # Raise ValidationError for invalid login
                raise ValidationError(
                    _("Please enter a correct username and password. Note that both fields may be case-sensitive."),
                    code='invalid_login',
                )
            
            if not user.is_active:
                raise ValidationError(
                    _("This account is inactive."),
                    code='inactive',
                )
            
            # Store the authenticated user (required by AuthenticationForm)
            self.user_cache = user
        
        return self.cleaned_data


class DonorRegistrationForm(forms.Form):
    """Registration form for donors."""
    username = forms.CharField(max_length=150, label='Username', widget=forms.TextInput(attrs={'placeholder': 'Choose a username (you will use this to log in)', 'autocomplete': 'username'}))
    mobile = forms.CharField(max_length=15, label='Mobile Number', widget=forms.TextInput(attrs={'placeholder': '10-digit mobile number'}))
    password = forms.CharField(label='Password', widget=forms.PasswordInput(attrs={'placeholder': 'Create password'}), min_length=8)
    confirm_password = forms.CharField(label='Confirm Password', widget=forms.PasswordInput(attrs={'placeholder': 'Confirm password'}))

    GENDER_CHOICES = [('', '-- Select --'), ('M', 'Male'), ('F', 'Female'), ('O', 'Other')]
    gender = forms.ChoiceField(choices=GENDER_CHOICES, required=False, label='Gender')

    date_of_birth = forms.DateField(required=False, label='Date of Birth', widget=forms.DateInput(attrs={'type': 'date'}))

    alternate_mobile = forms.CharField(max_length=15, required=False, label='Alternate Mobile', widget=forms.TextInput(attrs={'placeholder': '10-digit'}))
    preferred_language = forms.ChoiceField(
        choices=[('', '-- Select --'), ('english', 'English'), ('hindi', 'Hindi'), ('odia', 'Odia')],
        required=False, label='Preferred Language'
    )
    preferred_contact_time = forms.ChoiceField(
        choices=[('', '-- Select --'), ('morning', 'Morning'), ('afternoon', 'Afternoon'), ('evening', 'Evening'), ('any', 'Any')],
        required=False, label='Preferred Contact Time'
    )
    occupation = forms.CharField(max_length=100, required=False, label='Occupation', widget=forms.TextInput(attrs={'placeholder': 'e.g. Engineer, Student'}))
    emergency_contact_name = forms.CharField(max_length=100, required=False, label='Emergency Contact Name', widget=forms.TextInput(attrs={'placeholder': 'Name'}))
    emergency_contact_number = forms.CharField(max_length=15, required=False, label='Emergency Contact Number', widget=forms.TextInput(attrs={'placeholder': '10-digit'}))
    profile_photo = forms.ImageField(required=False, label='Profile Photo', widget=forms.FileInput(attrs={'accept': 'image/*'}))

    state = forms.CharField(max_length=100, required=False, label='State', widget=forms.TextInput(attrs={'placeholder': 'State'}))
    city = forms.CharField(max_length=100, required=False, label='City', widget=forms.TextInput(attrs={'placeholder': 'City'}))
    area = forms.CharField(max_length=200, required=False, label='Area / Locality', widget=forms.TextInput(attrs={'placeholder': 'Area or locality'}))
    pincode = forms.CharField(max_length=10, required=False, label='Pincode', widget=forms.TextInput(attrs={'placeholder': 'Pincode'}))

    weight_kg = forms.FloatField(required=False, label='Weight (kg)', widget=forms.NumberInput(attrs={'placeholder': 'Optional', 'step': '0.1', 'min': '0'}))

    donated_before = forms.ChoiceField(choices=[('', '-- Select --'), ('yes', 'Yes'), ('no', 'No')], required=False, label='Have you donated blood before?')
    last_donation_date = forms.DateField(required=False, label='Last Donation Date', widget=forms.DateInput(attrs={'type': 'date'}))

    medical_conditions = forms.ChoiceField(choices=[('', '-- Select --'), ('yes', 'Yes'), ('no', 'No')], required=False, label='Any major medical conditions?')
    currently_healthy = forms.ChoiceField(choices=[('', '-- Select --'), ('yes', 'Yes'), ('no', 'No')], required=False, label='Are you currently healthy?')

    emergency_available = forms.ChoiceField(choices=[('yes', 'Yes'), ('no', 'No')], required=True, label='Available for Emergency Donation?')
    preferred_contact = forms.ChoiceField(choices=UserProfile.CONTACT_METHOD_CHOICES, label='Preferred Contact Method', initial='call')

    consent_contact = forms.BooleanField(required=True, label='I agree to be contacted for blood donation requests')
    consent_terms = forms.BooleanField(required=True, label='I accept Terms & Privacy Policy')

    def clean_confirm_password(self):
        if self.cleaned_data.get('password') != self.cleaned_data.get('confirm_password'):
            raise ValidationError('Passwords do not match.')
        return self.cleaned_data['confirm_password']

    def clean_mobile(self):
        """Required donor mobile number."""
        mobile = (self.cleaned_data.get('mobile') or '').strip()
        if not mobile:
            raise ValidationError('Mobile number is required.')
        if not mobile.isdigit() or len(mobile) < 10:
            raise ValidationError('Enter a valid 10-digit mobile number.')
        if User.objects.filter(donor_profile__phone=mobile).exists():
            raise ValidationError('This mobile number is already registered.')
        return mobile

    def clean_username(self):
        raw = self.cleaned_data.get('username', '').strip()
        if not raw:
            raise ValidationError('Username is required.')
        if len(raw) < 3:
            raise ValidationError('Username must be at least 3 characters.')
        username = raw.lower()
        if not all(c.isalnum() or c in '._' for c in username):
            raise ValidationError('Username can only contain letters, numbers, dots and underscores.')
        if User.objects.filter(username__iexact=username).exists():
            raise ValidationError('This username is already taken.')
        return username

    def clean_alternate_mobile(self):
        val = (self.cleaned_data.get('alternate_mobile') or '').strip()
        if not val:
            return ''
        digits = ''.join(c for c in val if c.isdigit())
        if len(digits) != 10:
            raise ValidationError('Enter a valid 10-digit number.')
        return digits

    def clean_emergency_contact_number(self):
        val = (self.cleaned_data.get('emergency_contact_number') or '').strip()
        if not val:
            return ''
        digits = ''.join(c for c in val if c.isdigit())
        if len(digits) != 10:
            raise ValidationError('Enter a valid 10-digit number.')
        return digits

    def _bool_choice(self, val):
        if not val or val == '':
            return None
        return val == 'yes'
