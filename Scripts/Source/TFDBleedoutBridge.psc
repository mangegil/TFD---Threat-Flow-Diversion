Scriptname TFDBleedoutBridge extends Quest

Quest Property TFDBleedoutQuest Auto

Bool Property AllowAutoPackageEval Auto

Actor currentActor

TFDBleedoutQuestScript Function GetBleedoutController()
	If TFDBleedoutQuest == None
		Return None
	EndIf

	Return TFDBleedoutQuest as TFDBleedoutQuestScript
EndFunction

Bool Function IsFollowerActor(Actor a)
	If a == None
		Return False
	EndIf

	If a.IsPlayerTeammate()
		Return True
	EndIf

	Return False
EndFunction

Function RegisterEvents()
	UnregisterForAllModEvents()
	RegisterForModEvent("TFDBleedoutAssign", "OnBridgeEvent")
	RegisterForModEvent("TFDBleedoutPrimeSpeaker", "OnBridgeEvent")
	RegisterForModEvent("TFDBleedoutClearAll", "OnBridgeEvent")
	RegisterForModEvent("TFDBleedoutUnassign", "OnBridgeEvent")
	Trace("RegisterEvents done")
EndFunction

Event OnInit()
	Trace("OnInit")
	RegisterEvents()
EndEvent

Event OnPlayerLoadGame()
	Trace("OnPlayerLoadGame -> ClearAll + RegisterEvents")
	ClearAll()
	RegisterEvents()
EndEvent

Event OnBridgeEvent(String eventName, String strArg, Float numArg, Form sender)
	Trace("OnBridgeEvent name=" + eventName + " strArg='" + strArg + "' numArg=" + numArg + " sender=" + FormLabel(sender))

	If eventName == "TFDBleedoutAssign"
		Actor aAssign = sender as Actor
		If aAssign != None
			AssignActor(aAssign)
		Else
			Trace("Assign ignored: sender is not Actor")
		EndIf
		Return
	EndIf

	If eventName == "TFDBleedoutPrimeSpeaker"
		Actor aPrime = sender as Actor
		If aPrime != None
			Trace("Prime speaker actor=" + ActorLabel(aPrime))
			KickApproachAI(aPrime)
		Else
			Trace("Prime ignored: sender is not Actor")
		EndIf
		Return
	EndIf

	If eventName == "TFDBleedoutClearAll"
		ClearAll()
		Return
	EndIf

	If eventName == "TFDBleedoutUnassign"
		Actor aClear = sender as Actor
		If aClear != None
			ClearActor(aClear)
		Else
			Trace("Unassign ignored: sender is not Actor")
		EndIf
		Return
	EndIf

	Trace("Unknown bridge event ignored")
EndEvent

Function AssignActor(Actor a)
	TFDBleedoutQuestScript bleedCtrl = GetBleedoutController()

	If a == None
		Trace("AssignActor ignored: actor=None")
		Return
	EndIf

	If a.IsDead()
		Trace("AssignActor ignored: actor dead")
		Return
	EndIf

	If IsFollowerActor(a)
		Trace("AssignActor ignored: teammate/follower actor=" + ActorLabel(a))
		ClearActor(a)
		Return
	EndIf

	If currentActor == a
		If bleedCtrl != None
			bleedCtrl.SetSpeaker(a)
		EndIf
		If AllowAutoPackageEval
			KickApproachAI(a)
		EndIf
		Return
	EndIf

	If currentActor != None
		Trace("AssignActor replace previous speaker actor=" + ActorLabel(currentActor) + " -> " + ActorLabel(a))
		ClearAll()
	EndIf

	currentActor = a

	If bleedCtrl != None
		bleedCtrl.SetSpeaker(a)
	EndIf

	Trace("AssignActor active speaker=" + ActorLabel(a))

	If AllowAutoPackageEval
		KickApproachAI(a)
	EndIf
EndFunction

Function ClearActor(Actor a)
	TFDBleedoutQuestScript bleedCtrl = GetBleedoutController()

	If a == None
		Trace("ClearActor ignored: actor=None")
		Return
	EndIf

	If bleedCtrl != None
		bleedCtrl.ClearSpeakerForActor(a)
	EndIf

	RestoreNormalAI(a)

	If currentActor == a
		currentActor = None
	EndIf

	Trace("ClearActor done actor=" + ActorLabel(a))
EndFunction

Function ClearAll()
	TFDBleedoutQuestScript bleedCtrl = GetBleedoutController()
	Actor actorA = currentActor

	If bleedCtrl != None
		bleedCtrl.ClearSpeaker()
	EndIf

	RestoreNormalAI(actorA)
	currentActor = None

	Trace("ClearAll end")
EndFunction

Function KickApproachAI(Actor a)
	If a == None
		Trace("KickApproachAI ignored: actor=None")
		Return
	EndIf

	If IsFollowerActor(a)
		Trace("KickApproachAI ignored for teammate/follower actor=" + ActorLabel(a))
		Return
	EndIf

	Trace("KickApproachAI begin actor=" + ActorLabel(a) + " loaded=" + BoolLabel(a.Is3DLoaded()) + " inCombat=" + BoolLabel(a.IsInCombat()) + " weaponDrawn=" + BoolLabel(a.IsWeaponDrawn()))

	If !a.Is3DLoaded()
		Trace("KickApproachAI skip: actor 3D not loaded")
		Return
	EndIf

	If a.IsInCombat()
		a.StopCombat()
		a.StopCombatAlarm()
		Trace("KickApproachAI StopCombat")
	EndIf

	If a.IsWeaponDrawn()
		a.SheatheWeapon()
		Trace("KickApproachAI SheatheWeapon")
	EndIf

	a.EvaluatePackage()
	Trace("KickApproachAI EvaluatePackage done")
EndFunction

Function RestoreNormalAI(Actor a)
	If a == None
		Return
	EndIf

	If IsFollowerActor(a)
		Trace("RestoreNormalAI ignored for teammate/follower actor=" + ActorLabel(a))
		Return
	EndIf

	Trace("RestoreNormalAI begin actor=" + ActorLabel(a) + " loaded=" + BoolLabel(a.Is3DLoaded()) + " inCombat=" + BoolLabel(a.IsInCombat()) + " weaponDrawn=" + BoolLabel(a.IsWeaponDrawn()))

	If !a.Is3DLoaded()
		Trace("RestoreNormalAI skip: actor 3D not loaded")
		Return
	EndIf

	If a.IsInCombat()
		a.StopCombat()
		Trace("RestoreNormalAI StopCombat")
	EndIf

	If a.IsWeaponDrawn()
		a.SheatheWeapon()
		Trace("RestoreNormalAI SheatheWeapon")
	EndIf

	a.EvaluatePackage()
	Trace("RestoreNormalAI EvaluatePackage done")
EndFunction

Function Trace(String msg)
	Debug.Trace("[TFD][BleedBridge] " + msg)
EndFunction

String Function ActorLabel(Actor a)
	If a == None
		Return "None"
	EndIf

	ActorBase b = a.GetActorBase()
	If b != None
		Return b.GetName() + "(" + a.GetFormID() + ")"
	EndIf

	Return "Actor(" + a.GetFormID() + ")"
EndFunction

String Function FormLabel(Form f)
	If f == None
		Return "None"
	EndIf

	If f as ObjectReference != None
		ObjectReference r = f as ObjectReference
		Return r.GetDisplayName() + "(" + f.GetFormID() + ")"
	EndIf

	Return "Form(" + f.GetFormID() + ")"
EndFunction

String Function BoolLabel(Bool value)
	If value
		Return "true"
	EndIf
	Return "false"
EndFunction
