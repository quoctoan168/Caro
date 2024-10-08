from websockets import WebSocketServerProtocol

class Client:
    ws: WebSocketServerProtocol
    player_name: str
    player_status: int
    room_no: int

    def __init__(self, ws_: WebSocketServerProtocol, player_name_: str, player_status_: int, room_no_: int = None):
        self.ws = ws_
        self.player_name = player_name_
        self.player_status = player_status_
        self.room_no = room_no_

    def __repr__(self):
        return f"Client(name={self.player_name}, status={self.player_status}, room_no={self.room_no})"
    
    def get_room(self):
        return self.room_no

    def set_room(self, room_no: int):
        self.room_no = room_no