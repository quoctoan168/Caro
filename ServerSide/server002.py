import asyncio
import websockets
import json
from room import PlayRoom
from client import Client

state = "Initial state"
connected_clients = set()
rooms = {}

def get_client_by_ws(ws):
    return next((cl for cl in connected_clients if cl.ws == ws), None)

async def handle_start_connect(ws, msg_data):
    player_name = msg_data.get("player_name")

    if not player_name:
        error_response = {
            "head": "error",
            "message": "Player name required"
        }
        await ws.send(json.dumps(error_response))
        print("Sent to client: Player name required")
        return None

    client = Client(ws, player_name, 0)
    if any(cl.ws == ws for cl in connected_clients):
        print("Client already connected")
        return None

    connected_clients.add(client)
    return client

async def handle_create_room(client: Client, password: str):
    global rooms
    room_id = next((i for i in range(1, 101) if i not in rooms), -1)

    if room_id == -1:
        response = {
            "head": "error",
            "message": "Server full"
        }
    else:
        new_room = PlayRoom(client, room_id, password)
        rooms[room_id] = new_room
        response = {
            "head": "setup",
            "yourturn": 0,
            "room_id": room_id,
        }

    await client.ws.send(json.dumps(response))
    print(f"Sent to client: {response}")

async def handle_join_room(client: Client, room_id: int, password: str):
    global rooms
    if room_id in rooms:
        room = rooms[room_id]
        if password == room.password:
            room.add_client(client)
            response = {
                "head": "setup",
                "yourturn": 1,
                "room_id": room_id,
            }
            await client.ws.send(json.dumps(response))
            print(f"Sent to client: {response}")
        else:
            response = {
                "head": "error",
                "message": "Wrong password"
            }
            await client.ws.send(json.dumps(response))
            print(f"Sent to client: {response}")
    else:
        error_response = {
            "head": "error",
            "message": "Room not found"
        }
        await client.ws.send(json.dumps(error_response))
        print("Sent to client: Room not found")

async def handle_move(client: Client, msg_data):
    room_id = msg_data.get("room_id")
    if room_id in rooms:
        room = rooms[room_id]
        if client.ws in {cl.ws for cl in room.clients}:
            await room.notify_clients(json.dumps(msg_data))
            print(f"Broadcasted move to room {room_id}: {msg_data}")
        else:
            error_response = {
                "head": "error",
                "message": "Client not in room"
            }
            await client.ws.send(json.dumps(error_response))
            print("Sent to client: Client not in room")
    else:
        error_response = {
            "head": "error",
            "message": "Room not found"
        }
        await client.ws.send(json.dumps(error_response))
        print("Sent to client: Room not found")

async def send_room_list(ws):
    global rooms
    room_list = []

    for room_id, room in rooms.items():
        room_info = room.get_room_status()
        room_list.append(json.loads(room_info))

    response = {
        "head": "room_list",
        "rooms": room_list,
    }
    await ws.send(json.dumps(response))
    print(f"Sent to client: {response}")

async def handle_interrupted_client(ws):
    client = get_client_by_ws(ws)
    if client:
        room_id = client.get_room()
        if room_id is not None and room_id in rooms:
            room = rooms[room_id]
            room.remove_client(client)
            if not room.clients:
                del rooms[room_id]
                print(f"Deleted room {room_id} due to no clients")
        connected_clients.remove(client)

async def handle_message(ws, msg):
    try:
        msg_data = json.loads(msg)
    except json.JSONDecodeError:
        error_response = {
            "head": "error",
            "message": "Invalid JSON format"
        }
        await ws.send(json.dumps(error_response))
        print("Sent to client: Invalid JSON format")
        return

    client = get_client_by_ws(ws)
    msg_head = msg_data.get("head")
    if msg_head == "start_connect":
        client = await handle_start_connect(ws, msg_data)

    if client is None:
        return

    if msg_head == "create_room":
        await handle_create_room(client, msg_data.get("password"))

    elif msg_head == "join_room":
        room_id = msg_data.get("room_id")
        password = msg_data.get("password")
        if room_id and password:
            await handle_join_room(client, room_id, password)
        else:
            error_response = {
                "head": "error",
                "message": "Room ID and password required"
            }
            await ws.send(json.dumps(error_response))
            print("Sent to client: Room ID and password required")

    elif msg_head == "move":
        await handle_move(client, msg_data)

async def server(ws, path):
    global connected_clients, rooms
    try:
        async for msg in ws:
            if isinstance(msg, bytes):
                msg = msg.decode("utf-8")
            print(f"Msg from client: {msg}")
            await handle_message(ws, msg)
    except websockets.exceptions.ConnectionClosedError as e:
        await handle_interrupted_client(ws)
        print(f"Connection closed: {e}")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        ws.close()

async def main():
    start_server = websockets.serve(server, "0.0.0.0", 5000)
    print("Server started")
    await start_server

if __name__ == "__main__":
    asyncio.get_event_loop().run_until_complete(main())
    asyncio.get_event_loop().run_forever()
