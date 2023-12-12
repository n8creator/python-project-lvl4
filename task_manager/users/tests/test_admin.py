import pytest
from django.contrib import admin

from task_manager.users.admin import UserAdmin, UserChangeForm, UserCreationForm
from task_manager.users.models import User


@pytest.fixture
def user(django_db_setup, django_db_blocker):
    with django_db_blocker.unblock():
        return User.objects.create_user(email="test@example.com", password="password")


@pytest.fixture
def superuser(django_db_setup, django_db_blocker):
    with django_db_blocker.unblock():
        return User.objects.create_superuser(
            email="admin@example.com", password="adminpassword"
        )


@pytest.mark.django_db
def test_user_creation_form_valid(user):
    form = UserCreationForm(
        data={
            "email": "test2@example.com",
            "password1": "password",
            "password2": "password",
        }
    )
    assert form.is_valid()


@pytest.mark.django_db
def test_user_creation_form_invalid(user):
    form = UserCreationForm(
        data={
            "email": "test3@example.com",
            "password1": "password",
            "password2": "wrongpassword",
        }
    )
    assert not form.is_valid()


@pytest.mark.django_db
def test_user_change_form(user):
    form = UserChangeForm(instance=user)
    assert form.fields["password"].disabled


@pytest.mark.django_db
def test_user_admin(user):
    admin_instance = UserAdmin(User, admin.site)
    assert "email" in admin_instance.list_display
    assert "is_admin" in admin_instance.list_display


@pytest.mark.django_db
def test_user_admin_add_form_valid(superuser):
    form_data = {
        "email": "admin2@example.com",
        "password1": "adminpassword",
        "password2": "adminpassword",
    }
    form = UserAdmin.add_form(data=form_data)
    assert form.is_valid(), form.errors


@pytest.mark.django_db
def test_user_admin_add_form_invalid(superuser):
    form = UserAdmin.add_form(
        data={
            "email": "admin3@example.com",
            "password1": "adminpassword",
            "password2": "wrongpassword",
        }
    )
    assert not form.is_valid()
