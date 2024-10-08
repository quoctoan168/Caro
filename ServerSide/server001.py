import asyncio
import websockets
import json
import uuid

state = "Initial state"
connected_clients = set()
rooms = {}

class PlayRoom:
    def __init__(self, creator):
        self.creator = creator
        self.clients = {creator}

    async def notify_clients(self, message):
        if self.clients:  # Check if there are any connected clients
            await asyncio.wait([client.send(message) for client in self.clients])

    def add_client(self, client):
        self.clients.add(client)

    def remove_client(self, client):
        self.clients.remove(client)
        if client == self.creator:
            self.clients.clear()


async def handle_create_room(ws):
    global rooms
    room_id = str(uuid.uuid4())  # Generate a unique room ID
    new_room = PlayRoom(ws)
    rooms[room_id] = new_room

    response = {
        "head": "setup",
        "yourturn": 0,
        "room_id": room_id,
    }
    await ws.send(json.dumps(response))
    print(f"Sent to client: {response}")


async def handle_join_room(ws, room_id):
    global rooms
    if room_id in rooms:
        room = rooms[room_id]
        room.add_client(ws)

        response = {
            "head": "setup",
            "yourturn": 1,
            "room_id": room_id,
        }
        await ws.send(json.dumps(response))
        print(f"Sent to client: {response}")
    else:
        error_response = {
            "head": "error",
            "message": "Room not found"
        }
        await ws.send(json.dumps(error_response))
        print("Sent to client: Room not found")


async def handle_move(ws, msg_data):
    room_id = msg_data.get("room_id")
    if room_id in rooms:
        room = rooms[room_id]
        if ws in room.clients:
            await room.notify_clients(json.dumps(msg_data))
            print(f"Broadcasted move to room {room_id}: {msg_data}")
        else:
            error_response = {
                "head": "error",
                "message": "Client not in room"
            }
            await ws.send(json.dumps(error_response))
            print("Sent to client: Client not in room")
    else:
        error_response = {
            "head": "error",
            "message": "Room not found"
        }
        await ws.send(json.dumps(error_response))
        print("Sent to client: Room not found")


async def send_room_list(ws):
    global rooms
    room_list = list(rooms.keys())
    response = {
        "head": "room_list",
        "rooms": room_list,
    }
    await ws.send(json.dumps(response))
    print(f"Sent to client: {response}")


async def server(ws, path):
    global state, connected_clients
    connected_clients.add(ws)
    await send_room_list(ws)  # Send the list of rooms when a client connects

    try:
        async for msg in ws:
            if isinstance(msg, bytes):
                msg = msg.decode("utf-8")  # Decode binary message to string
            print(f"Msg from client: {msg}")

            try:
                msg_data = json.loads(msg)  # Parse the incoming message as JSON
            except json.JSONDecodeError:
                error_response = {
                    "head": "error",
                    "message": "Invalid JSON format"
                }
                await ws.send(json.dumps(error_response))
                print("Sent to client: Invalid JSON format")
                continue

            # Check if the message has the desired format
            if msg_data.get("head") == "create_room":
                await handle_create_room(ws)
            elif msg_data.get("head") == "join_room":
                room_id = msg_data.get("room_id")
                if room_id:
                    await handle_join_room(ws, room_id)
                else:
                    error_response = {
                        "head": "error",
                        "message": "Room ID required"
                    }
                    await ws.send(json.dumps(error_response))
                    print("Sent to client: Room ID required")
            elif msg_data.get("head") == "move":
                await handle_move(ws, msg_data)

    except websockets.exceptions.ConnectionClosedError as e:
        print(f"Connection closed: {e}")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        connected_clients.remove(ws)
        rooms_to_delete = []
        for room_id, room in rooms.items():
            room.remove_client(ws)
            if not room.clients:
                rooms_to_delete.append(room_id)

        for room_id in rooms_to_delete:
            del rooms[room_id]
            print(f"Deleted room {room_id} due to creator disconnect")

async def notify_clients(ws, message):
    for room in rooms.values():
        if ws in room.clients:
            await room.notify_clients(message)


async def main():
    start_server = websockets.serve(server, "0.0.0.0", 5000)
    print("Server started")
    await start_server

if __name__ == "__main__":
    asyncio.get_event_loop().run_until_complete(main())
    asyncio.get_event_loop().run_forever()
