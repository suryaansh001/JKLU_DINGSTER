from django.urls import path
from .views import (
    RegisterView, ProfileList, LikeProfile, LikedProfilesView, MatchesView, ChatMessagesView,
    UploadVideo, UploadImages, UploadPost, GetProfile, RootView
)
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from django.conf import settings
from django.conf.urls.static import static
from . import views

urlpatterns = [
    path('', RootView.as_view(), name='root'),
    path('register/', RegisterView.as_view(), name='register'),
    path('profiles/', ProfileList.as_view(), name='profiles'),
    path('like/', LikeProfile.as_view(), name='like_profile'),
    path('liked/', LikedProfilesView.as_view(), name='liked_profiles'),
    path('matches/', MatchesView.as_view(), name='matches'),
    path('chat/<int:match_id>/', views.ChatMessagesView.as_view(), name='chat_messages'),
    path('upload-video/', UploadVideo.as_view(), name='upload-video'),
    path('upload-images/', UploadImages.as_view(), name='upload-images'),
    path('upload-post/', UploadPost.as_view(), name='upload-post'),
    path('profile/', GetProfile.as_view(), name='get_profile'),
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)