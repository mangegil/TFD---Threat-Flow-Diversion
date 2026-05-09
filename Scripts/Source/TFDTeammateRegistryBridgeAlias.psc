Scriptname TFDTeammateRegistryBridgeAlias extends ReferenceAlias

TFDPlayerTeammateQuestScript Property Registry Auto
Faction Property PlayerFollowerFaction Auto
Faction Property CurrentFollowerFaction Auto
Float Property RefreshInterval = 5.0 Auto
Bool Property UnregisterIfNotTeammate = True Auto
Bool Property RemoveOnDeath = True Auto

Bool _started = False
Bool _syncQueued = False

String Function BoolText(Bool value)
	If value
		Return "TRUE"
	EndIf
	Return "FALSE"
EndFunction

String Function ScriptVersion()
	Return "R80 vanilla-teammate-contract"
EndFunction

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
	_syncQueued = False
EndFunction

Actor Function GetTrackedActor()
	Return GetActorReference()
EndFunction

Float Function GetDeferredSyncDelay()
	Return 0.35
EndFunction

Float Function GetLoadSyncDelay()
	Return 0.50
EndFunction

Function QueueSync(Float afDelay = 0.35)
	If !_started
		StartBridge()
	EndIf

	If afDelay < 0.10
		afDelay = 0.10
	EndIf

	_syncQueued = True
	RegisterForSingleUpdate(afDelay)
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

Bool Function HasTFDMarker(Actor akActor)
	If akActor == None || Registry == None
		Return False
	EndIf

	Return Registry.HasTFDTeammateMarker(akActor)
EndFunction

Bool Function ShouldRegister(Actor akActor)
	If akActor == None
		Return False
	EndIf

	If akActor.IsDead() || akActor.IsDisabled()
		Return False
	EndIf

	; R45: this alias/package quest is owned only by TFD-converted humanoids.
	; Vanilla or follower-framework actors may be player teammates, but they must not
	; be kept in this alias because the alias applies TFDTeammatePackage and can
	; override their normal combat/follow package stack.
	Return HasTFDMarker(akActor)
EndFunction

Function SyncNow()
	If Registry == None
		Return
	EndIf

	If Registry.IsEventLocked()
		QueueSync(GetDeferredSyncDelay())
		Return
	EndIf

	Actor akActor = GetTrackedActor()
	If akActor == None
		Return
	EndIf

	Bool markerOwned = HasTFDMarker(akActor)
	Bool hardInvalid = akActor.IsDead() || akActor.IsDisabled()

	If markerOwned
		Registry.EnsureActiveTeammateContract(akActor, "bridge_alias_sync")
	EndIf

	If ShouldRegister(akActor)
		Bool ok = Registry.RegisterOrRefreshTeammate(akActor)
		If markerOwned && !akActor.IsPlayerTeammate()
			Debug.Trace("[TFD][TeammateBridgeAlias] marker owned sync actor=" + akActor + " ok=" + BoolText(ok) + " playerTeammate=" + BoolText(akActor.IsPlayerTeammate()))
		EndIf
	ElseIf UnregisterIfNotTeammate
		If markerOwned && !hardInvalid
			Bool kept = Registry.RegisterOrRefreshTeammate(akActor)
			Debug.Trace("[TFD][TeammateBridgeAlias] unregister blocked marker actor=" + akActor + " kept=" + BoolText(kept) + " reason=marker_owned")
		Else
			Bool removed = Registry.UnregisterTeammate(akActor)
			If removed
				If hardInvalid
					Debug.Trace("[TFD][TeammateBridgeAlias] unregister actor=" + akActor + " reason=dead_or_disabled")
				Else
					Debug.Trace("[TFD][TeammateBridgeAlias] unregister actor=" + akActor + " reason=not_teammate_no_marker")
				EndIf
			EndIf
		EndIf
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
	Debug.Trace("[TFD][TeammateBridgeAlias] ScriptVersion " + ScriptVersion() + " event=OnInit")
	StartBridge()
	QueueSync(GetLoadSyncDelay())
EndEvent

Event OnPlayerLoadGame()
	StartBridge()
	QueueSync(GetLoadSyncDelay())
EndEvent

Event OnLoad()
	StartBridge()
	QueueSync(GetLoadSyncDelay())
EndEvent

Event OnUpdate()
	_syncQueued = False
	SyncNow()
	If _started && !_syncQueued
		RegisterForSingleUpdate(RefreshInterval)
	EndIf
EndEvent

Event OnLocationChange(Location akOldLoc, Location akNewLoc)
	QueueSync(GetDeferredSyncDelay())
EndEvent

Event OnCombatStateChanged(Actor akTarget, Int aeCombatState)
	QueueSync(GetDeferredSyncDelay())
EndEvent

Event OnBleedout()
	QueueSync(GetDeferredSyncDelay())
EndEvent

Event OnDeath(Actor akKiller)
	If RemoveOnDeath
		RemoveNow()
	EndIf
	StopBridge()
EndEvent