local Version = "0.1"

local orb = module.internal('orb')
local pred = module.internal('pred')
local ts = module.internal('TS')
local damage = module.internal('damage')

local menu = menu("Ivern", "Shadow Ivern")
	menu:header("name", "Shadow Ivern")

	menu:menu("q", "Q Settings")
		menu.q:header("hd", "Q Settings")
        menu.q:boolean("qc", "Use [Q] in combo", true)
        menu.q:boolean("qa", "Use second [Q] in combo auto?", true)

  menu:menu("e", "E Settings")
        menu.e:header("hd", "E Settings")
        menu.e:boolean("es", "Auto [E] shield self", true)
        menu.e:boolean("ea", "Auto [E] shield allies", true)


	menu:menu("draws", "Draw Settings")
		menu.draws:header("hd", "Drawing Options")
    
    menu.draws:menu("qdraw", "[Q] Drawings")
        menu.draws.qdraw:boolean("q", "Draw [Q] Range", true)
        menu.draws.qdraw:color("qcolor", "[Q] Range Color", 0, 106, 255, 100)

    menu.draws:menu("wdraw", "[W] Drawings")
        menu.draws.wdraw:boolean("w", "Draw [W] Range", true)
        menu.draws.wdraw:color("wcolor", "[W] Range Color", 0, 106, 255, 100)
    
    menu.draws:menu("edraw", "[E] Drawings")
        menu.draws.edraw:boolean("e", "Draw [E] Range", true)
        menu.draws.edraw:color("ecolor", "[E] Range Color", 0, 106, 255, 100)
    
    menu.draws:menu("rdraw", "[R] Drawings")
        menu.draws.rdraw:boolean("r", "Draw [R] Range", true)
        menu.draws.rdraw:color("rcolor", "[R] Range Color", 0, 106, 255, 100)
    
	menu:header("version", "Version: " .. Version)
        menu:header("developer", "Developer: Shadow")
        menu:header("credits", "Made for ZENBOT 2020")

  local function OnDraw()
	if menu.draws.qdraw.q:get() and player:spellSlot(0).state == 0 and player.isOnScreen then
		graphics.draw_circle(player.pos, q_pred_input.range, 2, menu.draws.qdraw.qcolor:get(), 80)
  end
  if menu.draws.wdraw.w:get() and player:spellSlot(1).state == 0 and player.isOnScreen then
		graphics.draw_circle(player.pos, w_pred_input.range, 2, menu.draws.wdraw.wcolor:get(), 80)
	end
  if menu.draws.edraw.e:get() and player:spellSlot(2).state == 0 and player.isOnScreen then
		graphics.draw_circle(player.pos, e_pred_input.range, 2, menu.draws.edraw.ecolor:get(), 80)
	end
  if menu.draws.rdraw.r:get() and player:spellSlot(3).state == 0 then
		graphics.draw_circle(player.pos, r_pred_input.range, 2, menu.draws.rdraw.rcolor:get(), 80)
	end
end

local q_pred_input = {
  delay = 0.25,
  speed = 1300,
  width = 80,
  range = 1100,
  boundingRadiusMod = 0,
  collision = {
    hero = true,
    minion = true,
    wall = true,
  },
}

  local e_pred_input = {
    delay = 0,
    speed = 20,
    radius = 285,
    range = 750,
    boundingRadiusMod = 0,
    collision = {
      hero = false,
      minion = false,
      wall = false,
    },
}

local active_pred_input

local function trace_filter(seg, obj)
  if seg.startPos:dist(seg.endPos) > active_pred_input.range then return false end
  if pred.trace.linear.hardlock(active_pred_input, seg, obj) then
    return true
  end
  if pred.trace.linear.hardlockmove(active_pred_input, seg, obj) then
    return true
  end
  if pred.trace.newpath(obj, 0.033, 0.500) then
    return true
  end
end

local function trace_filter_circ(seg, obj)
  if seg.startPos:dist(seg.endPos) > active_pred_input.range then return false end
  if pred.trace.circular.hardlock(active_pred_input, seg, obj) then
    return true
  end
  if pred.trace.circular.hardlockmove(active_pred_input, seg, obj) then
    return true
  end
  if pred.trace.newpath(obj, 0.033, 0.500) then
    return true
  end
end

local function rks_target_filter(res, obj, dist)
  if dist > r_pred_input.range then return false end
  local seg = pred.circular.get_prediction(active_pred_input, obj)
  if not seg then return false end
  if not trace_filter_circ(seg, obj) then return false end
  if (damage.spell(player, obj, 3) < obj.health) then return false end
  res.pos = seg.endPos
  return true
end

local function q_target_filter(res, obj, dist)
  if dist > q_pred_input.range then return false end
  local seg = pred.circular.get_prediction(active_pred_input, obj)
  if not seg then return false end
  if not trace_filter_circ(seg, obj) then return false end
  res.pos = seg.endPos
  return true
end

local function q_logic()
  if player:spellSlot(0).state ~= 0 then return end
  active_pred_input = q_pred_input
  local res = ts.get_result(q_target_filter)
  if res.pos then
    if menu.q.qc:get() and menu.q.qa:get() then
      print("Cast Q and go to target")
    player:castSpell('pos', 0, vec3(res.pos.x, res.pos.y, res.pos.z))
    return true
    end

    if menu.q.qc:get() and not menu.q.qa:get() then
      if player:spellSlot(0).name == "IvernQRecast" then return end
      print("Cast Q")
      player:castSpell('pos', 0, vec3(res.pos.x, res.pos.y, res.pos.z))
      return true
    end
  end
end

local function e_logic()
  if player:spellSlot(2).state ~= 0 then return end
  active_pred_input = e_pred_input
  local res = ts.get_result(e_target_filter)
  if res.pos then
    player:castSpell('pos', 2, vec3(res.pos.x, res.pos.y, res.pos.z))
    return true
  end
end



local function combo()
  if (menu.q.qc:get() and q_logic()) then
    return true
  end
end

local function harass()
  if (menu.q.qh:get() and q_logic()) then
    return true
  end
  if (menu.e.eh:get() and e_logic()) then
    return true
  end
end

local function AutoShield()
    if menu.e.es:get() then
    if player:spellSlot(2).state ~= 0 then return end
    if damage.predict(player, 3) <= 200 then
          player:castSpell('self', 2)
    end
    end

    if menu.e.ea:get() then
        for i=0, objManager.allies_n-1 do
          local obj = objManager.allies[i]
          if player.pos:dist(obj.pos) >= 750 then return end
          if player:spellSlot(2).state ~= 0 then return end
          if damage.predict(obj, 3) <= 200 then
            player:castSpell('pos', 2, vec3(obj.pos.x, obj.pos.y, obj.pos.z))
          end
        end
    end
end


local function OnTick()
  if orb.menu.combat.key:get() then combo() end
  if orb.menu.hybrid.key:get() then harass() end
  AutoShield()
end

local function OnDraw()

	if menu.draws.qdraw.q:get() and player:spellSlot(0).state == 0 and player.isOnScreen then
		graphics.draw_circle(player.pos, q_pred_input.range, 2, menu.draws.qdraw.qcolor:get(), 80)
  end
  if menu.draws.edraw.e:get() and player:spellSlot(2).state == 0 and player.isOnScreen then
		graphics.draw_circle(player.pos, e_pred_input.range, 2, menu.draws.edraw.ecolor:get(), 80)
	end
end

cb.add(cb.tick, OnTick)
cb.add(cb.draw, OnDraw)
print("Loaded ShadowAIO Ivern - v" .. Version)

