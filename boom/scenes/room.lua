--进入房间以后的ui,
local room = class("room")

local gui = require("libs.Gspot")
package.loaded["./libs/Gspot"] = nil
local utils = require("boom.utils")
local scrollview = require("libs.Gspot_ext.scrollview")
require "./libs/gooi"
local game_state = require("libs.hump.gamestate")
local lg = love.graphics
local cam = require("boom.camera")
local camera = cam:instance()
local bgimg = love.graphics.newImage("assets/bgimg.jpg")

local events = require("boom.events")
local RoomNetHandler = class("RoomNetHandler", System)
local room_net_handler = RoomNetHandler()
local InputHandler = class("InputHandler", System)
local input_handler = InputHandler()

--init_table中带入的数据
local myId = "ERRORID"   --玩家自己的Id
local roomId = "ERRORROOMID"
local groupId = 1
local roomMasterId = "ERRORROOMMASTERID"
local gameMode = 1
local mapType = 1
local lifeNumber = 3
local playersPerGroup = 1
local roomState = nil   --waiting or gaming
local playersInRoom = 1
local PlayerInfos = {[1] = {}, [2] = {}}   --包含房间内所有人的PlayerInfo, string playerId = 1;int32 playerStatus = 2;int32 groupId = 3;int32 tankType = 4;

local img_ready = lg.newImage("assets/backup/sign_bullet.png")   --地方准备好了的图片
local img_blank = lg.newImage("assets/backup/blank_32.png")

--所有控件
local gridRoominfo = nil
local lbl_title = nil
local lbl_mode = nil
local lbl_people = nil
local lbl_life = nil
local lbl_map = nil
local grid_1 = nil  --放置groupId为1的grid
local grid_2 = nil  --放置groupId为2的grid
local lbl_group1 = nil
local lbl_group2 = nil
local sv_tankbag = nil --坦克背包
--存放所有控件的table
local players_widgets = {[1] = {}, [2] = {}}  --存放两个groupId的所有玩家的信息显示的widget，为了方便更新显示玩家在房间中的情况
local gooi_widgets = {}

--固定尺寸
local window_w = 960--480
local window_h = 680--320
local gridRoominfo_x = 20--10
local gridRoominfo_y = 20--10
local gridRoominfo_w = 280--140
local gridRoominfo_h = 200--100
local lbl_group1_x = 320
local lbl_group1_y = 20
local lbl_group1_w = 150
local lbl_group1_h = 30
local grid_1_x = 320--160
local grid_1_y = 50--10
local grid_1_w = 600--300
local grid_1_h = 270--145
local lbl_group2_x = 320
local lbl_group2_y = 340
local lbl_group2_w = 150
local lbl_group2_h = 30
local grid_2_x = 320--160
local grid_2_y = 370--165
local grid_2_w = 600--300
local grid_2_h = 270--145
--local scrollitem_tankbag_pos = {0, 0, 280, 100}--{0, 0, 140, 50}
local scrollitem_tankimg_pos = {34, 34, 32, 32}
local scrollitem_tanktext_pos = {100, 0, 120, 100}

--坦克背包scrollgroup的各项参数
local scroll_window_index = 1 --变化范围是1~scroll_item_num_per_page
local scroll_focous_time_bound = 0.2  -- 按住方向键0.8s以后，开始快速滑动room_item
local scroll_frame_time_gap_bound = 0.05  -- 按住方向键以后，每过150ms越过一个room_item
local scroll_item_num_per_page = 3 -- 一页显示几个room_item
local scrollgroup_x = 20--10
local scrollgroup_y = 240--120
local scroll_item_height = 100--50   --scroll_item_height * scroll_item_num_per_page == scrollgroup_h，这一点在这里就要保证，不然会出问题
local scroll_item_width = 240--120

--控制信息
local isready = false  --玩家已经ready
local i_wanna_quit_room = false  --玩家提出了退房申请

--存放所有的tank
local tankbag = {
  [1] = {["tankType"] = 1, ["img"] = love.graphics.newImage("assets/tank/1.png")},
  [2] = {["tankType"] = 2, ["img"] = love.graphics.newImage("assets/tank/2.png")},
  [3] = {["tankType"] = 3, ["img"] = love.graphics.newImage("assets/tank/3.png")},
  [4] = {["tankType"] = 4, ["img"] = love.graphics.newImage("assets/tank/4.png")},
  [5] = {["tankType"] = 5, ["img"] = love.graphics.newImage("assets/tank/5.png")},
  [6] = {["tankType"] = 6, ["img"] = love.graphics.newImage("assets/tank/6.png")},
  [7] = {["tankType"] = 7, ["img"] = love.graphics.newImage("assets/tank/7.png")},
  [8] = {["tankType"] = 8, ["img"] = love.graphics.newImage("assets/tank/8.png")},
  [9] = {["tankType"] = 9, ["img"] = love.graphics.newImage("assets/tank/9.png")},
}
--存放所有的玩家的信息，groupId作key

--前置声明
local update_players_widgets, ready, cancel_ready, remove_widgets, quit_room, begin_game,
isMaster, get_enterroom_broadcast, get_quitroom_broadcast, get_gamebegin_broadcast,get_gamecancelready_broadcast, get_gamereadybroadcast
local setup_tankbag

--[[room的入口，有两种进入的可能：
1.roomlist:带入除了create_room带入的内容以外，还有所有PlayerInfo的集合
2.create_room:带入roomId,groupId,roomMasterId,gameMode,mapType,lifeNumber,playersPerGroup,roomState
]]--
function room:enter(pre, init_table)
  camera:lookAt(window_w/2, window_h/2)
  gui:setOriginSize(window_w, window_h)
  if window_w > love.graphics.getWidth() or window_h > love.graphics.getHeight() then
    --需要缩放
    local zoom = math.min(love.graphics.getWidth()/window_w, love.graphics.getHeight()/window_h)
    camera:zoomTo(zoom)
  else
    camera:zoomTo(1.0)
  end
  eventmanager:addListener("EnterRoomBroadcast", room_net_handler, room_net_handler.fireEnterRoomBroadcastEvent)
  eventmanager:addListener("GameBeginBroadcast", room_net_handler, room_net_handler.fireGameBeginBroadcastEvent)
  eventmanager:addListener("GameCancelReadyBroadcast", room_net_handler, room_net_handler.fireGameCancelReadyBroadcastEvent)
  eventmanager:addListener("GameReadyBroadcast", room_net_handler, room_net_handler.fireGameReadyBroadcastEvent)
  eventmanager:addListener("QuitRoomBroadcast", room_net_handler, room_net_handler.fireQuitRoomBroadcastEvent)
  eventmanager:addListener("RoomInputPressed", input_handler, input_handler.firePressedEvent)
  eventmanager:addListener("RoomInputReleased", input_handler, input_handler.fireReleasedEvent)
  font_big = lg.newFont("assets/font/Arimo-Bold.ttf", 28)
  font_small = lg.newFont("assets/font/Arimo-Bold.ttf", 20)
  font_current = lg.getFont()
  style = {
      font = font_small,
      radius = 5,
      innerRadius = 3,
      showBorder = true,
  }
  gooi.setStyle(style)
  gooi.desktopMode()
  gooi.shadow()

  --把从init_table带进来的数据拿出来
  myId = init_table and init_table["myId"] or myId
  roomId = init_table and init_table["roomId"] or roomId
  roomMasterId = init_table and init_table["roomMasterId"] or myId
  groupId = init_table and init_table["groupId"] or groupId
  gameMode = init_table and init_table["gameMode"] or gameMode
  mapType = init_table and init_table["mapType"] or mapType
  lifeNumber = init_table and init_table["lifeNumber"] or lifeNumber
  playersPerGroup = init_table and init_table["playersPerGroup"] or playersPerGroup
  PlayerInfos = init_table and init_table["PlayerInfos"] or {[1] = {}, [2] = {}}
  playersInRoom = init_table and init_table["playersInRoom"] or playersInRoom
  if init_table["from_create_room"] then
    --此时是房主创房间成功，玩家是房主
    PlayerInfos[groupId][#(PlayerInfos[groupId])+1] = {["playerId"] = myId, ["playerStatus"] = 2, ["tankType"] = -1}
  end
  --playersInfo = init_table and init_table["playersInfo"] or {}


  --init_table中有roomId,roomMasterId,groupId,playersInfo
  gridRoominfo = gooi.newPanel({x = gridRoominfo_x, y = gridRoominfo_y , w = gridRoominfo_w, h = gridRoominfo_h, layout = "grid 5x1"})

  lbl_title = gooi.newLabel({text = roomId}):left()
  lbl_mode  = gooi.newLabel({text = "mode:"..gameMode}):left()--
  lbl_people = gooi.newLabel({text = "people:"..playersPerGroup.." vs "..playersPerGroup}):left()
  lbl_life = gooi.newLabel({text = "life:"..lifeNumber}):left()
  lbl_map = gooi.newLabel({text = "map:"..mapType}):left()
  gridRoominfo:add(lbl_title, "1,1")
  gridRoominfo:add(lbl_mode, "2,1")
  gridRoominfo:add(lbl_people, "3,1")
  gridRoominfo:add(lbl_life, "4,1")
  gridRoominfo:add(lbl_map, "5,1")
  table.insert(gooi_widgets, gridRoominfo)
  table.insert(gooi_widgets, lbl_title)
  table.insert(gooi_widgets, lbl_mode)
  table.insert(gooi_widgets, lbl_people)
  table.insert(gooi_widgets, lbl_life)
  table.insert(gooi_widgets, lbl_map)
  lbl_group1 = gooi.newLabel({text = "GROUP1", x = lbl_group1_x, y = lbl_group1_y, w = lbl_group1_w, h = lbl_group1_h}):center()
  lbl_group2 = gooi.newLabel({text = "GROUP2", x = lbl_group2_x, y = lbl_group2_y, w = lbl_group2_w, h = lbl_group2_h}):center()
  table.insert(gooi_widgets, lbl_group1)
  table.insert(gooi_widgets, lbl_group2)

  --创建groupId==1的显示列表
  grid_1 = gooi.newPanel({x = grid_1_x, y = grid_1_y, w = grid_1_w, h = grid_1_h, layout = "grid 4x2"})
  for i = 1, 8 do
    local r = (i-1) % 4 + 1
    local c = math.floor((i-1)/4) + 1
    local lbl_1_item = gooi.newLabel({text = ""}):left()
    if i > playersPerGroup then
      lbl_1_item:setText("————"):center()
    end
    grid_1:add(lbl_1_item, r..","..c)
    players_widgets[1][#players_widgets[1]+1] = lbl_1_item
    table.insert(gooi_widgets, lbl_1_item)
  end

  --创建groupId==1的显示列表
  grid_2 = gooi.newPanel({x = grid_2_x, y = grid_2_y, w = grid_2_w, h = grid_2_h, layout = "grid 4x2"})
  for i = 1, 8 do
    local r = (i-1) % 4 + 1
    local c = math.floor((i-1)/4) + 1
    local lbl_2_item = gooi.newLabel({text = ""}):left()
    if i > playersPerGroup then
      lbl_2_item:setText("————"):center()
    end
    grid_2:add(lbl_2_item, r..","..c)
    players_widgets[2][#players_widgets[2]+1] = lbl_2_item
    table.insert(gooi_widgets, lbl_2_item)
  end
  table.insert(gooi_widgets, grid_1)
  table.insert(gooi_widgets, grid_2)
  --创建一个选择tank的列表
  setup_tankbag()
end

setup_tankbag = function()
  --创建scollgroup
  sv_tankbag = scrollview.createObject({x = scrollgroup_x, y = scrollgroup_y, item_width = scroll_item_width, item_height = scroll_item_height, item_num_per_page = scroll_item_num_per_page, time_before_fastscroll = scroll_focous_time_bound, time_between_fastscroll = scroll_frame_time_gap_bound, bgcolor = {255,255,255,20}, bgcolor_focous = {255,255,255, 50}}, gui)
  for i = 1, #tankbag do
    local gi = gui:group('', {x = 0, y = 0, w = scroll_item_width, h = scroll_item_height})
    gi.bgcolor = {255,255,255,0}
    local tank_img = gui:image("", scrollitem_tankimg_pos, gi, tankbag[i]["img"])
    local tank_text = gui:text(tankbag[i]["tankType"], scrollitem_tanktext_pos, gi, false, {255,255,255,0})
    sv_tankbag:addChild(gi, 'vertical')
  end
  sv_tankbag:allChildAdded()
  sv_tankbag:scrollToTop()
end


function room:leave()
  gui:feedback("room:leave")
  isready = false
  i_wanna_quit_room = false
  remove_widgets()
  PlayerInfos = {[1] = {}, [2] = {}}
end

function room:update(dt)
  update_players_widgets()  --根据最新的PlayerInfos[1],PlayerInfos[2]的内容更新所有的控件
  sv_tankbag:update(dt)
  gui:update(dt)
  gooi.update()
  if not test_on_windows then
    net:update(dt)
  end
end

function room:draw()
  --local bgimg = lg.newImage("assets/bgimg.jpg")
  lg.draw(bgimg,0,0)
  camera:attach()
  local r,g,b,a = lg.getColor()
  --绘制出两个玩家表格的格线
  --grid_1
  for i = 1, 5 do
    lg.line(grid_1_x, grid_1_y+(i-1)*grid_1_h/4, grid_1_x + grid_1_w, grid_1_y+(i-1)*grid_1_h/4)
  end
  for i = 1, 3 do
    lg.line(grid_1_x+(i-1)*grid_1_w/2, grid_1_y, grid_1_x+(i-1)*grid_1_w/2, grid_1_y+grid_1_h)
  end
  --grid_2
  for i = 1, 5 do
    lg.line(grid_2_x, grid_2_y+(i-1)*grid_2_h/4, grid_2_x + grid_2_w, grid_2_y+(i-1)*grid_2_h/4)
  end
  for i = 1, 3 do
    lg.line(grid_2_x+(i-1)*grid_2_w/2, grid_2_y, grid_2_x+(i-1)*grid_2_w/2, grid_2_y+grid_2_h)
  end
  --绘制lbl_group1和lbl_group2的背景
  lg.setColor(0, 0, 0, 127)
  lg.rectangle("fill", lbl_group1_x, lbl_group1_y, lbl_group1_w, lbl_group1_h)
  lg.rectangle("fill", lbl_group2_x, lbl_group2_y, lbl_group2_w, lbl_group2_h)
  lg.rectangle("fill", 0, 0, window_w, window_h)
  --绘制提示文字
  lg.setColor(255,255,255,255)
  --local font_current = lg.getFont()
  local ready_string = "O-ready"
  local cancel_ready_string = "X-cancel ready"
  local quit_string = "L1-quit room"
  local begin_string = "R1-master begin game"
  lg.print(ready_string, 20, 540)--10, 270)
  lg.print(cancel_ready_string, 20, 540 + font_small:getHeight())--10, 270)
  lg.print(quit_string, 20, 540 + 2*font_small:getHeight())--10, 270 + font_current:getHeight())
  lg.print(begin_string, 20, 540 + 3*font_small:getHeight())--10, 270 + 2*font_current:getHeight())
  lg.setColor(0, 0, 0, 127)
  lg.rectangle("fill", gridRoominfo_x, gridRoominfo_y, gridRoominfo_w, gridRoominfo_h)
  lg.setColor(r,g,b,a)
  gui:draw()
  gooi.draw()
  camera:detach()
end

--上下键翻阅坦克背包，O键选中tank并ready，X键取消ready，L键退房间，房主R键开始游戏！
function room:gamepadpressed(joystick, button)
  if button == "dpup" then
    --[[if isready then return end
    --begin_move_scrollgroup("up")
    sv_tankbag:scrollUp()]]--
    eventmanager:fireEvent(events.RoomInputPressed("up"))
  elseif button == "dpdown" then
    --[[if isready then return end
    --begin_move_scrollgroup("down")
    sv_tankbag:scrollDown()]]--
    eventmanager:fireEvent(events.RoomInputPressed("down"))
  elseif button == "b" then  --O键
    --ready()
    eventmanager:fireEvent(events.RoomInputPressed("a"))
  elseif button == "a" then  --X键
    --cancel_ready()
    eventmanager:fireEvent(events.RoomInputPressed("b"))
  elseif button == "leftshoulder" then
    --quit_room()
    eventmanager:fireEvent(events.RoomInputPressed("l1"))
  elseif button == "rightshoulder" then
    --begin_game()
    eventmanager:fireEvent(events.RoomInputPressed("r1"))
  elseif button == "guide" then
    eventmanager:fireEvent(events.RoomInputPressed("esc"))
  end
end

function room:gamepadreleased(joystick, button)
  if button == "dpup" then
    eventmanager:fireEvent(events.RoomInputReleased("up"))
  elseif button == "dpdown" then
    eventmanager:fireEvent(events.RoomInputReleased("down"))
  end
end

function room:keypressed(key, scancode, isrepeat)
  if key == "up" then
    eventmanager:fireEvent(events.RoomInputPressed("up"))
  elseif key == "down" then
    eventmanager:fireEvent(events.RoomInputPressed("down"))
  elseif key == "a" then  --O键
    eventmanager:fireEvent(events.RoomInputPressed("a"))
  elseif key == "b" then  --X键
    eventmanager:fireEvent(events.RoomInputPressed("b"))
  elseif key == "l" then
    eventmanager:fireEvent(events.RoomInputPressed("l1"))
  elseif key == "r" then
    eventmanager:fireEvent(events.RoomInputPressed("r1"))
  elseif key == "escape" then
    eventmanager:fireEvent(events.RoomInputPressed("esc"))
  end
end

function room:keyreleased(key)
  if key == "up" then
    eventmanager:fireEvent(events.RoomInputReleased("up"))
  elseif key == "down" then
    eventmanager:fireEvent(events.RoomInputReleased("down"))
  end
end

--本地函数
--获取一个进入房间的广播以后的处理，新进入的玩家是playerId，组别是groupId
get_enterroom_broadcast = function(playerId, groupId)
  print("room.lua get_enterroom_broadcast,playerId = "..playerId..",groupId = "..groupId)
  local group_players = PlayerInfos[groupId+1]
  --group_players是groupId对应的table
  local new_player_info_item = {}
  new_player_info_item["playerId"] = playerId
  new_player_info_item["playerStatus"] = 2 -- ready为1，未ready为2
  new_player_info_item["tankType"] = 2 --应该是从broadcast中获取
  group_players[#group_players+1] = new_player_info_item
end

--获取一个退出房间的广播以后的处理，退出的玩家是playerId，组别是groupId
get_quitroom_broadcast = function(isMaster, playerId)
  print("get_quitroom_broadcast, playerId = "..playerId)
  local roomlist = require("boom.scenes.roomlist")
  print("myId = "..myId.. " , quit room playerId = "..playerId)
  if i_wanna_quit_room and playerId == myId then
    print("i_wanna_quit_room and it's me")
    --Server准许了玩家的退房申请
    local init_table = {}
    init_table["myId"] = myId
    i_wanna_quit_room = false
    isready = false
    game_state.switch(roomlist, init_table)
  end

  local delete_groupId = 1
  if isMaster then
    local init_table = {}
    init_table["myId"] = myId
    game_state.switch(roomlist, init_table)  --散了散了
  else
    for i = 1, 2 do
      local group_players = PlayerInfos[i]
      for j = 1, #group_players do
        if group_players[j]["playerId"] == playerId then
          --found!
          print("found "..playerId.." at group"..i)
          delete_groupId = i
          goto delete_player
        end
      end
    end
   end
  ::delete_player:: do
    --执行删除玩家的操作
    local group_players = PlayerInfos[delete_groupId]
    local group_players_copy = {}
    for i = 1, #group_players do
      if group_players[i]["playerId"] ~= playerId then
        group_players_copy[#group_players_copy+1] = group_players[i]
      end
    end
    --此时group_players_copy是新的table
    PlayerInfos[delete_groupId] = group_players_copy
  end
end

--获取一个游戏开始的广播
get_gamebegin_broadcast = function(roomid)
  gui:feedback("roomId:"..roomid)
  if roomid ~= "-fail" then
    local test_place = require("boom.scenes.test_place")
    local init_table = {}
    init_table["myId"] = myId
    if isMaster() then
      init_table["isMaster"] = true
    else
      init_table["isMaster"] = false
    end
    local test_network = require "boom.scenes.test_network"

    local info = utils.GameRoomInfo(
      "test_network", playersPerGroup, lifeNumber, gameMode,
                                roomMasterId, myId
                                --[[{
                                  {player_id = "yuge", group_id = 1, tank_type = 1},
                                  {player_id = "hako", group_id = 2, tank_type = 1},
                                  {player_id = "lsm", group_id = 2, tank_type = 1},
                                }]]--
                              )

    info.players_info = {}
    for group_id = 1, 2 do
      local group = PlayerInfos[group_id]
      for i = 1, #group do
        info.players_info[#info.players_info+1] = {
          player_id = group[i].playerId,
          group_id = group_id,
          tank_type = group[i].tankType,
        }
        print(group[i].playerId, group_id, group[i].tankType)
      end
    end
    
    --这里的info的players_info的顺序是乱的！要确定
    table.sort(info.players_info, room.sort_players_info)
    game_state.switch(test_network, info)
  else
    gui:feedback("Cannot begin game!")
  end
end

--新加的排序算子
function room.sort_players_info(a, b)
  if a.group_id == b.group_id then
    return a.player_id < b.player_id
  else
    return a.group_id < b.group_id
  end
end

--获取一个玩家取消ready状态的广播
get_gamecancelready_broadcast = function(playerId)
  for i = 1, 2 do
    local group_players = PlayerInfos[i]
    for j = 1, #group_players do
      if group_players[j]["playerId"] == playerId then
        --found!
        group_players[j]["playerStatus"] = 2
        return
      end
    end
  end
end

--获取一个玩家进入ready状态的广播
get_gamereadybroadcast = function(playerId, tankType)
  for i = 1, 2 do
    local group_players = PlayerInfos[i]
    for j = 1, #group_players do
      if group_players[j]["playerId"] == playerId then
        --found!
        group_players[j]["playerStatus"] = 1
        group_players[j]["tankType"] = tankType
        return
      end
    end
  end
end

--更新players的相应的控件
update_players_widgets = function()
  --当前的玩家
  local my_group_id = groupId   --我方的组
  local oppo_group_id = 1 --对方的组
  if my_group_id == 1 then
    oppo_group_id = 2
  end
  --print("update_players_widgets: my_group_id = "..my_group_id..",oppo_group_id = "..oppo_group_id)
  --直接拿着新的PlayerInfos[my_group_id]数据进行players_widgets[my_group_id]的更新
  for i = 1, 8 do
    --[[if PlayerInfos[my_group_id] then
      print("PlayerInfos[my_group_id] is not nil")
    else
      print("PlayerInfos[my_group_id] is nil")
    end]]--
    if i <= #(PlayerInfos[my_group_id]) then
      local f_widget = players_widgets[my_group_id][i]
      local f_info_item = PlayerInfos[my_group_id][i]
      f_widget:setText(f_info_item["playerId"])
      if f_info_item["playerId"] == myId then
        f_widget:fg({255,0,0,255})
      end
      if f_info_item["playerStatus"] == 1 then --已经准备完成
        --设置一个坦克缩略图
        if tankbag[f_info_item["tankType"]] then
          local img_tank = tankbag[f_info_item["tankType"]]["img"]
          f_widget:setIcon(img_tank)
        else
          f_widget:setIcon(img_ready)
        end
      else
        --设置一个空白图
        f_widget:setIcon(img_blank)
      end
    elseif i <= playersPerGroup then
      local f_widget = players_widgets[my_group_id][i]
      f_widget:setText("")
      f_widget:setIcon(nil)
    else
      break
    end
  end
  --直接拿着新的PlayerInfos[oppo_group_id]数据进行players_widgets[oppo_group_id]的更新
  for i = 1, 8 do
    if i <= #PlayerInfos[oppo_group_id] then
      local e_widget = players_widgets[oppo_group_id][i]
      local e_info_item = PlayerInfos[oppo_group_id][i]
      e_widget:setText(e_info_item["playerId"])
      if e_info_item["playerStatus"] == 1 then --已经准备完成
        --设置一个准备完成的图片
        e_widget:setIcon(img_ready)
      else
        --设置一个空白图
        e_widget:setIcon(img_blank)
      end
    elseif i <= playersPerGroup then
      local e_widget = players_widgets[oppo_group_id][i]
      e_widget:setText("")
      e_widget:setIcon(nil)
    else
      break
    end
  end
end

--判断当前玩家是否是房主
isMaster = function()
  return roomMasterId == myId
end

--ready
ready = function()
  isready = true
  local tank_selected_index = sv_tankbag.getSelectedIndex()
  local tankType = tankbag[tank_selected_index]["tankType"]
  if not test_on_windows then
    net:requestGameReady(myId, roomId, tankType)
  end
end

--cancel_ready
cancel_ready = function()
  isready = false
  if not test_on_windows then
    net:requestGameCancelReady(myId, roomId)
  end
end

--离开时移除所有的组件
remove_widgets = function()
  for k,v in pairs(gooi_widgets) do
    gooi.removeComponent(v)
    --gooi_widgets[k] = nil
  end
  gooi_widgets = {}
  players_widgets[1] = {}
  players_widgets[2] = {}
  sv_tankbag:clean()
  scroll_items = {}
end

--离开房间
quit_room = function()
  if not test_on_windows then
    net:requestQuitRoom(roomId, myId)
    i_wanna_quit_room = true
  else
    --模拟收到退出的信息了
    local roomlist = require("boom.scenes.roomlist")
    local init_table = {}
    init_table["myId"] = myId
    game_state.switch(roomlist, init_table)
  end
end

--房主开始游戏
begin_game = function()
  --不是房主你开始个p啊
  if not isMaster() then
    print("you are not master,you cannot begin game.")
    return
  end
  --检查是否是已经全员到齐且全员ready
  --if #PlayerInfos[2] == playersPerGroup and #PlayerInfos[1] == playersPerGroup then
    for k, v in pairs(PlayerInfos[2]) do
      if not v["playerStatus"] == 1 then
        return
      end
    end
    for k, v in pairs(PlayerInfos[1]) do
      if not v["playerStatus"] == 1 then
        return
      end
    end
  --else
  --  return
  --end
  if not test_on_windows then
    net:requestGameBegin(roomId)
  end
end


--针对所有的pressed输入的事件处理函数
function InputHandler:firePressedEvent(event)
  local cmd = event.cmd
  if cmd == "up" then
    if i_wanna_quit_room then return end --提出了退房申请期间，是无法监听键盘的
    if isready then return end
    --begin_move_scrollgroup("up")
    sv_tankbag:scrollUp()
  elseif cmd == "down" then
    if i_wanna_quit_room then return end --提出了退房申请期间，是无法监听键盘的
    if isready then return end
    --begin_move_scrollgroup("down")
    sv_tankbag:scrollDown()
  elseif cmd == "a" then
    if i_wanna_quit_room then return end --提出了退房申请期间，是无法监听键盘的
    ready()
  elseif cmd == "b" then
    if i_wanna_quit_room then return end --提出了退房申请期间，是无法监听键盘的
    cancel_ready()
  elseif cmd == "l1" then
    if i_wanna_quit_room then return end --提出了退房申请期间，是无法监听键盘的
    quit_room()
  elseif cmd == "r1" then
    if i_wanna_quit_room then return end --提出了退房申请期间，是无法监听键盘的
    begin_game()
  elseif cmd == "esc" then
    love.event.quit()
  end
end

function InputHandler:fireReleasedEvent(event)
  local cmd = event.cmd
  if cmd == "up" then
    if not(joystick and (joystick:isGamepadDown("dpup") or joystick:isGamepadDown("dpdown"))) and not(love.keyboard.isDown("down") or love.keyboard.isDown("up")) then
      --stop_move_scrollgroup()
      sv_tankbag:stop_move()
    end
  elseif cmd == "down" then
    if not(joystick and (joystick:isGamepadDown("dpup") or joystick:isGamepadDown("dpdown")))  and not(love.keyboard.isDown("down") or love.keyboard.isDown("up")) then
      --stop_move_scrollgroup()
      sv_tankbag:stop_move()
    end
  end
end


--处理网络事件
--收到有人进入房间的广播
function RoomNetHandler:fireEnterRoomBroadcastEvent(event)
  print("RoomNetHandler:fireEnterRoomBroadcastEvent")
  get_enterroom_broadcast(event.playerId, event.groupId)
end

--收到游戏开始的广播
function RoomNetHandler:fireGameBeginBroadcastEvent(event)
  print("RoomNetHandler:fireGameBeginBroadcastEvent")
  get_gamebegin_broadcast(event.roomId)
end

--收到有玩家取消准备的广播
function RoomNetHandler:fireGameCancelReadyBroadcastEvent(event)
  print("RoomNetHandler:fireGameCancelReadyBroadcastEvent")
  get_gamecancelready_broadcast(event.playerId)
end

--收到有玩家进入准备状态的广播
function RoomNetHandler:fireGameReadyBroadcastEvent(event)
  print("RoomNetHandler:fireGameReadyBroadcastEvent")
  get_gamereadybroadcast(event.playerId, event.tankType)
end

--收到有人退出房间的广播
function RoomNetHandler:fireQuitRoomBroadcastEvent(event)
  print("RoomNetHandler:fireQuitRoomBroadcastEvent")
  get_quitroom_broadcast(event.isMaster,event.playerId)
end

return room
