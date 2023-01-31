vim.o.termguicolors = true

if not pcall(require, 'feline') then
  return
end


local feline = require('feline')
--local vi_mode = require('feline.providers.vi_mode')

local function get_highlight(name)
  local hl = vim.api.nvim_get_hl_by_name(name, true)
  if hl.link then
    return get_highlight(hl.link)
  end

  local hex = function(n)
    if n then
      return string.format('#%06x', n)
    end
  end

  local names = { 'underline', 'undercurl', 'bold', 'italic', 'reverse' }
  local styles = {}
  for _, n in ipairs(names) do
    if hl[n] then
      table.insert(styles, n)
    end
  end

  return {
    fg = hex(hl.foreground),
    bg = hex(hl.background),
    sp = hex(hl.special),
    style = #styles > 0 and table.concat(styles, ',') or 'NONE',
  }
end

local function generate_pallet_from_colorscheme()
  -- stylua: ignore
  local color_map = {
    black   = { index = 0, default = "#393b44" },
    red     = { index = 1, default = "#c94f6d" },
    green   = { index = 2, default = "#81b29a" },
    yellow  = { index = 3, default = "#dbc074" },
    blue    = { index = 4, default = "#719cd6" },
    magenta = { index = 5, default = "#9d79d6" },
    cyan    = { index = 6, default = "#63cdcf" },
    white   = { index = 7, default = "#dfdfe0" },
  }

  local diagnostic_map = {
    hint = { hl = 'DiagnosticHint', default = color_map.green.default },
    info = { hl = 'DiagnosticInfo', default = color_map.blue.default },
    warn = { hl = 'DiagnosticWarn', default = color_map.yellow.default },
    error = { hl = 'DiagnosticError', default = color_map.red.default },
  }

  local pallet = {}
  for name, value in pairs(color_map) do
    local global_name = 'terminal_color_' .. value.index
    pallet[name] = vim.g[global_name] and vim.g[global_name] or value.default
  end

  for name, value in pairs(diagnostic_map) do
    pallet[name] = get_highlight(value.hl).fg or value.default
  end

  pallet.sl = get_highlight('StatusLine')
  pallet.tab = get_highlight('TabLine')
  pallet.sel = get_highlight('TabLineSel')
  pallet.fill = get_highlight('TabLineFill')

  return pallet
end

local pallet = generate_pallet_from_colorscheme()

-- T theme
local T = {
  fg = '#ebdbb2',
  bg = '#3c3836',
  black = '#3c3836',
  skyblue = '#83a598',
  cyan = '#8e07c',
  green = '#b8bb26',
  oceanblue = '#076678',
  blue = '#458588',
  magenta = '#d3869b',
  orange = '#d65d0e',
  red = '#fb4934',
  violet = '#b16286',
  white = '#ebdbb2',
  yellow = '#fabd2f',
}

local sl = pallet.sl

T = {
  fg = sl.fg,
  bg = sl.bg,
  black = pallet.black or T.black,
  skyblue = pallet.skyblue or T.skyblue,
  cyan = pallet.cyan or T.cyan,
  green = pallet.green or T.green,
  oceanblue = pallet.oceanblue or T.oceanblue,
  blue = pallet.blue or T.blue,
  magenta = pallet.magenta or T.magenta,
  orange = pallet.orange or T.orange,
  red = pallet.red or T.red,
  violet = pallet.violet or T.violet,
  white = pallet.white or T.white,
  yellow = pallet.yellow or T.yellow,
}

local function hex2rgb(hex)
  hex = hex:gsub('#', '')
  return {
    tonumber('0x' .. hex:sub(1, 2)),
    tonumber('0x' .. hex:sub(3, 4)),
    tonumber('0x' .. hex:sub(5, 6)),
  }
end

local function rgb2hex(rgb)
  local hexadecimal = '#'
  for key, value in pairs(rgb) do
    local hex = ''
    while value > 0 do
      local index = math.fmod(value, 16) + 1
      value = math.floor(value / 16)
      hex = string.sub('0123456789ABCDEF', index, index) .. hex
    end
    if string.len(hex) == 0 then
      hex = '00'
    elseif string.len(hex) == 1 then
      hex = '0' .. hex
    end
    hexadecimal = hexadecimal .. hex
  end
  return hexadecimal
end

-- color helpers
local function darken(color, value)
  -- vanilla lua to darken a color by a value
  local rgb = hex2rgb(color)
  for i = 1, 3 do
    rgb[i] = math.max(rgb[i] - value, 0)
  end
  return rgb2hex(rgb)
end

local function convert_string_to_unicode(string)
  -- format is "04n"
  local icon = string.sub(string, 1, 2)
  local icon_map = {
    ['01'] = '',
    ['02'] = '',
    ['03'] = '',
    ['04'] = '',
    ['09'] = '',
    ['10'] = '',
    ['11'] = '',
    ['13'] = '',
    ['50'] = '',
    ['09'] = '',
    ['10'] = '',
    ['11'] = '',
    ['13'] = '',
    ['50'] = '',
  }
  return icon_map[icon]
end

local function get_temperature_color(temp)
  local temp = tonumber(temp)
  if temp < 50 then
    return darken(T.cyan, 20)
  elseif temp < 60 then
    return darken(T.blue, 20)
  elseif temp < 70 then
    return darken(T.green, 20)
  elseif temp < 80 then
    return darken(T.yellow, 20)
  elseif temp < 90 then
    return darken(T.orange, 20)
  else
    return darken(T.red, 20)
  end
end

-- get weather info (is localized in weather_data global)
function get_weather()
  local weather = weather_data
  if weather == nil then
    return ''
  end

  local icon = convert_string_to_unicode(weather.weather[1].icon)

  local temp = weather.main.temp

  return icon .. '  ' .. temp .. '°F '
end


-- provide weather
function provide_weather(component, opts)
  return get_weather()
end




-- components
local components = {
  -- components when buffer is active
  active = {
    {}, -- left section
    {}, -- right section
  },
  -- components when buffer is inactive
  inactive = {
    {}, -- left section
    {}, -- right section
  },
}

local LEFT, RIGHT = 1, 2 -- 1 is left, 2 is right

local function register_component(section, component_data, active)
  active = active == nil and true or active
  table.insert(active and components.active[section] or components.inactive[section], {
    name = component_data.name,
    provider = component_data.provider,
    left_sep = component_data.left_sep,
    right_sep = component_data.right_sep,
    hl = component_data.hl,
  })
end



register_component(RIGHT, {
  name = 'weather',
  provider = provide_weather,
  left_sep = '',
  hl = function()
    return {
      bg = get_temperature_color(weather_data.main.temp),
      fg = 'white',
    }
  end,
})


feline.setup({
  theme = T,
  components = components,
  -- vi_mode_colors = MODE_COLORS,
})
