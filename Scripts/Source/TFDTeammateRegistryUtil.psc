Scriptname TFDTeammateRegistryUtil extends Quest

TFDPlayerTeammateQuestScript Property Registry Auto

Function DebugRegisterCrosshair()
	If Registry == None
		Debug.Notification("TFD Registry: Registry property NONE")
		Return
	EndIf

	Actor akActor = Game.GetCurrentCrosshairRef() as Actor
	If akActor == None
		Debug.Notification("TFD Registry: crosshair bukan Actor")
		Return
	EndIf

	Bool ok = Registry.RegisterOrRefreshTeammate(akActor)
	If ok
		Debug.Notification("TFD Registry: actor diregister")
	Else
		Debug.Notification("TFD Registry: register gagal / slot penuh")
	EndIf
EndFunction

Function DebugUnregisterCrosshair()
	If Registry == None
		Debug.Notification("TFD Registry: Registry property NONE")
		Return
	EndIf

	Actor akActor = Game.GetCurrentCrosshairRef() as Actor
	If akActor == None
		Debug.Notification("TFD Registry: crosshair bukan Actor")
		Return
	EndIf

	Bool ok = Registry.UnregisterTeammate(akActor)
	If ok
		Debug.Notification("TFD Registry: actor di-unregister")
	Else
		Debug.Notification("TFD Registry: actor tidak ada di registry")
	EndIf
EndFunction

Function DebugPrintRegistry()
	If Registry == None
		Debug.Notification("TFD Registry: Registry property NONE")
		Return
	EndIf

	Int total = Registry.GetRegisteredCount()
	Int standing = Registry.GetStandingRegisteredCount()
	Int downed = Registry.GetDownedRegisteredCount()

	Debug.Notification("TFD Reg total=" + total + " standing=" + standing + " downed=" + downed)

	Int i = 0
	While i < 10
		Actor akActor = Registry.GetTeammateBySlot(i)
		If akActor != None
			If akActor.IsDead()
				Debug.Trace("TFD Registry Slot " + (i + 1) + ": DEAD")
			ElseIf akActor.IsBleedingOut()
				Debug.Trace("TFD Registry Slot " + (i + 1) + ": BLEEDOUT")
			Else
				Debug.Trace("TFD Registry Slot " + (i + 1) + ": STANDING")
			EndIf
		Else
			Debug.Trace("TFD Registry Slot " + (i + 1) + ": EMPTY")
		EndIf
		i += 1
	EndWhile
EndFunction

Function DebugPrune()
	If Registry == None
		Debug.Notification("TFD Registry: Registry property NONE")
		Return
	EndIf

	Registry.PruneInvalidTeammates()
	Debug.Notification("TFD Registry: prune done")
EndFunction

Function DebugClear()
	If Registry == None
		Debug.Notification("TFD Registry: Registry property NONE")
		Return
	EndIf

	Registry.ClearAllTeammates()
	Debug.Notification("TFD Registry: clear all done")
EndFunction