---------------------------------------------------------------
-- Callback management
---------------------------------------------------------------
-- If information needs to be updated when a variable changes,
-- this handler will run stored functions in response.
-- This extension of CallbackRegistryMixin also allows closures
-- to execute safely after combat.

local _, db = ...;
local CallbackHandler = CreateFrame('Frame', '$parentCallbackHandler', ConsolePort)
Mixin(CallbackHandler, CallbackRegistryMixin, {
	runSafeClosure  = function(f, args) f(unpack(args)) end;
	runSafeClosures = {};
	safeCallback    = function(func, ...)
		if InCombatLockdown() then
			return CallbackHandler:QueueSafeClosure(func, ...)
		end
		return func(...)
	end;
})

CallbackHandler:RegisterEvent('PLAYER_REGEN_ENABLED')
CallbackHandler:SetUndefinedEventsAllowed(true)
CallbackHandler:OnLoad()

-- Run closures after combat
CallbackHandler:SetScript('OnEvent', function(self)
	foreach(self.runSafeClosures, self.runSafeClosure)
	wipe(self.runSafeClosures)
end)

-- Extended API
function CallbackHandler:QueueSafeClosure(func, ...)
	self.runSafeClosures[func] = {...};
end

function CallbackHandler:RegisterSafeCallback(event, ...)
	return self:RegisterCallback(event, self.safeCallback, ...)
end

-- Database access
function db:RegisterSafeCallback(...)
	return CallbackHandler:RegisterSafeCallback(...)
end

function db:RegisterCallback(...)
	return CallbackHandler:RegisterCallback(...)
end

function db:TriggerEvent(...)
	return CallbackHandler:TriggerEvent(...)
end

-- Hook into global events
hooksecurefunc(EventRegistry, 'TriggerEvent', db.TriggerEvent)