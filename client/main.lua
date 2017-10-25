local Keys = {
  ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
  ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
  ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
  ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
  ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
  ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
  ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
  ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
  ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

local PlayerData                = {}
local GUI                       = {}
local HasAlreadyEnteredMarker   = false
local LastZone                  = nil
local CurrentAction             = nil
local CurrentActionMsg          = ''
local CurrentActionData         = {}
local OnJob                     = false
local CurrentCustomer           = nil
local CurrentCustomerBlip       = nil
local DestinationBlip           = nil
local IsNearCustomer            = false
local CustomerIsEnteringVehicle = false
local CustomerEnteredVehicle    = false
local TargetCoords              = nil

ESX                             = nil
GUI.Time                        = 0

Citizen.CreateThread(function()
  while ESX == nil do
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    Citizen.Wait(0)
  end
end)

function OpenWashActionsMenu()

  local elements = {
    {label = _U('spawn_veh'), value = 'spawn_vehicle'},
    {label = _U('cloakroom'), value = 'cloakroom'},
    {label = _U('deposit_stock'), value = 'put_stock'},
    {label = _U('take_stock'), value = 'get_stock'}
  }

  if Config.EnablePlayerManagement and PlayerData.job ~= nil and PlayerData.job.grade_name == 'boss' then
    table.insert(elements, {label = _U('boss_actions'), value = 'boss_actions'})
  end

  ESX.UI.Menu.CloseAll()

  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'wash_actions',
    {
      title    = 'Wash',
      elements = elements
    },
    function(data, menu)

      if data.current.value == 'cloakroom' then
        OpenCloakroomMenu()
      end

      if data.current.value == 'put_stock' then
        OpenPutStocksMenu()
      end

      if data.current.value == 'get_stock' then
        OpenGetStocksMenu()
      end

      if data.current.value == 'spawn_vehicle' then

        if Config.EnableSocietyOwnedVehicles then

          local elements = {}

          ESX.TriggerServerCallback('esx_society:getVehiclesInGarage', function(vehicles)

            for i=1, #vehicles, 1 do
              table.insert(elements, {label = GetDisplayNameFromVehicleModel(vehicles[i].model) .. ' [' .. vehicles[i].plate .. ']', value = vehicles[i]})
            end

            ESX.UI.Menu.Open(
              'default', GetCurrentResourceName(), 'vehicle_spawner',
              {
                title    = _U('spawn_veh'),
                align    = 'top-left',
                elements = elements,
              },
              function(data, menu)

                menu.close()

                local vehicleProps = data.current.value

                ESX.Game.SpawnVehicle(vehicleProps.model, Config.Zones.VehicleSpawnPoint.Pos, 270.0, function(vehicle)
                  ESX.Game.SetVehicleProperties(vehicle, vehicleProps)
                  local playerPed = GetPlayerPed(-1)
                  TaskWarpPedIntoVehicle(playerPed,  vehicle,  -1)
                end)

                TriggerServerEvent('esx_society:removeVehicleFromGarage', 'baller6', vehicleProps)

              end,
              function(data, menu)
                menu.close()
              end
            )

          end, 'wash')

        else

          menu.close()

          if Config.MaxInService == -1 then

            local playerPed = GetPlayerPed(-1)
            local coords    = Config.Zones.VehicleSpawnPoint.Pos

            ESX.Game.SpawnVehicle('baller6', coords, 225.0, function(vehicle)
              TaskWarpPedIntoVehicle(playerPed,  vehicle, -1)
            end)

          else

            ESX.TriggerServerCallback('esx_service:enableService', function(canTakeService, maxInService, inServiceCount)

              if canTakeService then

                local playerPed = GetPlayerPed(-1)
                local coords    = Config.Zones.VehicleSpawnPoint.Pos

                ESX.Game.SpawnVehicle('baller6', coords, 225.0, function(vehicle)
                  TaskWarpPedIntoVehicle(playerPed,  vehicle, -1)
                end)

              else

                ESX.ShowNotification(_U('full_service') .. inServiceCount .. '/' .. maxInService)

              end

            end, 'wash')

          end

        end

      end

      if data.current.value == 'boss_actions' then
        TriggerEvent('esx_society:openBossMenu', 'wash', function(data, menu)
          menu.close()
        end, {wash = true})
      end

    end,
    function(data, menu)

      menu.close()

      CurrentAction     = 'wash_actions_menu'
      CurrentActionMsg  = _U('press_to_open')
      CurrentActionData = {}

    end
  )

end

function OpenCloakroomMenu()

  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'cloakroom',
    {
      title    = _U('cloakroom'),
      align    = 'top-left',
      elements = {
        {label = _U('wash_clothes_civil'), value = 'citizen_wear'},
        {label = _U('wash_clothes_wash'), value = 'wash_wear'},
      },
    },
    function(data, menu)

      menu.close()

      if data.current.value == 'citizen_wear' then

        ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
          TriggerEvent('skinchanger:loadSkin', skin)
        end)

      end

      if data.current.value == 'wash_wear' then

        ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)

          if skin.sex == 0 then
            TriggerEvent('skinchanger:loadClothes', skin, jobSkin.skin_male)
          else
            TriggerEvent('skinchanger:loadClothes', skin, jobSkin.skin_female)
          end

        end)

      end

      CurrentAction     = 'wash_actions_menu'
      CurrentActionMsg  = _U('open_menu')
      CurrentActionData = {}

    end,
    function(data, menu)
      menu.close()
    end
  )

end

function OpenMobileWashActionsMenu()

  ESX.UI.Menu.CloseAll()

  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'mobile_wash_actions',
    {
      title    = 'Wash',
      elements = {
        {label = _U('billing'), value = 'billing'}
      }
    },
    function(data, menu)

      if data.current.value == 'billing' then

        ESX.UI.Menu.Open(
          'dialog', GetCurrentResourceName(), 'billing',
          {
            title = _U('invoice_amount')
          },
          function(data, menu)

            local amount = tonumber(data.value)

            if amount == nil then
              ESX.ShowNotification(_U('amount_invalid'))
            else

              menu.close()

              local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

              if closestPlayer == -1 or closestDistance > 3.0 then
                ESX.ShowNotification(_U('no_players_near'))
              else
                TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(closestPlayer), 'society_wash', 'Wash', amount)
              end

            end

          end,
          function(data, menu)
            menu.close()
          end
        )

      end

    end,
    function(data, menu)
      menu.close()
    end
  )

end

function OpenGetStocksMenu()

  ESX.TriggerServerCallback('esx_washjob:getStockItems', function(items)

    print(json.encode(items))

    local elements = {}

    for i=1, #items, 1 do
      table.insert(elements, {label = 'x' .. items[i].count .. ' ' .. items[i].label, value = items[i].name})
    end

    ESX.UI.Menu.Open(
      'default', GetCurrentResourceName(), 'stocks_menu',
      {
        title    = 'Wash Stock',
        elements = elements
      },
      function(data, menu)

        local itemName = data.current.value

        ESX.UI.Menu.Open(
          'dialog', GetCurrentResourceName(), 'stocks_menu_get_item_count',
          {
            title = _U('quantity')
          },
          function(data2, menu2)

            local count = tonumber(data2.value)

            if count == nil then
              ESX.ShowNotification(_U('quantity_invalid'))
            else
              menu2.close()
              menu.close()
              OpenGetStocksMenu()

              TriggerServerEvent('esx_washjob:getStockItem', itemName, count)
            end

          end,
          function(data2, menu2)
            menu2.close()
          end
        )

      end,
      function(data, menu)
        menu.close()
      end
    )

  end)

end

function OpenPutStocksMenu()

  ESX.TriggerServerCallback('esx_washjob:getPlayerInventory', function(inventory)

    local elements = {}

    for i=1, #inventory.items, 1 do

      local item = inventory.items[i]

      if item.count > 0 then
        table.insert(elements, {label = item.label .. ' x' .. item.count, type = 'item_standard', value = item.name})
      end

    end

    ESX.UI.Menu.Open(
      'default', GetCurrentResourceName(), 'stocks_menu',
      {
        title    = _U('inventory'),
        elements = elements
      },
      function(data, menu)

        local itemName = data.current.value

        ESX.UI.Menu.Open(
          'dialog', GetCurrentResourceName(), 'stocks_menu_put_item_count',
          {
            title = _U('quantity')
          },
          function(data2, menu2)

            local count = tonumber(data2.value)

            if count == nil then
              ESX.ShowNotification(_U('quantity_invalid'))
            else
              menu2.close()
              menu.close()
              OpenPutStocksMenu()

              TriggerServerEvent('esx_washjob:putStockItems', itemName, count)
            end

          end,
          function(data2, menu2)
            menu2.close()
          end
        )

      end,
      function(data, menu)
        menu.close()
      end
    )

  end)

end


RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
  PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
  PlayerData.job = job
end)

AddEventHandler('esx_washjob:hasEnteredMarker', function(zone)

  if zone == 'WashActions' then
    CurrentAction     = 'wash_actions_menu'
    CurrentActionMsg  = _U('press_to_open')
    CurrentActionData = {}
  end

  if zone == 'VehicleDeleter' then

    local playerPed = GetPlayerPed(-1)

    if IsPedInAnyVehicle(playerPed,  false) then
      CurrentAction     = 'delete_vehicle'
      CurrentActionMsg  = _U('store_veh')
      CurrentActionData = {}
    end

  end

end)

AddEventHandler('esx_washjob:hasExitedMarker', function(zone)
  ESX.UI.Menu.CloseAll()
  CurrentAction = nil
end)

RegisterNetEvent('esx_phone:loaded')
AddEventHandler('esx_phone:loaded', function(phoneNumber, contacts)

  local specialContact = {
    name       = 'Wash',
    number     = 'wash',
    base64Icon = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAAAAABWESUoAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfhChICAhptvKqkAAAB3ElEQVQ4y2P4DwMbBRTrrn59f6bfR8boKVz0PwOc1c7AwCzvbCXOzMCg9wqbgjWsDDCQ8Q+bgueGMHmBff+xKfg/ix2qIOkndgVf0xjB8jrX/2NX8P9NKtCBDKLb/+NS8LwYZAlPyqV/2BUctYZYwaAw5wc2BVsU4d7kKv+EqWCLNAMCsGR+QFdwWIkBGTDnf0VVcN8cIsFoAFXI1vEXWcH3FKhO/hMzoCyhzcgKlnFB9Ou2vr9dpgpRYfQAoeCZCUTM88H3399/XLGA8Ir+wBX0MYFFOHfej7q1MeLFWki8ih6DKXhhBNEieGmn7NWlTIVN0IhP/A1VsBIqwDz9+5bXGwQYmaDulLgAUfA3AeZ7qSnP/307kc8P47dDFLzUgQkwspjcu3v6ZxvMCPdvYAVnBaF83t4QwWsLRXbelIAKyN8DK9gOS0lCZ85ZX1souOu6GEzHMbCCzfDUGvfh0ZfbR382QqOdgX07WMFhHngkBu3++fVcGdyRnHvACh4gRaTUjXWCjHCe5HWwgt8JCAWsuf5Ike4N8cX/IxIMWAH3GmhI/pvOh02etfwnLLJ+L1bDlBdp/oyUom7V6HOh6JZLPPIHJU3+e7qhzFNLjJuJkZVX2ixx1tVfUAkA1V/8rvg0wdYAAAAldEVYdGRhdGU6Y3JlYXRlADIwMTctMTAtMThUMDI6MDI6MjYrMDI6MDBhJ5F/AAAAJXRFWHRkYXRlOm1vZGlmeQAyMDE3LTEwLTE4VDAyOjAyOjI2KzAyOjAwEHopwwAAAABJRU5ErkJggg==',
  }

  TriggerEvent('esx_phone:addSpecialContact', specialContact.name, specialContact.number, specialContact.base64Icon)

end)

-- Display markers
Citizen.CreateThread(function()
  while true do

    Wait(0)

    if PlayerData.job ~= nil and PlayerData.job.name == 'wash' then

      local coords = GetEntityCoords(GetPlayerPed(-1))

      for k,v in pairs(Config.Zones) do
        if(v.Type ~= -1 and GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true) < Config.DrawDistance) then
          DrawMarker(v.Type, v.Pos.x, v.Pos.y, v.Pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, v.Size.x, v.Size.y, v.Size.z, v.Color.r, v.Color.g, v.Color.b, 100, false, true, 2, false, false, false, false)
        end
      end

    end

  end
end)

-- Enter / Exit marker events
Citizen.CreateThread(function()
  while true do

    Wait(0)

    if PlayerData.job ~= nil and PlayerData.job.name == 'wash' then

      local coords      = GetEntityCoords(GetPlayerPed(-1))
      local isInMarker  = false
      local currentZone = nil

      for k,v in pairs(Config.Zones) do
        if(GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true) < v.Size.x) then
          isInMarker  = true
          currentZone = k
        end
      end

      if (isInMarker and not HasAlreadyEnteredMarker) or (isInMarker and LastZone ~= currentZone) then
        HasAlreadyEnteredMarker = true
        LastZone                = currentZone
        TriggerEvent('esx_washjob:hasEnteredMarker', currentZone)
      end

      if not isInMarker and HasAlreadyEnteredMarker then
        HasAlreadyEnteredMarker = false
        TriggerEvent('esx_washjob:hasExitedMarker', LastZone)
      end

    end

  end
end)

-- Key Controls
Citizen.CreateThread(function()
  while true do

    Citizen.Wait(0)

    if CurrentAction ~= nil then

      SetTextComponentFormat('STRING')
      AddTextComponentString(CurrentActionMsg)
      DisplayHelpTextFromStringLabel(0, 0, 1, -1)

      if IsControlPressed(0,  Keys['E']) and PlayerData.job ~= nil and PlayerData.job.name == 'wash' and (GetGameTimer() - GUI.Time) > 300 then

        if CurrentAction == 'wash_actions_menu' then
          OpenWashActionsMenu()
        end

        if CurrentAction == 'delete_vehicle' then

          local playerPed = GetPlayerPed(-1)

          if Config.EnableSocietyOwnedVehicles then
            local vehicleProps = ESX.Game.GetVehicleProperties(CurrentActionData.vehicle)
            TriggerServerEvent('esx_society:putVehicleInGarage', 'wash', vehicleProps)
          else
            if GetEntityModel(CurrentActionData.vehicle) == GetHashKey('wash') then
              if Config.MaxInService ~= -1 then
                TriggerServerEvent('esx_service:disableService', 'wash')
              end
            end
          end

          ESX.Game.DeleteVehicle(CurrentActionData.vehicle)

        end

        CurrentAction = nil
        GUI.Time      = GetGameTimer()

      end

    end

    if IsControlPressed(0,  Keys['F6']) and Config.EnablePlayerManagement and PlayerData.job ~= nil and PlayerData.job.name == 'wash' and (GetGameTimer() - GUI.Time) > 150 then
      OpenMobileWashActionsMenu()
      GUI.Time = GetGameTimer()
    end

    if IsControlPressed(0,  Keys['DELETE']) and (GetGameTimer() - GUI.Time) > 150 then

      if OnJob then
        StopWashJob()
      else

        if PlayerData.job ~= nil and PlayerData.job.name == 'wash' then

          local playerPed = GetPlayerPed(-1)

          if IsPedInAnyVehicle(playerPed,  false) then

            local vehicle = GetVehiclePedIsIn(playerPed,  false)

            if PlayerData.job.grade >= 3 then
              StartWashJob()
            else
              if GetEntityModel(vehicle) == GetHashKey('wash') then
                StartWashJob()
              else
                ESX.ShowNotification(_U('must_in_wash'))
              end
            end

          else

            if PlayerData.job.grade >= 3 then
              ESX.ShowNotification(_U('must_in_vehicle'))
            else
              ESX.ShowNotification(_U('must_in_wash'))
            end

          end

        end

      end

      GUI.Time = GetGameTimer()

    end

  end
end)
