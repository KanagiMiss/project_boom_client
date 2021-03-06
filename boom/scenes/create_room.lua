--创建房间的UI
local create_room = class("create_room")

local game_state = require("libs.hump.gamestate")

local gui = require("libs.Gspot")

local cam = require("boom.camera")
local camera = cam:instance()
--package.loaded["./libs/Gspot"] = nil

local events = require("boom.events")
local CreateRoomNetHandler = class("CreateRoomNetHandler", System)
local InputHandler = class("InputHandler", System)
local create_room_net_handler = CreateRoomNetHandler()
local input_handler = InputHandler()
local bgimg = love.graphics.newImage("assets/bgimg.jpg")

require "./libs/gooi"
local lg = love.graphics
local myId = nil
--各种控件
local lbl_title = nil
local lbl_mode = nil
local lbl_people = nil
local lbl_life = nil
local lbl_map = nil
local choose_table = nil
local lbl_mode_value = nil
local lbl_people_value = nil
local lbl_life_value = nil
local lbl_map_value = nil

--固定尺寸
local window_w = 960--480
local window_h = 640--320
local lbl_title_x = 20--10
local lbl_title_y = 20--10
local lbl_title_w = 920--460
local lbl_title_h = 120--60
local choose_table_x = 20--10
local choose_table_y = 160--80
local choose_table_w = 920--460
local choose_table_h = 400--200
--绘制当前选项的白框
local table_item_x = 20--10
local table_item_ys = {
  ["mode"] = 160,--80, 
  ["people"] = 260,--130, 
  ["life"] = 360,--180, 
  ["map"] = 460--230
  }
local table_item_w = 920--460
local table_item_h = 100--50

--前置声明
local submit_request, remove_widgets, back_to_roomlist
--所有的选项值
local selections = {
  ["mode"] = {1},
  ["people"] = {1,2,3,4,5,6,7,8},   --每队人数
  ["life"] = {1,3,5,10},
  ["map"] = {1}
}
--按了键以后的下一个选项类是什么
local next_select_class = {
  ["mode"] = "people",
  ["people"] = "life",
  ["life"] = "map",
  ["map"] = "mode"
}
--按了键以后的上一个选项类是什么
local prev_select_class = {
  ["mode"] = "map",
  ["people"] = "mode",
  ["life"] = "people",
  ["map"] = "life"
}
--当前在哪一个大项里
local current_select_class = "mode"
--选择的结果
local results = {
  ["mode"] = 1,
  ["people"] = 1,
  ["life"] = 1,
  ["map"] = 1
}
local submitting = false --是否正在提交中
local submit_line_x1 = 480--240
local submit_line_x2 = 480--240
local submit_line_length_bound = 400--200
local submit_line_shrink = false


--移除所有的组件
remove_widgets = function()
  gooi.removeComponent(lbl_title)
  gooi.removeComponent(lbl_mode)
  gooi.removeComponent(lbl_people)
  gooi.removeComponent(lbl_life)
  gooi.removeComponent(lbl_map)
  gooi.removeComponent(choose_table)
  gooi.removeComponent(lbl_mode_value)
  gooi.removeComponent(lbl_people_value)
  gooi.removeComponent(lbl_life_value)
  gooi.removeComponent(lbl_map_value)
end

--返回roomlist
back_to_roomlist = function()
  local init_table = {}
  init_table["myId"] = myId
  game_state.switch(roomlist, init_table)
end

--提交当前的选择表给Server
submit_request = function()
  --将results中的内容组织一下发送给Server
  local chosen_mode = selections["mode"][results["mode"]]
  local chosen_map = selections["map"][results["map"]]
  local chosen_life = selections["life"][results["life"]]
  local chosen_people = selections["people"][results["people"]]
  if not test_on_windows then
    submitting = true  --当前状态变成了提交中
    net:requestCreateRoom(myId, chosen_mode, chosen_map, chosen_life, chosen_people)
  else
    --windows上模拟已经创建房间成功的效果
    local init_table = {}
    init_table["myId"] = myId
    init_table["roomId"] = "fake_room_id"
    init_table["groupId"] = 1  --房主默认在1号队
    init_table["roomMasterId"] = myId
    init_table["gameMode"] = selections["mode"][results["mode"]]  --"chaos"
    init_table["mapType"] = selections["map"][results["map"]]  --"as_snow"
    init_table["lifeNumber"] = selections["life"][results["life"]]
    init_table["playersPerGroup"] = selections["people"][results["people"]]
    init_table["playersInRoom"] = 1
    game_state.switch(room, init_table)
  end
end

function create_room:enter(prev, init_table)
  current_select_class = "mode"
  if window_w > love.graphics.getWidth() or window_h > love.graphics.getHeight() then
    --需要缩放
    local zoom = math.min(love.graphics.getWidth()/window_w, love.graphics.getHeight()/window_h)
    camera:zoomTo(zoom)
  else
    camera:zoomTo(1.0)
  end
  
  eventmanager:addListener("CreateRoomRes", create_room_net_handler, create_room_net_handler.fireCreateRoomResEvent)
  eventmanager:addListener("CreateRoomInputPressed", input_handler, input_handler.firePressedEvent)
  myId = init_table and init_table["myId"]

  font_big = lg.newFont("assets/font/Arimo-Bold.ttf", 26)
  font_small = lg.newFont("assets/font/Arimo-Bold.ttf", 20)
  font_current = lg.getFont()
  style = {
      font = font_big,
      radius = 5,
      innerRadius = 3,
      showBorder = true,
  }

  gooi.setStyle(style)
  gooi.desktopMode()
  gooi.shadow()

  --创建控件
  lbl_title = gooi.newLabel({text = "Create Room", x = lbl_title_x, y = lbl_title_y, w = lbl_title_w, h = lbl_title_h}):center()
  choose_table = gooi.newPanel({x = choose_table_x, y = choose_table_y , w = choose_table_w, h = choose_table_h, layout = "grid 4x3"})
  choose_table
    :setColspan(1, 2, 2)
    :setColspan(2, 2, 2)
    :setColspan(3, 2, 2)
    :setColspan(4, 2, 2)
  choose_table.layout.debug = true

  style.font = font_small
  lbl_mode = gooi.newLabel({text = "mode:"}):left()
  lbl_people = gooi.newLabel({text = "people:"}):left()
  lbl_life = gooi.newLabel({text = "life:"}):left()
  lbl_map = gooi.newLabel({text = "map:"}):left()
  lbl_mode_value = gooi.newLabel({text = ""}):left()
  lbl_people_value = gooi.newLabel({text = ""}):left()
  lbl_life_value = gooi.newLabel({text = ""}):left()
  lbl_map_value = gooi.newLabel({text = ""}):left()

  choose_table:add(lbl_mode, "1,1")
  choose_table:add(lbl_people, "2,1")
  choose_table:add(lbl_life, "3,1")
  choose_table:add(lbl_map, "4,1")
  choose_table:add(lbl_mode_value, "1,2")
  choose_table:add(lbl_people_value, "2,2")
  choose_table:add(lbl_life_value, "3,2")
  choose_table:add(lbl_map_value, "4,2")
  camera:lookAt(window_w/2, window_h/2)
end

function create_room:update(dt)
  if submitting then
    --正在提交中，
    --更新动画数值
    if submit_line_shrink then
      --收缩中
      if submit_line_x2 - submit_line_x1 > 0 then
        submit_line_x2 = submit_line_x2 - 6--3
        submit_line_x1 = submit_line_x1 + 6--3
      else
        submit_line_x1 = 480--240
        submit_line_x2 = 480--240
        submit_line_shrink = false
      end
    else
      if submit_line_x2 - submit_line_x1 < submit_line_length_bound then
        submit_line_x1 = submit_line_x1 - 12--6
        submit_line_x2 = submit_line_x2 + 12--6
      else
        submit_line_x1 = -submit_line_length_bound/2 + 480--240
        submit_line_x2 = submit_line_length_bound/2 + 480--240
        submit_line_shrink = true
      end
    end
  end

  --
  local mode_value = selections["mode"][results["mode"]]
  local people_value = selections["people"][results["people"]]
  local life_value = selections["life"][results["life"]]
  local map_value = selections["map"][results["map"]]
  lbl_mode_value:setText(mode_value)
  lbl_people_value:setText(people_value)
  lbl_life_value:setText(life_value)
  lbl_map_value:setText(map_value)
  gooi.update(dt)
  gui:update(dt)
  if not test_on_windows then
    net:update(dt)
  end
end

function create_room:draw()
  --local bgimg = lg.newImage("assets/bgimg.jpg")
  lg.draw(bgimg,0,0)
  camera:attach()
  if submitting then
    --绘制提交中的动画
    lg.line(submit_line_x1, window_h/2, submit_line_x2, window_h/2)
  end
  local r,g,b,a = lg.getColor()
  lg.setColor(0, 0, 0, 127)
  lg.rectangle("fill", 0, 0, window_w, window_h)
  --绘制lbl_title的底框
  lg.setColor(0, 0, 0, 100)
  lg.rectangle("fill", lbl_title_x, lbl_title_y, lbl_title_w, lbl_title_h)
  lg.setColor(0, 0, 0, 60)
  lg.rectangle("fill", choose_table_x, choose_table_y, choose_table_w, choose_table_h)
  lg.setColor(r,g,b,a)
  gooi.draw()
  gui:draw()
  --为当前的选项绘制一个白色透明的盖板
  lg.setColor(255, 255, 255, 20)
  lg.rectangle("fill", table_item_x, table_item_ys[current_select_class], table_item_w, table_item_h)
  lg.setColor(r,g,b,a)
  local font_current = lg.getFont()
  local back_string = "L1-back"
  local confirm_string = "R1-confirm"
  lg.print(back_string, 40, window_h-font_current:getHeight() - 40)   --origin:20
  lg.print(confirm_string, window_w-font_current:getWidth(confirm_string) - 40, window_h-font_current:getHeight() - 40)  --origin:20
  camera:detach()
end

function create_room:leave()
  for k,v in pairs(results) do
    results[k] = 1
  end
  submitting = false
  remove_widgets()
  --将各种数值还原成1
  results["mode"] = 1
  results["people"] = 1
  results["life"] = 1
  results["map"] = 1
  current_select_class = "mode"
end

function create_room:gamepadpressed(joystick, button)
  if submitting then return end --提交中的时候禁止任何输入
  --上下且选项类，左右切选项值
  if button == "dpup" then
    eventmanager:fireEvent(events.CreateRoomInputPressed("up"))
  elseif button == "dpdown" then
    eventmanager:fireEvent(events.CreateRoomInputPressed("down"))
  elseif button == "dpleft" then
    eventmanager:fireEvent(events.CreateRoomInputPressed("left"))
  elseif button == "dpright" then
    eventmanager:fireEvent(events.CreateRoomInputPressed("right"))
  elseif button == "rightshoulder" then  --确认创建房间
    eventmanager:fireEvent(events.CreateRoomInputPressed("r1"))
  elseif button == "leftshoulder" then --取消创建房间，退回到roomlist
    eventmanager:fireEvent(events.CreateRoomInputPressed("l1"))
  elseif button == "guide" then
    eventmanager:fireEvent(events.CreateRoomInputPressed("esc"))
  end
end

function create_room:gamepadreleased(joystick, button)end

function create_room:keypressed(key, scancode, isrepeat)
  if submitting then return end --提交中的时候禁止任何输入
  --上下且选项类，左右切选项值
  if key == "up" then
    eventmanager:fireEvent(events.CreateRoomInputPressed("up"))
  elseif key == "down" then
    eventmanager:fireEvent(events.CreateRoomInputPressed("down"))
  elseif key == "left" then
    eventmanager:fireEvent(events.CreateRoomInputPressed("left"))
  elseif key == "right" then
    eventmanager:fireEvent(events.CreateRoomInputPressed("right"))
  elseif key == "r" then  --确认创建房间
    eventmanager:fireEvent(events.CreateRoomInputPressed("r1"))
  elseif key == "l" then --取消创建房间，退回到roomlist
    eventmanager:fireEvent(events.CreateRoomInputPressed("l1"))
  elseif key == "escape" then
    eventmanager:fireEvent(events.CreateRoomInputPressed("esc"))
  end
end

function create_room:keyreleased(key)end

--针对所有的pressed输入的事件处理函数
function InputHandler:firePressedEvent(event)
  local cmd = event.cmd
  if cmd == "up" then
    --切换到上一个选项
    current_select_class = prev_select_class[current_select_class]
  elseif cmd == "down" then
    current_select_class = next_select_class[current_select_class]
  elseif cmd == "left" then
    local select_item = selections[current_select_class]
    local result = results[current_select_class]
    result = result - 1
    if result < 1 then
      results[current_select_class] = #select_item
    else
      results[current_select_class] = result
    end
  elseif cmd == "right" then
    local select_item = selections[current_select_class]
    local result = results[current_select_class]
    result = result + 1
    if result > #select_item then
      results[current_select_class] = 1
    else
      results[current_select_class] = result
    end
  elseif cmd == "a" then
    
  elseif cmd == "b" then
    
  elseif cmd == "x" then
    
  elseif cmd == "y" then
    
  elseif cmd == "l1" then
    back_to_roomlist()
  elseif cmd == "l2" then
    
  elseif cmd == "r1" then
    print("create_room input_handler r1")
    submit_request()
  elseif cmd == "r2" then
    
  elseif cmd == "esc" then
    love.event.quit()
  end
end

function CreateRoomNetHandler:fireCreateRoomResEvent(event)
  --检查Server返回的roomId
  if event.roomId == "-1" then
    --创建房间失败
    submitting = false
  else
    --房间创建成功了
    --此时可以进入room.lua了，把该带的带进入
    local roomId = event.roomId
    local groupId = event.groupId + 1 --房间号为1/2，收到0/1
    local init_table = {}
    init_table["myId"] = myId
    init_table["roomId"] = roomId
    init_table["groupId"] = groupId  --房主默认在1号队
    init_table["roomMasterId"] = myId
    init_table["gameMode"] = selections["mode"][results["mode"]]  --"chaos"
    init_table["mapType"] = selections["map"][results["map"]]  --"as_snow"
    init_table["lifeNumber"] = selections["life"][results["life"]]
    init_table["playersPerGroup"] = selections["people"][results["people"]]
    init_table["playersInRoom"] = 1
    init_table["from_create_room"] = true   --是否是从create_room进入的
    game_state.switch(room, init_table)
  end
end

return create_room