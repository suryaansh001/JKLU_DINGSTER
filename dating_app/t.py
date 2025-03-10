from django.contrib.auth.models import User
from users.models import Profile

# Create users if not already done
user1, _ = User.objects.get_or_create(username='user1', defaults={'password': 'pass123'})
user2, _ = User.objects.get_or_create(username='user2', defaults={'password': 'pass123'})

# Create profiles
Profile.objects.get_or_create(user=user1, defaults={'bio': 'Hey there!', 'video_url': 'http://localhost:8000/media/video1.mp4'})
Profile.objects.get_or_create(user=user2, defaults={'bio': 'Swipe me!', 'video_url': 'http://localhost:8000/media/video2.mp4'})