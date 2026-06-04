local WindUI = loadstring(game:HttpGet(
  "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

local Window = WindUI:CreateWindow({
  Title = "BOSS",
  Icon = "star",
  Theme = "dark",
})

local Tab = Window:Tab({ Title = "Main", Icon = "home" })

Tab:Toggle({
  Title = "Enable Feature",
  Value = false,
  Callback = function(state)
    print("Feature:", state)
  end,
})
