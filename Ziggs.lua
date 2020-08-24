local Version = "0.1"

local orb = module.internal('orb')
local pred = module.internal('pred')
local ts = module.internal('TS')
local damage = module.internal('damage')

local menu = menu("ziggs", "Shadow Ziggs")
	menu:header("name", "Shadow Ziggs")

  menu:menu("q", "Q Settings")
  menu.q:header("hd", "Q Settings")
      menu.q:boolean("qc", "Use [Q] in combo", true)
      menu.q:boolean("qh", "Use [Q] in harass", true)
      menu.q:boolean("qlc", "Use [Q] in lane clear", true)

menu:menu("w", "W Settings")
      menu.w:header("hd", "W Settings")
      menu.w:boolean("wc", "Use [W] in combo", true)
      menu.w:boolean("wh", "Use [W] in harass", true)
      menu.q:boolean("wlc", "Use [W] in lane clear", true)

menu:menu("e", "E Settings")
      menu.e:header("hd", "E Settings")
      menu.e:boolean("ec", "Use [E] in combo", true)
      menu.e:boolean("eh", "Use [E] in harass", true)
      menu.e:boolean("elc", "Use [E] in lane clear", true)

menu:menu("r", "R Settings")
  menu.r:header("hd", "R Settings")
      menu.r:boolean("rc", "Use [R] in combo", true)
      menu.r:boolean("rh", "Use [R] in harass", true)
      menu.r:boolean("rks", "Use [R] in kill steal", true)

	menu:menu("ks", "Killsteal Settings")
		menu.ks:header("hd", "Killsteal Settings")
    menu.ks:boolean("mks", "Enable Killsteal", true)
		menu.ks:boolean("qks", "Use [Q] in Killsteal", true)
    menu.ks:boolean("eks", "Use [W] in Killsteal", true)
    menu.ks:boolean("wks", "Use [E] in Killsteal", true)
    menu.ks:boolean("rks", "Use [R] in Killsteal", true)

  menu:menu("tower", "Tower Kill Settings")
		menu.tower:header("hd", "Tower Kill Settings")
    menu.tower:boolean("mks", "Enable Tower Kill", true)
		menu.tower:boolean("qks", "Use [W] in Tower Kill", true)


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
		graphics.draw_circle(player.pos, 1000, 2, menu.draws.edraw.ecolor:get(), 80)
	end
  if menu.draws.rdraw.r:get() and player:spellSlot(3).state == 0 then
		graphics.draw_circle(player.pos, 600, 2, menu.draws.rdraw.rcolor:get(), 80)
	end
end
local q_pred_input = {
  delay = 0.25,
  speed = 1700,
  radius = 30,
  range = 1400,
  boundingRadiusMod = 0,
  collision = {
    hero = true,
    minion = true,
    wall = true,
  },
}

local w_pred_input = {
  delay = 0.25,
  speed = 1300,
  radius = 100,
  range = 1000,
  boundingRadiusMod = 0,
  collision = {
    hero = false,
    minion = false,
    wall = true,
  },
}

local e_pred_input = {
  delay = 0.25,
  speed = math.huge,
  width = 100,
  range = 900,
  boundingRadiusMod = 1,
  collision = {
    hero = false,
    minion = false,
    wall = true,
  },
}

local r_pred_input = {
  delay = 1.25,
  speed = math.huge,
  radius = 550,
  range = 5000,
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

local function qks_target_filter(res, obj, dist)
  if dist > 1100 then return false end
  local seg = pred.circular.get_prediction(active_pred_input, obj)
  if not seg then return false end
  if not trace_filter_circ(seg, obj) then return false end
  if (damage.spell(player, obj, 0) < obj.health) then return false end
  res.pos = seg.endPos
  return true
end

local function wks_target_filter(res, obj, dist)
  if dist > w_pred_input.range then return false end
  local seg = pred.circular.get_prediction(active_pred_input, obj)
  if not seg then return false end
  if not trace_filter_circ(seg, obj) then return false end
  if (damage.spell(player, obj, 1) < obj.health) then return false end
  res.pos = seg.endPos
  return true
end

local function eks_target_filter(res, obj, dist)
  if dist > 900 then return false end
  local seg = pred.linear.get_prediction(active_pred_input, obj)
  if not seg then return false end
  if not trace_filter(seg, obj) then return false end
  if (damage.spell(player, obj, 2) < obj.health) then return false end
  res.pos = seg.endPos
  return true
end

local function rks_target_filter(res, obj, dist)
  if dist > 5000 then return false end
  local seg = pred.linear.get_prediction(active_pred_input, obj)
  if not seg then return false end
  if not trace_filter(seg, obj) then return false end
  if (damage.spell(player, obj, 3) < obj.health) then return false end
  res.pos = seg.endPos
  return true
end

local function q_target_filter(res, obj, dist)
  if dist > 1100 then return false end
  local seg = pred.circular.get_prediction(active_pred_input, obj)
  if not seg then return false end
  if not trace_filter_circ(seg, obj) then return false end
  res.pos = seg.endPos
  return true
end

local function w_target_filter(res, obj, dist)
  if dist > 1000 then return false end
  local seg = pred.circular.get_prediction(active_pred_input, obj)
  if not seg then return false end
  if not trace_filter_circ(seg, obj) then return false end
  res.pos = seg.endPos
  return true
end

local function e_target_filter(res, obj, dist)
  if dist > 900 then return false end
  local seg = pred.linear.get_prediction(active_pred_input, obj)
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
    player:castSpell('pos', 0, vec3(res.pos.x, res.pos.y, res.pos.z))
    orb.core.set_server_pause()
    return true
  end
end

local function w_logic()
  if player:spellSlot(1).state ~= 0 then return end
  active_pred_input = w_pred_input
  local res = ts.get_result(w_target_filter)
  if res.pos then
    player:castSpell('pos', 1, vec3(res.pos.x, res.pos.y, res.pos.z))
    orb.core.set_server_pause()
    return true
  end
end

local function e_logic()
  if player:spellSlot(2).state ~= 0 then return end
  active_pred_input = e_pred_input
  local res = ts.get_result(e_target_filter)
  if res.pos then
    player:castSpell('pos', 2, vec3(res.pos.x, res.pos.y, res.pos.z))
    orb.core.set_server_pause()
    return true
  end
end

local function qks_logic()
  if player:spellSlot(0).state ~= 0 then return end
  active_pred_input = q_pred_input
  local res = ts.get_result(qks_target_filter)
  if res.pos then
    player:castSpell('pos', 0, vec3(res.pos.x, res.pos.y, res.pos.z))
    orb.core.set_server_pause()
    return true
  end
end

local function wks_logic()
  if player:spellSlot(1).state ~= 0 then return end
  active_pred_input = w_pred_input
  local res = ts.get_result(wks_target_filter)
  if res.pos then
    player:castSpell('pos', 1, vec3(res.pos.x, res.pos.y, res.pos.z))
    orb.core.set_server_pause()
    return true
  end
end

local function eks_logic()
  if player:spellSlot(2).state ~= 0 then return end
  active_pred_input = e_pred_input
  local res = ts.get_result(eks_target_filter)
  if res.pos then
    player:castSpell('pos', 2, vec3(res.pos.x, res.pos.y, res.pos.z))
    orb.core.set_server_pause()
    return true
  end
end

local function rks_logic()
  if player:spellSlot(3).state ~= 0 then return end
  active_pred_input = q_pred_input
  local res = ts.get_result(rks_target_filter)
  if res.pos then
    player:castSpell('pos', 3, vec3(res.pos.x, res.pos.y, res.pos.z))
    orb.core.set_server_pause()
    return true
  end
end

local function towerkill()
  for i=0, objManager.turrets.size[TEAM_ENEMY]-1 do
    local obj = objManager.turrets[TEAM_ENEMY][i]
    local distance = player.pos2D:dist(obj.pos2D)
    if distance < 1000 then
    -- Start Ziggs W Tower Math
    local health = obj.health
    local twentyfivehealth = (obj.maxHealth / 4)
    local twentysevenhealth = (obj.maxHealth * 27.5) * .01
    local thirtyhealth = (obj.maxHealth * 30) * .01
    local thirtytwentyfivehealth = (obj.maxHealth * 32.5) * .01 
    local thirtyfivehealth = (obj.maxHealth * 35) * .01
      print(obj.name)
      if player:spellSlot(1).level == 0 then return 
        player:castSpell('pos', 1, vec3(obj.pos.x, obj.pos.y, obj.pos.z))
      elseif player:spellSlot(1).level == 1 and health <= twentyfivehealth then
        player:castSpell('pos', 1, vec3(obj.pos.x, obj.pos.y, obj.pos.z))
      elseif player:spellSlot(1).level == 2 and health <= twentysevenhealth and distance < 1000 then
        player:castSpell('pos', 1, vec3(obj.pos.x, obj.pos.y, obj.pos.z))
      elseif player:spellSlot(1).level == 3 and health <= thirtyhealth and distance < 1000 then
        player:castSpell('pos', 1, vec3(obj.pos.x, obj.pos.y, obj.pos.z))
      elseif player:spellSlot(1).level == 4 and health <= thirtytwentyfivehealth and distance < 1000 then
        player:castSpell('pos', 1, vec3(obj.pos.x, obj.pos.y, obj.pos.z))
      elseif player:spellSlot(1).level == 5 and health <= thirtyfivehealth and distance < 1000 then
        player:castSpell('pos', 1, vec3(obj.pos.x, obj.pos.y, obj.pos.z))
      end
    else 
    end
end
end

local function combo()
  if (menu.e.ec:get() and e_logic()) then
    return true
  end
  if (menu.q.qc:get() and q_logic()) then
    return true
  end
  if (menu.w.wc:get() and w_logic()) then
    return true
  end
end

local function harass()
  if (menu.harass.q:get() and q_logic()) then
    return true
  end
  if (menu.harass.e:get() and e_logic()) then
    return true
  end
end

local function killsteal()
  if (menu.ks.qks:get() and qks_logic()) then
    return true
  end
  if (menu.ks.wks:get() and wks_logic()) then
    return true
  end
  if (menu.ks.eks:get() and eks_logic()) then
    return true
  end
  if (menu.ks.rks:get() and rks_logic()) then
    return true
  end
end

local function TestingData()
  graphics.draw_circle(v1, radius, width, color, pts_n)
end

local function OnTick()
  if orb.menu.combat.key:get() then combo() end
	if orb.menu.hybrid.key:get() then harass() end
  if menu.ks.mks:get() then killsteal(); end
  if menu.tower.mks:get() then towerkill(); end
end

local function OnDraw()

	if menu.draws.qdraw.q:get() and player:spellSlot(0).state == 0 and player.isOnScreen then
		graphics.draw_circle(player.pos, q_pred_input.range, 2, menu.draws.qdraw.qcolor:get(), 80)
  end
  if menu.draws.wdraw.w:get() and player:spellSlot(1).state == 0 and player.isOnScreen then
		graphics.draw_circle(player.pos, w_pred_input.range, 2, menu.draws.qdraw.qcolor:get(), 80)
	end
  if menu.draws.edraw.e:get() and player:spellSlot(2).state == 0 and player.isOnScreen then
		graphics.draw_circle(player.pos, e_pred_input.range, 2, menu.draws.edraw.ecolor:get(), 80)
	end
  if menu.draws.rdraw.r:get() and player:spellSlot(3).state == 0 then
    graphics.draw_circle(player.pos, r_pred_input.range, 2, menu.draws.rdraw.rcolor:get(), 80)
    minimap.draw_circle(player.pos, r_pred_input.range, 2, menu.draws.rdraw.rcolor:get(), 80)
  end
  
end

cb.add(cb.tick, OnTick)
cb.add(cb.draw, OnDraw)
print("Loaded ShadowAIO Ziggs - v" .. Version)

