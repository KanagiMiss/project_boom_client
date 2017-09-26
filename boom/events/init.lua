local KeyPressed = require("boom.events.KeyPressed")
local MousePressed = require("boom.events.MousePressed")
local KeyReleased = require("boom.events.KeyReleased")
local GamepadPressed = require("boom.events.GamepadPressed")
local GamepadReleased = require("boom.events.GamepadReleased")
local GamepadRightStickMoved = require("boom.events.GamepadRightStickMoved")
local MouseReleased = require("boom.events.MouseReleased")
local MouseMoved = require("boom.events.MouseMoved")
local NetKeyPressed = require("boom.events.NetKeyPressed")
local NetKeyReleased = require("boom.events.NetKeyReleased")
local NetMouseMoved = require("boom.events.NetMouseMoved")
local NetGamepadPressed = require("boom.events.NetGamepadPressed")
local NetGamepadReleased = require("boom.events.NetGamepadReleased")
local InputPressed = require("boom.events.InputPressed")
local InputReleased = require("boom.events.InputReleased")
local CreateRoomInputPressed = require("boom.events.CreateRoomInputPressed")
local RoomListInputPressed = require("boom.events.RoomListInputPressed")
local RoomListInputReleased = require("boom.events.RoomListInputReleased")
local RoomInputPressed = require("boom.events.RoomInputPressed")
local RoomInputReleased = require("boom.events.RoomInputReleased")
local SnapshotReceived = require("boom.events.SnapshotReceived")
local LoginRes = require("boom.events.LoginRes")
local CreateRoomRes = require("boom.events.CreateRoomRes")
local EnterRoomBroadcast = require("boom.events.EnterRoomBroadcast")
local EnterRoomRes = require("boom.events.EnterRoomRes")
local GameBeginBroadcast = require("boom.events.GameBeginBroadcast")
local GameCancelReadyBroadcast = require("boom.events.GameCancelReadyBroadcast")
local GameReadyBroadcast = require("boom.events.GameReadyBroadcast")
local GetRoomListRes = require("boom.events.GetRoomListRes")
local QuitRoomBroadcast = require("boom.events.QuitRoomBroadcast")
local BeginContact = require("boom.events.BeginContact")
local EndContact = require("boom.events.EndContact")
local PreSolve = require("boom.events.PreSolve")
local PostSolve = require("boom.events.PostSolve")
local Damage = require("boom.events.Damage")
local EntityDestroy = require("boom.events.EntityDestroy")
local GameOver = require("boom.events.GameOver")
local GameOverBroadcast = require("boom.events.GameOverBroadcast")

local events = {
    KeyPressed = KeyPressed,
    MousePressed = MousePressed,
    MouseMoved = MouseMoved,
    KeyReleased = KeyReleased,
    MouseReleased = MouseReleased,
    NetKeyPressed = NetKeyPressed,
    NetKeyReleased = NetKeyReleased,
    NetMouseMoved = NetMouseMoved,
    NetGamepadPressed = NetGamepadPressed,
    NetGamepadReleased = NetGamepadReleased,
    GamepadPressed = GamepadPressed,
    GamepadReleased = GamepadReleased,
    GamepadRightStickMoved = GamepadRightStickMoved,
    InputPressed = InputPressed,
    InputReleased = InputReleased,
    CreateRoomInputPressed = CreateRoomInputPressed,
    SnapshotReceived = SnapshotReceived,
    LoginRes = LoginRes,
    CreateRoomRes = CreateRoomRes,
    RoomListInputPressed = RoomListInputPressed,
    RoomListInputReleased = RoomListInputReleased,
    RoomInputPressed = RoomInputPressed,
    RoomInputReleased = RoomInputReleased,
    EnterRoomBroadcast = EnterRoomBroadcast,
    EnterRoomRes = EnterRoomRes,
    GameBeginBroadcast = GameBeginBroadcast,
    GameCancelReadyBroadcast = GameCancelReadyBroadcast,
    GameReadyBroadcast = GameReadyBroadcast,
    GetRoomListRes = GetRoomListRes,
    QuitRoomBroadcast = QuitRoomBroadcast,
    BeginContact = BeginContact,
    EndContact = EndContact,
    PreSolve = PreSolve,
    PostSolve = PostSolve,
    Damage = Damage,
    EntityDestroy = EntityDestroy,
    GameOver = GameOver,
    GameOverBroadcast = GameOverBroadcast,
}
return events
