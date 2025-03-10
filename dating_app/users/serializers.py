from rest_framework import serializers
from .models import Profile, Post, Like, Match, Message

class PostSerializer(serializers.ModelSerializer):
    class Meta:
        model = Post
        fields = ['id', 'image_url', 'caption', 'created_at']

class ProfileSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    posts = PostSerializer(many=True, read_only=True)

    class Meta:
        model = Profile
        fields = ['id', 'username', 'bio', 'video_url', 'image_urls', 'posts', 'favorite_food', 'two_truths_and_a_lie', 'dream_vacation']

class LikeSerializer(serializers.ModelSerializer):  # Renamed from LikedProfileSerializer
    liked_username = serializers.CharField(source='liked.user.username', read_only=True)

    class Meta:
        model = Like
        fields = ['id', 'liked_username', 'timestamp']

class MatchSerializer(serializers.ModelSerializer):
    user1_username = serializers.CharField(source='user1.user.username', read_only=True)
    user2_username = serializers.CharField(source='user2.user.username', read_only=True)

    class Meta:
        model = Match
        fields = ['id', 'user1_username', 'user2_username', 'timestamp']

class MessageSerializer(serializers.ModelSerializer):
    sender_username = serializers.CharField(source='sender.user.username', read_only=True)

    class Meta:
        model = Message
        fields = ['id', 'sender_username', 'content', 'timestamp']