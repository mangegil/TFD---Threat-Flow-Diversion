Scriptname TFDInCombatBridge extends Quest

ReferenceAlias Property Speaker Auto

Bool Property AllowAutoPackageEval Auto
Bool Property ClearAllOnPlayerLoadGame = True Auto
Float Property UpdateInterval = 0.25 Auto

Actor currentActor
Bool sawDialogueOpen

Function TraceDebug(String msg)
	Debug.Trace("[TFD][InCombatBridge] " + msg)
EndFunction

String Function Bool01(Bool value)
	If value
		Return "1"
	EndIf
	Return "0"
EndFunction

Float Function DistToPlayer(Actor a)
	Actor p = Game.GetPlayer()
	If a == None || p == None
		Return -1.0
	EndIf
	Return a.GetDistance(p)
EndFunction

Bool Function IsDialogueMenuOpen()
	Return UI.IsMenuOpen("Dialogue Menu") || UI.IsMenuOpen("DialogueMenu")
EndFunction

Function LogActorState(String tag, Actor a)
	If a == None
		TraceDebug(tag + " actor=None")
		Return
	EndIf

	TraceDebug(tag + " actor=" + a + " inCombat=" + Bool01(a.IsInCombat()) + " weaponDrawn=" + Bool01(a.IsWeaponDrawn()) + " loaded=" + Bool01(a.Is3DLoaded()) + " dist=" + DistToPlayer(a))
EndFunction

Function RegisterEvents()
	UnregisterForAllModEvents()
	RegisterForModEvent("TFDInCombatAssign", "OnBridgeEvent")
	RegisterForModEvent("TFDInCombatClear", "OnBridgeEvent")
	RegisterForModEvent("TFDInCombatClearAll", "OnBridgeEvent")
EndFunction

Event OnInit()
	RegisterEvents()
EndEvent

Event OnPlayerLoadGame()
	If ClearAllOnPlayerLoadGame
		ClearAllForLoad()
	Else
		PruneStaleState()
	EndIf
	RegisterEvents()
EndEvent

Event OnBridgeEvent(String eventName, String strArg, Float numArg, Form sender)
	If eventName == "TFDInCombatAssign"
		Actor aAssign = sender as Actor
		If aAssign != None
			AssignActor(aAssign)
		EndIf
		Return
	EndIf

	If eventName == "TFDInCombatClear"
		Actor aClear = sender as Actor
		If aClear != None
			ClearActor(aClear)
		EndIf
		Return
	EndIf

	If eventName == "TFDInCombatClearAll"
		ClearAll()
		Return
	EndIf
EndEvent

Function AssignActor(Actor a)
	If a == None
		TraceDebug("AssignActor actor=None")
		Return
	EndIf

	If a.IsDead()
		TraceDebug("AssignActor actor dead")
		Return
	EndIf

	LogActorState("AssignActor begin", a)

	If currentActor == a
		SetSpeaker(a)
		sawDialogueOpen = False
		EnforceApproachState(a)
		RegisterForSingleUpdate(UpdateInterval)
		Return
	EndIf

	If currentActor != None
		ClearAll()
	EndIf

	SetSpeaker(a)
	currentActor = a
	sawDialogueOpen = False

	EnforceApproachState(a)
	LogActorState("AssignActor after EnforceApproachState", a)
	RegisterForSingleUpdate(UpdateInterval)
EndFunction

Event OnUpdate()
	PruneStaleState()

	If currentActor == None
		TraceDebug("OnUpdate currentActor=None")
		Return
	EndIf

	LogActorState("OnUpdate tick", currentActor)

	If currentActor.IsDead()
		TraceDebug("OnUpdate actor dead -> ClearAll")
		ClearAll()
		Return
	EndIf

	If currentActor.Is3DLoaded()
		If currentActor.IsInCombat()
			TraceDebug("OnUpdate StopCombat actor still in combat")
			currentActor.StopCombat()
			currentActor.StopCombatAlarm()
		EndIf

		If currentActor.IsWeaponDrawn()
			TraceDebug("OnUpdate SheatheWeapon actor still drawn")
			currentActor.SheatheWeapon()
		EndIf

		If AllowAutoPackageEval
			currentActor.EvaluatePackage()
			TraceDebug("OnUpdate EvaluatePackage")
		EndIf
	EndIf

	Bool open = IsDialogueMenuOpen()
	TraceDebug("OnUpdate dialogueOpen=" + Bool01(open))

	If open
		sawDialogueOpen = True
		RegisterForSingleUpdate(UpdateInterval)
		Return
	EndIf

	If sawDialogueOpen
		TraceDebug("OnUpdate sawDialogueOpen then closed -> ClearAll")
		ClearAll()
		Return
	EndIf

	RegisterForSingleUpdate(UpdateInterval)
EndEvent

Function EnforceApproachState(Actor a)
	If a == None
		TraceDebug("EnforceApproachState actor=None")
		Return
	EndIf

	LogActorState("EnforceApproachState before", a)

	If !a.Is3DLoaded()
		Return
	EndIf

	If a.IsInCombat()
		a.StopCombat()
		a.StopCombatAlarm()
	EndIf

	If a.IsWeaponDrawn()
		a.SheatheWeapon()
	EndIf

	If AllowAutoPackageEval
		a.EvaluatePackage()
		TraceDebug("EnforceApproachState EvaluatePackage")
	EndIf

	LogActorState("EnforceApproachState after", a)
EndFunction

Function ClearActor(Actor a)
	If a == None
		TraceDebug("ClearActor actor=None")
		Return
	EndIf

	LogActorState("ClearActor begin", a)

	If Speaker != None && Speaker.GetReference() == a
		Speaker.Clear()
	EndIf

	RestoreNormalAI(a)

	If currentActor == a
		currentActor = None
		sawDialogueOpen = False
	EndIf
EndFunction

Function ClearAll()
	TraceDebug("ClearAll begin")
	Actor a = currentActor

	If a == None
		a = GetSpeakerActor()
	EndIf

	If Speaker != None
		ClearAlias(Speaker)
	EndIf

	RestoreNormalAI(a)
	currentActor = None
	sawDialogueOpen = False
	TraceDebug("ClearAll done")
EndFunction

Function ClearAllForLoad()
	TraceDebug("ClearAllForLoad begin")
	ClearAll()
	TraceDebug("ClearAllForLoad done")
EndFunction

Function RestoreNormalAI(Actor a)
	If a == None
		Return
	EndIf

	LogActorState("RestoreNormalAI before", a)

	If a.Is3DLoaded()
		a.EvaluatePackage()
		TraceDebug("RestoreNormalAI lightweight EvaluatePackage")
	EndIf

	LogActorState("RestoreNormalAI after", a)
EndFunction

Function SetSpeaker(Actor a)
	If Speaker == None
		Return
	EndIf

	If a == None
		If Speaker.GetReference() != None
			Speaker.Clear()
		EndIf
		Return
	EndIf

	If Speaker.GetReference() != a
		Speaker.ForceRefTo(a)
	EndIf
EndFunction

Actor Function GetSpeakerActor()
	If Speaker == None
		Return None
	EndIf
	Actor a = Speaker.GetReference() as Actor
	If IsActorStale(a)
		If a != None
			Speaker.Clear()
		EndIf
		Return None
	EndIf
	Return a
EndFunction

Bool Function IsActorStale(Actor a)
	If a == None
		Return True
	EndIf
	If a.IsDead()
		Return True
	EndIf
	Return False
EndFunction

Function PruneStaleState()
	Actor aliasActor = None
	If Speaker != None
		aliasActor = Speaker.GetReference() as Actor
	EndIf

	If IsActorStale(currentActor)
		currentActor = None
	EndIf

	If IsActorStale(aliasActor)
		If Speaker != None && aliasActor != None
			Speaker.Clear()
		EndIf
		aliasActor = None
	EndIf

	If currentActor == None && aliasActor != None
		currentActor = aliasActor
	ElseIf currentActor != None && aliasActor == None
		SetSpeaker(currentActor)
	ElseIf currentActor != None && aliasActor != None && currentActor != aliasActor
		SetSpeaker(currentActor)
	EndIf
EndFunction

Function ClearAlias(ReferenceAlias al)
	If al == None
		Return
	EndIf

	If al.GetReference() != None
		al.Clear()
	EndIf
EndFunction
