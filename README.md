# esx_washjob

[REQUIEREMENTS]

esx_society => ``https://github.com/ESX-Org/esx_society``


UPDATE esx_society [server/main.lua] ``Wash instant``


```
      end

    end
  )

SetTimeout(1 * 1000, WashMoneyCRON)

end

SetTimeout(1 * 1000, WashMoneyCRON)

--TriggerEvent('cron:runAt', 3, 0, WashMoneyCRON)
```


``if you use this job, turn off whitening for all bosses, otherwise the job is useless !``

[DISABLE WHITENING FOR OTHER BOSSES, for all jobs]

```
esx_ambulancejob, mecanojob, bankerjob, realestateagentjob, taxijob, cardealer [client/main.lua]

if data.current.value == 'boss_actions' then
        TriggerEvent('esx_society:openBossMenu', 'cardealer', function(data, menu)
          menu.close()
        end, {wash = false})
```

```
esx_policejob, mafiajob, armyjob, statejob [client/main.lua]

if CurrentAction == 'menu_boss_actions' then

          ESX.UI.Menu.CloseAll()

          TriggerEvent('esx_society:openBossMenu', 'airlines', function(data, menu)

            menu.close()

            CurrentAction     = 'menu_boss_actions'
            CurrentActionMsg  = _U('open_bossmenu')
            CurrentActionData = {}

          end, {wash = false})
