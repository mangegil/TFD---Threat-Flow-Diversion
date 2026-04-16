Scriptname TFDPlayerSaviorBridge extends Quest

ReferenceAlias Property Savior Auto

Bool Property AllowAutoPackageEval = True Auto
Bool Property ClearOnPlayerLoad = True Auto
Int Property RescueWakeStage = -1 Auto
Float Property ReevalDelayA = 0.20 Auto
Float Property ReevalDelayB = 0.75 Auto
Float Property ClearDelayAfterDialogue = 0.20 Auto
Float Property DialoguePollInterval = 0.25 Auto
Float Property SaviorForceClearTimeout = 15.00 Auto

Bool _initialized = False
Actor _pendingSavior = None
Int _pendingReevalPass = 0

Bool _awaitingSaviorDialogue = False
Bool _saviorDialogueSeen = False
Float _saviorAssignRealTime = 0.0

Function RegisterEvents()
	UnregisterForAllModEvents()
	UnregisterForMenu("Dialogue Menu")

	RegisterForModEvent("TFDPlayerSaviorAssign", "OnBridgeEvent")
	RegisterForModEvent("TFDPlayerSaviorClear", "OnBridgeEvent")
	RegisterForModEvent("TFDPlayerSaviorRefresh", "OnBridgeEvent")

	RegisterForMenu("Dialogue Menu")

	TraceDebug("RegisterEvents done")
EndFunction

Event OnInit()
	_initialized = True
	RegisterEvents()
EndEvent

Event OnPlayerLoadGame()
	TraceDebug("OnPlayerLoadGame")
	If ClearOnPlayerLoad
		ClearSavior()
	EndIf
	RegisterEvents()
EndEvent

Function EnsureInit()
	If _initialized
		Return
	EndIf
	_initialized = True
	RegisterEvents()
EndFunction

Event OnBridgeEvent(String eventName, String strArg, Float numArg, Form sender)
	EnsureInit()
	TraceDebug("OnBridgeEvent name=" + eventName + " sender=" + FormLabel(sender))

	If eventName == "TFDPlayerSaviorAssign"
		Actor aAssign = sender as Actor
		If aAssign != None
			AssignSavior(aAssign)
		Else
			TraceDebug("Assign ignored: sender is not Actor")
		EndIf
		Return
	EndIf

	If eventName == "TFDPlayerSaviorClear"
		ClearSavior()
		Return
	EndIf

	If eventName == "TFDPlayerSaviorRefresh"
		RefreshSavior()
		Return
	EndIf

	TraceDebug("Unknown bridge event ignored")
EndEvent

Event OnMenuOpen(String menuName)
	If menuName != "Dialogue Menu"
		Return
	EndIf

	If !_awaitingSaviorDialogue
		Return
	EndIf

	Actor current = GetSavior()
	If current == None
		Return
	EndIf

	_saviorDialogueSeen = True
	TraceDebug("OnMenuOpen Dialogue Menu -> Savior dialogue seen actor=" + ActorLabel(current))
EndEvent

Event OnMenuClose(String menuName)
	If menuName != "Dialogue Menu"
		Return
	EndIf

	If !_awaitingSaviorDialogue
		Return
	EndIf

	If !_saviorDialogueSeen
		TraceDebug("OnMenuClose Dialogue Menu ignored: no savior dialogue seen yet")
		Return
	EndIf

	TraceDebug("OnMenuClose Dialogue Menu -> clear Savior after rescue dialogue")
	Utility.WaitMenuMode(ClearDelayAfterDialogue)
	ClearSavior()
EndEvent

Bool Function AssignSavior(Actor akActor)
	EnsureInit()

	If akActor == None
		TraceDebug("AssignSavior ignored: actor=None")
		Return False
	EndIf

	If akActor.IsDead()
		TraceDebug("AssignSavior ignored: actor dead")
		Return False
	EndIf

	If Savior == None
		TraceDebug("AssignSavior failed: Savior alias=None")
		Return False
	EndIf

	Actor current = Savior.GetActorReference()
	If current != None && current != akActor
		TraceDebug("AssignSavior replacing old=" + ActorLabel(current))
		Savior.Clear()
	EndIf

	Savior.ForceRefTo(akActor)

	If Savior.GetReference() != akActor
		TraceDebug("AssignSavior verify FAILED now=" + FormLabel(Savior.GetReference()))
		Return False
	EndIf

	TraceDebug("AssignSavior success actor=" + ActorLabel(akActor))

	_awaitingSaviorDialogue = True
	_saviorDialogueSeen = False
	_saviorAssignRealTime = Utility.GetCurrentRealTime()

	If RescueWakeStage >= 0
		If GetStage() != RescueWakeStage
			SetStage(RescueWakeStage)
			TraceDebug("AssignSavior SetStage=" + RescueWakeStage)
		EndIf
	EndIf

	PrimeSaviorAI(akActor)

	_pendingSavior = akActor
	_pendingReevalPass = 1
	RegisterForSingleUpdate(ReevalDelayA)

	Return True
EndFunction

Function ClearSavior()
	EnsureInit()

	_pendingSavior = None
	_pendingReevalPass = 0
	_awaitingSaviorDialogue = False
	_saviorDialogueSeen = False
	_saviorAssignRealTime = 0.0

	If Savior == None
		Return
	EndIf

	Actor current = Savior.GetActorReference()
	If current != None
		TraceDebug("ClearSavior actor=" + ActorLabel(current))
	EndIf

	Savior.Clear()
EndFunction

Function RefreshSavior()
	EnsureInit()

	Actor current = GetSavior()
	If current == None
		TraceDebug("RefreshSavior skipped: none")
		Return
	EndIf

	If current.IsDead()
		TraceDebug("RefreshSavior actor dead -> clear")
		ClearSavior()
		Return
	EndIf

	If RescueWakeStage >= 0
		If GetStage() != RescueWakeStage
			SetStage(RescueWakeStage)
			TraceDebug("RefreshSavior SetStage=" + RescueWakeStage)
		EndIf
	EndIf

	PrimeSaviorAI(current)
	TraceDebug("RefreshSavior actor=" + ActorLabel(current))
EndFunction

Event OnUpdate()
	; 1) re-evaluate awal supaya package greet punya kesempatan menang
	If _pendingSavior != None
		If Savior == None
			_pendingSavior = None
			_pendingReevalPass = 0
		Else
			Actor current = Savior.GetActorReference()

			If current == None
				TraceDebug("OnUpdate Savior alias empty")
				_pendingSavior = None
				_pendingReevalPass = 0
			ElseIf current != _pendingSavior
				TraceDebug("OnUpdate pending savior mismatch current=" + ActorLabel(current) + " pending=" + ActorLabel(_pendingSavior))
				_pendingSavior = None
				_pendingReevalPass = 0
			ElseIf current.IsDead()
				TraceDebug("OnUpdate pending savior dead -> clear")
				ClearSavior()
				Return
			Else
				If AllowAutoPackageEval
					current.EvaluatePackage()
					TraceDebug("OnUpdate re-evaluate pass=" + _pendingReevalPass + " actor=" + ActorLabel(current))
				EndIf

				If _pendingReevalPass == 1
					_pendingReevalPass = 2
					RegisterForSingleUpdate(ReevalDelayB)
					Return
				Else
					_pendingSavior = None
					_pendingReevalPass = 0
				EndIf
			EndIf
		EndIf
	EndIf

	; 2) fallback polling, kalau menu events miss tetap bisa clear
	If _awaitingSaviorDialogue
		Actor saviorActor = GetSavior()

		If saviorActor == None
			TraceDebug("OnUpdate awaiting dialogue but Savior alias empty -> clear flags")
			_awaitingSaviorDialogue = False
			_saviorDialogueSeen = False
			_saviorAssignRealTime = 0.0
			Return
		EndIf

		If saviorActor.IsDead()
			TraceDebug("OnUpdate awaiting dialogue savior dead -> clear")
			ClearSavior()
			Return
		EndIf

		Bool dialogueOpen = UI.IsMenuOpen("Dialogue Menu")

		If dialogueOpen
			If !_saviorDialogueSeen
				_saviorDialogueSeen = True
				TraceDebug("OnUpdate polling -> Savior dialogue detected open")
			EndIf
		Else
			If _saviorDialogueSeen
				TraceDebug("OnUpdate polling -> dialogue already seen and now closed, clear Savior")
				ClearSavior()
				Return
			EndIf
		EndIf

		Float elapsed = Utility.GetCurrentRealTime() - _saviorAssignRealTime
		If elapsed >= SaviorForceClearTimeout
			TraceDebug("OnUpdate timeout -> clear Savior elapsed=" + elapsed)
			ClearSavior()
			Return
		EndIf

		RegisterForSingleUpdate(DialoguePollInterval)
		Return
	EndIf
EndEvent

Function PrimeSaviorAI(Actor akActor)
	If akActor == None
		Return
	EndIf

	; Putus agenda lama supaya package Savior/ForceGreet punya peluang menang.
	akActor.StopCombat()
	akActor.StopCombatAlarm()
	akActor.SheatheWeapon()

	If AllowAutoPackageEval
		akActor.EvaluatePackage()
	EndIf
EndFunction

Bool Function HasSavior()
	Return GetSavior() != None
EndFunction

Actor Function GetSavior()
	If Savior == None
		Return None
	EndIf
	Return Savior.GetActorReference()
EndFunction

Bool Function IsSavior(Actor akActor)
	If akActor == None
		Return False
	EndIf

	Actor current = GetSavior()
	If current == None
		Return False
	EndIf

	Return current == akActor
EndFunction

String Function ActorLabel(Actor a)
	If a == None
		Return "None"
	EndIf

	String nameText = a.GetDisplayName()
	If nameText == ""
		nameText = "UnnamedActor"
	EndIf

	Return nameText + "[" + Hex8(a.GetFormID()) + "]"
EndFunction

String Function FormLabel(Form f)
	If f == None
		Return "None"
	EndIf

	Actor a = f as Actor
	If a != None
		Return ActorLabel(a)
	EndIf

	Return "Form[" + Hex8(f.GetFormID()) + "]"
EndFunction

String Function Hex8(Int value)
	Int v = value
	If v < 0
		v = Math.LogicalAnd(v, 0xFFFFFFFF)
	EndIf

	String digits = "0123456789ABCDEF"
	String out = ""
	Int shift = 28

	While shift >= 0
		Int nibble = Math.RightShift(v, shift)
		nibble = Math.LogicalAnd(nibble, 0xF)
		out = out + StringUtil.GetNthChar(digits, nibble)
		shift -= 4
	EndWhile

	Return out
EndFunction

Function TraceDebug(String msg)
	Debug.Trace("[TFDPlayerSaviorBridge] " + msg)
EndFunction