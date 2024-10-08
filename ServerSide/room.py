import asyncio
import json
from typing import Any, List, Set
from client import Client

class PlayRoom:
    clients: Set[Client]
    room_no: int
    status: int
    o_player: str
    x_player: str
    board_state: List[List[int]]
    password: str

    # Khai báo các hằng số
    PLAYING_0 = 0  # Chờ player O đánh
    PLAYING_1 = 1  # Chờ player X đánh
    WAITING = -1
    WAIT_PLAYER = "Waiting for player..."

    def __init__(self, creator: Client, room_id: int, password: str):
        self.clients = {creator}
        self.room_no = room_id
        self.password = password
        self.o_player = creator.player_name
        self.x_player = self.WAIT_PLAYER
        self.status = PlayRoom.WAITING  # Mặc định là WAITING
        self.board_state = [[-1 for _ in range(3)] for _ in range(3)]
        creator.set_room(room_id)

    def start_game(self):
        self.status = PlayRoom.PLAYING_0
        print(f"Room {self.room_no} is now playing.")

    async def notify_clients(self, message):
        if self.clients:  # Check if there are any connected clients
            await asyncio.wait([client.ws.send(message) for client in self.clients])

    def add_client(self, client: Client):
        self.clients.add(client)
        client.set_room(self.room_no)

    def remove_client(self, client: Client):
        self.clients.remove(client)
        client.set_room(None)

    def get_room_status(self):
        # Lọc các client có player_name không trùng với o_player hoặc x_player
        filtered_clients = [
            client.player_name for client in self.clients
            if client.player_name != self.o_player and client.player_name != self.x_player
        ]
        # Create a dictionary with the room status
        room_status = {
            "room_no": self.room_no,
            "status": self.status,
            "o_player": self.o_player,
            "x_player": self.x_player,
            "viewers": filtered_clients
        }
        return json.dumps(room_status, indent=4)