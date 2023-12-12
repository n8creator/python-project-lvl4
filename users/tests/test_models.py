import pytest
from django.contrib.auth import get_user_model

from users.models import User


@pytest.mark.django_db
def test_create_user():
    User = get_user_model()
    user = User.objects.create_user(email="test@example.com", password="password")
    assert user.email == "test@example.com"
    assert user.check_password("password")
    assert not user.is_staff
    assert not user.is_superuser


@pytest.mark.django_db
def test_create_superuser():
    User = get_user_model()
    superuser = User.objects.create_superuser(
        email="admin@example.com", password="adminpassword"
    )
    assert superuser.email == "admin@example.com"
    assert superuser.check_password("adminpassword")
    assert superuser.is_staff
    assert superuser.is_superuser
