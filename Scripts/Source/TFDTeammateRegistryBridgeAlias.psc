Scriptname TFDTeammateRegistryBridgeAlias extends ReferenceAlias

TFDPlayerTeammateQuestScript Property Registry Auto
Faction Property PlayerFollowerFaction Auto
Faction Property CurrentFollowerFaction Auto
Float Property RefreshInterval = 5.0 Auto
Bool Property UnregisterIfNotTeammate = True Auto
Bool Property RemoveOnDeath = True Auto

Bool _started = False

Function StartBridge()
	If _started
		Return
	EndIf
	_started = True
	RegisterForSingleUpdate(0.5)
EndFunction

Function StopBridge()
	UnregisterForUpdate()
	_started = False
EndFunction

Actor Function GetTrackedActor()
	Return GetActorReference()
EndFunction

Bool Function HasAnchorFaction(Actor akActor)
	If akActor == None
		Return False
	EndIf

	If CurrentFollowerFaction != None
		If akActor.IsInFaction(CurrentFollowerFaction)
			Return True
		EndIf
	EndIf

	If PlayerFollowerFaction != None
		If akActor.IsInFaction(PlayerFollowerFaction)
			Return True
		EndIf
	EndIf

	Return False
EndFunction

Bool Function ShouldRegister(Actor akActor)
	If akActor == None
		Return False
	EndIf

	If akActor.IsDead()
		Return False
	EndIf

	If akActor.IsPlayerTeammate()
		Return True
	EndIf

	If HasAnchorFaction(akActor)
		Return True
	EndIf

	Return False
EndFunction

Function SyncNow()
	If Registry == None
		Return
	EndIf

	Actor akActor = GetTrackedActor()
	If akActor == None
		Return
	EndIf

	If ShouldRegister(akActor)
		Registry.RegisterOrRefreshTeammate(akActor)
	ElseIf UnregisterIfNotTeammate
		Registry.UnregisterTeammate(akActor)
	EndIf
EndFunction

Function RemoveNow()
	If Registry == None
		Return
	EndIf

	Actor akActor = GetTrackedActor()
	If akActor == None
		Return
	EndIf

	Registry.UnregisterTeammate(akActor)
EndFunction

Event OnInit()
	StartBridge()
	SyncNow()
EndEvent

Event OnPlayerLoadGame()
	StartBridge()
	SyncNow()
EndEvent

Event OnLoad()
	StartBridge()
	SyncNow()
EndEvent

Event OnUpdate()
	SyncNow()
	If _started
		RegisterForSingleUpdate(RefreshInterval)
	EndIf
EndEvent

Event OnLocationChange(Location akOldLoc, Location akNewLoc)
	SyncNow()
EndEvent

Event OnCombatStateChanged(Actor akTarget, Int aeCombatState)
	SyncNow()
EndEvent

Event OnBleedout()
	SyncNow()
EndEvent

Event OnDeath(Actor akKiller)
	If RemoveOnDeath
		RemoveNow()
	EndIf
	StopBridge()
EndEvent
