Scriptname TFDPlayerTeammateQuestScript extends Quest

ReferenceAlias Property Player Auto

ReferenceAlias Property Teammate01 Auto
ReferenceAlias Property Teammate02 Auto
ReferenceAlias Property Teammate03 Auto
ReferenceAlias Property Teammate04 Auto
ReferenceAlias Property Teammate05 Auto
ReferenceAlias Property Teammate06 Auto
ReferenceAlias Property Teammate07 Auto
ReferenceAlias Property Teammate08 Auto
ReferenceAlias Property Teammate09 Auto
ReferenceAlias Property Teammate10 Auto

Faction Property PlayerFollowerFaction Auto
Faction Property CurrentFollowerFaction Auto

Bool _initialized = False
Bool _eventLocked = False
Actor _cachedAssistTarget = None

Float Function GetNormalUpdateInterval()
	Return 1.00
EndFunction

Float Function GetAssistUpdateInterval()
	Return 0.35
EndFunction

Event OnInit()
	EnsureInit()
	RegisterBridgeEvents()
	RegisterForSingleUpdate(GetNormalUpdateInterval())
EndEvent

Event OnPlayerLoadGame()
	EnsureInit()
	RegisterBridgeEvents()
	RegisterForSingleUpdate(0.50)
EndEvent

Event OnUpdate()
	EnsureInit()

	If !_eventLocked
		PruneInvalidTeammates()
		RefreshAssistTargetCache()
		UpdateAssistCombat()
	EndIf

	If ShouldRunAssistUpdate()
		RegisterForSingleUpdate(GetAssistUpdateInterval())
	Else
		RegisterForSingleUpdate(GetNormalUpdateInterval())
	EndIf
EndEvent

Event OnBridgeEvent(String eventName, String strArg, Float numArg, Form sender)
	Actor a = sender as Actor

	If eventName == "TFDHumanoidTeammateAssign"
		If a != None
			RegisterOrRefreshTeammate(a)
		EndIf
		Return
	EndIf

	If eventName == "TFDCreatureTeammateAssign"
		If a != None
			RegisterOrRefreshTeammate(a)
		EndIf
		Return
	EndIf

	If eventName == "TFDCreatureTeammateUnassign"
		If a != None
			UnregisterTeammate(a)
		EndIf
		Return
	EndIf
EndEvent

Function RegisterBridgeEvents()
	UnregisterForAllModEvents()
	RegisterForModEvent("TFDHumanoidTeammateAssign", "OnBridgeEvent")
	RegisterForModEvent("TFDCreatureTeammateAssign", "OnBridgeEvent")
	RegisterForModEvent("TFDCreatureTeammateUnassign", "OnBridgeEvent")
EndFunction

Actor Function GetPlayerActor()
	Actor playerRef = None

	If Player != None
		playerRef = Player.GetActorReference()
	EndIf

	If playerRef == None
		playerRef = Game.GetPlayer()
	EndIf

	Return playerRef
EndFunction

Bool Function ShouldRunAssistUpdate()
	Actor playerRef = GetPlayerActor()
	If playerRef == None
		Return False
	EndIf

	If playerRef.IsDead()
		Return False
	EndIf

	If !playerRef.IsBleedingOut()
		Return False
	EndIf

	If GetStandingRegisteredCount() <= 0
		Return False
	EndIf

	Return True
EndFunction

Function RefreshAssistTargetCache()
	Actor liveTarget = ResolveLiveAssistTarget()
	If IsValidAssistTarget(liveTarget)
		_cachedAssistTarget = liveTarget
	ElseIf !IsValidAssistTarget(_cachedAssistTarget)
		_cachedAssistTarget = None
	EndIf
EndFunction

Actor Function ResolveLiveAssistTarget()
	Actor playerRef = GetPlayerActor()
	If playerRef != None
		Actor playerTarget = playerRef.GetCombatTarget()
		If IsValidAssistTarget(playerTarget)
			Return playerTarget
		EndIf
	EndIf

	Int i = 0
	While i < GetMaxSlots()
		Actor teammate = GetTeammateBySlot(i)
		If teammate != None
			If !teammate.IsDead() && !teammate.IsBleedingOut()
				Actor teammateTarget = teammate.GetCombatTarget()
				If IsValidAssistTarget(teammateTarget)
					Return teammateTarget
				EndIf
			EndIf
		EndIf
		i += 1
	EndWhile

	Return None
EndFunction

Actor Function ResolveSharedAssistTarget()
	Actor liveTarget = ResolveLiveAssistTarget()
	If IsValidAssistTarget(liveTarget)
		_cachedAssistTarget = liveTarget
		Return liveTarget
	EndIf

	If IsValidAssistTarget(_cachedAssistTarget)
		Return _cachedAssistTarget
	EndIf

	Return None
EndFunction

Bool Function IsValidAssistTarget(Actor akTarget)
	Actor playerRef = GetPlayerActor()

	If akTarget == None
		Return False
	EndIf

	If akTarget.IsDead()
		Return False
	EndIf

	If akTarget.IsBleedingOut()
		Return False
	EndIf

	If IsLikelyTeammateActor(akTarget)
		Return False
	EndIf

	If playerRef == None
		Return True
	EndIf

	If akTarget.IsHostileToActor(playerRef)
		Return True
	EndIf

	If playerRef.IsHostileToActor(akTarget)
		Return True
	EndIf

	Return False
EndFunction

Actor Function ResolveActorAssistTarget(Actor akActor, Actor akSharedTarget)
	If akActor == None
		Return None
	EndIf

	Actor ownTarget = akActor.GetCombatTarget()
	If IsValidAssistTarget(ownTarget)
		Return ownTarget
	EndIf

	If IsValidAssistTarget(akSharedTarget)
		Return akSharedTarget
	EndIf

	Return None
EndFunction

Function UpdateAssistCombat()
	If !ShouldRunAssistUpdate()
		Return
	EndIf

	Actor sharedTarget = ResolveSharedAssistTarget()

	Int i = 0
	While i < GetMaxSlots()
		Actor teammate = GetTeammateBySlot(i)
		If teammate != None
			If !teammate.IsDead() && !teammate.IsBleedingOut()
				NudgeAssistCombat(teammate, sharedTarget)
			EndIf
		EndIf
		i += 1
	EndWhile
EndFunction

Function NudgeAssistCombat(Actor akActor, Actor akSharedTarget)
	If akActor == None
		Return
	EndIf

	If !akActor.Is3DLoaded()
		Return
	EndIf

	Actor target = ResolveActorAssistTarget(akActor, akSharedTarget)
	If target == None
		akActor.EvaluatePackage()
		Return
	EndIf

	If !akActor.IsInCombat()
		akActor.StartCombat(target)
	ElseIf akActor.GetCombatTarget() != target
		akActor.StartCombat(target)
	EndIf

	If !akActor.IsWeaponDrawn()
		akActor.DrawWeapon()
	EndIf

	akActor.EvaluatePackage()
EndFunction

Function EnsureInit()
	If _initialized
		Return
	EndIf
	_initialized = True
EndFunction

ReferenceAlias Function GetSlotByIndex(Int aiIndex)
	If aiIndex == 0
		Return Teammate01
	ElseIf aiIndex == 1
		Return Teammate02
	ElseIf aiIndex == 2
		Return Teammate03
	ElseIf aiIndex == 3
		Return Teammate04
	ElseIf aiIndex == 4
		Return Teammate05
	ElseIf aiIndex == 5
		Return Teammate06
	ElseIf aiIndex == 6
		Return Teammate07
	ElseIf aiIndex == 7
		Return Teammate08
	ElseIf aiIndex == 8
		Return Teammate09
	ElseIf aiIndex == 9
		Return Teammate10
	EndIf

	Return None
EndFunction

Int Function GetMaxSlots()
	Return 10
EndFunction

Bool Function IsEventLocked()
	Return _eventLocked
EndFunction

Function LockForEvent()
	_eventLocked = True
EndFunction

Function UnlockAfterEvent()
	_eventLocked = False
EndFunction

Bool Function HasFollowerAnchorFaction(Actor akActor)
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

Bool Function IsLikelyTeammateActor(Actor akActor)
	If akActor == None
		Return False
	EndIf

	If akActor.IsDead()
		Return False
	EndIf

	If akActor.IsPlayerTeammate()
		Return True
	EndIf

	If HasFollowerAnchorFaction(akActor)
		Return True
	EndIf

	Return False
EndFunction

Bool Function IsRegistered(Actor akActor)
	EnsureInit()

	If akActor == None
		Return False
	EndIf

	Int i = 0
	While i < GetMaxSlots()
		ReferenceAlias slotAlias = GetSlotByIndex(i)
		If slotAlias != None
			ObjectReference slotRef = slotAlias.GetReference()
			If slotRef == akActor
				Return True
			EndIf
		EndIf
		i += 1
	EndWhile

	Return False
EndFunction

Int Function FindSlotIndex(Actor akActor)
	EnsureInit()

	If akActor == None
		Return -1
	EndIf

	Int i = 0
	While i < GetMaxSlots()
		ReferenceAlias slotAlias = GetSlotByIndex(i)
		If slotAlias != None
			ObjectReference slotRef = slotAlias.GetReference()
			If slotRef == akActor
				Return i
			EndIf
		EndIf
		i += 1
	EndWhile

	Return -1
EndFunction

Int Function FindEmptySlotIndex()
	EnsureInit()

	Int i = 0
	While i < GetMaxSlots()
		ReferenceAlias slotAlias = GetSlotByIndex(i)
		If slotAlias != None
			If slotAlias.GetReference() == None
				Return i
			EndIf
		EndIf
		i += 1
	EndWhile

	Return -1
EndFunction

Bool Function RegisterTeammate(Actor akActor)
	EnsureInit()

	If akActor == None
		Return False
	EndIf

	If IsRegistered(akActor)
		Return True
	EndIf

	Int emptyIndex = FindEmptySlotIndex()
	If emptyIndex < 0
		Return False
	EndIf

	ReferenceAlias slotAlias = GetSlotByIndex(emptyIndex)
	If slotAlias == None
		Return False
	EndIf

	slotAlias.ForceRefTo(akActor)
	Return True
EndFunction

Bool Function RegisterOrRefreshTeammate(Actor akActor)
	EnsureInit()

	If akActor == None
		Return False
	EndIf

	If !IsLikelyTeammateActor(akActor)
		Return False
	EndIf

	If IsRegistered(akActor)
		Return True
	EndIf

	Return RegisterTeammate(akActor)
EndFunction

Bool Function UnregisterTeammate(Actor akActor)
	EnsureInit()

	If akActor == None
		Return False
	EndIf

	Int slotIndex = FindSlotIndex(akActor)
	If slotIndex < 0
		Return False
	EndIf

	ReferenceAlias slotAlias = GetSlotByIndex(slotIndex)
	If slotAlias == None
		Return False
	EndIf

	slotAlias.Clear()
	If _cachedAssistTarget == akActor
		_cachedAssistTarget = None
	EndIf
	Return True
EndFunction

Function ClearAllTeammates()
	EnsureInit()

	Int i = 0
	While i < GetMaxSlots()
		ReferenceAlias slotAlias = GetSlotByIndex(i)
		If slotAlias != None
			slotAlias.Clear()
		EndIf
		i += 1
	EndWhile

	_cachedAssistTarget = None
EndFunction

Function PruneInvalidTeammates()
	EnsureInit()

	If _eventLocked
		Return
	EndIf

	Int i = 0
	While i < GetMaxSlots()
		ReferenceAlias slotAlias = GetSlotByIndex(i)
		If slotAlias != None
			Actor slotActor = slotAlias.GetActorReference()
			If slotActor != None
				If !IsLikelyTeammateActor(slotActor)
					slotAlias.Clear()
					If _cachedAssistTarget == slotActor
						_cachedAssistTarget = None
					EndIf
				EndIf
			EndIf
		EndIf
		i += 1
	EndWhile
EndFunction

Int Function GetRegisteredCount()
	EnsureInit()

	Int count = 0
	Int i = 0
	While i < GetMaxSlots()
		ReferenceAlias slotAlias = GetSlotByIndex(i)
		If slotAlias != None
			If slotAlias.GetReference() != None
				count += 1
			EndIf
		EndIf
		i += 1
	EndWhile

	Return count
EndFunction

Actor Function GetTeammateBySlot(Int aiSlotIndex)
	EnsureInit()

	ReferenceAlias slotAlias = GetSlotByIndex(aiSlotIndex)
	If slotAlias == None
		Return None
	EndIf

	Return slotAlias.GetActorReference()
EndFunction

Actor Function GetRegisteredTeammateAt(Int aiIndex)
	EnsureInit()

	If aiIndex < 0
		Return None
	EndIf

	Int current = 0
	Int i = 0
	While i < GetMaxSlots()
		ReferenceAlias slotAlias = GetSlotByIndex(i)
		If slotAlias != None
			Actor slotActor = slotAlias.GetActorReference()
			If slotActor != None
				If current == aiIndex
					Return slotActor
				EndIf
				current += 1
			EndIf
		EndIf
		i += 1
	EndWhile

	Return None
EndFunction

Bool Function HasAnyRegisteredTeammate()
	Return GetRegisteredCount() > 0
EndFunction

Bool Function IsRegisteredTeammateAlive(Actor akActor)
	If akActor == None
		Return False
	EndIf

	If !IsRegistered(akActor)
		Return False
	EndIf

	Return !akActor.IsDead()
EndFunction

Bool Function IsRegisteredTeammateStanding(Actor akActor)
	If akActor == None
		Return False
	EndIf

	If !IsRegistered(akActor)
		Return False
	EndIf

	If akActor.IsDead()
		Return False
	EndIf

	If akActor.IsBleedingOut()
		Return False
	EndIf

	Return True
EndFunction

Int Function GetStandingRegisteredCount()
	EnsureInit()

	Int count = 0
	Int i = 0
	While i < GetMaxSlots()
		ReferenceAlias slotAlias = GetSlotByIndex(i)
		If slotAlias != None
			Actor slotActor = slotAlias.GetActorReference()
			If slotActor != None
				If !slotActor.IsDead() && !slotActor.IsBleedingOut()
					count += 1
				EndIf
			EndIf
		EndIf
		i += 1
	EndWhile

	Return count
EndFunction

Int Function GetDownedRegisteredCount()
	EnsureInit()

	Int count = 0
	Int i = 0
	While i < GetMaxSlots()
		ReferenceAlias slotAlias = GetSlotByIndex(i)
		If slotAlias != None
			Actor slotActor = slotAlias.GetActorReference()
			If slotActor != None
				If slotActor.IsDead() || slotActor.IsBleedingOut()
					count += 1
				EndIf
			EndIf
		EndIf
		i += 1
	EndWhile

	Return count
EndFunction

Actor Function GetFirstStandingRegisteredTeammate()
	EnsureInit()

	Int i = 0
	While i < GetMaxSlots()
		ReferenceAlias slotAlias = GetSlotByIndex(i)
		If slotAlias != None
			Actor slotActor = slotAlias.GetActorReference()
			If slotActor != None
				If !slotActor.IsDead() && !slotActor.IsBleedingOut()
					Return slotActor
				EndIf
			EndIf
		EndIf
		i += 1
	EndWhile

	Return None
EndFunction

Actor Function GetFirstDownedRegisteredTeammate()
	EnsureInit()

	Int i = 0
	While i < GetMaxSlots()
		ReferenceAlias slotAlias = GetSlotByIndex(i)
		If slotAlias != None
			Actor slotActor = slotAlias.GetActorReference()
			If slotActor != None
				If slotActor.IsDead() || slotActor.IsBleedingOut()
					Return slotActor
				EndIf
			EndIf
		EndIf
		i += 1
	EndWhile

	Return None
EndFunction
