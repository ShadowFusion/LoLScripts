local Version = "0.1"

local orb = module.internal('orb')
local pred = module.internal('pred')
local ts = module.internal('TS')
local damage = module.internal('damage')

local menu = menu("Gnar", "Shadow Gnar")
	menu:header("name", "Shadow Gnar")

	menu:menu("q", "Q Settings")
		menu.q:header("hd", "Q Settings")
        menu.q:boolean("qc", "Use [Q] in combo", true)
        menu.q:boolean("qh", "Use [Q] in harass", true)
        menu.q:boolean("qlc", "Use [Q] in lane clear", true)
        menu.q:boolean("qf", "Use [Q] in jungle clear", true)

	menu:menu("w", "W Settings")
        menu.w:header("hd", "W Settings")
        menu.w:boolean("wc", "Use [W] in combo", true)
        menu.w:boolean("wh", "Use [W] in harass", true)
        menu.q:boolean("wlc", "Use [W] in lane clear", true)

  menu:menu("e", "E Settings")
        menu.e:header("hd", "E Settings")
        menu.e:boolean("ec", "Use [E] in combo", true)
        menu.e:boolean("eh", "Use [E] in harass", true)
        menu.e:boolean("eg", "Use [E] in gap close", true)

	menu:menu("r", "R Settings")
		menu.r:header("hd", "R Settings")
        menu.r:boolean("rks", "Use [R] in kill steal", true)

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
  delay = 0,
  speed = 1200,
  width = 55,
  range = 1100,
  boundingRadiusMod = 0,
  collision = {
    hero = false,
    minion = false,
    wall = true,
  },
}
  local e_pred_input = {
    delay = 0.25,
    speed = 0,
    radius = 350,
    range = 425,
    boundingRadiusMod = 1,
    collision = {
      hero = false,
      minion = false,
      wall = false,
    },
}

local r_pred_input = {
  delay = 0.25,
  speed = 1500,
  radius = 375,
  range = 375,
  boundingRadiusMod = 1,
  collision = {
    hero = true,
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
  if obj.maxHealth / 4 >= obj.health then
  end
  if obj.health > obj.maxHealth / 4 then return end
  res.pos = seg.endPos
  return true
end

local function q_target_filter(res, obj, dist)
  if dist > q_pred_input.range then return false end
  local seg = pred.linear.get_prediction(active_pred_input, obj)
  if not seg then return false end
  if not trace_filter_circ(seg, obj) then return false end
  res.pos = seg.endPos
  return true
end

local function w_target_filter(res, obj, dist)
  if dist > w_pred_input.range then return false end
  local seg = pred.circular.get_prediction(active_pred_input, obj)
  if not seg then return false end
  if not trace_filter_circ(seg, obj) then return false end
  res.pos = seg.endPos
  return true
end

local function e_target_filter(res, obj, dist)
  if dist > e_pred_input.range then return false end
  local seg = pred.linear.get_prediction(active_pred_input, obj)
  if not seg then return false end
  if not trace_filter(seg, obj) then return false end
  res.pos = seg.endPos
  return true
end

local function egap_target_filter(res, obj, dist)
  if dist > e_pred_input.range * 2 then return false end
  local seg = pred.linear.get_prediction(active_pred_input, obj)
  if not seg then return false end
  if not trace_filter(seg, obj) then return false end
  res.pos = seg.endPos
  return true
end

local function r_target_filter(res, obj, dist)
  if dist > r_pred_input.range then return false end
  local seg = pred.circular.get_prediction(active_pred_input, obj)
  if not seg then return false end
  if not trace_filter(seg, obj) then return false end
  res.pos = seg.endPos
  return true
end

local function q_logic()
  if player:spellSlot(0).state ~= 0 then return end
  active_pred_input = q_pred_input
  local res = ts.get_result(q_target_filter)
  if res.pos then
    player:castSpell('pos', 0, vec3(res.pos))
    return true
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

local function rks_logic()
  if player:spellSlot(3).state ~= 0 then return end
  active_pred_input = r_pred_input
  local res = ts.get_result(rks_target_filter)
  if res.pos then
    player:castSpell('pos', 3, vec3(res.pos.x, res.pos.y, res.pos.z))
    return true
  end
end

local function farm()
  if (menu.q.qf:get()) then
    if orb.menu.lane_clear.key:get() then
      local seg, obj = orb.farm.skill_farm_linear(q_pred_input)
      if seg then
        player:castSpell('pos', 0, vec3(seg.endPos.x, seg.endPos.y, seg.endPos.y))
      end
    end
  end
end


local function combo()
  if (menu.q.qc:get() and q_logic()) then
    return true
  end
  if (menu.e.ec:get() and e_logic()) then
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

local function killsteal()
  if menu.r.rks:get() and rks_logic() then
    return true
  end
end

local function TestingData()

end

local function EGapCloser()
  if (menu.e.eg:get()) then
    print("Menu Activated")
    local seg, obj = orb.farm.skill_farm_linear(e_pred_input)
      if seg then

      end

  end
end


local function Farming()
  if (menu.q.qf:get()) then
    if orb.menu.lane_clear.key:get() then
      local seg, obj = orb.farm.skill_clear_linear(q_pred_input)
      if obj and obj.isMonster then
        player:castSpell('pos', 0, vec3(seg.endPos.x, mousePos.y, seg.endPos.y))
      end
    end
  end

  if (menu.q.qlc:get()) then
    if orb.menu.lane_clear.key:get() then
      local seg, obj = orb.farm.skill_clear_linear(q_pred_input)
      if obj then
        player:castSpell('pos', 0, vec3(seg.endPos.x, mousePos.y, seg.endPos.y))
      end
    end
  end

end

local function OnTick()
  if orb.menu.combat.key:get() then combo() end
  if orb.menu.hybrid.key:get() then harass() end
  if orb.menu.lane_clear.key:get() then Farming() end
  killsteal()
  TestingData()
  EGapCloser()
end

local function OnDraw()

	if menu.draws.qdraw.q:get() and player:spellSlot(0).state == 0 and player.isOnScreen then
		graphics.draw_circle(player.pos, q_pred_input.range, 2, menu.draws.qdraw.qcolor:get(), 80)
  end
  if menu.draws.edraw.e:get() and player:spellSlot(2).state == 0 and player.isOnScreen then
		graphics.draw_circle(player.pos, e_pred_input.range, 2, menu.draws.edraw.ecolor:get(), 80)
	end
  if menu.draws.rdraw.r:get() and player:spellSlot(3).state == 0 then
    graphics.draw_circle(player.pos, r_pred_input.range, 2, menu.draws.rdraw.rcolor:get(), 80)
  end
  
end

cb.add(cb.tick, OnTick)
cb.add(cb.draw, OnDraw)
print("Loaded ShadowAIO Gnar - v" .. Version)

