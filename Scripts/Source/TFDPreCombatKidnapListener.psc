Scriptname TFDPreCombatKidnapListener extends Quest

Event OnInit()
	RegisterEvents()
EndEvent

Event OnPlayerLoadGame()
	RegisterEvents()
EndEvent

Function RegisterEvents()
	UnregisterForAllModEvents()
	RegisterForModEvent("TFDPreCombatKidnap", "OnPreCombatKidnap")
EndFunction

Event OnPreCombatKidnap(String eventName, String strArg, Float numArg, Form sender)
	Debug.Trace("TFDPreCombatKidnapListener: legacy transition globals removed; native flow owns kidnap transition.")
EndEvent
