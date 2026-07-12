local function get_cursor_prototype(player)
    if player.cursor_ghost
    then
        return player.cursor_ghost.name
    elseif player.cursor_stack and player.cursor_stack.valid_for_read
    then
        return player.cursor_stack.prototype
    end
    return nil
end

local function is_rail_signal(x)
    return (x == "rail-signal" or x == "rail-chain-signal")
end

rail_related_names = {
    ["rail-signal"] = true,
    ["rail-chain-signal"] = true,
    ["train-stop"] = true,
    ["rail-support"] = true,
    ["rail-ramp"] = true,
    ["locomotive"] = true,
    ["cargo-wagon"] = true,
    ["fluid-wagon"] = true,
    ["straight-rail"] = true,
    ["half-diagonal-rail"] = true,
    ["curved-rail-a"] = true,
    ["curved-rail-b"] = true,
    ["elevated-straight-rail"] = true,
    ["elevated-half-diagonal-rail"] = true,
    ["elevated-curved-rail-a"] = true,
    ["elevated-curved-rail-b"] = true,
}

local red = {1.0, 0.0, 0.0}
local green = {0.0, 0.8, 0.2}
local blue = {0.0, 0.75 , 1.0}
local amber = {1.0, 0.9, 0.0}
--local amber2 = {0.7, 0.6, 0.0}
local white = {1.0, 1.0, 1.0}

local function entity_state_color(signal)
    if signal.type == "entity-ghost"
    then
        return white
    end
    if signal.to_be_deconstructed()
    then
        return red
    end
    local entity_status = signal.status
    if (entity_status == defines.entity_status.cant_divide_segments or entity_status == defines.entity_status.not_connected_to_rail)
    then
        local colors = {green, amber, red}
        return colors[math.floor(game.tick / 30) % 3 + 1]
    end
    local state = signal.signal_state
    if state == defines.signal_state.closed or state == defines.signal_state.reserved_by_circuit_network
    then
        return red
    elseif state == defines.signal_state.reserved
    then
        return amber
    --[[
        if game.tick % 30 > 15
        then
            return amber
        else
            return amber2
        end
        ]]--
    else
        if signal.type == "rail-chain-signal"
        then
            local chain_state = signal.chain_signal_state
            if chain_state == defines.chain_signal_state.all_open
            then
                return green
            elseif chain_state == defines.chain_signal_state.partially_open
            then
                return blue
            elseif chain_state ==defines.chain_signal_state.none_open
            then
                return red
            end
        end
    end
    return green
end

local function add_sprite(sprite)
    table.insert(storage.signal_circles, sprite)
end

local function get_neighbour_signal(signal)
    if signal.type == "entity-ghost" then return nil end
    local connected_rails = signal.get_connected_rails()
    if #connected_rails == 0
    then
        return nil
    else
        local a = connected_rails[1].get_rail_segment_signal(defines.rail_direction.front, true)
        local b = connected_rails[1].get_rail_segment_signal(defines.rail_direction.front, false)
        if a == signal then return b end
        if b == signal then return a end
        local c = connected_rails[1].get_rail_segment_signal(defines.rail_direction.back, true)
        local d = connected_rails[1].get_rail_segment_signal(defines.rail_direction.back, false)
        if c == signal then return d end
        if d == signal then return c end
        return nil
    end
end

local function draw_rail_signal_circles()
    if storage.signal_circles == nil
    then
        storage.signal_circles = {}
    end
    for _, circle in pairs(storage.signal_circles)
    do
        circle.destroy()
    end
    storage.signal_circles = {}
    for _, player in pairs(game.players)
    do
        local prototype = get_cursor_prototype(player)
        if prototype and ((prototype.place_result and rail_related_names[prototype.place_result.type]) or prototype.type == "rail-planner")
        then
            local x0 = player.position.x
            local y0 = player.position.y
            local a = 100.0
            local area = {{x0 - a, y0 - a}, {x0 + a, y0 + a}}
            for _, signal in pairs(player.surface.find_entities_filtered{surface=player.surface, area = area})
            do
                if is_rail_signal(signal.type) or (signal.type == "entity-ghost" and is_rail_signal(signal.ghost_type))
                then
                    local color = entity_state_color(signal)
                    if signal.to_be_deconstructed()
                    then
                        add_sprite(rendering.draw_text{
                            text="×",
                            color=color,
                            scale=6.0,
                            alignment="center",
                            vertical_alignment="middle",
                            target={entity=signal, offset={0, -0.25}},
                            surface=signal.surface,
                            players={player},
                            only_in_alt_mode = true})
                    elseif (signal.status == defines.entity_status.cant_divide_segments) or (signal.status == defines.entity_status.not_connected_to_rail)
                    then
                        add_sprite(rendering.draw_text{
                            text="?",
                            color=color,
                            scale=6.0,
                            alignment="center",
                            vertical_alignment="middle",
                            target={entity=signal, offset={0, -0.25}},
                            surface=signal.surface,
                            players={player},
                            only_in_alt_mode = true})
                    else
                        local text = "↓"
                        if signal.type == "rail-signal" or (signal.type == "entity-ghost" and signal.ghost_type == "rail-signal")
                        then
                            add_sprite(rendering.draw_circle{
                                color=color,
                                radius=0.5,
                                width=5,
                                filled=true,
                                target=signal,
                                surface=signal.surface,
                                players={player},
                                only_in_alt_mode = true,
                            })
                        else
                            add_sprite(rendering.draw_circle{
                                color=color,
                                radius=0.4,
                                width=6,
                                filled=true,
                                target=signal,
                                surface=signal.surface,
                                players={player},
                                only_in_alt_mode = true,
                            })
                            add_sprite(rendering.draw_circle{
                                color=color,
                                radius=0.8,
                                width=6,
                                filled=false,
                                target=signal,
                                surface=signal.surface,
                                players={player},
                                only_in_alt_mode = true,
                            })
                        end
                        local neighbour = get_neighbour_signal(signal)
                        local angle = signal.direction * 3.14159265 / 8
                        local r = 1
                        if signal.direction % 2 == 1
                        then
                            r = 0.75
                        end
                        if not neighbour
                        then
                            r = r * 1.5
                        end
                        add_sprite(rendering.draw_text{
                            text=text,
                            color=color,
                            scale=5,
                            alignment="center",
                            vertical_alignment="middle",
                            target={entity=signal, offset={r * math.cos(angle), r * math.sin(angle) -0.05}},
                            orientation=(signal.direction * 0.0625),
                            surface=signal.surface,
                            players={player},
                            only_in_alt_mode = true})
                    end
                end
            end
        end
    end
end

script.on_event(defines.events.on_player_cursor_stack_changed,
    function(event)
        draw_rail_signal_circles()
    end)

script.on_nth_tick(60, function(event)
    draw_rail_signal_circles()
end)

script.on_event(defines.events.on_tick, function(event)
    if storage.signal_circles ~= nil
    then
        for _, circle in pairs(storage.signal_circles)
        do
            if circle.valid and circle.target.entity.type ~= "entity-ghost"
            then
                circle.color = entity_state_color(circle.target.entity)
            end
        end
    end
end)
