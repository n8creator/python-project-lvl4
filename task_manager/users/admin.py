"""
Django Admin Customization For Users.
"""
from django import forms
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth.forms import ReadOnlyPasswordHashField
from django.core.exceptions import ValidationError

from task_manager.users.models import User


class UserCreationForm(forms.ModelForm):
    """
    A form for creating a new users. Includes all the required fields, plus a repeated password.
    """

    password1 = forms.CharField(label="Password", widget=forms.PasswordInput)
    password2 = forms.CharField(
        label="Password confirmation", widget=forms.PasswordInput
    )

    class Meta:
        model = User
        fields = ["email"]

    def clean_password2(self):
        # Check that the two passwords entries match
        password1 = self.cleaned_data.get("password1")
        password2 = self.cleaned_data.get("password2")
        if password1 and password2 and password1 != password2:
            raise ValidationError("Passwords don't match!")
        return password2

    def save(self, commit=True):
        # Save the provided password in hashed format
        user = super().save(commit=False)
        user.set_password(self.cleaned_data["password1"])
        if commit:
            user.save()
        return user


class UserChangeForm(forms.ModelForm):
    """
    A form for updating Users.
    """

    # Replace password field with admin's disabled password hash display field
    password = ReadOnlyPasswordHashField()  # type: ignore

    class Meta:
        model = User
        fields = ["email", "is_active", "is_admin"]


class UserAdmin(BaseUserAdmin):
    """
    Define Admin Page for Users.
    """

    # The forms to add and change user instances.
    form = UserChangeForm
    add_form = UserCreationForm

    # The fields to be used in displaying the User model.
    ordering = ["id"]
    list_display = ["email", "name", "last_login", "is_admin"]
    list_filter = ["is_admin"]
    search_fields = ["email"]
    fieldsets = [
        (None, {"fields": ["name", "email", "password"]}),
        ("Permissions", {"fields": ["is_active", "is_staff", "is_superuser"]}),
        ("System info", {"fields": ["last_login"]}),
    ]

    filter_horizontal = []
    readonly_fields = ["last_login", "password"]

    # Fieldsets used when creating a user.
    add_fieldsets = [
        (
            None,
            {
                "classes": ["wide"],
                "fields": [
                    "email",
                    "password1",
                    "password2",
                    "name",
                    "is_active",
                    "is_staff",
                    "is_superuser",
                ],
            },
        ),
    ]


# Register User models in admin
admin.site.register(User, UserAdmin)
