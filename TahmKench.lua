local Version = "0.1"

local orb = module.internal('orb')
local pred = module.internal('pred')
local ts = module.internal('TS')
local damage = module.internal('damage')

local menu = menu("tahm", "UnBenchTheKench")
    menu:header("name", "UnBenchTheKench")

    menu:menu("q", "Q Settings")
        menu.q:header("hd", "Q Settings")
        menu.q:boolean("qc", "Use [Q] in combo", true)
        menu.q:boolean("qh", "Use [Q] in harass", true)
        menu.q:header("hd", "Q Auto Settings")
        menu.q:boolean("qas", "Auto [Q] to stun", true)

    menu:menu("w", "W Settings")
        menu.w:header("hd", "W Settings")
        menu.w:boolean("wc", "Use [W] in combo", true)
        menu.w:boolean("wh", "Use [W] in harass", true)
        menu.w:header("hd", "W Auto Settings")
        menu.w:boolean("wae", "Auto [W] to eat", true)
        menu.w:boolean("waenq", "Only Auto [W] if cant stun?", true)

  menu:menu("e", "E Settings")
        menu.e:header("hd", "E Settings")
        menu.e:boolean("ea", "Use [E] Auto", true)

    menu:menu("draws", "Draw Settings")
        menu.draws:header("hd", "Drawing Options")
    
    menu.draws:menu("qdraw", "[Q] Drawings")
        menu.draws.qdraw:boolean("q", "Draw [Q] Range", true)
        menu.draws.qdraw:color("qcolor", "[Q] Range Color", 0, 106, 255, 100)
    
    menu.draws:menu("rdraw", "[R] Drawings")
        menu.draws.rdraw:boolean("r", "Draw [R] Range", true)
        menu.draws.rdraw:color("rcolor", "[R] Range Color", 0, 106, 255, 100)
    
    menu:header("version", "Version: " .. Version)
        menu:header("developer", "Developer: Zanthir/Shadow")
        menu:header("credits", "Made for Echelon")


local q_pred_input = {
  delay = 0.25,
  speed = 0,
  radius = 210,
  range = 800,
  boundingRadiusMod = 0,
  collision = {
    hero = true,
    minion = true,
    wall = false,
  },
}

local w_pred_input = {
  delay = 0.25,
  speed = 0,
  radius = 250,
  range = 250,
  boundingRadiusMod = 0,
  collision = {
    hero = true,
    minion = true,
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


local function q_target_filter(res, obj, dist)
  if dist > q_pred_input.range then return false end
  local seg = pred.circular.get_prediction(active_pred_input, obj)
  if not seg then return false end
  if not trace_filter_circ(seg, obj) then return false end
  res.pos = seg.endPos
  return true
end

local function q_stun_target_filter(res, obj, dist)
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
    player:castSpell('pos', 0, vec3(res.pos.x, res.pos.y, res.pos.z))
    return true
  end
end


local AutoFunction;AutoFunction = function()
  for threat, tsobj in pairs(ts.get_sorted_heroes()) do
    local target = tsobj.obj
    local dist = target:dist()
    if dist <= q_pred_input.range then
      for i = 0, target.buffManager.count - 1 do
          local buff = target.buffManager:get(i)
          if (buff.valid) then
            if menu.q.qas:get() then
              if dist > q_pred_input.range then return false end
                if buff.name == "tahmkenchpdevourable" then
                    player:castSpell('pos', 0, vec3(target.pos.x, target.pos.y, target.pos.z))
                end
            end
            if menu.w.wae:get() and not menu.w.waenq:get() then
                if buff.name == "tahmkenchpdevourable" then
                    q_logic()
                end
            end
            if menu.w.wae:get() and menu.w.waenq:get() then
              if player:spellSlot(0).state ~= 0 then
                if buff.name == "tahmkenchpdevourable" then
                  player:castSpell('pos', 1, vec3(target.pos.x, target.pos.y, target.pos.z))
                end
              end
            end
        end
      end 
    end
  end
end

local function autoeat()
  for i=0, objManager.allies_n-1 do
    local obj = objManager.allies[i]
    if player.pos:dist(obj.pos) >= 250 then return end
    if player:spellSlot(1).state ~= 0 then return end
    if damage.predict(obj, 3) <= 100 then
      player:castSpell('pos', 1, vec3(obj.pos.x, obj.pos.y, obj.pos.z))
    end
  end
end

local function autoshield()
    if player:spellSlot(2).state ~= 0 then return end
    if damage.predict(player, 3) <= 100 then
      player:castSpell('self', 2)
    end
end
--[[
local function wenemyminions()
local hasfood;
  if orb.menu.combat.key:get() then return end
  if hasfood == true then return end
    local seg, obj = orb.farm.skill_clear_linear(w_pred_input)
    if obj then
      player:castSpell('pos', 1, vec3(obj.pos.x, obj.pos.y, obj.pos.z))
      print("got obj")
    end

    if hasfood == true then
      player:castSpell('pos', 1, vec3(target.pos.x, target.pos.y, target.pos.z))
    end

    for i = 0, player.buffManager.count - 1 do
      local buff = player.buffManager:get(i)
      if (buff.valid) then
            if buff.name == "tahmkenchwhasdevouredtarget" then
                hasfood = true
                print(hasfood)
        end
      end
    end
end
]]

cb.add(cb.tick, AutoFunction)

local RRange = {
    2500,
    5500,
    8500
}

local function combo()
  if (menu.q.qc:get() and q_logic()) then
    return true
  end
end

local function harass()
  if (menu.q.qh:get() and q_logic()) then
    return true
  end
end

local function killsteal()
    
end

local function TestingData()
end

local function OnDraw()
  if menu.draws.qdraw.q:get() and player:spellSlot(0).state == 0 and player.isOnScreen then
      graphics.draw_circle(player.pos, q_pred_input.range, 2, menu.draws.qdraw.qcolor:get(), 80)
end
end

local function OnDraw2()
  if menu.draws.rdraw.r:get() and player:spellSlot(3).state == 0 then
        minimap.draw_circle(player.pos, RRange[player:spellSlot(3).level], 2, menu.draws.rdraw.rcolor:get())
    end
  end

local function OnTick()
  if orb.menu.combat.key:get() then combo() end
  if orb.menu.hybrid.key:get() then harass() end
  killsteal()
  TestingData()
  autoeat()
  autoshield()
end

cb.add(cb.tick, OnTick)
cb.add(cb.draw, OnDraw)
cb.add(cb.draw2, OnDraw2)
print("Loaded UnbenchTheKench - v" .. Version)

