(function()
  LUABroadcaster = {
    hashBroadcaster = {},
    addListener = function(self, broadcaster, event, funcString, scope)
      if not funcString or not broadcaster then
        print("LUABroadcaster ERROR: trying to add nil event listener to " .. tostring(broadcaster.tableName))
        return
      end
      broadcaster = tostring(broadcaster)
      if not self.hashBroadcaster[broadcaster] then
        self.hashBroadcaster[broadcaster] = {}
      end
      if not self.hashBroadcaster[broadcaster][event] then
        self.hashBroadcaster[broadcaster][event] = {}
      end
      self.hashBroadcaster[broadcaster][event][#self.hashBroadcaster[broadcaster][event] + 1] = {scope, funcString}
    end,
    removeListener = function(self, broadcaster, event, funcString, scope)
      broadcaster = tostring(broadcaster)
      if not self.hashBroadcaster[broadcaster] or not self.hashBroadcaster[broadcaster][event] then
        return
      end
      for k, v in pairs(self.hashBroadcaster[broadcaster][event]) do
        local a = v[1]
        local b = v[2]
        if (a and a == scope or not a) and b == funcString then
          self.hashBroadcaster[broadcaster][event][k] = nil
        end
      end
    end,
    dispatchEvent = function(self, broadcaster, event, ...)
      broadcaster = tostring(broadcaster)
      if not self.hashBroadcaster[broadcaster] or not self.hashBroadcaster[broadcaster][event] then
        return
      end
      for k, v in pairs(self.hashBroadcaster[broadcaster][event]) do
        local scope = v[1]
        local funcString = v[2]
        if funcString then
          if scope and scope[funcString] then
            scope[funcString](scope, unpack(arg))
          elseif _G[funcString] then
            _G[funcString](unpack(arg))
          end
        end
      end
    end,
    dumpListeners = function(self, broadcaster)
      broadcaster = tostring(broadcaster)
      if not self.hashBroadcaster[broadcaster] then
        print("0 listeners")
        return
      end
      for k, v in pairs(self.hashBroadcaster[broadcaster]) do
        for k2, v2 in pairs(self.hashBroadcaster[broadcaster][k]) do
          local scope = v2[1]
          local funcString = v2[2]
          if funcString then
            print("listener for " .. k .. ": " .. funcString)
          end
        end
      end
    end
  }
end)()
;(function()
  Utils = {}
  Utils.intervals = {}
  Utils.intervalId = 0
  Utils.numActiveIntervals = 0
  function Utils:SetInterval(interval, repeatCount, func, scope, ...)
    local id = self.intervalId + 1
    local hash = self.intervals
    self.numActiveIntervals = self.numActiveIntervals + 1
    hash[id] = {
      func = func,
      scope = scope,
      args = arg,
      lastUpdateTime = os.clock(),
      interval = interval,
      repeatCount = repeatCount,
      executeCount = 0,
      complete = false,
      flagForRemoval = false
    }
    self.intervalId = id
    self:ValidateIntervalUpdateList()
    return id
  end
  function Utils:SetTimeout(timeout, func, scope, ...)
    return self:SetInterval(timeout, 1, func, scope, ...)
  end
  function Utils:ValidateIntervalUpdateList()
    if self.numActiveIntervals > 0 then
      UpdateList.UtilsIntervalTimerProcessing = self
    else
      UpdateList.UtilsIntervalTimerProcessing = nil
    end
  end
  function Utils:ClearInterval(intervalId)
    local intervalObj = self.intervals[intervalId]
    if intervalObj then
      intervalObj.flagForRemoval = true
    end
  end
  function Utils:ClearTimeout(timeoutId)
    self:ClearInterval(timeoutId)
  end
  function Utils:RemoveInterval(intervalId)
    if self.intervals[intervalId] then
      self.numActiveIntervals = self.numActiveIntervals - 1
      self.intervals[intervalId] = nil
      self:ValidateIntervalUpdateList()
    end
  end
  function Utils:RemoveFlaggedIntervals()
    local k, obj
    local hash = self.intervals
    local keysToRemove = {}
    for k, obj in pairs(hash) do
      if obj and obj.flagForRemoval then
        table.insert(keysToRemove, k)
      end
    end
    for k in pairs(keysToRemove) do
      self:RemoveInterval(keysToRemove[k])
    end
  end
  function Utils:Update()
    self:ProcessIntervalTimers()
  end
  function Utils:ProcessIntervalTimers()
    local k, obj
    local curTime = os.clock()
    local hash = self.intervals
    self:RemoveFlaggedIntervals()
    for k, obj in pairs(hash) do
      local lastUpdateTime = obj.lastUpdateTime
      if curTime - lastUpdateTime >= obj.interval then
        local func = obj.func
        local scope = obj.scope
        if scope then
          func(scope, unpack(obj.args))
        else
          func(unpack(obj.args))
        end
        local repeatCount = obj.repeatCount
        local executeCount = obj.executeCount + 1
        obj.executeCount = executeCount
        obj.lastUpdateTime = curTime
        if repeatCount > 0 and repeatCount <= executeCount then
          self:ClearInterval(k)
        end
      end
    end
  end
  TableUtils = {}
  function TableUtils:Join(list, delimiter, listProperty)
    delimiter = delimiter or ","
    local len = #list
    if len == 0 then
      return ""
    end
    local str = ""
    for i = 1, len do
      local val = list[i]
      if listProperty ~= nil then
        val = val[listProperty]
      end
      str = str .. tostring(val)
      if i < len then
        str = str .. tostring(delimiter)
      end
    end
    return str
  end
  function TableUtils:Slice(list, i1, i2)
    local res = {}
    local n = #list
    i1 = i1 or 1
    i2 = i2 or n
    if i2 < 0 then
      i2 = n + i2 + 1
    elseif n < i2 then
      i2 = n
    end
    if i1 < 1 or n < i1 then
      return {}
    end
    local k = 1
    for i = i1, i2 do
      res[k] = list[i]
      k = k + 1
    end
    return res
  end
  StringUtils = {}
  function StringUtils:ReplaceInString(str, replaceParams)
    local i
    for i = 1, #replaceParams do
      str = string.gsub(str, "%%" .. tostring(i - 1), replaceParams[i])
    end
    return str
  end
  function StringUtils:Split(str, delim, maxNb)
    if string.find(str, delim) == nil then
      return {str}
    end
    if maxNb == nil or maxNb < 1 then
      maxNb = 0
    end
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gfind(str, pat) do
      nb = nb + 1
      result[nb] = part
      lastPos = pos
      if nb == maxNb then
        break
      end
    end
    if nb ~= maxNb then
      result[nb + 1] = string.sub(str, lastPos)
    end
    return result
  end
  TimerGroup = {
    TIMER_EVENT = "OnTimerEvent",
    ACTIVE_TIMER_CHANGE = "OnActiveTimerChange",
    id = nil,
    timers = {},
    activeTimer = nil,
    Create = function(id)
      local timerGroup = {}
      setmetatable(timerGroup, {__index = TimerGroup})
      timerGroup.id = id
      return timerGroup
    end,
    Add = function(self, timer)
      self.timers[timer.id] = timer
      LUABroadcaster:addListener(timer, Timer.EVENT_TIMER_START, "HandleTimerStart", self)
      LUABroadcaster:addListener(timer, Timer.EVENT_TIMER_STOP, "HandleTimerStop", self)
      LUABroadcaster:addListener(timer, Timer.EVENT_TIMER_CANCEL, "HandleTimerCancel", self)
      LUABroadcaster:addListener(timer, Timer.EVENT_TIMER_UPDATE, "HandleTimerUpdate", self)
      LUABroadcaster:addListener(timer, Timer.EVENT_TIMER_COMPLETE, "HandleTimerComplete", self)
    end,
    Remove = function(self, timer)
      LUABroadcaster:removeListener(timer, Timer.EVENT_TIMER_START, "HandleTimerStart", self)
      LUABroadcaster:removeListener(timer, Timer.EVENT_TIMER_STOP, "HandleTimerStop", self)
      LUABroadcaster:removeListener(timer, Timer.EVENT_TIMER_CANCEL, "HandleTimerCancel", self)
      LUABroadcaster:removeListener(timer, Timer.EVENT_TIMER_UPDATE, "HandleTimerUpdate", self)
      LUABroadcaster:removeListener(timer, Timer.EVENT_TIMER_COMPLETE, "HandleTimerComplete", self)
      self.timers[timer.id] = nil
    end,
    GetActiveTimer = function(self)
      return self.activeTimer
    end,
    SetActiveTimer = function(self, timer)
      local hasChanged = timer ~= self.activeTimer
      self.activeTimer = timer
      if hasChanged then
        LUABroadcaster:dispatchEvent(self, self.ACTIVE_TIMER_CHANGE, self.activeTimer)
      end
    end,
    HandleTimerStart = function(self, timer)
      if not timer then
        return
      end
      if self.activeTimer and timer ~= self.activeTimer then
        self.activeTimer:Stop()
      end
      self:SetActiveTimer(timer)
      self:DispatchEvent(Timer.EVENT_TIMER_START, timer)
    end,
    HasRunningTimer = function(self)
      local k, v
      local hasRunningTimer = false
      for k, v in pairs(self.timers) do
        if v and v:IsRunning() then
          hasRunningTimer = true
        end
      end
      return hasRunningTimer
    end,
    StopActiveTimer = function(self)
      if self.activeTimer and self.activeTimer:IsRunning() then
        self.activeTimer:Stop()
      end
    end,
    HandleTimerStop = function(self, timer)
      if not self:HasRunningTimer() then
        self:SetActiveTimer(nil)
      end
      self:DispatchEvent(Timer.EVENT_TIMER_STOP, timer)
    end,
    HandleTimerUpdate = function(self, timer)
      self:DispatchEvent(Timer.EVENT_TIMER_UPDATE, timer)
    end,
    HandleTimerComplete = function(self, timer)
      self:DispatchEvent(Timer.EVENT_TIMER_COMPLETE, timer)
    end,
    HandleTimerCancel = function(self, timer)
      self:DispatchEvent(Timer.EVENT_TIMER_CANCEL, timer)
    end,
    DispatchEvent = function(self, event, timer)
      LUABroadcaster:dispatchEvent(self, self.TIMER_EVENT, event, timer)
    end
  }
  Timer = {
    EVENT_TIMER_START = "OnTimerStart",
    EVENT_TIMER_COMPLETE = "OnTimerComplete",
    EVENT_TIMER_UPDATE = "OnTimerUpdate",
    EVENT_TIMER_STOP = "OnTimerStop",
    EVENT_TIMER_CANCEL = "OnTimerCancel",
    DEBUG = false,
    id = nil,
    duration = 0,
    startTime = nil,
    lastTickTime = nil,
    tickSoundId = nil,
    tickSoundInterval = 1000,
    lastUpdateTime = nil,
    updateInterval = 250,
    Create = function(id)
      local timer = {}
      setmetatable(timer, {__index = Timer})
      timer.id = id
      return timer
    end,
    Start = function(self, params)
      if self:IsRunning() then
        self:Stop()
      end
      if params.duration then
        self.duration = params.duration
      else
        return
      end
      if params.updateInterval then
        self.updateInterval = params.updateInterval
      end
      if params.tickSoundId then
        self.tickSoundId = params.tickSoundId
        if params.tickSoundInterval then
          self.tickSoundInterval = params.tickSoundInterval
        end
        self.lastTickTime = os.clock()
      end
      self.startTime = os.clock()
      self:OnTimerStart()
      self:OnTimerUpdate(true)
      UpdateList[self.id] = self
    end,
    Stop = function(self, isComplete)
      if not self:IsRunning() then
        return
      end
      self.startTime = nil
      self.lastTickTime = nil
      self.lastUpdateTime = nil
      UpdateList[self.id] = nil
      self:OnTimerUpdate(true)
      self:OnTimerStop()
      if isComplete then
        self:OnTimerComplete()
      else
        self:OnTimerCancel()
      end
    end,
    IsRunning = function(self)
      return self.startTime ~= nil
    end,
    TimeLeft = function(self)
      if self:IsRunning() then
        return self.duration - (os.clock() - self.startTime)
      end
      return 0
    end,
    ProgressPercent = function(self)
      if self:IsRunning() then
        return (self.duration - self:TimeLeft()) / self.duration * 100
      end
      return 0
    end,
    HasTickSound = function(self)
      return self.tickSoundId ~= nil and self.tickSoundInterval ~= nil
    end,
    PlayTickSound = function(self)
      if self:HasTickSound() then
        SoundHandler:PlaySoundById(self.tickSoundId)
      end
    end,
    Update = function(self)
      if self:IsRunning() and self:TimeLeft() <= 0 then
        self:Stop(true)
      else
        if self:HasTickSound() then
          local curTime = os.clock()
          if curTime - self.lastTickTime >= self.tickSoundInterval then
            self:PlayTickSound()
            self.lastTickTime = curTime
          end
        end
        self:OnTimerUpdate()
      end
    end,
    ToString = function(self)
      return "[TIMER " .. tostring(self.id) .. "]"
    end,
    OnTimerStart = function(self)
      LUABroadcaster:dispatchEvent(self, self.EVENT_TIMER_START, self)
      if self.DEBUG then
        print(self:ToString() .. " Start")
      end
    end,
    OnTimerStop = function(self)
      LUABroadcaster:dispatchEvent(self, self.EVENT_TIMER_STOP, self)
      if self.DEBUG then
        print(self:ToString() .. " Stop")
      end
    end,
    OnTimerCancel = function(self)
      LUABroadcaster:dispatchEvent(self, self.EVENT_TIMER_CANCEL, self)
      if self.DEBUG then
        print(self:ToString() .. " Cancel")
      end
    end,
    OnTimerComplete = function(self)
      LUABroadcaster:dispatchEvent(self, self.EVENT_TIMER_COMPLETE, self)
      if self.DEBUG then
        print(self:ToString() .. " Complete")
      end
    end,
    OnTimerUpdate = function(self, force)
      local curTime = os.clock()
      if force or not self.lastUpdateTime or curTime - self.lastUpdateTime >= self.updateInterval then
        LUABroadcaster:dispatchEvent(self, self.EVENT_TIMER_UPDATE, self)
        self.lastUpdateTime = curTime
        if self.DEBUG then
          print(self:ToString() .. " Update, TimeLeft: " .. tostring(self:TimeLeft()))
        end
      end
    end
  }
end)()
;(function()
  PS2ProfileTypes = {
    NONE = 0,
    INFILTRATOR = 1,
    LIGHT_ASSAULT = 3,
    COMBAT_MEDIC = 4,
    ENGINEER = 5,
    HEAVY_ASSAULT = 6,
    MAX = 7
  }
  PS2Zones = {
    INDAR = {
      id = 2,
      name = Ui.GetStringById(5)
    },
    SEARHUS = {
      id = 3,
      name = Ui.GetStringById(617)
    },
    HOSSIN = {
      id = 4,
      name = Ui.GetStringById(558595)
    },
    AMERISH = {
      id = 6,
      name = Ui.GetStringById(4)
    },
    ESAMIR = {
      id = 8,
      name = Ui.GetStringById(6)
    },
    TUTORIAL = {
      id = 95,
      name = Ui.GetStringById(557875)
    },
    VR_NC = {
      id = 96,
      name = Ui.GetStringById(557721)
    },
    VR_TR = {
      id = 97,
      name = Ui.GetStringById(557721)
    },
    VR_VS = {
      id = 98,
      name = Ui.GetStringById(557721)
    },
    zoneHashById = nil,
    GetCurrentZoneId = function(self)
      return Map.GetCurrentZoneId()
    end,
    GetCurrentZone = function(self)
      return self:GetZoneById(self:GetCurrentZoneId())
    end,
    GetZoneById = function(self, id)
      return self.zoneHashById[id]
    end,
    IsInVrZone = function(self)
      return Loadouts.IsVrZone() == "1"
    end,
    IsInTutorialZone = function(self)
      return self:GetCurrentZone() == PS2Zones.TUTORIAL
    end,
    Initialize = function(self)
      local hash = {}
      local i
      for i = 1, #self.ALL do
        hash[self.ALL[i].id] = self.ALL[i]
      end
      self.zoneHashById = hash
    end
  }
  PS2Zones.ALL = {
    PS2Zones.INDAR,
    PS2Zones.SEARHUS,
    PS2Zones.HOSSIN,
    PS2Zones.AMERISH,
    PS2Zones.ESAMIR,
    PS2Zones.TUTORIAL,
    PS2Zones.VR_NC,
    PS2Zones.VR_TR,
    PS2Zones.VR_VS
  }
  PS2Zones:Initialize()
  PS2Factions = {
    NONE = {
      id = 0,
      name = Ui.GetString("UI.None"),
      iconId = 0,
      defaultHudTintColor = "0"
    },
    VS = {
      id = 1,
      name = Ui.GetString("UI.FactionVS"),
      iconId = 21,
      defaultHudTintColor = "4460130"
    },
    NC = {
      id = 2,
      name = Ui.GetString("UI.FactionNC"),
      iconId = 19,
      defaultHudTintColor = "19328"
    },
    TR = {
      id = 3,
      name = Ui.GetString("UI.FactionTR"),
      iconId = 20,
      defaultHudTintColor = "10357519"
    }
  }
  PS2Factions.ALL = {
    PS2Factions.NONE,
    PS2Factions.VS,
    PS2Factions.NC,
    PS2Factions.TR
  }
  function PS2Factions:GetFactionInfoById(factionId)
    if factionId == 1 then
      return self.VS
    elseif factionId == 2 then
      return self.NC
    elseif factionId == 3 then
      return self.TR
    end
    return nil
  end
  UpdateList = {}
  function OnUpdate()
    for x in pairs(UpdateList) do
      UpdateList[x]:Update()
    end
  end
end)()
;(function()
  BusinessEnvironment = {
    permissions = {},
    permissionsHashById = {},
    dsName = "BaseClient.BusinessEnvironment",
    EnvironmentIds = {
      LOCAL = "local",
      MAIN = "main",
      QA = "qa",
      TEST = "test",
      STAGE = "stage",
      LIVE = "live",
      THE_NINE = "the9",
      INNOVA = "innova"
    },
    PublisherIds = {STATION = "STATION", PSG = "PSG"},
    GetCurrentEnvironment = function(self)
      return DataSourceConnection:GetDataByColumnName(self.dsName, 0, "Environment")
    end,
    GetVoiceChatEnabled = function(self)
      return DataSourceConnection:GetDataByColumnName(self.dsName, 0, "AllowVoiceChat") == "1"
    end,
    GetVideoEnabled = function(self)
      return DataSourceConnection:GetDataByColumnName(self.dsName, 0, "AllowVideo") == "1"
    end,
    GetSocialCommunicationsEnabled = function(self)
      return DataSourceConnection:GetDataByColumnName(self.dsName, 0, "AllowSocialCommunications") == "1"
    end
  }
end)()
;(function()
  Constants = {}
  Constants.FactionColors = {
    "#C27FFF",
    "#79A5FF",
    "#FF574B"
  }
  Constants.VoiceRoomType = {
    ECHO = "Echo",
    PROXIMITY = "Proximity",
    FACTION = "Faction",
    GROUP = "Group",
    GROUP_LEADER = "GroupLeader",
    RAID = "Raid",
    GUILD = "Guild",
    CUSTOM = "Custom"
  }
  Constants.VoiceRoomTypes = {
    Constants.VoiceRoomType.ECHO,
    Constants.VoiceRoomType.PROXIMITY,
    Constants.VoiceRoomType.FACTION,
    Constants.VoiceRoomType.GROUP,
    Constants.VoiceRoomType.GROUP_LEADER,
    Constants.VoiceRoomType.RAID,
    Constants.VoiceRoomType.GUILD,
    Constants.VoiceRoomType.CUSTOM
  }
  Constants.HitTestTypes = {
    BUTTON_EVENTS = "ButtonEvents",
    SHAPES_NO_INVIS = "ShapesNoInvisible",
    SHAPES = "Shapes",
    BOUNDS = "Bounds"
  }
end)()
;(function()
  function GuiOnSave()
  end
  function GuiOnInit()
    guiInitModule("Main")
    clear()
    Startup()
  end
  function Startup()
    DataSourceEvents:Initialize()
    LUABroadcaster:dispatchEvent(UiEventDispatcher, ClientEvents.CLIENT_INIT)
  end
  function GuiOnShutdown()
    if DesignTools_OnShutdown then
      DesignTools_OnShutdown()
    end
    collectgarbage()
  end
  if systemDoFile == nil then
    systemDoFile = dofile
    function dofileInternalOnlyCommand(theFile)
      print("/dofile " .. Client.PathScripts .. theFile)
      print("---------------------------------------")
      print("Include new *.lua file in scripts.txt.")
      systemDoFile(Client.PathScripts .. theFile)
    end
  end
end)()
;(function()
  SoundHandler = {}
  SoundHandler.EVENT_VOICE_STARTED = "onVoiceStarted"
  SoundHandler.EVENT_VOICE_FINISHED = "onVoiceFinished"
  SoundHandler.sounds = {
    UI_Hunger_Warning = 836466590,
    UI_Health_Warning = 1100101729,
    UI_Thirst_Warning = 544538495,
    UI_Window_Open = 4135004417,
    UI_Window_Close = 4244658871,
    UI_Window_Socket = 3094306338,
    UI_Window_RightClick = 1851686588,
    UI_Radial_Use = 923455810,
    UI_Radial_Drop = 2899971506,
    UI_Button_Press = 2567115941,
    UI_Error = 3863669763,
    PLAY_OPENING_SCREEN = 1157274753,
    PLAY_LOADING_MUSIC = 361969910,
    PLAY_SPAWN = 1012143543,
    STOP_OPENING_SCREEN = 3312155467,
    STOP_LOADING_MUSIC = 1120854248,
    STOP_SPAWN = 3585121581
  }
  SoundHandler.music = {}
  SoundHandler.UiSoundsEnabled = true
  function SoundHandler:GetSoundIdByName(soundName)
    if not self.sounds[soundName] then
      return nil
    end
    return self.sounds[soundName]
  end
  function SoundHandler:PlaySoundById(soundDefId, volume)
    if not self.UiSoundsEnabled then
      return nil
    end
    if not soundDefId then
      return nil
    end
    if not tonumber(volume) then
      volume = 1
    end
    Ui.PlayUiSound(soundDefId)
  end
  function SoundHandler:PlaySoundByName(soundName, volume)
    self:PlaySoundById(SoundHandler:GetSoundIdByName(soundName), volume)
  end
  function SoundHandler:PlayErrorSound()
    self:PlaySoundById(SoundHandler.sounds.UI_Error)
  end
  SoundManager = {}
  function SoundManager:GetSoundByName()
  end
  function SoundManager:PlaySoundFromDefinition()
  end
  function SoundManager:PlaySoundByName()
  end
end)()
;(function()
  Client.ContextDepth = 0
  Context = {}
  Context.mList = {}
  Context.mHash = {}
  Context.mLockHash = {}
  Context.isLocked = false
  Context.EVENT_LOCK_CHANGE = "OnContextLockChange"
  function Context:Push(theScope, escapeFunction, identifier, ignoreTopFocus)
  end
  function Context:Lock(identifier)
  end
  function Context:Unlock(identifier)
  end
  function Context:IsElementLocked(identifier)
  end
  function Context:Pop(identifier)
  end
  function Context:ValidateMouseCursor()
  end
  function Context:GetElementByIdentifier(identifier)
  end
  function Context:HasElement(identifier)
  end
  function Context:GetIndexByIdentifier(identifier)
    return -1
  end
  function Context:GetTopElement()
    return nil
  end
  function Context:SetFocusToTopWindow()
  end
  function Context:Clear(force)
  end
  function Context:ExecuteAndPop(force, identifier)
    return nil
  end
  function Context:CallQuit(force, identifier)
  end
  function Context:Show()
  end
end)()
;(function()
  DataSources = {
    DS_GROUP_MEMBER_DATA = "BaseClient.GroupMemberData",
    DS_FACILITY_GOALS = "BaseClient.FacilityGoals",
    DS_CLOSEST_INTERACTION = "BaseClient.ClosestInteractionTargetData",
    DS_PLAYER_INFO = "Player.Info",
    DS_GUILDS = "BaseClient.Guilds",
    DS_RAIDS = "BaseClient.RaidDataSource",
    DS_GROUPS = "BaseClient.GroupData",
    DS_CONTAINER = "Loadouts.ProxiedCharacterLoadoutSlotContainerDataSource"
  }
  BroadcastingDataSources = {
    {
      name = DataSources.DS_GROUP_MEMBER_DATA,
      onUpdate = false,
      onDataChanged = false
    },
    {
      name = DataSources.DS_FACILITY_GOALS,
      onUpdate = true,
      onDataChanged = false
    },
    {
      name = DataSources.DS_CLOSEST_INTERACTION,
      onUpdate = true,
      onDataChanged = false
    },
    {
      name = DataSources.DS_PLAYER_INFO,
      onUpdate = true,
      onDataChanged = true
    },
    {
      name = DataSources.DS_GUILDS,
      onUpdate = true,
      onDataChanged = false
    },
    {
      name = DataSources.DS_RAIDS,
      onUpdate = true,
      onDataChanged = false
    },
    {
      name = DataSources.DS_GROUPS,
      onUpdate = true,
      onDataChanged = false
    },
    {
      name = DataSources.DS_CONTAINER,
      onUpdate = true,
      onDataChanged = true
    }
  }
  DataSourceEvents = {}
  function DataSourceEvents:getUpdateEvent(dsName)
    return dsName .. ".OnDataUpdate"
  end
  function DataSourceEvents:getDataChangedEvent(dsName)
    return dsName .. ".OnDataChanged"
  end
  function DataSourceEvents:Initialize()
    local i
    local len = #BroadcastingDataSources
    for i = 1, len do
      do
        local config = BroadcastingDataSources[i]
        local dsName = config.name
        local ds = DsTable.Find(tostring(dsName))
        local addUpdateListener = config.onUpdate
        local addDataChangedListener = config.onDataChanged
        if ds then
          local updateCallback = string.gsub(tostring(dsName), "%p", "_")
          local changedCallback = updateCallback
          local enableScriptEvents = false
          if addUpdateListener then
            updateCallback = updateCallback .. "_OnDataUpdate"
            enableScriptEvents = true
            _G[updateCallback] = function()
              LUABroadcaster:dispatchEvent(DataSourceEvents, self:getUpdateEvent(dsName))
            end
          end
          if addDataChangedListener then
            changedCallback = changedCallback .. "_OnDataChanged"
            enableScriptEvents = true
            _G[changedCallback] = function(row, col, val)
              LUABroadcaster:dispatchEvent(DataSourceEvents, self:getDataChangedEvent(dsName), row, col, val)
            end
          end
          if enableScriptEvents then
            ds:EnableScriptEvents()
          end
        end
      end
    end
  end
  function strjoin(delimiter, list)
    local len = 0
    for k, v in pairs(list) do
      len = len + 1
    end
    if len == 0 then
      return ""
    end
    local string = list[0]
    for i = 1, len - 1 do
      string = string .. delimiter .. list[i]
    end
    return string
  end
end)()
;(function()
  ClientEvents = {
    CLIENT_INIT = "onClientInit",
    CLIENT_GUI_PRELOAD = "onClientGuiPreloadRequest",
    CLIENT_RESIZE = "onResize"
  }
  GameStates = {}
  GameStates.ALIVE_INFANTRY_HUD = 0
  GameStates.KILL_CAM = 1
  GameStates.ZONE_LOADING = 2
  GameStates.SPAWN_SELECTION = 3
  GameStates.SETTINGS_MENU = 4
  GameStates.INVENTORY = 5
  GameStates.MARKETPLACE = 7
  GameStates.PERMISSION_LOCK = 8
  GameStates.ESCAPE_MENU = 9
  GameStates.BROWSER = 10
  GameStates.COUNT = 11
  EscapeStack = {}
  CloseWithEscapeStates = {}
  CloseWithEscapeStates[GameStates.SETTINGS_MENU] = true
  CloseWithEscapeStates[GameStates.INVENTORY] = true
  CloseWithEscapeStates[GameStates.MARKETPLACE] = true
  CloseWithEscapeStates[GameStates.ESCAPE_MENU] = true
  CloseWithEscapeStates[GameStates.BROWSER] = true
  GameEvents = {}
  GameEvents.EVENT_GAME_STATE_CHANGE = "OnGameStateChange"
  GameEvents.EVENT_PLAYER_EQUIPMENT_TERMINAL_INTERACTION = "OnPlayerEquipmentTerminalInteraction"
  GameEvents.EVENT_PLAYER_RESPAWN_REQUEST_RESPONSE = "OnPlayerRespawnRequestResponse"
  GameEvents.EVENT_WARPGATE_TERMINAL_INTERACTION = "OnWarpgateTerminalInteraction"
  GameEvents.EVENT_WORLD_READY_COMPLETE = "OnWorldReadyComplete"
  GameEvents.EVENT_PLAYER_LOGOUT = "OnPlayerLogout"
  GameEvents.lockTimer = 0
  GameEvents.isLockOwner = false
  GameEvents.hasLoadedWorldAfterLogin = false
  GameEvents.numAuthenticatedLogins = 0
  GameEvents.hasGameScene = false
  GameEvents.hasDefaulted = false
  function GameEvents:SetCurrentGameState(state)
    print("Setting current game state: " .. tostring(state))
    if GameStates[state] == true then
      GameStates[state] = false
    else
      GameStates[state] = true
    end
  end
  function GameEvents:HideAll()
    for i = GameStates.ZONE_LOADING, GameStates.COUNT - 1 do
      GameEvents:HideState(i)
    end
  end
  function GameEvents:UnloadAll()
    GameEvents:HideAll()
    HudHandler:Hide()
    Console:Hide()
  end
  function GameEvents:RestoreAll()
    for i = GameStates.ZONE_LOADING, GameStates.COUNT - 1 do
      if GameStates[i] == true then
        GameEvents:ShowState(i)
      else
        GameEvents:HideState(i)
      end
    end
  end
  function GameEvents:HideState(state)
    GameStates[state] = false
    if CloseWithEscapeStates[state] then
      for i, v in ipairs(EscapeStack) do
        if v == state then
          table.remove(EscapeStack, i)
          break
        end
      end
    end
    GameEvents:ValidateMouseState()
    GameEvents:ValidateFocus()
    if state == GameStates.KILL_CAM then
    elseif state == GameStates.ZONE_LOADING then
      LoadingScreenHandler:Hide()
    elseif state == GameStates.SPAWN_SELECTION then
      print("GameEvents:HideState No Spawn Selection")
    elseif state == GameStates.SETTINGS_MENU then
      HudHandler:HideSettings()
    elseif state == GameStates.ESCAPE_MENU then
      HudHandler:HideEscapeMenu()
    elseif state == GameStates.INVENTORY then
      HudHandler:HideInventory()
    elseif state == GameStates.MARKETPLACE then
      MarketplaceHandler:Hide()
    elseif state == GameStates.PERMISSION_LOCK then
      HudHandler:HideLockWindow()
    elseif state == GameStates.BROWSER then
      InGameBrowserHandler:Hide()
    end
  end
  function GameEvents:ShowState(state)
    GameStates[state] = true
    if CloseWithEscapeStates[state] then
      table.insert(EscapeStack, state)
    end
    GameEvents:ValidateMouseState()
    GameEvents:ValidateFocus()
    if state == GameStates.KILL_CAM then
    elseif state == GameStates.ZONE_LOADING then
      LoadingScreenHandler:Show()
    elseif state == GameStates.SPAWN_SELECTION then
      print("GameEvents:ShowState No Spawn Selection")
    elseif state == GameStates.SETTINGS_MENU then
      HudHandler:ShowSettings()
    elseif state == GameStates.ESCAPE_MENU then
      HudHandler:ShowEscapeMenu()
    elseif state == GameStates.INVENTORY then
      HudHandler:ShowInventory()
      HudHandler:SetFocus()
    elseif state == GameStates.MARKETPLACE then
      MarketplaceHandler:Show()
    elseif state == GameStates.BROWSER then
      InGameBrowserHandler:Show()
    elseif state == GameStates.PERMISSION_LOCK then
      HudHandler:ShowLockWindow(GameEvents.isLockOwner, GameEvents.lockTimer)
      HudHandler:SetFocus()
    end
  end
  function GameEvents:ShowEscapeMenu()
    GameEvents:ShowState(GameStates.ESCAPE_MENU)
  end
  function GameEvents:HideEscapeMenu()
    GameEvents:HideState(GameStates.ESCAPE_MENU)
  end
  function GameEvents:ShowSettings()
    GameEvents:ShowState(GameStates.SETTINGS_MENU)
  end
  function GameEvents:HideSettings()
    GameEvents:HideState(GameStates.SETTINGS_MENU)
    GameEvents:ShowState(GameStates.ESCAPE_MENU)
  end
  function GameEvents:ShowBrowser()
    GameEvents:ShowState(GameStates.BROWSER)
    local url = "http://h1z1.com"
    InGameBrowserHandler:Show(url)
  end
  function GameEvents:HideBrowser()
    GameEvents:HideState(GameStates.BROWSER)
  end
  function GameEvents:HideInventory()
    GameEvents:HideState(GameStates.INVENTORY)
  end
  function GameEvents:OnWaitingForWorldReady(isZoning)
    print("Waiting For World Ready")
  end
  function GameEvents:OnWaitingForWorldReadyComplete(isZoning)
    local isFirstWorldLoadAfterLogin = false
    if not GameEvents.hasLoadedWorldAfterLogin then
      isFirstWorldLoadAfterLogin = true
      self.numAuthenticatedLogins = self.numAuthenticatedLogins + 1
      self.hasLoadedWorldAfterLogin = true
    end
    LUABroadcaster:dispatchEvent(GameEvents, GameEvents.EVENT_WORLD_READY_COMPLETE, isFirstWorldLoadAfterLogin)
  end
  function GameEvents:OnPlayerBeginZoning(geo, zonetype, isSameGeo, isSuccess)
    print("On Player Begin Zoning")
  end
  function GameEvents:OnPlayerZoning(geo, zonetype, isSameGeo, isSuccess)
    print("On Player Zoning")
  end
  function GameEvents:OnLoadingScreenShown(result)
    print("On Loading Screen Shown")
    LoadingScreenHandler:Show()
  end
  function GameEvents:OnLoadingScreenDropped()
    print("On Loading Screen Dropped")
    GameEvents:SetAliveInfantryGameState()
  end
  function GameEvents:OnPlayerLogout()
    print("On Logout")
  end
  function GameEvents:OnDisconnected(msg)
    print("On Disconnect")
  end
  function GameEvents:ValidateMouseState()
    if GameStates[GameStates.SETTINGS_MENU] or GameStates[GameStates.ESCAPE_MENU] or GameStates[GameStates.INVENTORY] or GameStates[GameStates.CONTAINER] or GameStates[GameStates.MARKETPLACE] or GameStates[GameStates.KILL_CAM] or GameStates[GameStates.PERMISSION_LOCK] or GameStates[GameStates.BROWSER] or CharacterSelectHandler.isShown or Console.isShown then
      Ui.ShowCursor()
    else
      Ui.HideCursor()
    end
  end
  function GameEvents:ValidateFocus()
    if GameStates[GameStates.MARKETPLACE] then
      MarketplaceHandler:SetFocus()
    elseif GameStates[GameStates.KILL_CAM] then
      DeathHandler:SetFocus()
    elseif GameStates[GameStates.INVENTORY] or GameStates[GameStates.SETTINGS_MENU] or GameStates[GameStates.ESCAPE_MENU] or GameStates[GameStates.BROWSER] or GameStates[GameStates.PERMISSION_LOCK] then
      HudHandler:SetFocus()
    else
      Window.SetFocus()
    end
  end
  function GameEvents:OnEscape(focusedCtrlName)
    if CharacterSelectHandler.isShown == true or GameStates[GameStates.PERMISSION_LOCK] then
      GameEvents:ValidateMouseState()
      return
    end
    local focusedHandler = UiHandlerBase:GetHandlerBySwfName(focusedCtrlName)
    if table.getn(EscapeStack) > 0 then
      local escState = table.remove(EscapeStack)
      if escState == GameStates.SETTINGS_MENU then
        HudHandler:DispatchGameEvent("EscapeKeyPressed")
      else
        GameEvents:HideState(escState)
      end
      if table.getn(EscapeStack) > 0 then
        GameEvents:ShowState(table.remove(EscapeStack))
      end
    elseif focusedHandler == HudHandler then
    else
      GameEvents:HideAll()
      GameEvents:ShowState(GameStates.ESCAPE_MENU)
    end
    GameEvents:ValidateMouseState()
    GameEvents:ValidateFocus()
  end
  function GameEvents:NotHudState()
    local ret = false
    for i = GameStates.KILL_CAM, table.getn(GameStates) do
      if GameStates[i] == true then
        ret = true
      end
    end
    return ret
  end
  function GameEvents:OnInventoryToggle()
    if GameStates[GameStates.SETTINGS] == true or GameStates[GameStates.MARKETPLACE] == true then
      return
    end
    if GameStates[GameStates.INVENTORY] == true then
      GameEvents:HideState(GameStates.INVENTORY)
    else
      GameEvents:ShowState(GameStates.INVENTORY)
    end
  end
  function GameEvents:HandleBeginCharacterAccess(isVehicle)
    if isVehicle then
      return
    end
    GameEvents:ShowState(GameStates.INVENTORY)
    HudHandler:ShowContainer()
  end
  function GameEvents:HandleEndCharacterAccess()
    GameEvents:HideState(GameStates.INVENTORY)
  end
  function GameEvents:OnMarketplaceToggle()
    if GameStates[GameStates.SETTINGS] == true then
      return
    end
    if GameStates[GameStates.MARKETPLACE] == true then
      GameEvents:HideState(GameStates.MARKETPLACE)
    else
      GameEvents:ShowState(GameStates.MARKETPLACE)
    end
  end
  function GameEvents:OnSetPermissionLock(timeout)
    GameEvents.isLockOwner = true
    if timeout ~= nil then
      GameEvents.lockTimer = timeout
    else
      GameEvents.lockTimer = 60000
    end
    GameEvents:ShowState(GameStates.PERMISSION_LOCK)
  end
  function GameEvents:OnAccessPermissionLock(timeout)
    GameEvents.isLockOwner = false
    if timeout ~= nil then
      GameEvents.lockTimer = timeout
    else
      GameEvents.lockTimer = 60000
    end
    GameEvents:ShowState(GameStates.PERMISSION_LOCK)
  end
  function GameEvents:OnPermissionLockComplete()
    GameEvents:HideState(GameStates.PERMISSION_LOCK)
    GameEvents.lockTimer = 0
    GameEvents.isLockOwner = false
  end
  function GameEvents:OnMapToggle(focusedCtrlName)
    print("On Map")
  end
  function GameEvents:OnNameValidationResponse(guid, success, errorCode)
    print("Deprecated Validation Response")
  end
  function GameEvents:OnRedeployToggle()
    print("Deprecated Redeploy")
  end
  function GameEvents:OnInstantActionToggle()
    print("Deprecated Instant Action Toggle")
  end
  function GameEvents:OnPlayerRevived()
    print("Deprecated Player Revival!")
  end
  function GameEvents:SetAliveInfantryGameState()
    self:SetCurrentGameState(GameStates.ALIVE_INFANTRY_HUD)
    GameStates[GameStates.KILL_CAM] = false
    LoadingScreenHandler:Hide()
    DeathHandler:Hide()
    HudHandler:Show()
  end
  function GameEvents:SetSettingsMenuGameState()
    GameEvents:ShowState(GameStates.SETTINGS_MENU)
  end
  function GameEvents:SetKillCamGameState(isRespawnAllowed)
    GameStates[GameStates.KILL_CAM] = true
    GameEvents:HideAll()
    HudHandler:Hide()
    DeathHandler:Show(isRespawnAllowed)
  end
  function GameEvents:SetDefaultGameState()
    GameEvents:HideAll()
    GameEvents:SetAliveInfantryGameState()
  end
  function GameEvents:SetSpawnSelectionGameState(hasScene)
  end
end)()
;(function()
  UiEventDispatcher = {}
  HUD = {}
  function HUD:onResize()
    LUABroadcaster:dispatchEvent(UiEventDispatcher, ClientEvents.CLIENT_RESIZE)
  end
  UiZLayers = {
    MINIGAME = 105,
    VEHICLE_HUD = 109,
    RETICLE = 110,
    HUD = 112,
    WINDOW = 114,
    CLICK_GOBBLER = 118,
    NAVIGATION_WINDOW_BG = 119,
    MODAL_WINDOW = 140,
    NAVIGATION_WINDOW = 150,
    CONTEXT_MENU = 160,
    TUTORIAL_WINDOW = 161,
    HELP_WINDOW = 162,
    QUIZ_WINDOW = 163,
    BUNDLE_PURCHASE_WINDOW = 165,
    REPORT_PLAYER_WINDOW = 166,
    STATION_CASH_PURCHASE_WINDOW = 167,
    INGAME_BROWSER = 168,
    SERVER_QUEUE_WINDOW = 169,
    TOOLTIP = 170,
    TUTORIAL = 172,
    NOTIFICATION = 175,
    TAB_SCREEN = 178,
    TOOL = 180,
    LOADING_SCREEN = 190
  }
  UiHandlerBase = {
    swfName = "default",
    wndName = "default",
    swfNameToHandlerHash = {},
    swfFile = "",
    isShown = false,
    tableName = nil,
    unloadOnHide = true,
    isDebugOn = false,
    hitTestMethod = Constants.HitTestTypes.BUTTON_EVENTS,
    ZLayer = UiZLayers.WINDOW,
    panelSoundsEnabled = false,
    isAS3 = false,
    isModal = false,
    loadOnInit = false,
    isInteractive = true,
    pushToContext = false,
    clearContextOnShow = false,
    lockContextOnShow = false,
    enableLogging = false,
    allowInvokesWhenHidden = true,
    events = {
      VISIBILITY_UPDATE = "OnVisibilityUpdate"
    }
  }
  function inheritsFrom(baseClass)
    local new_class = {}
    local class_mt = {__index = new_class}
    function new_class:create()
      local newinst = {}
      setmetatable(newinst, class_mt)
      return newinst
    end
    if nil ~= baseClass then
      setmetatable(new_class, {__index = baseClass})
    end
    function new_class:class()
      return new_class
    end
    function new_class:superClass()
      return baseClass
    end
    function new_class:instanceof(theClass)
      local b_isa = false
      local cur_class = new_class
      while nil ~= cur_class and false == b_isa do
        if cur_class == theClass then
          b_isa = true
        else
          cur_class = cur_class:superClass()
        end
      end
      return b_isa
    end
    LUABroadcaster:addListener(UiEventDispatcher, ClientEvents.CLIENT_RESIZE, "OnResize", new_class)
    LUABroadcaster:addListener(UiEventDispatcher, ClientEvents.CLIENT_INIT, "OnInit", new_class)
    LUABroadcaster:addListener(GameEvents, GameEvents.EVENT_WORLD_READY_COMPLETE, "OnClientLoadComplete", new_class)
    return new_class
  end
  function UiHandlerBase:SetUiProperties(wndName, swfName, swfFile, tableName, zLayer)
    Window.Create(wndName, swfName, swfFile, tableName)
    self.wndName = wndName
    self.swfName = wndName .. "." .. swfName
    self.swfFile = swfFile
    self.tableName = tableName
    self.swfNameToHandlerHash[self.swfName] = self
    local diffSwfName = string.gsub(self.swfName, "%p", "_")
    if self.OnUserEvent then
      _G[diffSwfName .. "_OnUserEvent"] = function(a, ...)
        self:OnUserEvent(a, ...)
      end
    end
    if self.OnSwfFocus then
      _G[diffSwfName .. "_OnFocus"] = function(isFocused)
        self:OnSwfFocus(isFocused)
      end
    end
    if zLayer then
      self.ZLayer = zLayer
      local wnd = self:getWindow()
      if wnd then
        wnd:SetProperty("ZLayer", zLayer)
      end
    end
  end
  function UiHandlerBase:GetHandlerBySwfName(swfName)
    return self.swfNameToHandlerHash[swfName]
  end
  function UiHandlerBase:Show()
    if self.isShown then
      return
    end
    self.isShown = true
    local wnd = self:getWindow()
    if wnd then
      wnd:SetProperty("ZLayer", self.ZLayer)
      local isInteractive = "0"
      if self.isInteractive then
        isInteractive = "1"
      end
      wnd:SetProperty("IsInteractive", isInteractive)
      if self.clearContextOnShow then
        Context:Clear()
      end
      if self.lockContextOnShow then
        Context:Lock(self.tableName)
      end
      if self.pushToContext then
        Context:Push(self, self.OnContextPop, self.tableName)
      end
      if self.isModal then
        wnd:ShowModal()
      else
        wnd:Show()
      end
      wnd:SetHitTestType(self.hitTestMethod)
      self:ASInvoke("setWindowData", self.tableName)
      self:ASInvoke("onSwfShow")
      self:OnResize()
      if self.panelSoundsEnabled then
        SoundHandler:PlaySoundById(SoundHandler.sounds.UI_Pane_Open, 1)
      end
      LUABroadcaster:dispatchEvent(self, self.events.VISIBILITY_UPDATE, true)
    end
    if self.enableLogging then
      self:LogShow()
    end
  end
  function UiHandlerBase:OnContextPop()
    self:Hide()
  end
  function UiHandlerBase:LogShow()
    if self.tableName then
      Ui.SetWallOfData(self.tableName, "show")
    end
  end
  function UiHandlerBase:Hide()
    if not self.isShown then
      return
    end
    self:ASInvoke("onSwfHide")
    self.isShown = false
    local wnd = self:getWindow()
    if wnd then
      local close = self.unloadOnHide
      if close then
        wnd:Close()
      else
        wnd:Hide()
      end
      if self.panelSoundsEnabled then
        SoundHandler:PlaySoundById(SoundHandler.sounds.UI_Pane_Close, 1)
      end
      LUABroadcaster:dispatchEvent(self, self.events.VISIBILITY_UPDATE, false)
    end
    if self.enableLogging then
      self:LogHide()
    end
  end
  function UiHandlerBase:Exit(force)
    if force then
      Context:Unlock(self.tableName)
    end
    Context:ExecuteAndPop(force, self.tableName)
  end
  function UiHandlerBase:LogHide()
    if self.tableName then
      Ui.SetWallOfData(self.tableName, "hide")
    end
  end
  function UiHandlerBase:ASInvoke(func, ...)
    if not func or not self.allowInvokesWhenHidden and not self.isShown then
      return
    end
    local swf = self:getSwf()
    func = tostring(func)
    if swf then
      swf:Invoke(func, ...)
    end
  end
  function UiHandlerBase:OnInit()
  end
  function UiHandlerBase:OnClientLoadComplete()
    LUABroadcaster:removeListener(GameEvents, GameEvents.EVENT_WORLD_READY_COMPLETE, "OnClientLoadComplete", self)
    if self.loadOnInit then
      self:getWindow():LoadMovie()
    end
  end
  function UiHandlerBase:OnResize()
    if self.isShown then
      self:ASInvoke("swfResize")
    end
  end
  function UiHandlerBase:SetFocus()
    if self.isShown then
      local wnd = self:getWindow()
      local swf = self:getSwf()
      if wnd and swf then
        wnd:SetFocus()
        swf:SetFocus()
      end
    end
  end
  function UiHandlerBase:OnSwfFocus(isFocused)
    if self.isShown == true then
      if self.isAS3 then
        self:ASInvoke("onSwfFocus", isFocused)
      else
        self:ASInvoke("swfFocus", isFocused)
      end
    end
  end
  function UiHandlerBase:OnUserEvent(a, ...)
    if self[a] then
      self[a](self, ...)
    end
  end
  function UiHandlerBase:getWindow()
    return Window.Find(self.wndName)
  end
  function UiHandlerBase:getSwf()
    return GfxCtrl.Find(self.swfName)
  end
  function UiHandlerBase:DebugPrint(msg)
    if self.isDebugOn then
      if self.tableName then
        msg = self.tableName .. " >> " .. msg
      end
      print(msg)
    end
  end
  function UiHandlerBase:DebugPrintVars(...)
    if self.isDebugOn then
      local i
      local s = ""
      local len = #arg
      for i = 1, len do
        s = s .. tostring(arg[i])
        if i < len then
          s = s .. ", "
        end
      end
      if self.tableName then
        s = self.tableName .. " >> " .. s
      end
      print(s)
    end
  end
  ModalUiHandlerBase = inheritsFrom(UiHandlerBase)
  ModalUiHandlerBase.enableLogging = true
  ModalUiHandlerBase.isModal = true
  ModalUiHandlerBase.pushToContext = true
  ModalUiHandlerBase.hitTestMethod = Constants.HitTestTypes.SHAPES_NO_INVIS
  MarketplacePopupScreen = inheritsFrom(UiHandlerBase)
  MarketplacePopupScreen.enableLogging = true
  MarketplacePopupScreen.logReferrerId = -1
  MarketplacePopupScreen.logReferrerContext = -1
  MarketplacePopupScreen.logScreenId = -1
  function MarketplacePopupScreen:Show(referrerContext)
    self.logReferrerId = MarketplaceHandler.Referrers.UI
    self.logReferrerContext = referrerContext
    MarketplaceHandler:RegisterUiHandler(self)
    UiHandlerBase.Show(self)
  end
  function MarketplacePopupScreen:Hide()
    MarketplaceHandler:UnregisterUiHandler(self)
    UiHandlerBase.Hide(self)
  end
  function MarketplacePopupScreen:LogShow()
    self:DebugPrintVars("LogShow", self.logScreenId, self.logReferrerId, self.logReferrerContext)
    if self.logScreenId > -1 and self.logReferrerId > -1 and self.logReferrerContext > -1 then
      InGamePurchaseStoreScreen.OnScreenOpen(self.logScreenId, self.logReferrerId, self.logReferrerContext)
    end
  end
  function MarketplacePopupScreen:LogHide()
    self:DebugPrintVars("LogHide", self.logScreenId)
    if self.logScreenId then
      InGamePurchaseStoreScreen.OnScreenClose(self.logScreenId)
    end
  end
  function MarketplacePopupScreen:OnResize()
    MaximizeWin(self)
    UiHandlerBase.OnResize(self)
  end
  FullScreenUiHandlerBase = inheritsFrom(UiHandlerBase)
  FullScreenUiHandlerBase.pageTitle = ""
  FullScreenUiHandlerBase.pageCategoryItems = {}
  FullScreenUiHandlerBase.enableLogging = true
  FullScreenUiHandlerBase.tutorial = nil
  FullScreenUiHandlerBase.tutorialOption = nil
  FullScreenUiHandlerBase.persistLastViewedCategoryIndex = true
  FullScreenUiHandlerBase.lastViewedCategoryIndex = nil
  FullScreenUiHandlerBase.hitTestMethod = Constants.HitTestTypes.SHAPES_NO_INVIS
  function FullScreenUiHandlerBase:Show()
    UiHandlerBase.Show(self)
    self:SetFocus()
  end
  function FullScreenUiHandlerBase:GetNavigationCategoryItems()
    return self:FilterNavigationCategoryItems(self.pageCategoryItems)
  end
  function FullScreenUiHandlerBase:FilterNavigationCategoryItems(items)
    local len = #items
    local i
    local res = {}
    for i = 1, len do
      local item = items[i]
      if item and self:ValidateNavigationCategoryItem(item) then
        table.insert(res, item)
      end
    end
    return res
  end
  function FullScreenUiHandlerBase:ValidateNavigationCategoryItem(item)
    return true
  end
  function FullScreenUiHandlerBase:OnNavigationCategorySelect(index, id, label, iconId)
    self:ASInvoke("onNavigationCategorySelect", index, id, label, iconId)
    self.lastViewedCategoryIndex = index
    if self.enableLogging and self.tableName then
      Ui.SetWallOfData(self.tableName, "category_select", id)
    end
  end
  function FullScreenUiHandlerBase:PersistLastViewedCategoryIndex()
    return self.persistLastViewedCategoryIndex
  end
  function FullScreenUiHandlerBase:GetLastViewedCategoryIndex()
    return self.lastViewedCategoryIndex
  end
  function FullScreenUiHandlerBase:SetTutorial(id)
    self.tutorial = id
  end
  function MaximizeWin(view)
    local wnd = Window.Find(view.wndName)
    local swf = GfxCtrl.Find(view.swfName)
    local sw, sh = Window.GetCanvasSize()
    if wnd then
      wnd:SetProperty("X", 0)
      wnd:SetProperty("Y", 0)
      wnd:SetProperty("Width", sw)
      wnd:SetProperty("Height", sh)
    end
    if swf then
      swf:SetProperty("X", 0)
      swf:SetProperty("Y", 0)
      swf:SetProperty("Width", sw)
      swf:SetProperty("Height", sh)
    end
  end
end)()
;(function()
  ChatHandler = {}
  ChatHandler.unloadOnHide = false
  ChatHandler.isDebugOn = false
  ChatHandler.EVENT_SET_CHAT_TEXT = "onSetChatText"
  ChatHandler.EVENT_SHOW_VOICE_CHAT = "onShowVoiceChat"
  ChatHandler.EVENT_HIDE_VOICE_CHAT = "onHideVoiceChat"
  ChatHandler.EVENT_SELECT_VOICE_CHAT = "onSelectVoiceChat"
  ChatHandler.registeredChannelGroups = {}
  ChatHandler.registeredHandlers = {}
  LUABroadcaster:addListener(DataSourceEvents, DataSourceEvents:getUpdateEvent(DataSources.DS_GROUPS), "ValidateActiveChannelGroups", ChatHandler)
  LUABroadcaster:addListener(DataSourceEvents, DataSourceEvents:getUpdateEvent(DataSources.DS_GUILDS), "ValidateActiveChannelGroups", ChatHandler)
  LUABroadcaster:addListener(DataSourceEvents, DataSourceEvents:getUpdateEvent(DataSources.DS_RAIDS), "ValidateActiveChannelGroups", ChatHandler)
  function ChatHandler:ASInvoke(func, ...)
    for tableName, handler in pairs(self.registeredHandlers) do
      if handler then
        handler:ASInvoke(func, ...)
      end
    end
  end
  function ChatHandler:RegisterUiHandler(handler)
    self.registeredHandlers[tostring(handler)] = handler
    ChatHandler:RefreshChatLog()
  end
  function ChatHandler:UnregisterUiHandler(handler)
    self.registeredHandlers[tostring(handler)] = nil
  end
  function ChatHandler:OnFontSizeChanged()
  end
  function ChatHandler:SendChat(msg)
    if msg == nil then
      return
    end
    msg = Ui.MakeHtmlSafe(msg)
    Ui.ProcessChatCommand(msg)
  end
  function ChatHandler:StartChat(text, showSlash)
    self:SetInputText(text)
  end
  function ChatHandler:SetChatText(newText)
    if Console.isShown then
      Console:SetText(newText)
    else
      self:SetInputText(newText)
    end
  end
  function OnPrintConsole(text, colorIndex)
    Console:ShowMessage(nil, "Message", text, 0, 16777215)
  end
  function OnPrint(text, sizeChat, fgColor, bgColor, noReturn)
    local message = inheritsFrom(ChatMessageBase)
    message.text = text
    message.sizeChat = sizeChat
    message.textColor = fgColor
    message.bgColor = bgColor
    message.channelId = ChatChannels.SYSTEM_MESSAGE:GetId()
    ChatHandler:AddChatMessage(message)
  end
  function ChatHandler:CycleChatTabs()
    self:ASInvoke("cycleChatChannelGroupTabs")
  end
  function ChatHandler:SetInputText(msg)
    LUABroadcaster:dispatchEvent(ChatHandler, ChatHandler.EVENT_SET_CHAT_TEXT, msg)
  end
  function ChatHandler:ShowVoiceChatMacros()
    LUABroadcaster:dispatchEvent(self, self.EVENT_SHOW_VOICE_CHAT)
  end
  function ChatHandler:HideVoiceChatMacros()
    LUABroadcaster:dispatchEvent(self, self.EVENT_HIDE_VOICE_CHAT)
  end
  function ChatHandler:OnVoiceChatMacroSelect(index)
    LUABroadcaster:dispatchEvent(self, self.EVENT_SELECT_VOICE_CHAT, index)
  end
  function OnReceiveSay(fromGuid, fromName, msg, isChatLogged, sizeChat, fgColor, bgColor, channelId, isNPC, isRef, isFriend, areaName, fromFactionId)
    local message = inheritsFrom(ChatMessageBase)
    message.text = msg
    message.fromGuid = fromGuid
    message.fromName = fromName
    message.fontSize = sizeChat
    message.textColor = fgColor
    message.bgColor = bgColor
    message.fgColor = fgColor
    message.channelId = channelId
    message.fromFactionId = fromFactionId
    ChatHandler:AddChatMessage(message)
  end
  function OnReceiveWhisper(fromGuid, fromName, msg, isChatLogged, sizeChat, fgColor, bgColor, channelId, isNPC, isRef)
    fromGuid = tostring(fromGuid)
    local message = inheritsFrom(ChatMessageBase)
    message.text = msg
    message.fromGuid = fromGuid
    message.fromName = fromName
    message.textColor = fgColor
    message.bgColor = bgColor
    message.fgColor = fgColor
    message.channelId = ChatChannels.WHISPER:GetId()
    message.fromFactionId = fromFactionId
    ChatHandler:AddChatMessage(message)
    WhisperChatChannelGroup:OnReceiveMessage(fromGuid, fromName, msg, channelId)
    if fromGuid ~= tostring(Ui.GetPlayerGuid()) then
      SoundHandler:PlaySoundById(SoundHandler.sounds.UI_Whisper_Received)
    end
  end
  function OnReceiveEmote(fromGuid, fromName, msg, isChatLogged, sizeChat, fgColor, bgColor)
  end
  function OnReceiveGuildSay(fromGuid, fromName, msg)
  end
  ChatMessageBase = {
    fromName = "",
    fromGuid = "",
    text = "",
    channelId = "",
    fontSize = -1,
    textColor = "#FFFFFF",
    bgColor = "",
    areaName = "",
    fromFactionId = -1,
    escapeHtml = true
  }
  function ChatMessageBase:IsFromLocalPlayer()
    return self.fromGuid == Ui.GetPlayerGuid()
  end
  function ChatMessageBase:GetFormattedMessage()
    local channelId = self.channelId
    local channel = ChatChannel:GetChannelById(channelId)
    if channel then
      return channel:GetFormattedMessage(self)
    end
    return "Error: Cannot find chat channel " .. tostring(channelId)
  end
  ChatChannel = {}
  ChatChannel.id = ""
  ChatChannel.prefixString = ""
  ChatChannel.hashById = {}
  function ChatChannel:Create(id, prefixString)
    local chatChannel = {}
    setmetatable(chatChannel, {__index = ChatChannel})
    chatChannel.id = id
    self.hashById[id] = chatChannel
    if prefixString then
      chatChannel.prefixString = prefixString
    end
    return chatChannel
  end
  function ChatChannel:GetId()
    return self.id
  end
  function ChatChannel:GetChannelById(id)
    return self.hashById[id]
  end
  function ChatChannel:GetFormattedMessage(message)
    local textColor = message.textColor
    local prefix = self:GetMessagePrefixText(message)
    local fromName = self:GetMessageFromText(message)
    local body = self:GetMessageBodyText(message)
    local headerStr = ""
    if prefix and prefix ~= "" then
      headerStr = headerStr .. prefix .. " "
    end
    if fromName and fromName ~= "" then
      headerStr = headerStr .. fromName .. ": "
    end
    local formattedMessage = "<font color=\"" .. tostring(textColor) .. "\">" .. headerStr .. body .. "</font>"
    return formattedMessage
  end
  function ChatChannel:GetMessagePrefixText(message)
    return self.prefixString
  end
  function ChatChannel:GetMessageFromText(message)
    local fromName = ""
    if message:IsFromLocalPlayer() then
      fromName = Ui.GetString("UI.Chat.You")
    elseif message.fromName ~= "" and message.fromGuid ~= "" then
      fromName = message.fromName
    else
      return ""
    end
    return fromName
  end
  function ChatChannel:GetMessageBodyText(message)
    return message.text
  end
  ChatChannels = {
    WORLD_SAY = ChatChannel:Create("WorldSay", ""),
    SQUAD_SAY = ChatChannel:Create("GroupSay", Ui.GetString("UI.HudSquad")),
    PLATOON_SAY = ChatChannel:Create("RaidSay", Ui.GetString("UI.ChatPlatoon")),
    SQUAD_OWNER_SAY = ChatChannel:Create("GroupOwnerSay", Ui.GetString("UI.HudSquadOwner")),
    OUTFIT_SAY = ChatChannel:Create("GuildSay", Ui.GetString("UI.HudOutfit")),
    WORLD_SHOUT = ChatChannel:Create("WorldShout", Ui.GetString("UI.HudYell")),
    WHISPER = ChatChannel:Create("Whisper", Ui.GetString("UI.HudTell")),
    WORLD_AREA = ChatChannel:Create("WorldArea", Ui.GetString("UI.HudArea")),
    WORLD_REGION = ChatChannel:Create("WorldRegion", Ui.GetString("UI.ChatRegion")),
    ORDERS = ChatChannel:Create("Orders", Ui.GetString("UI.HudOrders")),
    SYSTEM_MESSAGE = ChatChannel:Create("SystemMessage"),
    GENERIC = ChatChannel:Create("Generic"),
    MISC = ChatChannel:Create("Misc"),
    DEBUG_OUTPUT = ChatChannel:Create("DebugOutput"),
    SQUAD_GENERIC = ChatChannel:Create("SquadGeneric"),
    PLATOON_GENERIC = ChatChannel:Create("PlatoonGeneric"),
    OUTFIT_GENERIC = ChatChannel:Create("OutfitGeneric"),
    ITEM_RECEIVED = ChatChannel:Create("ItemReceived")
  }
  function ChatChannels.WORLD_SHOUT:GetMessageFromText(message)
    local color = "#FFFFFF"
    local targetFactionId = message.fromFactionId
    if targetFactionId and targetFactionId > 0 then
      local factionColor = Constants.FactionColors[targetFactionId]
      if factionColor then
        color = factionColor
      end
    end
    fromName = "<font color=\"" .. color .. "\">" .. ChatChannel.GetMessageFromText(self, message) .. "</font>"
    return fromName
  end
  function ChatChannels.WHISPER:GetMessagePrefixText(message)
    if not message:IsFromLocalPlayer() then
      return ChatChannel.GetMessagePrefixText(self, message)
    end
    return ""
  end
  function ChatChannels.WHISPER:GetMessageFromText(message)
    if not message:IsFromLocalPlayer() then
      return ChatChannel.GetMessageFromText(self, message)
    end
    return ""
  end
  function ChatChannels.WORLD_REGION:GetMessagePrefixText(message)
    local prefix = self.prefixString
    local areaName = message.areaName
    if areaName and areaName ~= "" then
      prefix = "[" .. areaName .. "]"
    end
    return prefix
  end
  ChatChannelGroupIds = {
    GENERAL = Ui.GetString("UI.GeneralPC"),
    SQUAD = Ui.GetString("UI.SquadPC"),
    OUTFIT = Ui.GetString("UI.OutfitPC"),
    WHISPER = Ui.GetString("UI.WhisperPC"),
    SQUAD_LEADER = Ui.GetString("UI.LeaderPC"),
    PLATOON = Ui.GetString("UI.PlatoonPC"),
    ITEMS = Ui.GetString("UI.Chat.Items")
  }
  ChatChannelGroup = {}
  ChatChannelGroup.id = ""
  ChatChannelGroup.maxHistory = 200
  ChatChannelGroup.isDirty = false
  ChatChannelGroup.history = {}
  ChatChannelGroup.curLogIndex = 0
  ChatChannelGroup.recentMessages = {}
  ChatChannelGroup.channelHash = nil
  ChatChannelGroup.priority = 1
  ChatChannelGroup.defaultInputMessage = ""
  ChatChannelGroup.clearTextInputOnFocus = false
  ChatChannelGroup.defaultOutputMessage = Ui.GetString("UI.NoMessages")
  ChatChannelGroup.defaultSendCommand = ""
  ChatChannelGroup.vivoxRoomType = Constants.VoiceRoomType.PROXIMITY
  ChatChannelGroup.applyLastUsedCommand = false
  ChatChannelGroup.acceptAllChannels = false
  function ChatChannelGroup:HasChannel(channelId)
    if self.acceptAllChannels or self.channelHash and self.channelHash[channelId] == true then
      return true
    end
    return false
  end
  function ChatChannelGroup:AddChannel(channelId)
    if not self.channelHash then
      self.channelHash = {}
    end
    self.channelHash[channelId] = true
  end
  function ChatChannelGroup:RemoveChannel(channelId)
    if not self.channelHash then
      self.channelHash = {}
    end
    self.channelHash[channelId] = nil
  end
  function ChatChannelGroup:ResetLog()
    self.history = {}
    self.recentMessages = {}
    self.curLogIndex = 0
  end
  GeneralChatChannelGroup = inheritsFrom(ChatChannelGroup)
  GeneralChatChannelGroup.id = ChatChannelGroupIds.GENERAL
  GeneralChatChannelGroup.history = {}
  GeneralChatChannelGroup.recentMessages = {}
  GeneralChatChannelGroup.curLogIndex = 0
  GeneralChatChannelGroup.priority = 1
  GeneralChatChannelGroup.defaultSendCommand = "/say"
  GeneralChatChannelGroup.defaultOutputMessage = Ui.GetString("UI.NoMessages")
  GeneralChatChannelGroup.vivoxRoomType = Constants.VoiceRoomType.PROXIMITY
  GeneralChatChannelGroup.clearTextInputOnFocus = false
  GeneralChatChannelGroup.applyLastUsedCommand = true
  GeneralChatChannelGroup:AddChannel(ChatChannels.WORLD_SAY:GetId())
  GeneralChatChannelGroup:AddChannel(ChatChannels.SYSTEM_MESSAGE:GetId())
  GeneralChatChannelGroup:AddChannel(ChatChannels.WHISPER:GetId())
  GeneralChatChannelGroup:AddChannel(ChatChannels.GENERIC:GetId())
  GeneralChatChannelGroup:AddChannel(ChatChannels.MISC:GetId())
  GeneralChatChannelGroup:AddChannel(ChatChannels.DEBUG_OUTPUT:GetId())
  SquadChatChannelGroup = inheritsFrom(ChatChannelGroup)
  SquadChatChannelGroup.id = ChatChannelGroupIds.SQUAD
  SquadChatChannelGroup.history = {}
  SquadChatChannelGroup.recentMessages = {}
  SquadChatChannelGroup.curLogIndex = 0
  SquadChatChannelGroup.priority = 2
  SquadChatChannelGroup.defaultSendCommand = "/squadsay"
  SquadChatChannelGroup.defaultOutputMessage = Ui.GetString("UI.NoMessages")
  SquadChatChannelGroup.vivoxRoomType = Constants.VoiceRoomType.GROUP
  SquadChatChannelGroup:AddChannel(ChatChannels.SQUAD_SAY:GetId())
  SquadChatChannelGroup:AddChannel(ChatChannels.WHISPER:GetId())
  SquadChatChannelGroup:AddChannel(ChatChannels.SYSTEM_MESSAGE:GetId())
  SquadChatChannelGroup:AddChannel(ChatChannels.ORDERS:GetId())
  SquadChatChannelGroup:AddChannel(ChatChannels.SQUAD_GENERIC:GetId())
  PlatoonChatChannelGroup = inheritsFrom(ChatChannelGroup)
  PlatoonChatChannelGroup.id = ChatChannelGroupIds.PLATOON
  PlatoonChatChannelGroup.history = {}
  PlatoonChatChannelGroup.recentMessages = {}
  PlatoonChatChannelGroup.curLogIndex = 0
  PlatoonChatChannelGroup.priority = 3
  PlatoonChatChannelGroup.defaultSendCommand = "/platoonsay"
  PlatoonChatChannelGroup.defaultOutputMessage = Ui.GetString("UI.NoMessages")
  PlatoonChatChannelGroup.vivoxRoomType = Constants.VoiceRoomType.RAID
  PlatoonChatChannelGroup:AddChannel(ChatChannels.PLATOON_SAY:GetId())
  PlatoonChatChannelGroup:AddChannel(ChatChannels.WHISPER:GetId())
  PlatoonChatChannelGroup:AddChannel(ChatChannels.SYSTEM_MESSAGE:GetId())
  PlatoonChatChannelGroup:AddChannel(ChatChannels.ORDERS:GetId())
  PlatoonChatChannelGroup:AddChannel(ChatChannels.PLATOON_GENERIC:GetId())
  SquadLeaderChatChannelGroup = inheritsFrom(ChatChannelGroup)
  SquadLeaderChatChannelGroup.id = ChatChannelGroupIds.SQUAD_LEADER
  SquadLeaderChatChannelGroup.history = {}
  SquadLeaderChatChannelGroup.recentMessages = {}
  SquadLeaderChatChannelGroup.curLogIndex = 0
  SquadLeaderChatChannelGroup.priority = 4
  SquadLeaderChatChannelGroup.vivoxRoomType = Constants.VoiceRoomType.GROUP_LEADER
  SquadLeaderChatChannelGroup.defaultSendCommand = "/leader"
  SquadLeaderChatChannelGroup.defaultOutputMessage = Ui.GetString("UI.NoMessages")
  SquadLeaderChatChannelGroup:AddChannel(ChatChannels.SQUAD_OWNER_SAY:GetId())
  SquadLeaderChatChannelGroup:AddChannel(ChatChannels.WHISPER:GetId())
  SquadLeaderChatChannelGroup:AddChannel(ChatChannels.SYSTEM_MESSAGE:GetId())
  SquadLeaderChatChannelGroup:AddChannel(ChatChannels.ORDERS:GetId())
  OutfitChatChannelGroup = inheritsFrom(ChatChannelGroup)
  OutfitChatChannelGroup.id = ChatChannelGroupIds.OUTFIT
  OutfitChatChannelGroup.history = {}
  OutfitChatChannelGroup.recentMessages = {}
  OutfitChatChannelGroup.curLogIndex = 0
  OutfitChatChannelGroup.priority = 5
  OutfitChatChannelGroup.defaultSendCommand = "/outfitsay"
  OutfitChatChannelGroup.defaultOutputMessage = Ui.GetString("UI.NoMessages")
  OutfitChatChannelGroup.vivoxRoomType = Constants.VoiceRoomType.GUILD
  OutfitChatChannelGroup:AddChannel(ChatChannels.OUTFIT_SAY:GetId())
  OutfitChatChannelGroup:AddChannel(ChatChannels.WHISPER:GetId())
  OutfitChatChannelGroup:AddChannel(ChatChannels.SYSTEM_MESSAGE:GetId())
  OutfitChatChannelGroup:AddChannel(ChatChannels.ORDERS:GetId())
  OutfitChatChannelGroup:AddChannel(ChatChannels.OUTFIT_GENERIC:GetId())
  WhisperChatChannelGroup = inheritsFrom(ChatChannelGroup)
  WhisperChatChannelGroup.id = ChatChannelGroupIds.WHISPER
  WhisperChatChannelGroup.history = {}
  WhisperChatChannelGroup.recentMessages = {}
  WhisperChatChannelGroup.curLogIndex = 0
  WhisperChatChannelGroup.priority = 6
  WhisperChatChannelGroup.defaultSendCommand = ""
  WhisperChatChannelGroup.defaultInputMessage = "/whisper "
  WhisperChatChannelGroup.defaultOutputMessage = Ui.GetString("UI.NoMessages")
  WhisperChatChannelGroup.vivoxRoomType = Constants.VoiceRoomType.PROXIMITY
  WhisperChatChannelGroup:AddChannel(ChatChannels.WHISPER:GetId())
  WhisperChatChannelGroup.activeWhisperTargetHash = {}
  WhisperChatChannelGroup.activeWhisperTargets = {}
  WhisperChatChannelGroup.whisperCount = 0
  WhisperChatChannelGroup.whisperTargetIndex = 1
  ItemChatChannelGroup = inheritsFrom(ChatChannelGroup)
  ItemChatChannelGroup.id = ChatChannelGroupIds.ITEMS
  ItemChatChannelGroup.history = {}
  ItemChatChannelGroup.recentMessages = {}
  ItemChatChannelGroup.curLogIndex = 0
  ItemChatChannelGroup.priority = 7
  ItemChatChannelGroup.defaultSendCommand = "/say"
  ItemChatChannelGroup.defaultOutputMessage = Ui.GetString("UI.NoMessages")
  ItemChatChannelGroup:AddChannel(ChatChannels.ITEM_RECEIVED:GetId())
  function WhisperChatChannelGroup:OnReceiveMessage(fromGuid, fromName, msg, channelId)
    if tostring(fromGuid) == tostring(Ui.GetPlayerGuid()) then
      fromName = channelId
    end
    local t = self.activeWhisperTargetHash
    local u = {}
    t[fromName] = self.whisperCount
    for k, v in pairs(t) do
      table.insert(u, {name = k, priority = v})
    end
    table.sort(u, function(w1, w2)
      return w1.priority < w2.priority
    end)
    self.whisperCount = self.whisperCount + 1
    self.activeWhisperTargets = u
  end
  function WhisperChatChannelGroup:GetLastWhisperCommand()
    local numActiveWhisperTargets = #self.activeWhisperTargets
    local curIndex = self.whisperTargetIndex
    if numActiveWhisperTargets > 0 then
      if curIndex > 1 then
        curIndex = curIndex - 1
      else
        curIndex = numActiveWhisperTargets
      end
      self.whisperTargetIndex = curIndex
      return "/whisper " .. tostring(self.activeWhisperTargets[curIndex].name) .. " "
    end
    return "/whisper "
  end
  function WhisperChatChannelGroup:GetNextWhisperCommand()
    local numActiveWhisperTargets = #self.activeWhisperTargets
    local curIndex = self.whisperTargetIndex
    if numActiveWhisperTargets > 0 then
      if numActiveWhisperTargets > curIndex then
        curIndex = curIndex + 1
      else
        curIndex = 1
      end
      self.whisperTargetIndex = curIndex
      return "/whisper " .. tostring(self.activeWhisperTargets[curIndex].name) .. " "
    end
    return "/whisper "
  end
  function ChatHandler:HandleHudStateChange(fromState, toState)
    if toState == UIStateCharacterSelect then
      ChatHandler:ResetChatHistory()
    end
  end
  function ChatHandler:GetAvailableChannelGroups()
    return {
      GeneralChatChannelGroup,
      SquadChatChannelGroup,
      SquadLeaderChatChannelGroup,
      OutfitChatChannelGroup,
      WhisperChatChannelGroup,
      PlatoonChatChannelGroup,
      ItemChatChannelGroup
    }
  end
  function ChatHandler:GetChannelGroupById(id)
    return ChatHandler.registeredChannelGroups[id]
  end
  function ChatHandler:GetRegisteredChannelGroups(boolSort)
    local k, v
    local res = {}
    for k, v in pairs(self.registeredChannelGroups) do
      table.insert(res, v)
    end
    if boolSort then
      table.sort(res, function(g1, g2)
        return g1.priority < g2.priority
      end)
    end
    return res
  end
  function ChatHandler:GetGroupsWithChannel(channelId)
    local channelGroupName, channelGroup
    local groups = {}
    for id, channelGroup in pairs(ChatHandler.registeredChannelGroups) do
      if channelGroup:HasChannel(channelId) then
        table.insert(groups, channelGroup)
      end
    end
    return groups
  end
  function ChatHandler:HasActiveWhispers()
    local serGroups = self:GetRegisteredChatChannelGroupIds()
    return string.find(serGroups, "Whisper") ~= nil
  end
  function ChatHandler:HasRegisteredChannelGroup(channelGroup)
    if channelGroup and ChatHandler.registeredChannelGroups and ChatHandler.registeredChannelGroups[channelGroup.id] then
      return true
    end
    return false
  end
  function ChatHandler:RegisterChannelGroup(channelGroup, ignoreDispatch)
    if not channelGroup or ChatHandler:HasRegisteredChannelGroup(channelGroup) then
      return false
    end
    ChatHandler.registeredChannelGroups[channelGroup.id] = channelGroup
    if not ignoreDispatch then
      ChatHandler:DispatchChannelGroupsChange()
    end
    return true
  end
  function ChatHandler:DumpRegisteredChannelGroups()
    local k, v
    for k, v in pairs(self.registeredChannelGroups) do
      print(k)
    end
  end
  function ChatHandler:UnregisterChannelGroup(channelGroup, ignoreDispatch)
    if not self:HasRegisteredChannelGroup(channelGroup) then
      return false
    end
    ChatHandler.registeredChannelGroups[channelGroup.id] = nil
    if not ignoreDispatch then
      ChatHandler:DispatchChannelGroupsChange()
    end
    return true
  end
  function ChatHandler:DispatchChannelGroupsChange()
    self:ASInvoke("onChatChannelGroupsChange")
  end
  function ChatHandler:AddChannelToGroup(channelGroup, channelId)
    channelGroup:AddChannel(channelId)
    ChatHandler:MarkChannelGroupDirty(channelGroup)
  end
  function ChatHandler:RemoveChannelFromGroup(channelGroup, channelId)
    channelGroup:RemoveChannel(channelId)
    ChatHandler:MarkChannelGroupDirty(channelGroup)
  end
  function ChatHandler:Update()
    local id, channelGroup
    for id, channelGroup in pairs(ChatHandler.registeredChannelGroups) do
      if channelGroup and channelGroup.isDirty then
        self:ASInvoke("onChatChannelGroupChange", channelGroup.id)
        channelGroup.isDirty = false
      end
    end
    UpdateList.ChatHandler_ValidateChannelGroups = nil
  end
  function ChatHandler:MarkChannelGroupDirty(channelGroup)
    if channelGroup then
      channelGroup.isDirty = true
      UpdateList.ChatHandler_ValidateChannelGroups = ChatHandler
    end
  end
  function ChatHandler:RefreshChatLog()
    ChatHandler:DispatchChannelGroupsChange()
  end
  function ChatHandler:AddChatMessageByParams(msg, color, channelId)
    local chatMessage = inheritsFrom(ChatMessageBase)
    chatMessage.text = msg
    chatMessage.textColor = color
    chatMessage.channelId = channelId
    self:AddChatMessage(chatMessage)
  end
  function ChatHandler:AddChatMessage(chatMessage)
    if not chatMessage then
      return
    end
    local channelId = chatMessage.channelId
    local groups = self:GetGroupsWithChannel(channelId)
    local numGroups = #groups
    local i
    for i = 1, numGroups do
      local group = groups[i]
      local historyLen = #group.history
      if group then
        if historyLen >= group.maxHistory then
          table.remove(group.history, 1)
        end
        table.insert(group.history, chatMessage)
        group.curLogIndex = group.curLogIndex + 1
        group.isDirty = true
        ChatHandler:MarkChannelGroupDirty(group)
      end
    end
  end
  function ChatHandler:GetLogForChannelGroup(id, numMessages)
    local channelGroup = self:GetChannelGroupById(id)
    if channelGroup then
      local messages = {}
      if numMessages == nil or numMessages >= channelGroup.maxHistory then
        messages = channelGroup.history
      elseif numMessages > 0 then
        messages = TableUtils:Slice(channelGroup.history, #channelGroup.history - numMessages + 1, #channelGroup.history)
      else
        return ""
      end
      return self:BuildChatLog(messages)
    end
    return "Error: Cannot find channel group for " .. tostring(id)
  end
  function ChatHandler:GetCurrentLogIndexForChannelGroup(id)
    local channelGroup = self:GetChannelGroupById(id)
    if channelGroup then
      return channelGroup.curLogIndex
    end
  end
  function ChatHandler:BuildChatLog(messages)
    local numMessages = #messages
    local s = ""
    local i
    for i = 1, numMessages do
      s = s .. messages[i]:GetFormattedMessage()
      if i < numMessages then
        s = s .. "<br>"
      end
    end
    return s
  end
  function ChatHandler:FormatPlayerInfoForHTMLLink(playerName, playerGuid)
    return "<a href=\"event:ShowPlayerMenu|" .. tostring(playerName) .. "|" .. tostring(playerGuid) .. "\">[" .. tostring(playerName) .. "]</a>"
  end
  function ChatHandler:ResetChatHistory()
    GeneralChatChannelGroup:ResetLog()
    SquadChatChannelGroup:ResetLog()
    SquadLeaderChatChannelGroup:ResetLog()
    OutfitChatChannelGroup:ResetLog()
    WhisperChatChannelGroup:ResetLog()
    PlatoonChatChannelGroup:ResetLog()
    ChatHandler:RefreshChatLog()
  end
  function ChatHandler:ValidateActiveChannelGroups()
    local result = self:RegisterChannelGroup(GeneralChatChannelGroup)
    if result then
      self:DispatchChannelGroupsChange()
    end
  end
  function ChatHandler:IsPlayerSquadLeader()
    local ds = DsTable.Find("BaseClient.GroupMemberData")
    if ds then
      local i
      local numRows = ds:GetRowCount()
      local playerGuid = tostring(Ui.GetPlayerGuid())
      for i = 0, numRows - 1 do
        if ds:GetData(i, 1) == playerGuid then
          return ds:GetData(i, 7) == "1"
        end
      end
    end
    return false
  end
  ChatHandler:ValidateActiveChannelGroups()
  Client.ChatHandler = "ChatHandler"
end)()
;(function()
  DeathHandler = inheritsFrom(FullScreenUiHandlerBase)
  DeathHandler:SetUiProperties("Main.wndDeath", "swfDeath", "UI\\Death.swf", "DeathHandler", UiZLayers.MODAL_WINDOW)
  DeathHandler.isDebugOn = false
  DeathHandler.isAS3 = true
  DeathHandler.pageTitle = Ui.GetString("UI.Death")
  function DeathHandler:Show(isRespawnAllowed)
    FullScreenUiHandlerBase.Show(self)
    self:ASInvoke("SetRespawnAllowed", isRespawnAllowed)
    Ui.ShowCursor()
  end
  function DeathHandler:Hide()
    FullScreenUiHandlerBase.Hide(self)
  end
  function DeathHandler:OnResize()
    MaximizeWin(self)
    self:superClass().OnResize(self)
  end
end)()
;(function()
  NotificationHandler = {}
end)()
;(function()
  function GuiRestoreAppWindowPosition(strName)
    W = Window.Find("Main." .. strName)
    if W ~= nil and SavedSettings ~= nil and SavedSettings[strName] ~= nil then
      W:SetPosition(SavedSettings[strName].x, SavedSettings[strName].y)
      W:SetSize(SavedSettings[strName].w, SavedSettings[strName].h)
    end
  end
  GuiSaver = {
    Count = 0,
    theFile = nil,
    Begin = function(self)
      self.Count = 0
      self.theFile = io.open("SaveSettings", "wt")
      if self.theFile ~= nil then
        self.theFile:write("SavedSettings = {\n")
      end
    end,
    End = function(self)
      if self.theFile ~= nil then
        self.theFile:write("}\n")
        self.theFile:close()
      end
    end,
    SaveAppWindowPosition = function(self, strName)
      if self.theFile ~= nil then
        W = Window.Find("Main." .. strName)
        if W ~= nil then
          local x, y
          x, y = W:GetPosition()
          local w, h
          w, h = W:GetSize()
          if self.Count > 0 then
            self.theFile:write(",\n")
          end
          self.theFile:write("   " .. strName .. " = {\n")
          self.theFile:write("      x=" .. tostring(x) .. ",\n")
          self.theFile:write("      y=" .. tostring(y) .. ",\n")
          self.theFile:write("      w=" .. tostring(w) .. ",\n")
          self.theFile:write("      h=" .. tostring(h) .. "\n")
          self.theFile:write("   }\n")
          self.Count = self.Count + 1
        end
      end
    end
  }
end)()
;(function()
  Console = inheritsFrom(UiHandlerBase)
  Console:SetUiProperties("Main.wndConsole", "swfConsole", "UI\\Console.swf", "Console", UiZLayers.TOOL)
  Console.unloadOnHide = true
  Console.isLocked = false
  Console.history = {}
  Console.startIndex = 0
  Console.endIndex = 0
  Console.isDirty = false
  Console.maxHistory = 300
  Console.historyDumpFileName = "ConsoleDump.txt"
  Console.logFileName = "ConsoleLog.txt"
  Console.loggingEnabled = false
  Console.isAS3 = true
  LUABroadcaster:addListener(UiEventDispatcher, ClientEvents.CLIENT_INIT, "Init", Console)
  LUABroadcaster:addListener(UiEventDispatcher, ClientEvents.CLIENT_RESIZE, "OnResize", Console)
  function Console:StartDebugConsole()
    if Client.EnableDebugConsole then
      if self.isShown then
        self:Hide()
      else
        self:Show()
      end
    end
  end
  function Console:Init()
    self:OnResize()
  end
  function Console:Show()
    self:superClass().Show(self)
    self:Invalidate()
    if UpdateList.Console ~= self then
      UpdateList.Console = self
    end
    self:OnResize()
    self:SetFocus()
    GameEvents:ValidateMouseState()
    HudHandler:ASInvoke("SetNotificationPositionLow")
  end
  function Console:Hide()
    UpdateList.Console = nil
    self:superClass().Hide(self)
    GameEvents:ValidateMouseState()
    HudHandler:ASInvoke("SetNotificationPositionHigh")
  end
  function Console:OnResize()
    if not self.isShown then
      return
    end
    MaximizeWin(self)
    self:superClass().OnResize(self)
  end
  function Console:Update()
    if self.isDirty and self.isShown then
      local message = ""
      local count = #self.history
      for i = self.endIndex, count do
        if self.history[i] ~= nil then
          if i ~= self.endIndex then
            message = message .. "\n"
          end
          message = message .. self.history[i]
        end
      end
      for i = 0, self.endIndex - 1 do
        if self.history[i] ~= nil then
          message = message .. "\n"
          message = message .. self.history[i]
        end
      end
      self.isDirty = false
      self:SetOutputMessage(message)
    end
  end
  function Console:ShowMessage(guid, from, msg, sizeChat, fgColor, bgColor)
    if msg == "" then
      return
    end
    self.history[self.endIndex] = msg
    self.endIndex = self.endIndex + 1
    if self.endIndex >= self.maxHistory then
      self.endIndex = 0
    end
    if self.endIndex == self.startIndex then
      self.startIndex = self.startIndex + 1
    end
    if self.startIndex >= self.maxHistory then
      self.startIndex = 0
    end
    if self.isLocked then
      return
    end
    self:Invalidate()
    if self.loggingEnabled then
      ConsoleWrapper:LogConsoleMessageToFile(msg)
    end
  end
  function Console:ClearHistory()
    if not Ui.IsAdminClient() then
      return
    end
    if self.loggingEnabled then
      print("/clear")
    end
    self.history = {}
    self.startIndex = 0
    self.endIndex = 0
    self.isShown = false
    self:Show()
  end
  function Console:Invalidate()
    self.isDirty = true
  end
  function Console:SetFocus()
    if self.isShown then
      self:getWindow():SetFocus()
      self:getSwf():SetFocus()
      self:SetInputFocus(true)
    end
  end
  function Console:ClearFocus()
    if self.isShown then
    end
  end
  function Console:SetOutputMessage(message)
    if self.isShown then
      self:ASInvoke("setOutputMessage", message)
    end
  end
  function Console:SetInputFocus(value)
    if self.isShown then
      self:ASInvoke("setInputFocus", value)
    end
  end
  function Console:SetText(newText)
    if self.isShown then
      self:ASInvoke("setInputText", newText)
    end
  end
  function Console:ShowSwf()
    if self.isShown then
      self:ASInvoke("show")
    end
  end
  function Console:HideSwf()
    if self.isShown then
      self:ASInvoke("hide")
    end
  end
  ConsoleWrapper = {}
  function ConsoleWrapper:Show()
    Console:Show()
  end
  function ConsoleWrapper:Hide()
    Console:Hide()
  end
  function ConsoleWrapper:PrintIsConsoleLocked()
    print([[
--		Console Logging Info		--
	Action:			Status
	isLocked:		]] .. tostring(self:GetIsConsoleLocked()))
  end
  function ConsoleWrapper:LockConsole()
    ConsoleWrapper:SetIsConsoleLocked(true)
  end
  function ConsoleWrapper:UnlockConsole()
    ConsoleWrapper:SetIsConsoleLocked(false)
  end
  function ConsoleWrapper:GetIsConsoleLocked()
    return Console.isLocked
  end
  function ConsoleWrapper:SetIsConsoleLocked(value)
    Console.isLocked = value
    print("Console isLocked = " .. tostring(Console.isLocked) .. ".")
    Console:Invalidate()
  end
  function ConsoleWrapper:ClearConsoleHistory()
    Console:ClearHistory()
  end
  function ConsoleWrapper:ClearConsoleFocus()
    Console:ClearFocus()
  end
  function ConsoleWrapper:DumpConsoleHistory(filename)
    filename = filename or Console.historyDumpFileName
    io.output(io.open(filename, "w"))
    io.write("File Dumped at [" .. os.date() .. [[
].

]])
    local count = #Console.history
    for i = Console.endIndex, count - 1 do
      if Console.history[i] ~= nil then
        io.write(Console.history[i] .. "\n")
      end
    end
    for i = 0, Console.endIndex - 1 do
      if Console.history[i] ~= nil then
        io.write(Console.history[i] .. "\n")
      end
    end
    io.flush()
    io.close()
    os.execute("START " .. filename)
    print("Console history written to file '" .. tostring(filename) .. "'.")
  end
  function ConsoleWrapper:SetConsoleHistory(value)
    if not value or type(tonumber(value)) ~= "number" then
      print("Console history value is not a valid number. Please enter a valid number to set as the max history ( Default: 300 ).")
      return
    end
    local oldHistory = Console.maxHistory
    Console:ClearHistory()
    Console.maxHistory = tonumber(value)
    print("Console history has been changed from '" .. tostring(oldHistory) .. "' to '" .. tostring(Console.maxHistory) .. "'.")
  end
  function ConsoleWrapper:ChatSetPreviousCommand()
    Ui.ChatSetPreviousCommand()
  end
  function ConsoleWrapper:ChatSetNextCommand()
    Ui.ChatSetNextCommand()
  end
  function ConsoleWrapper:ChatTabCompletion(value)
    Ui.ChatTabCompletion(value)
  end
  function ConsoleWrapper:ProcessChatCommand(message)
    Ui.ProcessChatCommand(message)
  end
  function ConsoleWrapper:PrintIsConsoleLogging()
    print([[
--		Console Logging Info		--
	Action:			Status
	isLogging:		]] .. tostring(ConsoleWrapper:GetIsConsoleLoggingToFile()))
  end
  function ConsoleWrapper:ConsoleLoggingOn()
    ConsoleWrapper:SetIsConsoleLoggingToFile(true)
  end
  function ConsoleWrapper:ConsoleLoggingOff()
    ConsoleWrapper:SetIsConsoleLoggingToFile(false)
  end
  function ConsoleWrapper:GetIsConsoleLoggingToFile()
    return Console.loggingEnabled
  end
  function ConsoleWrapper:SetIsConsoleLoggingToFile(value)
    if not Ui.IsAdminClient() then
      value = false
    end
    Console.loggingEnabled = value
    print([[
--		Console Logging Info		--
	Action:			Toggle Console Logging
	Logging Enabled:		]] .. tostring(Console.loggingEnabled) .. [[

	Log Filename:		]] .. tostring(Console.logFileName) .. "")
  end
  function ConsoleWrapper:OpenConsoleLogFile()
    if not Ui.IsAdminClient() then
      return
    end
    local result = os.execute("START " .. Console.logFileName)
    print([[
--		Console Logging Info		--
	Action:			Log File Opened
	Log Filename:		]] .. tostring(Console.logFileName))
    if result > 0 then
      print([[
--		Console Logging Info		--
	Action:			Log File Opened
	Failed on Result:		]] .. tostring(result))
    end
  end
  function ConsoleWrapper:ClearConsoleLogFile()
    if not Ui.IsAdminClient() then
      return
    end
    print([[
--		Console Logging Info		--
	Action:			Log File Cleared
	Log Filename:		]] .. tostring(Console.logFileName))
    io.output(io.open(Console.logFileName, "w+"))
    io.close()
  end
  function ConsoleWrapper:LogConsoleMessageToFile(message)
    if not Ui.IsAdminClient() then
      return
    end
    io.output(io.open(Console.logFileName, "a+"))
    io.write(message .. "\n")
    io.flush()
    io.close()
  end
  function ConsoleWrapper:SetLogFileName(filename)
    Console.logFileName = filename
  end
  function ConsoleWrapper:GetLogFileName()
    return Console.logFileName
  end
  Logger = {}
  function Logger:print(category, msg)
  end
end)()
;(function()
  AppConfirm = {
    UserOk = nil,
    UserCancel = nil,
    ConfirmDialog = Ui.GetName("Main.wndConfirm"),
    ConfirmDialogLabel = Ui.GetName("Main.wndConfirm.lblLabel"),
    Shown = false,
    Ok = function(self)
      local W = Window.Find(self.ConfirmDialog)
      if W ~= nil then
        SetModalResult(true)
        W:Close()
      end
      if self.UserOk ~= nil then
        self.UserOk()
      end
      if self.Shown then
        self.Shown = false
        GfxCtrl.DisableStateBlock()
      end
    end,
    Cancel = function(self)
      local W = Window.Find(self.ConfirmDialog)
      if W ~= nil then
        SetModalResult(false)
        W:Close()
      end
      if self.UserCancel ~= nil then
        self.UserCancel()
      end
      if self.Shown then
        self.Shown = false
        GfxCtrl.DisableStateBlock()
      end
    end,
    Display = function(self, t, ParamOkFunction, ParamCancelFunction)
      if not self.Shown then
        self.Shown = true
        GfxCtrl.EnableStateBlock()
      end
      self.UserOk = ParamOkFunction
      self.UserCancel = ParamCancelFunction
      local W = Window.Find(self.ConfirmDialog)
      if W ~= nil then
        local L = LabelControl.find(self.ConfirmDialogLabel)
        if L ~= nil then
          L:setText(t)
        end
        W:Center()
        W:ShowModal()
      end
    end
  }
  function Main_wndConfirm_btnOk_OnClick()
    AppConfirm:Ok()
  end
  function Main_wndConfirm_btnCancel_OnClick()
    AppConfirm:Cancel()
  end
end)()
;(function()
  ClickGobblerHandler = inheritsFrom(UiHandlerBase)
  ClickGobblerHandler:SetUiProperties("Main.wndClickGobbler", "swfClickGobbler", "UI\\ClickGobbler.swf", "ClickGobblerHandler", UiZLayers.CLICK_GOBBLER)
  function ClickGobblerHandler:OnResize()
    MaximizeWin(self)
    self:superClass().OnResize(self)
  end
end)()
;(function()
  Gaq = {}
  Gaq.curRequests = {}
  Gaq.registeredHandlers = {}
  LUABroadcaster:addListener(GameEvents, GameEvents.EVENT_PLAYER_LOGOUT, "ClearRequests", Gaq)
  Gaq.EVENT_ADD_ITEM = "OnAddItem"
  Gaq.EVENT_REMOVE_ITEM = "OnRemoveItem"
  Gaq.EVENT_MAXIMIZE = "OnMaximize"
  Gaq.TYPE_ITEM_CLAIM = "ClaimNotification"
  Gaq.TYPE_GROUP_INVITE = "GroupInvite"
  Gaq.TYPE_OUTFIT_INVITE = "OutfitInvite"
  Gaq.TYPE_FRIEND_INVITE = "FriendInvite"
  Gaq.TYPE_SWAP_SEAT = "SwapSeatRequest"
  Gaq.TYPE_WARP_TO_ZONE = "WarpToZoneRequest"
  Gaq.TYPE_NUDGE_OFFER = "NudgeOffer"
  Gaq.responseConfigOk = {
    {
      label = Ui.GetString("UI.Ok"),
      callback = "Gaq:Accept"
    }
  }
  Gaq.responseConfigAcceptDecline = {
    {
      label = Ui.GetString("UI.Accept"),
      callback = "Gaq:Accept"
    },
    {
      label = Ui.GetString("UI.Decline"),
      callback = "Gaq:Decline"
    }
  }
  Gaq.requestQueueActionCount = 0
  function Gaq:RegisterUiHandler(handler)
    self.registeredHandlers[tostring(handler)] = handler
  end
  function Gaq:UnregisterUiHandler(handler)
    self.registeredHandlers[tostring(handler)] = nil
  end
  function Gaq:ASInvoke(func, ...)
    for tableName, handler in pairs(self.registeredHandlers) do
      if handler then
        handler:ASInvoke(func, ...)
      end
    end
  end
  function Gaq:ClearRequests()
    self.curRequests = {}
  end
  function Gaq:OnUserGaqResponse(id, response)
    GameActionQueue.Respond(tonumber(id), tonumber(response))
  end
  function Gaq:AddGameAction(type, msg, gaqId, ...)
    if self[type] then
      self[type](self, type, msg, gaqId, unpack(arg))
      LUABroadcaster:dispatchEvent(Gaq, Gaq.EVENT_ADD_ITEM, type, msg, gaqId, responseButtonParams, unpack(arg))
    else
      print("<ERROR> GAQ Handler Func Not Found >> " .. tostring(type))
    end
  end
  function Gaq:RemoveGaqItemById(gaqId)
    local i, entry
    local total = #Gaq.curRequests
    local hasRemoved = false
    gaqId = tostring(gaqId)
    for i = total, 1, -1 do
      entry = Gaq.curRequests[i]
      if tostring(entry.id) == gaqId then
        table.remove(Gaq.curRequests, i)
        hasRemoved = true
      end
    end
    if hasRemoved then
      self.requestQueueActionCount = self.requestQueueActionCount + 1
      self:ASInvoke("handleGaqRemoveItem", gaqId)
    end
  end
  function Gaq:RemoveGaqItemByType(type)
    local i, entry
    local total = #Gaq.curRequests
    type = tostring(type)
    for i = total, 1, -1 do
      entry = Gaq.curRequests[i]
      if tostring(entry.type) == type then
        table.remove(Gaq.curRequests, i)
        self:ASInvoke("handleGaqRemoveItem", entry.id)
      end
    end
  end
  function Gaq:TextNotification(type, msg, gaqId, formattedDate)
    NotificationHandler:ShowGeneralNotification(msg)
  end
  function Gaq:GroupInvite(type, msg, gaqId, formattedDate)
    Gaq:AddRequestToQueue(gaqId, type, Ui.GetString("UI.SquadInvite"), msg, formattedDate)
  end
  function Gaq:GroupApproval(type, msg, gaqId, formattedDate)
    Gaq:AddRequestToQueue(gaqId, type, Ui.GetString("UI.GroupApproval"), msg, formattedDate)
  end
  function Gaq:GuildInvite(type, msg, gaqId, formattedDate)
    Gaq:AddRequestToQueue(gaqId, type, Ui.GetString("UI.OutfitInvite"), msg, formattedDate)
  end
  function Gaq:FriendInvite(type, msg, gaqId, formattedDate, playerGuid)
    Gaq:AddRequestToQueue(gaqId, type, Ui.GetString("UI.FriendInvite"), msg, formattedDate)
  end
  function Gaq:ClaimNotification(type, msg, gaqId, formattedDate, itemId, iconId, gifterGuid, gifterName)
    Gaq:AddRequestToQueue(gaqId, type, Ui.GetString("UI.ClaimItem"), msg, formattedDate, self.responseConfigOk)
  end
  function Gaq:ItemReceived(type, msg, gaqId, receivedType, itemId, quantity, imageSetId, tintValue, giftingGuid, giftingName)
  end
  function Gaq:SwapSeatRequest(type, msg, gaqId, formattedDate)
    Gaq:AddRequestToQueue(gaqId, type, Ui.GetString("UI.SwapSeatRequest"), msg, formattedDate)
  end
  function Gaq:WarpToZoneRequest(type, msg, gaqId, formattedDate)
    if ServerQueueHandler.isShown and ServerQueueHandler.queuedForZoneId > 0 then
      Warpgate.WarpToZone(ServerQueueHandler.queuedForZoneId)
    else
      Gaq:AddRequestToQueue(gaqId, type, Ui.GetString("UI.ContinentWarp"), msg, formattedDate)
    end
  end
  function Gaq:NudgeOffer(type, msg, gaqId, formattedDate)
    Gaq:AddRequestToQueue(gaqId, type, Ui.GetString("UI.NudgeOffer"), msg, formattedDate)
  end
  function Gaq:RentalItemRemoved(type, msg, gaqId, formattedDate)
    Gaq:AddRequestToQueue(gaqId, type, Ui.GetString("UI.ItemRental.RentalExpired"), msg, formattedDate, self.responseConfigOk)
  end
  function Gaq:TrialItemRemoved(type, msg, gaqId, formattedDate)
  end
  function Gaq:SkillLineDeprecated(type, msg, gaqId, itemId, formattedDate)
    Gaq:AddRequestToQueue(gaqId, type, Ui.GetString("UI.Skills.SkillLineDeprecated"), msg, formattedDate, self.responseConfigOk)
  end
  function Gaq:GetCurrentRequests()
    return Gaq.curRequests
  end
  function Gaq:GetLastReceivedEntry()
    return self.lastReceivedEntry
  end
  function Gaq:GetRequestQueueActionCount()
    return self.requestQueueActionCount
  end
  function Gaq:AddRequestToQueue(id, type, title, msg, formattedDate, responseButtonParams)
    responseButtonParams = responseButtonParams or self.responseConfigAcceptDecline
    title = title and Ui.StringToUpper(title)
    self.requestQueueActionCount = self.requestQueueActionCount + 1
    local entry = {
      id = id,
      type = type,
      title = title,
      msg = msg,
      responseButtonParams = responseButtonParams
    }
    table.insert(self.curRequests, entry)
    self.lastReceivedEntry = entry
    self:ASInvoke("handleGaqAddItem", entry)
  end
  function Gaq:SetSelectedGaqId(id)
    if GameActionQueue.Select then
      GameActionQueue.Select(id)
    end
  end
  function Gaq:DumpCurrentRequests()
    local i
    local total = #Gaq.curRequests
    for i = 1, total do
      entry = Gaq.curRequests[i]
      print("GAQ request: " .. tostring(entry.id) .. ", " .. tostring(entry.title) .. ", " .. tostring(entry.msg))
    end
  end
  function Gaq:Decline(gaqId)
    GameActionQueue.Respond(tonumber(gaqId), 1)
    self:RemoveGaqItemById(gaqId)
  end
  function Gaq:Accept(gaqId)
    GameActionQueue.Respond(tonumber(gaqId), 0)
    self:RemoveGaqItemById(gaqId)
  end
end)()
;(function()
  SettingsHandler = inheritsFrom(FullScreenUiHandlerBase)
  SettingsHandler:SetUiProperties("Main.wndSettings", "swfSettings", "UI\\Settings.swf", "SettingsHandler", UiZLayers.MODAL_WINDOW)
  SettingsHandler.isAS3 = true
  SettingsHandler.isDebugOn = false
  SettingsHandler.pageTitle = Ui.GetString("UI.Settings")
  function SettingsHandler:OnResize()
    MaximizeWin(self)
    self:superClass().OnResize(self)
  end
  function SettingsHandler:Hide()
    self:superClass().Hide(self)
  end
  function SettingsHandler:Show()
    self:superClass().Show(self)
    Ui.ShowCursor()
  end
end)()
;(function()
  MarketplaceHandler = inheritsFrom(FullScreenUiHandlerBase)
  MarketplaceHandler:SetUiProperties("Main.wndMarketplace", "swfMarketplace", "UI\\Marketplace.swf", "MarketplaceHandler", UiZLayers.MODAL_WINDOW)
  LUABroadcaster:addListener(Gaq, Gaq.EVENT_ADD_ITEM, "HandleGaqAddItem", MarketplaceHandler)
  MarketplaceHandler.isAS3 = true
  MarketplaceHandler.isDebugOn = false
  MarketplaceHandler.isShown = false
  MarketplaceHandler.registeredHandlers = {}
  MarketplaceHandler.CATEGORY_IMPLANTS = 23
  MarketplaceHandler.CATEGORY_INFANTRY_WEAPONS = 2
  MarketplaceHandler.CATEGORY_INFANTRY_CUSTOMIZATION = 25
  MarketplaceHandler.CATEGORY_VEHICLE_WEAPONS = 3
  MarketplaceHandler.CATEGORY_VEHICLE_CUSTOMIZATION = 27
  MarketplaceHandler.CATEGORY_KEYS = 1
  MarketplaceHandler.CATEGORY_TICKETS = 2
  MarketplaceHandler.CATEGORY_BUNDLES = 3
  MarketplaceEvents = {
    ON_ORDER_RESPONSE = "OnOrderResponse"
  }
  MarketplaceHandler.CurrencyIds = {
    STATION_CASH = 7000,
    SEVEN_CASH = 7001,
    RUBLE = 7002,
    SKILL_POINTS = 10,
    RESOURCE_AURAXIUM = 1,
    RESOURCE_AEROSPACE = 2,
    RESOURCE_MECHANIZED = 3,
    RESOURCE_INFANTRY = 4
  }
  MarketplaceHandler.Referrers = {UI = 0}
  MarketplaceHandler.ReferrerContexts = {
    MarketplaceMainScreen = 1,
    MarketplaceCategoryList = 2,
    MarketplaceSearchList = 3,
    MarketplaceHomePage = 4,
    MarketplaceBillboard = 5,
    MarketplaceNavAddStationCashButton = 6,
    MarketplaceNavBecomeAMemberButton = 7,
    MarketplaceAddStationCashScreen = 8,
    MarketplaceBundlePreviewScreen = 9,
    MarketplaceBundlePurchaseScreen = 10,
    EscapeMenuMarketplaceButton = 11,
    Hud = 12,
    SocialScreen = 13,
    CharacterLoadoutScreen = 14,
    VehicleLoadoutScreen = 15,
    SkillScreen = 16,
    ProfileScreen = 17,
    GAQ = 18
  }
  MarketplaceHandler.ScreenInfo = {
    Main = {id = 1, referrerContext = -1},
    StationCashPurchase = {
      id = 2,
      referrerContext = MarketplaceHandler.ReferrerContexts.MarketplaceAddStationCashScreen
    },
    MembershipPurchase = {id = 3, referrerContext = -1},
    BundlePreview = {
      id = 4,
      referrerContext = MarketplaceHandler.ReferrerContexts.MarketplaceBundlePreviewScreen
    },
    BundlePurchase = {
      id = 5,
      referrerContext = MarketplaceHandler.ReferrerContexts.MarketplaceBundlePurchaseScreen
    }
  }
  function MarketplaceHandler:Show()
    if MarketplaceHandler.isShown ~= true then
      FullScreenUiHandlerBase.Show(self)
      InGamePurchaseStoreScreen.OnScreenOpen(self.ScreenInfo.Main.id, self.Referrers.UI, self.ReferrerContexts.EscapeMenuMarketplaceButton)
      Ui.ShowCursor()
      MarketplaceHandler.isShown = true
    end
  end
  function MarketplaceHandler:Hide()
    if MarketplaceHandler.isShown == true then
      FullScreenUiHandlerBase.Hide(self)
      InGamePurchaseStoreScreen.OnScreenClose(self.ScreenInfo.Main.id)
      MarketplaceHandler.isShown = false
    end
  end
  function MarketplaceHandler:OnResize()
    MaximizeWin(self)
    FullScreenUiHandlerBase.OnResize(self)
  end
  function MarketplaceHandler:ASInvoke(func, ...)
    for tableName, handler in pairs(self.registeredHandlers) do
      if handler then
        handler:ASInvoke(func, ...)
      end
    end
    if self.isShown then
      FullScreenUiHandlerBase.ASInvoke(self, func, ...)
    end
  end
  function MarketplaceHandler:RegisterUiHandler(handler)
    self.registeredHandlers[tostring(handler)] = handler
  end
  function MarketplaceHandler:UnregisterUiHandler(handler)
    self.registeredHandlers[tostring(handler)] = nil
  end
  function MarketplaceHandler:IsPurchasingEnabled()
    return true
  end
  function MarketplaceHandler:IsOneClickItemPurchaseEnabled()
    return false
  end
  function MarketplaceHandler:EnableOneClickItemPurchase(result)
    Ui.SetUserOptionsValue("UI", "MarketplaceOneClickItemPurchase", result)
    Ui.SaveUserOptions()
  end
  function MarketplaceHandler:SelectCategory(categoryId)
    self:ASInvoke("selectCategory", categoryId)
  end
  function MarketplaceHandler:SelectImplantsCategory()
    self:SelectCategory(self.CATEGORY_IMPLANTS)
  end
  function MarketplaceHandler:SelectKeysCategory()
    self:SelectCategory(self.CATEGORY_KEYS)
  end
  function MarketplaceHandler:SelectTicketsCategory()
    self:SelectCategory(self.CATEGORY_TICKETS)
  end
  function MarketplaceHandler:SelectBundlesCategory()
    self:SelectCategory(self.CATEGORY_BUNDLES)
  end
  function MarketplaceHandler:GetItemCategories()
    local ds = DsTree.Find("InGamePurchase.StoreBundleCategories")
    local node = ds:GetRootNode()
    if node then
      local dataCount = node:GetDataCount()
      local childCount = node:GetChildCount()
      local i
      local s = ""
      for i = 0, childCount - 1 do
        local child = node:GetChildNode(i)
        local catText = child:GetText()
        local catIcon = child:GetBitmapIndex()
        local catId = child:GetData(0)
        s = s .. tostring(catId) .. "|" .. tostring(catText) .. "|" .. tostring(catIcon)
        if i < childCount - 1 then
          s = s .. "~"
        end
      end
      return s
    end
    return ""
  end
  function MarketplaceHandler:GetBinaryBoolean(value)
    value = tostring(value)
    if value == "1" or value == "true" then
      return 1
    end
    return 0
  end
  function MarketplaceHandler:PlayErrorSound()
  end
  function MarketplaceHandler:PlayActionResultSound(result, id, isMusic)
    if result then
      if isMusic then
        SoundHandler:PlayMusic(id)
      else
        SoundHandler:PlaySoundById(id)
      end
    else
      self:PlayErrorSound()
    end
  end
  CoinStoreHandler = {}
  function CoinStoreHandler:OnBuy(result, resultMessage, itemId, quantity, price, tintId, rentalTermPeriod)
    MarketplaceHandler:DebugPrintVars("OnBuy", result, resultMessage, itemId, quantity, price, tintId, rentalTermPeriod)
    if MarketplaceBundlePurchaseHandler.isShown then
      MarketplaceHandler:OnOrderResponse(result, "", quantity, 0, price, 0, resultMessage, false, rentalTermPeriod, "")
    end
  end
  function MarketplaceHandler:OnOrderPreviewResponse(result, discount, total, resultCode, resultMessage)
    self:DebugPrintVars("OnOrderPreviewResponse", result, discount, total, resultCode, resultMessage)
    self:ASInvoke("onOrderPreviewResponse", self:GetBinaryBoolean(result), discount, total, resultCode, resultMessage)
    if self:GetBinaryBoolean(result) == 0 then
      self:PlayErrorSound()
    end
  end
  function MarketplaceHandler:OnOrderResponse(result, bundleId, quantity, discount, total, resultCode, resultMessage, isWalletCurrency, rentalTermPeriod, orderId)
    self:DebugPrintVars("OnOrderResponse", result, bundleId, quantity, discount, total, resultCode, resultMessage, isWalletCurrency, rentalTermPeriod, orderId)
    self:ASInvoke("onOrderResponse", self:GetBinaryBoolean(result), bundleId, quantity, discount, total, resultCode, tostring(resultMessage), isWalletCurrency, rentalTermPeriod, orderId)
    LUABroadcaster:dispatchEvent(MarketplaceEvents, MarketplaceEvents.ON_ORDER_RESPONSE, result, bundleId, quantity, discount, total, resultCode, resultMessage, isWalletCurrency, rentalTermPeriod, orderId)
    self:PlayActionResultSound(self:GetBinaryBoolean(result) == 1, SoundHandler.sounds.UI_Marketplace_Item_Purchase)
  end
  function MarketplaceHandler:OnSubscriptionPriceList(result)
    self:DebugPrintVars("OnSubscriptionPriceList", result)
    self:ASInvoke("onReceiveMembershipPriceList", result)
    if self:GetBinaryBoolean(result) == 0 then
      self:PlayErrorSound()
    end
  end
  function MarketplaceHandler:OnMembershipPurchasePreviewResponse(result, orderId, isChargeValid, subtotal, tax, vatTax, discount, total, stationCashCredit, legalText, statusString)
    self:DebugPrintVars("OnMembershipPurchasePreviewResponse", result, orderId, isChargeValid, subtotal, tax, vatTax, discount, total, stationCashCredit, legalText, statusString)
    self:ASInvoke("onMembershipPurchasePreviewResponse", result, orderId, isChargeValid, subtotal, tax, vatTax, discount, total, stationCashCredit, legalText, statusString)
    if self:GetBinaryBoolean(result) == 0 then
      self:PlayErrorSound()
    end
  end
  function MarketplaceHandler:OnMembershipPurchasePreviewResponseNextCharge(result, subTotal, total, nextChargeDate, isDiscounted)
    self:DebugPrintVars("OnMembershipPurchasePreviewResponseNextCharge", result, subTotal, total, nextChargeDate, isDiscounted)
    self:ASInvoke("onMembershipPurchasePreviewResponseNextCharge", result, subTotal, total, nextChargeDate, isDiscounted)
    if self:GetBinaryBoolean(result) == 0 then
      self:PlayErrorSound()
    end
  end
  function MarketplaceHandler:OnMembershipPurchaseComplete(result, orderId, isChargeValid, subtotal, tax, vatTax, discount, total, stationCashCredit, statusString)
    self:DebugPrintVars("OnMembershipPurchaseComplete", result, orderId, isChargeValid, subtotal, tax, vatTax, discount, total, stationCashCredit, statusString)
    self:ASInvoke("onMembershipPurchaseComplete", result, orderId, isChargeValid, subtotal, tax, vatTax, discount, total, stationCashCredit, statusString)
    self:PlayActionResultSound(self:GetBinaryBoolean(result) == 1, SoundHandler.music.UI_Marketplace_Membership_Grant_Success, true)
    self:PlayActionResultSound(self:GetBinaryBoolean(result) == 1, SoundHandler.sounds.UI_Marketplace_Membership_Grant)
  end
  function MarketplaceHandler:OnAddCreditCard(result, paymentSourceId, statusString)
    self:DebugPrintVars("OnAddCreditCard", result, paymentSourceId, statusString)
    self:ASInvoke("onAddCreditCard", result, paymentSourceId, statusString)
    self:PlayActionResultSound(self:GetBinaryBoolean(result) == 1, SoundHandler.sounds.UI_Marketplace_CreditCard_Add)
  end
  function MarketplaceHandler:OnDeleteCreditCard(result, paymentSourceId, statusString)
    self:DebugPrintVars("OnDeleteCreditCard", result, paymentSourceId)
    self:ASInvoke("onDeleteCreditCard", result, paymentSourceId, statusString)
    self:PlayActionResultSound(self:GetBinaryBoolean(result) == 1, SoundHandler.sounds.UI_Marketplace_CreditCard_Delete)
  end
  function MarketplaceHandler:OnPaymentSourcesAvailable(result, statusString)
    self:DebugPrintVars("OnPaymentSourcesAvailable", result, statusString)
    self:ASInvoke("onPaymentSourcesAvailable", result, statusString)
    if self:GetBinaryBoolean(result) == 0 then
      self:PlayErrorSound()
    end
  end
  function MarketplaceHandler:OnUpdatedAcceptedCreditCards(result, acceptedCreditCardTypesCount)
    self:DebugPrintVars("OnUpdatedAcceptedCreditCards", result, acceptedCreditCardTypesCount)
    self:ASInvoke("onUpdatedAcceptedCreditCards", result, acceptedCreditCardTypesCount)
    if self:GetBinaryBoolean(result) == 0 then
      self:PlayErrorSound()
    end
  end
  function MarketplaceHandler:OnReceiveStationCashPriceList(result)
    self:DebugPrintVars("OnReceiveStationCashPriceList", result)
    self:ASInvoke("onReceiveStationCashPriceList", result)
  end
  function MarketplaceHandler:OnWalletFundPreview(result, orderId, price, prePromotionPrice, tax, vatTax, total, legalText, prePromotionStationCashAmount, stationCashAmount, isStationCashPromotionActive, isPricePromotionActive, statusString)
    self:DebugPrintVars("onFundWalletPreview", result, orderId, price, prePromotionPrice, tax, vatTax, total, legalText, prePromotionStationCashAmount, stationCashAmount, isStationCashPromotionActive, isPricePromotionActive, statusString)
    self:ASInvoke("onFundWalletPreview", result, orderId, price, prePromotionPrice, tax, vatTax, total, legalText, prePromotionStationCashAmount, stationCashAmount, isStationCashPromotionActive, isPricePromotionActive, statusString)
    if self:GetBinaryBoolean(result) == 0 then
      self:PlayErrorSound()
    end
  end
  function MarketplaceHandler:OnFundWalletComplete(result, orderId, price, prePromotionPrice, tax, vatTax, total, purchaseLegalText, purchasePromotionalText, prePromotionStationCashAmount, stationCashAmount, isStationCashPromotionActive, isPricePromotionActive, walletBalance, statusString)
    self:DebugPrintVars("OnFundWalletComplete", result, orderId, price, prePromotionPrice, tax, vatTax, total, purchaseLegalText, purchasePromotionalText, prePromotionStationCashAmount, stationCashAmount, isStationCashPromotionActive, isPricePromotionActive, walletBalance, statusString)
    self:ASInvoke("onFundWalletComplete", result, orderId, price, prePromotionPrice, tax, vatTax, total, purchaseLegalText, purchasePromotionalText, prePromotionStationCashAmount, stationCashAmount, isStationCashPromotionActive, isPricePromotionActive, walletBalance, statusString)
    self:PlayActionResultSound(self:GetBinaryBoolean(result) == 1, SoundHandler.sounds.UI_Marketplace_Item_Purchase)
  end
  PromotionsHandler = {}
  function PromotionsHandler:OnCodeRedemption(result, status, shortTermsAndConditions, longTermsAndConditions, hasRedirectedToWeb)
    MarketplaceHandler:ASInvoke("onCodeRedemptionResponse", result, status, shortTermsAndConditions, longTermsAndConditions, hasRedirectedToWeb)
    if hasRedirectedToWeb ~= 1 then
      MarketplaceHandler:PlayActionResultSound(MarketplaceHandler:GetBinaryBoolean(result) == 1, SoundHandler.sounds.UI_Promo_Code_Redemption)
    end
  end
  function PromotionsHandler:OnKeyCodeAwardReceived()
  end
  function MarketplaceHandler:OnUpdatedStoreBundle(storeId, bundleId)
    self:ASInvoke("onUpdatedStoreBundle", tonumber(bundleId))
  end
  function MarketplaceHandler:OnWalletInfo(result, t, balance)
    self:ASInvoke("onWalletInfo", self:GetBinaryBoolean(result), balance)
  end
  function MarketplaceHandler:HandleGaqAddItem(type, msg, gaqId, param1, param2, param3, param4)
    if type == Gaq.TYPE_ITEM_CLAIM then
      self:ASInvoke("onCodeRedemptionItemClaimAvailable")
    end
  end
  function MarketplaceHandler:OnFinalizeThirdPartyOrderTransaction()
    NotificationHandler:ShowGeneralNotification(Ui.GetString("UI.Marketplace.SteamWalletTransactionSuccessful"), nil, nil, true)
    self:PlayActionResultSound(self:GetBinaryBoolean(result) == 1, SoundHandler.sounds.UI_StationCash_Increase)
    self:PlayActionResultSound(self:GetBinaryBoolean(result) == 1, SoundHandler.music.UI_Marketplace_StationCash_Grant_Success, true)
  end
  function MarketplaceHandler:OnPaymentPageLoaded(result)
    if result == 0 then
      NotificationHandler:ErrorMessage(0, Ui.GetString("UI.Marketplace.UnableToLoadPageRightNow"))
      self:PlayErrorSound()
    end
  end
  Client.MarketplaceHandler = "MarketplaceHandler"
  Client.HandlerCoinStore = "CoinStoreHandler"
  Client.HandlerPromotions = "PromotionsHandler"
end)()
;(function()
  DataSourceConnection = {}
  DataSourceConnection.s_dsColumnNameHash = {}
  DataSourceConnection.isDebugOn = false
  function DataSourceConnection:GetRowCount(dsName)
    local ds = DsTable.Find(dsName)
    if not ds then
      return "Error: DsTable.Find( " .. tostring(dsName) .. " )"
    end
    return ds:GetRowCount()
  end
  function DataSourceConnection:GetColumnCount(dsName)
    local ds = DsTable.Find(dsName)
    if not ds then
      return "Error: DsTable.Find( " .. tostring(dsName) .. " )"
    end
    return ds:GetColumnCount()
  end
  function DataSourceConnection:GetData(dsName, row, column)
    local ds = DsTable.Find(dsName)
    if not ds then
      return "Error: DsTable.Find( " .. tostring(dsName) .. " )"
    end
    return ds:GetData(tonumber(row), tonumber(column))
  end
  function DataSourceConnection:GetDataByColumnName(dsName, rowIndex, columnName)
    local colIndex = self:GetColumnByName(dsName, columnName)
    return self:GetData(dsName, rowIndex, colIndex)
  end
  function DataSourceConnection:GetColumnByName(dsName, columnName)
    local ds = DsTable.Find(dsName)
    if not ds then
      return "Error: DsTable.Find( " .. tostring(dsName) .. " )"
    end
    if not DataSourceConnection.s_dsColumnNameHash[dsName] then
      DataSourceConnection.s_dsColumnNameHash[dsName] = {}
      for c = 0, ds:GetColumnCount() - 1 do
        DataSourceConnection.s_dsColumnNameHash[dsName][ds:GetColumnName(c)] = c
      end
    end
    return DataSourceConnection.s_dsColumnNameHash[dsName][columnName]
  end
  function DataSourceConnection:GetItemDefinitionIndex(defID)
    return InventoryScreen.GetItemDefinitionIndex(tonumber(defID))
  end
  function DataSourceConnection:GetItemIndexByColumn(dsName, column, value)
    local ds = DsTable.Find(dsName)
    if not ds then
      return "Error: DsTable.Find( " .. tostring(dsName) .. " )"
    end
    local index = -1
    for i = 0, ds:GetRowCount() - 1 do
      if ds:GetData(i, column) == value then
        index = i
        break
      end
    end
    return index
  end
  function DataSourceConnection:GetRowAsTable(dsName, row)
    local ds = DsTable.Find(dsName)
    local rowData
    if ds and row < ds:GetRowCount() then
      rowData = {}
      local columnCount = ds:GetColumnCount()
      for column = 0, columnCount - 1 do
        rowData[ds:GetColumnName(column)] = ds:GetData(row, column)
      end
    end
    return rowData
  end
  function DataSourceConnection:GetItemAsTableById(itemDefId)
    local dsName = "BaseClient.AllItemDefinitions"
    local row = InventoryScreen.GetItemDefinitionIndex(tonumber(itemDefId))
    return self:GetRowAsTable(dsName, row)
  end
  function DataSourceConnection:DumpRowData(dsName, row)
    local ds = DsTable.Find(dsName)
    if not ds then
      return "Error: DsTable.Find( " .. tostring(dsName) .. " )"
    end
    print(">> dsName " .. tostring(dsName))
    for i = 0, ds:GetRowCount() - 1 do
      if i == tonumber(row) then
        print("\t>> Row " .. tostring(i))
        for c = 0, ds:GetColumnCount() - 1 do
          print("\t\t>> Column[ " .. tostring(c) .. " ]: " .. tostring(ds:GetColumnName(c)) .. " = " .. tostring(ds:GetData(i, c)))
        end
      end
    end
  end
  function DataSourceConnection:GetColumnName(dsName, index)
    local ds = DsTable.Find(dsName)
    index = tonumber(index)
    if ds then
      local val = ds:GetColumnName(index)
      return val
    end
  end
  function DataSourceConnection:DumpItemDefinitionData(defID)
    local index = DataSourceConnection:GetItemDefinitionIndex(defID)
    DataSourceConnection:DumpRowData("BaseClient.AllItemDefinitions", index)
  end
  function DataSourceConnection:print(msg)
    UiHandlerBase.print(self, msg)
  end
end)()
;(function()
  ConfirmationHandler = inheritsFrom(ModalUiHandlerBase)
  ConfirmationHandler:SetUiProperties("Main.wndConfirmation", "swfConfirmation", "UI\\ConfirmationDialog.swf", "ConfirmationHandler", UiZLayers.NOTIFICATION)
  ConfirmationHandler.curCallbackScope = nil
  ConfirmationHandler.curCallbackFuncAccept = nil
  ConfirmationHandler.curCallbackFuncDecline = nil
  ConfirmationHandler.clearContextOnShow = false
  ConfirmationHandler.isDebugOn = true
  ConfirmationHandler.lockContextOnShow = true
  ConfirmationHandler.isAS3 = true
  ConfirmationHandler.playerHasResponded = false
  function ConfirmationHandler:OnResize()
    MaximizeWin(self)
    self:superClass().OnResize(self)
  end
  function ConfirmationHandler:Show(title, msg, iconId, callbackScope, callbackFuncAccept, callbackFuncDecline, isLuaCallback, ...)
    self.curCallbackScope = tostring(callbackScope)
    self.curCallbackFuncAccept = tostring(callbackFuncAccept)
    self.curCallbackFuncDecline = tostring(callbackFuncDecline)
    self.isLuaCallback = tonumber(isLuaCallback)
    self.curCallbackParams = arg
    self.playerHasResponded = false
    ModalUiHandlerBase.Show(self)
    self:ASInvoke("setConfirmationType", 1)
    self:ASInvoke("setMessage", title, msg, 2)
  end
  function ConfirmationHandler:ShowOkMessage(title, msg, iconId, callbackScope, callbackFuncAccept, isLuaCallback, ...)
    self.curCallbackScope = tostring(callbackScope)
    self.curCallbackFuncAccept = tostring(callbackFuncAccept)
    self.curCallbackFuncDecline = ""
    self.isLuaCallback = tonumber(isLuaCallback)
    self.curCallbackParams = arg
    ModalUiHandlerBase.Show(self)
    self:ASInvoke("setConfirmationType", 1)
    self:ASInvoke("setMessage", title, msg, 1)
  end
  function ConfirmationHandler:ShowDeleteMessage(title, msg, iconId, callbackScope, callbackFuncAccept, isLuaCallback, name, guid, ...)
    self.curCallbackScope = tostring(callbackScope)
    self.curCallbackFuncAccept = tostring(callbackFuncAccept)
    self.curCallbackFuncDecline = ""
    self.isLuaCallback = tonumber(isLuaCallback)
    self.curCallbackParams = arg
    self.playerHasResponded = false
    ModalUiHandlerBase.Show(self)
    self:ASInvoke("setArgs", name, guid)
    self:ASInvoke("setMessage", title, msg)
  end
  function ConfirmationHandler:ShowOverrideBoostMessage(oldImplantIndex, newImplantIndex, ...)
    self.curCallbackScope = "Implants"
    self.curCallbackFuncAccept = "SelectImplant"
    self.curCallbackFuncDecline = ""
    self.isLuaCallback = 0
    self.curCallbackParams = arg
    self.playerHasResponded = false
    ModalUiHandlerBase.Show(self)
    self:ASInvoke("setConfirmationType", 3)
    self:ASInvoke("setArgs", oldImplantIndex, newImplantIndex)
  end
  function ConfirmationHandler:ShowNameChangeMessage()
    self.curCallbackScope = nil
    self.playerHasResponded = false
    ModalUiHandlerBase.Show(self)
    self:ASInvoke("setConfirmationType", 4)
    self:ASInvoke("setArgs", "1", "1")
    self:ASInvoke("setMessage", "Name Change", "Please Enter New Name", 2)
  end
  function ConfirmationHandler:ShowCaisWarningMessage(msg)
    self.curCallbackScope = nil
    self.playerHasResponded = false
    ModalUiHandlerBase.Show(self)
    self:ASInvoke("setConfirmationType", 5)
    self:ASInvoke("setMessage", Ui.GetString("UI.AntiIndulgenceWarning"), msg, 2)
  end
  function ConfirmationHandler:OnPlayerRespond(accept)
    accept = tostring(accept)
    self.playerHasResponded = true
    local callbackScope = self.curCallbackScope
    local callbackFuncAccept = self.curCallbackFuncAccept
    local callbackFuncDecline = self.curCallbackFuncDecline
    local params = self.curCallbackParams
    local isLuaCallback = self.isLuaCallback
    local scope = _G[callbackScope]
    if scope then
      if accept == "1" then
        if scope[callbackFuncAccept] then
          if isLuaCallback == 1 then
            scope[callbackFuncAccept](scope, unpack(params))
          else
            scope[callbackFuncAccept](unpack(params))
          end
        else
          self:DebugPrint("ERROR: Cannot find method " .. tostring(callbackFuncAccept) .. " on " .. tostring(callbackScope))
        end
      elseif scope[callbackFuncDecline] then
        if isLuaCallback == 1 then
          scope[callbackFuncDecline](scope, unpack(params))
        else
          scope[callbackFuncDecline](unpack(params))
        end
      elseif callbackFuncDecline ~= nil and callbackFuncDecline ~= "" then
        self:DebugPrint("ERROR: Cannot find method " .. tostring(callbackFuncDecline) .. " on " .. tostring(callbackScope))
      end
    else
      self:DebugPrint("ERROR: Cannot find scope " .. tostring(callbackScope))
    end
    if self.playerHasResponded == true then
      self.curCallbackScope = nil
      self.curCallbackFuncAccept = nil
      self.curCallbackFuncDecline = nil
      self.curCallbackParams = nil
      ModalUiHandlerBase.Hide(self)
    end
  end
  function ConfirmationHandler:Hide()
    if self.curCallbackScope then
      self:OnPlayerRespond("0", false)
    end
    ModalUiHandlerBase.Hide(self)
  end
  function ConfirmationHandler:OnNameValidationResponse(guid, success, errorCode)
    self:ASInvoke("onNameValidationResponse", guid, success, errorCode)
  end
end)()
;(function()
  LoadingScreenHandler = inheritsFrom(UiHandlerBase)
  LoadingScreenHandler:SetUiProperties("Main.wndLoading", "swfLoading", "UI\\LoadingScreen.swf", "LoadingScreenHandler", UiZLayers.LOADING_SCREEN)
  LoadingScreenHandler.isDebugOn = false
  LoadingScreenHandler.unloadOnHide = true
  LoadingScreenHandler.isAS3 = true
  LoadingScreenHandler.hasShownPromo = false
  LoadingScreenHandler.isInteractive = false
  function LoadingScreenHandler:Show(pageId)
    UiHandlerBase.Show(self)
  end
  function LoadingScreenHandler:HideNow()
    UiHandlerBase.Hide(self)
  end
  function LoadingScreenHandler:Hide()
    if self.isShown then
      self:ASInvoke("triggerExitAnimation")
    end
  end
  function LoadingScreenHandler:ShouldShowPromo()
    local ret = self.hasShownPromo
    self.hasShownPromo = true
    return not ret
  end
  function LoadingScreenHandler:OnResize()
    MaximizeWin(self)
    UiHandlerBase.OnResize(self)
  end
end)()
;(function()
  AppMsgBox = {
    UserOk = nil,
    WindowName = "Main.wndMessage",
    LabelName = "Main.wndMessage.lblLabel",
    stateBlock = false,
    Ok = function(self)
      local W = Window.Find(self.WindowName)
      if W ~= nil then
        SetModalResult(true)
        W:Hide()
        if self.stateBlock then
          self.stateBlock = false
          GfxCtrl.DisableStateBlock()
        end
      end
      if self.UserOk ~= nil then
        self.UserOk()
      end
    end,
    Display = function(self, t, ParamOkFunction)
      self.UserOk = ParamOkFunction
      local W = Window.Find(self.WindowName)
      if W ~= nil then
        if self.stateBlock == false then
          self.stateBlock = true
          GfxCtrl.EnableStateBlock()
        end
        local L = LabelControl.find(self.LabelName)
        if L ~= nil then
          L:setText(t)
        end
        W:Center()
        W:ShowModal()
      end
    end
  }
  function Main_wndMessage_btnOk_OnClick()
    AppMsgBox:Ok()
  end
end)()
;(function()
  HudHandler = inheritsFrom(UiHandlerBase)
  HudHandler:SetUiProperties("Main.wndHud", "swfHud", "UI\\Main.swf", "HudHandler", UiZLayers.HUD)
  LUABroadcaster:addListener(ChatHandler, ChatHandler.EVENT_SET_CHAT_TEXT, "OnSetChatText", HudHandler)
  HudHandler.isAS3 = true
  HudHandler.isDebugOn = false
  HudHandler.unloadOnHide = false
  HudHandler.curChatChannelGroup = ""
  HudHandler.allowInvokesWhenHidden = false
  HudHandler.Notifications = {}
  function HudHandler:DispatchGameEvent(event, ...)
    self:ASInvoke("dispatchGameEvent", event, unpack(arg))
  end
  function HudHandler:ShowInventory()
    self:DispatchGameEvent("ShowInventory")
  end
  function HudHandler:HideInventory()
    self:DispatchGameEvent("HideInventory")
  end
  function HudHandler:ShowSettings()
    self:DispatchGameEvent("ShowSettings")
  end
  function HudHandler:HideSettings()
    self:DispatchGameEvent("HideSettings")
  end
  function HudHandler:ShowEscapeMenu()
    self:DispatchGameEvent("ShowEscapeMenu")
  end
  function HudHandler:HideEscapeMenu()
    self:DispatchGameEvent("HideEscapeMenu")
  end
  function HudHandler:ShowContainer()
    self:DispatchGameEvent("ShowInspectedContainer")
  end
  function HudHandler:HideContainer()
    self:DispatchGameEvent("HideInspectedContainer")
  end
  function HudHandler:ShowLockWindow(isOwner, timeout)
    self:DispatchGameEvent("ShowPermissionLockWindow", isOwner, timeout)
  end
  function HudHandler:HideLockWindow()
    self:DispatchGameEvent("HidePermissionLockWindow")
  end
  function HudHandler:Show()
    UiHandlerBase.Show(self)
    ChatHandler:RegisterUiHandler(self)
  end
  function HudHandler:Hide()
    ChatHandler:UnregisterUiHandler(self)
    UiHandlerBase.Hide(self)
  end
  function HudHandler:OnResize()
    MaximizeWin(self)
    self:superClass().OnResize(self)
  end
  function HudHandler:DebugReset()
    self:Hide()
    self:getSwf():Unload()
    self:Show()
  end
  function HudHandler:DebugAddItems()
    local i
    for i = 100, 122 do
      Ui.ProcessChatCommand("/item add " .. tostring(i))
    end
  end
  function HudHandler:DebugContainers()
    local ds = DsTable.Find("Loadouts.LoadoutSlotContainerDataSource")
    local rowCount = ds:GetRowCount()
    local i
    for i = 0, rowCount - 1 do
      print(ds:GetData(i, 2) .. ", " .. ds:GetData(i, 150) .. ", " .. ds:GetData(i, 151))
    end
  end
  function HudHandler:OnSetChatText(msg)
    self:ASInvoke("setChatInputMessage", msg)
    self:SetFocus()
  end
end)()
;(function()
  HelpHandler = inheritsFrom(ModalUiHandlerBase)
  HelpHandler:SetUiProperties("Main.wndHelpScreen", "swfHelpScreen", "UI\\HelpScreen.swf", "HelpHandler", UiZLayers.HELP_WINDOW)
  HelpHandler.isAS3 = true
  HelpHandler.isDebugOn = false
  function HelpHandler:OnResize()
    MaximizeWin(self)
    self:superClass().OnResize(self)
  end
  function HelpHandler:Show()
    ModalUiHandlerBase.Show(self)
    LUABroadcaster:addListener(Tutorial, Tutorial.EVENT_TUTORIAL_ENDED, "ValidateTutorialState", HelpHandler)
  end
  function HelpHandler:Hide()
    LUABroadcaster:removeListener(Tutorial, Tutorial.EVENT_TUTORIAL_ENDED, "ValidateTutorialState", HelpHandler)
    ModalUiHandlerBase.Hide(self)
  end
  function HelpHandler:ValidateTutorialState()
    self:ASInvoke("validateTutorialState")
  end
  function HelpHandler:OnSubmitBug(cat, subcat, severity, bugText)
    Ui.OnBugReportUiSubmit(cat, subcat, severity, bugText)
  end
  BindCommandToLua("bug", "HelpHandler:Show")
end)()
;(function()
  InGameBrowserHandler = inheritsFrom(UiHandlerBase)
  InGameBrowserHandler:SetUiProperties("Main.wndOnlineHelp", "", "", "OnlineHelpHandler", 252)
  InGameBrowserHandler.isAS3 = true
  InGameBrowserHandler.isDebugOn = false
  InGameBrowserHandler.isReady = false
  InGameBrowserHandler.URI = nil
  InGameBrowserHandler.PAGE_CS_HELP = 1
  InGameBrowserHandler.pageToLoad = nil
  function InGameBrowserHandler:OnResize()
    MaximizeWin(self)
    UiHandlerBase.OnResize(self)
  end
  function InGameBrowserHandler:Show(page)
    self.pageToLoad = page
    OnlineHelpWindow.Load()
  end
  function InGameBrowserHandler:Hide()
    OnlineHelpWindow.Stop()
    UiHandlerBase.Hide(self)
  end
  function InGameBrowserHandler:OnStatus(status)
    if status == 1 then
      UiHandlerBase.Show(self)
      self.isReady = true
      self:SetPage(self.pageToLoad)
    end
  end
  function InGameBrowserHandler:SetPage(pageId)
    if not pageId or pageId == InGameBrowserHandler.PAGE_CS_HELP then
      OnlineHelpWindow.NavigatePetitionUri()
    end
  end
  function InGameBrowserHandler:ShowHelpPage()
    UIStateManager:SetInGameBrowserState(self.PAGE_CS_HELP)
  end
  Client.HandlerOnlineHelpWindow = "InGameBrowserHandler"
end)()
;(function()
  MarketplaceBundlePurchaseHandler = inheritsFrom(MarketplacePopupScreen)
  MarketplaceBundlePurchaseHandler:SetUiProperties("Main.wndMarketplaceBundlePurchase", "swfMarketplaceBundlePurchase", "UI\\MarketplaceBundlePurchase.swf", "MarketplaceBundlePurchaseHandler", UiZLayers.BUNDLE_PURCHASE_WINDOW)
  MarketplaceBundlePurchaseHandler.isDebugOn = false
  MarketplaceBundlePurchaseHandler.clearContextOnShow = false
  MarketplaceBundlePurchaseHandler.lockContextOnShow = false
  MarketplaceBundlePurchaseHandler.isAS3 = true
  MarketplaceBundlePurchaseHandler.logScreenId = MarketplaceHandler.ScreenInfo.BundlePurchase.id
  MarketplaceBundlePurchaseHandler.isShown = false
  function MarketplaceBundlePurchaseHandler:Show(bundleId, referrerContext)
    if MarketplaceBundlePurchaseHandler.isShown ~= true then
      MarketplacePopupScreen.Show(self, referrerContext)
      self:ASInvoke("setBundleId", bundleId)
      MarketplaceBundlePurchaseHandler.isShown = true
    end
  end
  function MarketplaceBundlePurchaseHandler:Hide()
    if MarketplaceBundlePurchaseHandler.isShown == true then
      MarketplacePopupScreen.Hide(self)
      Context:ValidateMouseCursor()
      InGamePurchaseStoreScreen.CancelOrder()
      MarketplaceBundlePurchaseHandler.isShown = false
    end
  end
  function MarketplaceBundlePurchaseHandler:OnItemPurchaseConfirmationAccept()
    self:ASInvoke("onItemPurchaseConfirmationAccept")
  end
end)()
;(function()
  MarketplaceStationCashPurchaseHandler = inheritsFrom(MarketplacePopupScreen)
  MarketplaceStationCashPurchaseHandler:SetUiProperties("Main.wndMarketplaceStationCashPurchase", "swfMarketplaceStationCashPurchase", "UI\\MarketplaceStationCashPurchase.swf", "MarketplaceStationCashPurchaseHandler", UiZLayers.STATION_CASH_PURCHASE_WINDOW)
  MarketplaceStationCashPurchaseHandler.isDebugOn = false
  MarketplaceStationCashPurchaseHandler.clearContextOnShow = false
  MarketplaceStationCashPurchaseHandler.lockContextOnShow = false
  MarketplaceStationCashPurchaseHandler.isAS3 = true
  MarketplaceStationCashPurchaseHandler.logScreenId = MarketplaceHandler.ScreenInfo.StationCashPurchase.id
end)()
;(function()
  MarketplaceMembershipPurchaseHandler = inheritsFrom(MarketplacePopupScreen)
  MarketplaceMembershipPurchaseHandler:SetUiProperties("Main.wndMarketplaceMembershipPurchase", "swfMarketplaceMembershipPurchase", "UI\\MarketplaceMembershipPurchase.swf", "MarketplaceMembershipPurchaseHandler", UiZLayers.STATION_CASH_PURCHASE_WINDOW)
  MarketplaceMembershipPurchaseHandler.isDebugOn = false
  MarketplaceMembershipPurchaseHandler.clearContextOnShow = false
  MarketplaceMembershipPurchaseHandler.lockContextOnShow = false
  MarketplaceMembershipPurchaseHandler.isAS3 = true
  MarketplaceMembershipPurchaseHandler.logScreenId = MarketplaceHandler.ScreenInfo.MembershipPurchase.id
end)()
;(function()
  MarketplaceBundlePreviewHandler = inheritsFrom(MarketplacePopupScreen)
  MarketplaceBundlePreviewHandler:SetUiProperties("Main.wndMarketplaceBundlePreview", "swfMarketplaceBundlePreview", "UI\\MarketplaceBundlePreview.swf", "MarketplaceBundlePreviewHandler", UiZLayers.BUNDLE_PURCHASE_WINDOW)
  MarketplaceBundlePreviewHandler.isDebugOn = false
  MarketplaceBundlePreviewHandler.clearContextOnShow = false
  MarketplaceBundlePreviewHandler.lockContextOnShow = false
  MarketplaceBundlePreviewHandler.isAS3 = true
  MarketplaceBundlePreviewHandler.logScreenId = MarketplaceHandler.ScreenInfo.BundlePreview.id
  function MarketplaceBundlePreviewHandler:Show(bundleId, itemId, itemName, imageSetId, hasGuiModel, referrerContext)
    InGamePurchaseStoreScreen.OnStoreBundlePreview(1, bundleId)
    InGamePurchaseStoreScreen.SetActiveBundleId(bundleId)
    MarketplacePopupScreen.Show(self, referrerContext)
    self:ASInvoke("setOverrideItemId", itemId, itemName, imageSetId, hasGuiModel)
  end
  function MarketplaceBundlePreviewHandler:Hide()
    MarketplacePopupScreen.Hide(self)
    Context:ValidateMouseCursor()
  end
end)()
;(function()
  InGameBrowserHandler = inheritsFrom(ModalUiHandlerBase)
  InGameBrowserHandler:SetUiProperties("Main.wndInGameBrowser", "swfInGameBrowser", "UI\\InGameBrowser.swf", "InGameBrowserHandler", UiZLayers.INGAME_BROWSER)
  InGameBrowserHandler.isDebugOn = true
  InGameBrowserHandler.isAS3 = true
  InGameBrowserHandler.browser = nil
  InGameBrowserHandler.clearContextOnShow = false
  InGameBrowserHandler.isLoading = false
  InGameBrowserHandler.hitTestMethod = Constants.HitTestTypes.BOUNDS
  InGameBrowserHandler.MODE_CS_PETITION = 1
  InGameBrowserHandler.MODE_MARKETPLACE_TOPUP = 2
  InGameBrowserHandler.MODE_MARKETPLACE_SMS = 3
  InGameBrowserHandler.MODE_MARKETPLACE_PAYPAL = 4
  function InGameBrowserHandler:OnResize()
    local wnd = Window.Find(self.wndName)
    local swf = GfxCtrl.Find(self.swfName)
    local sw, sh = Window.GetCanvasSize()
    if wnd then
      wnd:SetProperty("X", 0)
      wnd:SetProperty("Y", 0)
      wnd:SetProperty("Width", sw)
      wnd:SetProperty("Height", sh)
    end
    if swf then
      swf:SetProperty("X", 0)
      swf:SetProperty("Y", 0)
      swf:SetProperty("Width", sw)
      swf:SetProperty("Height", sh)
    end
    self:superClass().OnResize(self)
  end
  function InGameBrowserHandler:Hide()
    if self.browser then
      self.browser.Destroy(self.swfName)
    end
    self.browser = nil
    if Browser.OnHide then
      Browser.OnHide(self.swfName)
    end
    self:superClass().Hide(self)
  end
  function InGameBrowserHandler:Show(url)
    if self.browser then
      self.browser:LoadUrl(self.swfName, url)
    else
      self.pendingUrl = url
    end
    self:superClass().Show(self)
  end
  function InGameBrowserHandler:ShowHelpPage()
    if Ui.OpenSupportUrl then
      Ui.OpenSupportUrl()
    end
  end
  function InGameBrowserHandler:OnSwfLoadComplete()
    if not self.browser then
      self.browser = Browser.Create("SecureCommerce", "Main.wndInGameBrowser.swfInGameBrowser", "BrowserRenderTarget", self.wndName, "www.google.com", 1024, 768)
      self.browser:EnableRenderOnPageLoad(true)
    end
    if self.pendingUrl then
      self.browser.LoadUrl(self.swfName, self.pendingUrl)
      self.pendingUrl = nil
    end
    if Browser.OnShow then
      Browser.OnShow(self.swfName)
    end
  end
  function InGameBrowserHandler:OnMouseEvent(event, localX, localY, modifiers, offset)
    if self.browser then
      self.browser.OnMouseEvent(self.swfName, event, localX, localY, modifiers, offset * 20)
    end
  end
  function InGameBrowserHandler:OnKeyEvent(event, keyCode, charCode, modifiers)
    if self.browser then
      self.browser.OnKeyEvent(self.swfName, event, keyCode, charCode, modifiers)
    end
  end
  function InGameBrowserHandler:OnFocusEvent(event)
    if self.browser then
      self.browser.OnFocusEvent(self.wndName, event)
    end
  end
  function InGameBrowserHandler:OnUrlChange(url)
    self:ASInvoke("handleBrowserUrlChange", url)
  end
  function InGameBrowserHandler:OnStateChange(values)
    if self.browser and self.isLoading and not values.isLoading then
      self.browser.EnableRenderOnPageLoad(self.swfName, false)
    end
    self.isLoading = values.isLoading
    self:ASInvoke("handleBrowserStateChange", values)
  end
  function InGameBrowserHandler:NavigateToUrl(url)
    if self.browser then
      self.browser.LoadUrl(self.swfName, url)
    end
  end
  function InGameBrowserHandler:NavigateToNextPage()
    if self.browser then
      self.browser.Forward(self.swfName)
    end
  end
  function InGameBrowserHandler:NavigateToPreviousPage()
    if self.browser then
      self.browser.Back(self.swfName)
    end
  end
  function InGameBrowserHandler:RefreshPage()
    if self.browser then
      self.browser.Refresh(self.swfName)
    end
  end
  function InGameBrowserHandler:StopPageLoading()
    if self.browser then
      self.browser.Stop(self.swfName)
    end
  end
  function InGameBrowserHandler:SetRenderSize(width, height)
    if self.browser then
      self.browser.SetRenderSize(self.swfName, width, height)
    end
  end
  function InGameBrowserHandler:OnShowPopupMenu(data)
    self:ASInvoke("handleBrowserShowPopupMenu", data)
  end
  function InGameBrowserHandler:OnSelectPopupMenuItem(index)
    if self.browser then
      self.browser.DidSelectPopupMenuItem(self.swfName, index)
    end
  end
  function InGameBrowserHandler:OnCancelPopupMenu()
    if self.browser then
      self.browser.DidCancelPopupMenu(self.swfName)
    end
  end
end)()
;(function()
  CharacterSelectHandler = inheritsFrom(FullScreenUiHandlerBase)
  CharacterSelectHandler:SetUiProperties("Main.wndCharacterSelect", "swfCharacterSelect", "UI\\characterselect.swf", "CharacterSelectHandler", UiZLayers.MODAL_WINDOW)
  CharacterSelectHandler.isAS3 = true
  CharacterSelectHandler.isDebugOn = false
  CharacterSelectHandler.pageTitle = Ui.GetString("UI.CharacterSelect")
  CharacterSelectHandler.isShown = false
  function CharacterSelectHandler:OnResize()
    MaximizeWin(self)
    self:superClass().OnResize(self)
  end
  function CharacterSelectHandler:Hide()
    self:superClass().Hide(self)
    CharacterSelectHandler.isShown = false
  end
  function CharacterSelectHandler:Show()
    HudHandler:Hide()
    SettingsHandler:Hide()
    self:superClass().Show(self)
    Ui.ShowCursor()
    CharacterSelectHandler.isShown = true
  end
  function CharacterSelectHandler:DispatchGameEvent(eventName, ...)
    print("dispatch game event: " .. tostring(eventName))
    self:ASInvoke("dispatchGameEvent", eventName, unpack(arg))
  end
  function CharacterSelectHandler:OnCharacterCreate(success, guid, result)
    if success then
      CharacterSelect.SetCharacter(tostring(guid))
      CharacterSelect.EnterGame()
    else
      self:DispatchGameEvent("onCharacterCreateFailed", result, guid)
    end
  end
  function CharacterSelectHandler:OnCharacterLogin(success, result)
    self:DispatchGameEvent("onCharacterLogin", success, result)
  end
  function CharacterSelectHandler:OnCharacterLoginComplete()
    self:Hide()
  end
  function CharacterSelectHandler:OnCharacterNameValidation(success, result)
    self:DispatchGameEvent("onNameValidationResponse", success, result)
  end
  function CharacterSelectHandler:OnForcedDisconnect()
    GameEvents:OnDisconnected()
  end
  function CharacterSelectHandler:OnCharacterDelete(success)
    print("on char delete: " .. tostring(success))
    self:DispatchGameEvent("onCharacterDelete", success)
  end
  function CharacterSelectHandler:RequestCharacterDelete(playerName, guid)
    local msg = "Are you sure you want to delete the character " .. playerName .. "?"
    ConfirmationHandler:ShowDeleteMessage("Delete Character", msg, 0, "CharacterSelect", "DeleteCharacter", "", playerName, guid, guid)
  end
end)()
