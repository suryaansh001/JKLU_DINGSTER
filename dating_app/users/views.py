

from django.http import JsonResponse
from django.core.files.storage import FileSystemStorage
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser
from django.contrib.auth.models import User
from django.db import models
from .models import Profile, Post, Like, Match, Message
from .serializers import ProfileSerializer, PostSerializer, LikeSerializer, MatchSerializer, MessageSerializer
from rest_framework.permissions import IsAuthenticated


class RootView(APIView):
    def get(self, request):
        return JsonResponse({'message': 'Welcome to Dating App API'})

class RegisterView(APIView):
    def post(self, request, *args, **kwargs):
        username = request.data.get('username')
        password = request.data.get('password')
        favorite_food = request.data.get('favorite_food', '')
        two_truths_and_a_lie = request.data.get('two_truths_and_a_lie', '')
        dream_vacation = request.data.get('dream_vacation', '')
        if not username or not password:
            return JsonResponse({'error': 'Username and password required'}, status=400)
        if User.objects.filter(username=username).exists():
            return JsonResponse({'error': 'Username already taken'}, status=400)
        user = User.objects.create_user(username=username, password=password)
        Profile.objects.create(
            user=user,
            bio=f"{username}'s profile",
            favorite_food=favorite_food,
            two_truths_and_a_lie=two_truths_and_a_lie,
            dream_vacation=dream_vacation
        )
        return JsonResponse({'message': 'User registered successfully'}, status=201)

class ProfileList(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        profiles = Profile.objects.exclude(user=request.user)
        serializer = ProfileSerializer(profiles, many=True)
        for profile in serializer.data:
            if profile['video_url'] and not profile['video_url'].startswith('http'):
                profile['video_url'] = f'http://localhost:8000{profile["video_url"]}'
            profile['image_urls'] = [
                f'http://localhost:8000{url}' if not url.startswith('http') else url
                for url in profile['image_urls']
            ]
        return Response({'profiles': serializer.data})

class LikeProfile(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        liked_user_id = request.data.get('liked_user_id')
        if not liked_user_id:
            return JsonResponse({'error': 'Liked user ID required'}, status=400)
        try:
            liked_user = User.objects.get(id=liked_user_id)
            liked_profile, _ = Profile.objects.get_or_create(user=liked_user, defaults={'bio': f"{liked_user.username}'s profile"})
        except User.DoesNotExist:
            return JsonResponse({'error': 'User not found'}, status=404)
        
        liker = request.user
        if liker == liked_user:
            return JsonResponse({'error': 'Cannot like yourself'}, status=400)
        
        # Create like (using Like instead of LikedProfile)
        liker_profile, _ = Profile.objects.get_or_create(user=liker, defaults={'bio': f"{liker.username}'s profile"})
        like, created = Like.objects.get_or_create(liker=liker_profile, liked=liked_profile)
        if not created:
            return JsonResponse({'message': 'Already liked'}, status=200)
        
        # Check for mutual like and create match
        if Like.objects.filter(liker=liked_profile, liked=liker_profile).exists():
            Match.objects.get_or_create(user1=liker_profile, user2=liked_profile)
            return JsonResponse({'message': 'Match created!'}, status=201)
        
        return JsonResponse({'message': 'Profile liked'}, status=201)

class LikedProfilesView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        liker_profile = Profile.objects.get(user=request.user)
        likes = Like.objects.filter(liker=liker_profile)
        serializer = LikeSerializer(likes, many=True)  # Updated to LikeSerializer
        return Response(serializer.data)

class MatchesView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        profile = Profile.objects.get(user=request.user)
        matches = Match.objects.filter(models.Q(user1=profile) | models.Q(user2=profile))
        serializer = MatchSerializer(matches, many=True)
        return Response(serializer.data)

class ChatMessagesView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, match_id):
        match = Match.objects.get(id=match_id)
        if request.user not in [match.user1.user, match.user2.user]:
            return JsonResponse({'error': 'Not part of this match'}, status=403)
        messages = Message.objects.filter(match=match).order_by('timestamp')
        serializer = MessageSerializer(messages, many=True)
        return Response(serializer.data)

    def post(self, request, match_id):
        match = Match.objects.get(id=match_id)
        if request.user not in [match.user1.user, match.user2.user]:
            return JsonResponse({'error': 'Not part of this match'}, status=403)
        content = request.data.get('content')
        if not content:
            return JsonResponse({'error': 'Message content required'}, status=400)
        sender_profile = Profile.objects.get(user=request.user)
        message = Message.objects.create(match=match, sender=sender_profile, content=content)
        serializer = MessageSerializer(message)
        return Response(serializer.data, status=201)

class UploadVideo(APIView):
    parser_classes = [MultiPartParser]
    permission_classes = [IsAuthenticated]

    def post(self, request, *args, **kwargs):
        if 'video' in request.FILES:
            video_file = request.FILES['video']
            fs = FileSystemStorage(location=f'media/{request.user.username}', base_url=f'/media/{request.user.username}/')
            filename = fs.save(video_file.name, video_file)
            video_url = fs.url(filename)
            full_url = f'http://localhost:8000{video_url}'
            profile, _ = Profile.objects.get_or_create(user=request.user, defaults={'bio': f'{request.user.username}\'s profile'})
            profile.video_url = full_url
            profile.save()
            return JsonResponse({'video_url': full_url})
        return JsonResponse({'error': 'No video file provided'}, status=400)

class UploadImages(APIView):
    parser_classes = [MultiPartParser]
    permission_classes = [IsAuthenticated]

    def post(self, request, *args, **kwargs):
        if 'images' in request.FILES:
            fs = FileSystemStorage(location=f'media/{request.user.username}', base_url=f'/media/{request.user.username}/')
            image_urls = []
            for image_file in request.FILES.getlist('images'):
                filename = fs.save(image_file.name, image_file)
                image_url = fs.url(filename)
                full_url = f'http://localhost:8000{image_url}'
                image_urls.append(full_url)
            profile, _ = Profile.objects.get_or_create(user=request.user, defaults={'bio': f'{request.user.username}\'s profile'})
            profile.image_urls = list(set(profile.image_urls + image_urls))
            profile.save()
            return JsonResponse({'image_urls': image_urls})
        return JsonResponse({'error': 'No images provided'}, status=400)

class UploadPost(APIView):
    parser_classes = [MultiPartParser]
    permission_classes = [IsAuthenticated]

    def post(self, request, *args, **kwargs):
        if 'image' in request.FILES:
            image_file = request.FILES['image']
            caption = request.POST.get('caption', '')
            fs = FileSystemStorage(location=f'media/{request.user.username}', base_url=f'/media/{request.user.username}/')
            filename = fs.save(image_file.name, image_file)
            image_url = fs.url(filename)
            full_url = f'http://localhost:8000{image_url}'
            profile, _ = Profile.objects.get_or_create(user=request.user, defaults={'bio': f'{request.user.username}\'s profile'})
            post = Post(profile=profile, image_url=full_url, caption=caption)
            post.save()
            return JsonResponse({'image_url': full_url, 'caption': caption})
        return JsonResponse({'error': 'No image provided'}, status=400)

class GetProfile(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            profile = Profile.objects.get(user=request.user)
            return Response(ProfileSerializer(profile).data)
        except Profile.DoesNotExist:
            return JsonResponse({'error': 'Profile not found'}, status=404)

    def patch(self, request):
        profile = Profile.objects.get(user=request.user)
        for field in ['bio', 'favorite_food', 'two_truths_and_a_lie', 'dream_vacation']:
            if field in request.data:
                setattr(profile, field, request.data[field])
        profile.save()
        return Response(ProfileSerializer(profile).data)

# from django.http import JsonResponse
# from django.core.files.storage import FileSystemStorage


# from rest_framework.views import APIView
# from rest_framework.response import Response
# from rest_framework.parsers import MultiPartParser
# from django.contrib.auth.models import User
# from .models import Profile, Post
# from .serializers import ProfileSerializer, PostSerializer
# from rest_framework.permissions import IsAuthenticated

# class RootView(APIView):
#     def get(self, request):
#         return JsonResponse({"message": "Django server is running!"})

# class RegisterView(APIView):
#     def post(self, request, *args, **kwargs):
#         username = request.data.get('username')
#         password = request.data.get('password')
#         if not username or not password:
#             return JsonResponse({'error': 'Username and password required'}, status=400)
#         if User.objects.filter(username=username).exists():
#             return JsonResponse({'error': 'Username already taken'}, status=400)
#         user = User.objects.create_user(username=username, password=password)
#         Profile.objects.create(user=user, bio=f"{username}'s profile")
#         return JsonResponse({'message': 'User registered successfully'}, status=201)

# class UploadVideo(APIView):
#     parser_classes = [MultiPartParser]
#     permission_classes = [IsAuthenticated]

#     def post(self, request, *args, **kwargs):
#         if 'video' in request.FILES:
#             video_file = request.FILES['video']
#             fs = FileSystemStorage(location=f'media/{request.user.username}', base_url=f'/media/{request.user.username}/')
#             filename = fs.save(video_file.name, video_file)
#             video_url = fs.url(filename)
#             full_url = f'http://localhost:8000{video_url}'
#             profile, _ = Profile.objects.get_or_create(user=request.user, defaults={'bio': f'{request.user.username}\'s profile'})
#             profile.video_url = full_url
#             profile.save()
#             return JsonResponse({'video_url': full_url})
#         return JsonResponse({'error': 'No video file provided'}, status=400)

# class UploadImages(APIView):
#     parser_classes = [MultiPartParser]
#     permission_classes = [IsAuthenticated]

#     def post(self, request, *args, **kwargs):
#         if 'images' in request.FILES:
#             fs = FileSystemStorage(location=f'media/{request.user.username}', base_url=f'/media/{request.user.username}/')
#             image_urls = []
#             for image_file in request.FILES.getlist('images'):
#                 filename = fs.save(image_file.name, image_file)
#                 image_url = fs.url(filename)
#                 full_url = f'http://localhost:8000{image_url}'
#                 image_urls.append(full_url)
#             profile, _ = Profile.objects.get_or_create(user=request.user, defaults={'bio': f'{request.user.username}\'s profile'})
#             profile.image_urls = list(set(profile.image_urls + image_urls))
#             profile.save()
#             return JsonResponse({'image_urls': image_urls})
#         return JsonResponse({'error': 'No images provided'}, status=400)

# class UploadPost(APIView):
#     parser_classes = [MultiPartParser]
#     permission_classes = [IsAuthenticated]

#     def post(self, request, *args, **kwargs):
#         if 'image' in request.FILES:
#             image_file = request.FILES['image']
#             caption = request.POST.get('caption', '')
#             fs = FileSystemStorage(location=f'media/{request.user.username}', base_url=f'/media/{request.user.username}/')
#             filename = fs.save(image_file.name, image_file)
#             image_url = fs.url(filename)
#             full_url = f'http://localhost:8000{image_url}'
#             profile, _ = Profile.objects.get_or_create(user=request.user, defaults={'bio': f'{request.user.username}\'s profile'})
#             post = Post(profile=profile, image_url=full_url, caption=caption)
#             post.save()
#             return JsonResponse({'image_url': full_url, 'caption': caption})
#         return JsonResponse({'error': 'No image provided'}, status=400)

# class ProfileList(APIView):
#     def get(self, request):
#         profiles = Profile.objects.all()
#         serializer = ProfileSerializer(profiles, many=True)
#         for profile in serializer.data:
#             if profile['video_url'] and not profile['video_url'].startswith('http'):
#                 profile['video_url'] = f'http://localhost:8000{profile["video_url"]}'
#             elif profile['video_url'] and 'dating_app' in profile['video_url']:
#                 profile['video_url'] = profile['video_url'].replace('/dating_app/media/', '/media/')
#             profile['image_urls'] = [
#                 f'http://localhost:8000{url}' if not url.startswith('http') else url
#                 for url in profile['image_urls']
#             ]
#         return JsonResponse({'profiles': serializer.data})

# class GetProfile(APIView):
#     permission_classes = [IsAuthenticated]

#     def get(self, request):
#         user = request.user
#         try:
#             profile = Profile.objects.get(user=user)
#             return Response(ProfileSerializer(profile).data)
#         except Profile.DoesNotExist:
#             return JsonResponse({'error': 'Profile not found'}, status=404)


