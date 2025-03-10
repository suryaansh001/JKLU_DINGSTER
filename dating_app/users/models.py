from django.db import models
from django.contrib.auth.models import User

class Profile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    bio = models.TextField(blank=True)
    video_url = models.URLField(blank=True, null=True)
    image_urls = models.JSONField(default=list, blank=True)
    prompt_answers = models.JSONField(default=dict, blank=True)  # For Hinge-like prompts
    favorite_food = models.CharField(max_length=100, blank=True)  # Added
    two_truths_and_a_lie = models.TextField(blank=True)  # Added
    dream_vacation = models.CharField(max_length=100, blank=True)  # Added

    def __str__(self):
        return f"{self.user.username}'s Profile"

class Like(models.Model):
    liker = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name='likes_sent')
    liked = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name='likes_received')
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('liker', 'liked')  # Prevent duplicate likes

class Match(models.Model):
    user1 = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name='matches_as_user1')
    user2 = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name='matches_as_user2')
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user1', 'user2')

class Message(models.Model):
    match = models.ForeignKey(Match, on_delete=models.CASCADE, related_name='messages')
    sender = models.ForeignKey(Profile, on_delete=models.CASCADE)
    content = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)

class Post(models.Model):
    profile = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name='posts')
    image_url = models.URLField(blank=True, null=True)
    caption = models.TextField(max_length=500, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Post by {self.profile.user.username} at {self.created_at}"
# from django.db import models

# # Create your models here.
# from django.db import models
# from django.contrib.auth.models import User
# from django.db import models
# from django.contrib.auth.models import User



# # class Profile(models.Model):
# #     user = models.OneToOneField(User, on_delete=models.CASCADE)
# #     bio = models.TextField(blank=True)
# #     video_url = models.URLField(blank=True, null=True)
# from django.db import models
# from django.contrib.auth.models import User

# class Profile(models.Model):
#     user = models.OneToOneField(User, on_delete=models.CASCADE)
#     bio = models.TextField(blank=True)
#     video_url = models.URLField(blank=True, null=True)
#     image_urls = models.JSONField(default=list, blank=True)  # Stores list of image URLs

#     def __str__(self):
#         return f"{self.user.username}'s Profile"
# class Post(models.Model):
#     profile = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name='posts')
#     image_url = models.URLField(blank=True, null=True)
#     caption = models.TextField(max_length=500, blank=True)
#     created_at = models.DateTimeField(auto_now_add=True)

#     def __str__(self):
#         return f"Post by {self.profile.user.username} at {self.created_at}"   
# from django.db import models
# from django.contrib.auth.models import User
# from django.contrib.gis.db import models as gis_models

# class Profile(models.Model):
#     user = models.OneToOneField(User, on_delete=models.CASCADE)
#     bio = models.TextField(blank=True)
#     video_url = models.URLField(blank=True, null=True)
#     image_urls = models.JSONField(default=list, blank=True)
#     location = gis_models.PointField(null=True, blank=True)  # Add geolocation

#     def __str__(self):
#         return f"{self.user.username}'s Profile"

# class Post(models.Model):
#     profile = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name='posts')
#     image_url = models.URLField(blank=True, null=True)
#     caption = models.TextField(max_length=500, blank=True)
#     created_at = models.DateTimeField(auto_now_add=True)

#     def __str__(self):
#         return f"Post by {self.profile.user.username} at {self.created_at}"