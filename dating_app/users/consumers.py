from channels.generic.websocket import AsyncWebsocketConsumer
import json
from .models import Message, Match
from django.contrib.auth.models import User
from channels.db import database_sync_to_async

class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.match_id = self.scope['url_route']['kwargs']['match_id']
        self.room_group_name = f'chat_{self.match_id}'

        # Verify the user is part of the match
        user = self.scope['user']
        if not await self._is_user_in_match(user, self.match_id):
            await self.close()
            return

        await self.channel_layer.group_add(self.room_group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(self.room_group_name, self.channel_name)

    async def receive(self, text_data):
        data = json.loads(text_data)
        message = data['message']
        sender = self.scope['user']

        # Save the message to the database
        await self._save_message(sender, self.match_id, message)

        # Broadcast the message to the group
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'chat_message',
                'content': message,
                'sender_username': sender.username,
                'timestamp': data['timestamp'],
            }
        )

    async def chat_message(self, event):
        await self.send(text_data=json.dumps({
            'content': event['content'],
            'sender_username': event['sender_username'],
            'timestamp': event['timestamp'],
        }))

    @database_sync_to_async
    def _is_user_in_match(self, user, match_id):
        try:
            match = Match.objects.get(id=match_id)
            return user in [match.user1, match.user2]
        except Match.DoesNotExist:
            return False

    @database_sync_to_async
    def _save_message(self, sender, match_id, content):
        match = Match.objects.get(id=match_id)
        Message.objects.create(sender=sender, match=match, content=content)from channels.generic.websocket import AsyncWebsocketConsumer
import json
from .models import Message, Match
from django.contrib.auth.models import User
from channels.db import database_sync_to_async

class ChatConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.match_id = self.scope['url_route']['kwargs']['match_id']
        self.room_group_name = f'chat_{self.match_id}'

        # Verify the user is part of the match
        user = self.scope['user']
        if not await self._is_user_in_match(user, self.match_id):
            await self.close()
            return

        await self.channel_layer.group_add(self.room_group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(self.room_group_name, self.channel_name)

    async def receive(self, text_data):
        data = json.loads(text_data)
        message = data['message']
        sender = self.scope['user']

        # Save the message to the database
        await self._save_message(sender, self.match_id, message)

        # Broadcast the message to the group
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'chat_message',
                'content': message,
                'sender_username': sender.username,
                'timestamp': data['timestamp'],
            }
        )

    async def chat_message(self, event):
        await self.send(text_data=json.dumps({
            'content': event['content'],
            'sender_username': event['sender_username'],
            'timestamp': event['timestamp'],
        }))

    @database_sync_to_async
    def _is_user_in_match(self, user, match_id):
        try:
            match = Match.objects.get(id=match_id)
            return user in [match.user1, match.user2]
        except Match.DoesNotExist:
            return False

    @database_sync_to_async
    def _save_message(self, sender, match_id, content):
        match = Match.objects.get(id=match_id)
        Message.objects.create(sender=sender, match=match, content=content)