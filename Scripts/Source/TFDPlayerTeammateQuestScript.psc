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
Faction Property TFDTeammateFaction Auto
Faction Property TFDExpiredTeammate Auto

Bool Property EnableConvertedFollowMaintenance = True Auto
Bool Property EnableConvertedFollowMoveTo = False Auto
Float Property ConvertedFollowNudgeInterval = 3.00 Auto
Float Property ConvertedFollowEvaluateDistance = 2048.00 Auto
Float Property ConvertedFollowCatchUpDistance = 6000.00 Auto
Float Property ConvertedFollowCatchUpOffset = 512.00 Auto

Bool _initialized = False
Bool _eventLocked = False
Actor _cachedAssistTarget = None
Float _cachedAssistTargetUntil = 0.0
Float _assistAlertUntil = 0.0
Float _nextConvertedFollowNudgeAt = 0.0
Bool _lastPrimePackageSuppressedByCombatBehavior = False
Float _nextRosterDiagAt = 0.0
Bool _postCombatPrimeSlot01 = False
Bool _postCombatPrimeSlot02 = False
Bool _postCombatPrimeSlot03 = False
Bool _postCombatPrimeSlot04 = False
Bool _postCombatPrimeSlot05 = False
Bool _postCombatPrimeSlot06 = False
Bool _postCombatPrimeSlot07 = False
Bool _postCombatPrimeSlot08 = False
Bool _postCombatPrimeSlot09 = False
Bool _postCombatPrimeSlot10 = False

String Function BoolText(Bool value)
	If value
		Return "TRUE"
	EndIf
	Return "FALSE"
EndFunction

Function TraceCombatDiag(String asStage, Actor akActor, String asReason = "")
	If akActor == None
		Return
	EndIf

	Actor playerRef = GetPlayerActor()
	Actor actorTarget = akActor.GetCombatTarget()
	Actor playerTarget = None
	Bool playerInCombat = False

	If playerRef != None
		playerTarget = playerRef.GetCombatTarget()
		playerInCombat = playerRef.IsInCombat()
	EndIf

	Debug.Trace("[TFD][TeammateRegistryDiag] stage=" + asStage + " actor=" + akActor + " reason=" + asReason + " actorDead=" + BoolText(akActor.IsDead()) + " actorBleeding=" + BoolText(akActor.IsBleedingOut()) + " actorDisabled=" + BoolText(akActor.IsDisabled()) + " actorInCombat=" + BoolText(akActor.IsInCombat()) + " actorTarget=" + actorTarget + " actorWeapon=" + BoolText(akActor.IsWeaponDrawn()) + " actorLoaded=" + BoolText(akActor.Is3DLoaded()) + " playerInCombat=" + BoolText(playerInCombat) + " playerTarget=" + playerTarget + " tfdMarker=" + BoolText(HasTFDTeammateMarker(akActor)) + " activeMarker=" + BoolText(HasActiveTFDTeammateMarker(akActor)) + " registered=" + BoolText(IsRegistered(akActor)) + " followerAnchor=" + BoolText(HasFollowerAnchorFaction(akActor)) + " playerTeammate=" + BoolText(akActor.IsPlayerTeammate()))
EndFunction

String Function ScriptVersion()
	Return "R91 alert-window-assist-scan"
EndFunction

Bool Function IsSoftHumanoidAssignReason(String asReason)
	If asReason == "loading_menu_closed"
		Return True
	EndIf

	If asReason == "post_load_humanoid_catchup"
		Return True
	EndIf

	If asReason == "register_now_refresh"
		Return True
	EndIf

	If asReason == "teammate_activate_dialogue"
		Return True
	EndIf

	If asReason == "teammate_crosshair_activate_dialogue"
		Return True
	EndIf

	If asReason == "teammate_downed_activate_dialogue"
		Return True
	EndIf

	If asReason == "teammate_downed_fallback_activate_dialogue"
		Return True
	EndIf

	If asReason == "teammate_defeated_redirect_dialogue"
		Return True
	EndIf

	Return False
EndFunction

Bool Function IsConvertedPackageRepairReason(String asReason)
	If asReason == "loading_menu_closed"
		Return True
	EndIf

	If asReason == "post_load_humanoid_catchup"
		Return True
	EndIf

	If asReason == "converted_package_repair"
		Return True
	EndIf

	Return False
EndFunction

Bool Function IsR86DiagnosticPackageInterferenceReason(String asReason)
	If asReason == "loading_menu_closed"
		Return True
	EndIf

	If asReason == "post_load_humanoid_catchup"
		Return True
	EndIf

	If asReason == "converted_package_repair"
		Return True
	EndIf

	If asReason == "follow_maintenance"
		Return True
	EndIf

	If asReason == "register_now_refresh"
		Return True
	EndIf

	Return False
EndFunction

Bool Function IsSoftCombatBehaviorRepairReason(String asReason)
	If asReason == "loading_menu_closed"
		Return True
	EndIf

	If asReason == "post_load_humanoid_catchup"
		Return True
	EndIf

	If asReason == "converted_package_repair"
		Return True
	EndIf

	If asReason == "follow_maintenance"
		Return True
	EndIf

	If asReason == "register_now_refresh"
		Return True
	EndIf

	Return False
EndFunction

Bool Function ShouldSuppressSoftRepairDuringCombatBehavior(Actor akActor, String asReason)
	If akActor == None
		Return False
	EndIf

	If !IsSoftCombatBehaviorRepairReason(asReason)
		Return False
	EndIf

	If akActor.IsDead() || akActor.IsBleedingOut() || akActor.IsDisabled()
		Return False
	EndIf

	If !HasTFDTeammateMarker(akActor)
		Return False
	EndIf

	Actor playerRef = GetPlayerActor()
	If playerRef == None
		Return False
	EndIf

	If playerRef.IsDead() || playerRef.IsBleedingOut()
		Return False
	EndIf

	; R86 diagnostic: with TFD combat behavior disabled, soft package repair still must not
	; reset AI/package state while vanilla follower combat is trying to start.
	If playerRef.IsInCombat()
		Return True
	EndIf

	Actor playerTarget = playerRef.GetCombatTarget()
	If IsValidAssistTarget(playerTarget)
		Return True
	EndIf

	If akActor.IsInCombat()
		Return True
	EndIf

	Actor actorTarget = akActor.GetCombatTarget()
	If IsValidAssistTarget(actorTarget)
		Return True
	EndIf

	If akActor.IsWeaponDrawn() && playerRef.IsWeaponDrawn()
		Return True
	EndIf

	Return False
EndFunction

Bool Function HasRegisteredRosterCombatPressure(Actor akIgnore = None)
	; R88: this means real combat pressure, not just weapon-drawn mirroring.
	; R87 treated player+teammate weapon drawn as pressure and blocked the initial
	; package prime, which left converted teammates with teammate flags but no
	; settled follow package.
	Actor playerRef = GetPlayerActor()

	If playerRef != None
		Actor playerTarget = playerRef.GetCombatTarget()
		If IsValidAssistTarget(playerTarget)
			Return True
		EndIf
	EndIf

	Int i = 0
	While i < GetMaxSlots()
		Actor teammate = GetTeammateBySlot(i)
		If teammate != None && teammate != akIgnore
			If !teammate.IsDead() && !teammate.IsBleedingOut() && !teammate.IsDisabled()
				If teammate.IsInCombat()
					Return True
				EndIf

				Actor teammateTarget = teammate.GetCombatTarget()
				If IsValidAssistTarget(teammateTarget)
					Return True
				EndIf
			EndIf
		EndIf
		i += 1
	EndWhile

	Return False
EndFunction

Bool Function ShouldBlockPrimePackageTouchNow(Actor akActor, String asReason)
	If akActor == None
		Return False
	EndIf

	If akActor.IsDead() || akActor.IsBleedingOut() || akActor.IsDisabled()
		Return False
	EndIf

	If !HasTFDTeammateMarker(akActor)
		Return False
	EndIf

	Actor playerRef = GetPlayerActor()
	If playerRef != None
		If playerRef.IsDead()
			Return False
		EndIf

		; R88: do not block package prime from stale player combat or weapon-drawn mirroring.
		; Block only when there is a concrete target. This keeps vanilla follow package
		; settlement alive after recruit while still avoiding package touches during real combat.
		Actor playerTarget = playerRef.GetCombatTarget()
		If IsValidAssistTarget(playerTarget)
			Return True
		EndIf
	EndIf

	If akActor.IsInCombat()
		Return True
	EndIf

	Actor actorTarget = akActor.GetCombatTarget()
	If IsValidAssistTarget(actorTarget)
		Return True
	EndIf

	If HasRegisteredRosterCombatPressure(akActor)
		Return True
	EndIf

	Return False
EndFunction

Function TraceRosterSnapshotIfNeeded(String asReason)
	Float nowTime = Utility.GetCurrentRealTime()
	If nowTime < _nextRosterDiagAt
		Return
	EndIf

	If !HasRegisteredRosterCombatPressure(None)
		Return
	EndIf

	_nextRosterDiagAt = nowTime + 2.00

	Actor playerRef = GetPlayerActor()
	Bool playerCombat = False
	Bool playerWeapon = False
	Actor playerTarget = None

	If playerRef != None
		playerCombat = playerRef.IsInCombat()
		playerWeapon = playerRef.IsWeaponDrawn()
		playerTarget = playerRef.GetCombatTarget()
	EndIf

	Debug.Trace("[TFD][TeammateRoster] snapshot reason=" + asReason + " registered=" + GetRegisteredCount() + " standing=" + GetStandingRegisteredCount() + " downed=" + GetDownedRegisteredCount() + " playerCombat=" + BoolText(playerCombat) + " playerWeapon=" + BoolText(playerWeapon) + " playerTarget=" + playerTarget)

	Int i = 0
	While i < GetMaxSlots()
		Actor teammate = GetTeammateBySlot(i)
		If teammate != None
			Float distanceToPlayer = -1.0
			If playerRef != None
				distanceToPlayer = teammate.GetDistance(playerRef)
			EndIf

			Debug.Trace("[TFD][TeammateRoster] slot=" + i + " actor=" + teammate + " dist=" + distanceToPlayer + " dead=" + BoolText(teammate.IsDead()) + " bleeding=" + BoolText(teammate.IsBleedingOut()) + " disabled=" + BoolText(teammate.IsDisabled()) + " loaded=" + BoolText(teammate.Is3DLoaded()) + " inCombat=" + BoolText(teammate.IsInCombat()) + " target=" + teammate.GetCombatTarget() + " weapon=" + BoolText(teammate.IsWeaponDrawn()) + " tfdMarker=" + BoolText(HasTFDTeammateMarker(teammate)) + " activeMarker=" + BoolText(HasActiveTFDTeammateMarker(teammate)) + " registered=" + BoolText(IsRegistered(teammate)) + " followerAnchor=" + BoolText(HasFollowerAnchorFaction(teammate)) + " playerTeammate=" + BoolText(teammate.IsPlayerTeammate()))
		EndIf
		i += 1
	EndWhile
EndFunction


Float Function GetAssistThreatScanRadius()
	Return 3500.0
EndFunction

Int Function GetAssistThreatScanAttempts()
	Return 12
EndFunction

Float Function GetAssistAlertWindowSeconds()
	Return 12.00
EndFunction

Bool Function HasAssistAlertWindow()
	If Utility.GetCurrentRealTime() <= _assistAlertUntil
		Return True
	EndIf

	Return False
EndFunction

Function OpenAssistAlertWindow(String asReason)
	Float keepSeconds = GetAssistAlertWindowSeconds()
	If keepSeconds < 3.0
		keepSeconds = 12.0
	EndIf

	_assistAlertUntil = Utility.GetCurrentRealTime() + keepSeconds
EndFunction

Function RefreshAssistAlertWindow()
	Actor playerRef = GetPlayerActor()
	If playerRef == None
		Return
	EndIf

	If playerRef.IsDead()
		Return
	EndIf

	Actor playerTarget = playerRef.GetCombatTarget()
	If playerRef.IsBleedingOut() || playerRef.IsInCombat() || IsValidAssistTarget(playerTarget)
		OpenAssistAlertWindow("player_combat")
		Return
	EndIf

	; R91: after a real fight starts, keep the assist scanner awake while weapons stay drawn.
	; Skyrim can show hostile red radar dots while GetCombatTarget() and IsInCombat() are temporarily None/False.
	If HasAssistAlertWindow() && playerRef.IsWeaponDrawn()
		OpenAssistAlertWindow("player_weapon_alert_hold")
		Return
	EndIf

	Int i = 0
	While i < GetMaxSlots()
		Actor teammate = GetTeammateBySlot(i)
		If teammate != None
			If !teammate.IsDead() && !teammate.IsBleedingOut() && !teammate.IsDisabled()
				Actor teammateTarget = teammate.GetCombatTarget()
				If teammate.IsInCombat() || IsValidAssistTarget(teammateTarget)
					OpenAssistAlertWindow("teammate_combat")
					Return
				EndIf
			EndIf
		EndIf
		i += 1
	EndWhile
EndFunction

Bool Function HasAssistThreatScanPressure()
	If HasAssistAlertWindow()
		Return True
	EndIf

	Actor playerRef = GetPlayerActor()
	If playerRef != None
		If playerRef.IsInCombat()
			Return True
		EndIf

		Actor playerTarget = playerRef.GetCombatTarget()
		If IsValidAssistTarget(playerTarget)
			Return True
		EndIf
	EndIf

	Int i = 0
	While i < GetMaxSlots()
		Actor teammate = GetTeammateBySlot(i)
		If teammate != None
			If !teammate.IsDead() && !teammate.IsBleedingOut() && !teammate.IsDisabled()
				If teammate.IsInCombat()
					Return True
				EndIf

				Actor teammateTarget = teammate.GetCombatTarget()
				If IsValidAssistTarget(teammateTarget)
					Return True
				EndIf
			EndIf
		EndIf
		i += 1
	EndWhile

	Return False
EndFunction

Bool Function IsRegisteredTeammateTargetingActor(Actor akTarget)
	If akTarget == None
		Return False
	EndIf

	Int i = 0
	While i < GetMaxSlots()
		Actor teammate = GetTeammateBySlot(i)
		If teammate != None
			If !teammate.IsDead() && !teammate.IsBleedingOut() && !teammate.IsDisabled()
				If teammate.GetCombatTarget() == akTarget
					Return True
				EndIf
			EndIf
		EndIf
		i += 1
	EndWhile

	Return False
EndFunction

Bool Function IsValidScannedAssistThreat(Actor akTarget)
	If !IsValidAssistTarget(akTarget)
		Return False
	EndIf

	If !akTarget.Is3DLoaded()
		Return False
	EndIf

	Actor playerRef = GetPlayerActor()
	If playerRef != None
		If akTarget == playerRef
			Return False
		EndIf

		If akTarget.GetCombatTarget() == playerRef
			Return True
		EndIf

		If HasAssistAlertWindow()
			If akTarget.IsHostileToActor(playerRef) || playerRef.IsHostileToActor(akTarget)
				Return True
			EndIf
		EndIf
	EndIf

	If akTarget.IsInCombat()
		Return True
	EndIf

	If akTarget.IsWeaponDrawn() && HasAssistThreatScanPressure()
		Return True
	EndIf

	If IsRegisteredTeammateTargetingActor(akTarget)
		Return True
	EndIf

	Return False
EndFunction

Actor Function FindNearbyAssistThreatFrom(ObjectReference akCenter, String asReason)
	If akCenter == None
		Return None
	EndIf

	Float radius = GetAssistThreatScanRadius()
	If radius < 512.0
		radius = 2500.0
	EndIf

	Actor closest = Game.FindClosestActorFromRef(akCenter, radius)
	If IsValidScannedAssistThreat(closest)
		Debug.Trace("[TFD][TeammateRegistry] assist scan target source=closest center=" + akCenter + " target=" + closest + " reason=" + asReason)
		Return closest
	EndIf

	Int attempts = GetAssistThreatScanAttempts()
	If attempts < 1
		attempts = 1
	EndIf

	Int i = 0
	While i < attempts
		Actor randomTarget = Game.FindRandomActorFromRef(akCenter, radius)
		If IsValidScannedAssistThreat(randomTarget)
			Debug.Trace("[TFD][TeammateRegistry] assist scan target source=random center=" + akCenter + " target=" + randomTarget + " reason=" + asReason + " attempt=" + i)
			Return randomTarget
		EndIf
		i += 1
	EndWhile

	Return None
EndFunction

Actor Function FindNearbyAssistThreat(String asReason)
	If !HasAssistThreatScanPressure()
		Return None
	EndIf

	Actor playerRef = GetPlayerActor()
	Actor target = FindNearbyAssistThreatFrom(playerRef, asReason + "_player")
	If IsValidScannedAssistThreat(target)
		Return target
	EndIf

	Int i = 0
	While i < GetMaxSlots()
		Actor teammate = GetTeammateBySlot(i)
		If teammate != None
			If !teammate.IsDead() && !teammate.IsBleedingOut() && !teammate.IsDisabled() && teammate.Is3DLoaded()
				target = FindNearbyAssistThreatFrom(teammate, asReason + "_slot" + i)
				If IsValidScannedAssistThreat(target)
					Return target
				EndIf
			EndIf
		EndIf
		i += 1
	EndWhile

	Return None
EndFunction

Bool Function SlotNeedsPostCombatPrime(Int aiSlot)
	If aiSlot == 0
		Return _postCombatPrimeSlot01
	ElseIf aiSlot == 1
		Return _postCombatPrimeSlot02
	ElseIf aiSlot == 2
		Return _postCombatPrimeSlot03
	ElseIf aiSlot == 3
		Return _postCombatPrimeSlot04
	ElseIf aiSlot == 4
		Return _postCombatPrimeSlot05
	ElseIf aiSlot == 5
		Return _postCombatPrimeSlot06
	ElseIf aiSlot == 6
		Return _postCombatPrimeSlot07
	ElseIf aiSlot == 7
		Return _postCombatPrimeSlot08
	ElseIf aiSlot == 8
		Return _postCombatPrimeSlot09
	ElseIf aiSlot == 9
		Return _postCombatPrimeSlot10
	EndIf

	Return False
EndFunction

Function SetPostCombatPrimeSlot(Int aiSlot, Bool abValue)
	If aiSlot == 0
		_postCombatPrimeSlot01 = abValue
	ElseIf aiSlot == 1
		_postCombatPrimeSlot02 = abValue
	ElseIf aiSlot == 2
		_postCombatPrimeSlot03 = abValue
	ElseIf aiSlot == 3
		_postCombatPrimeSlot04 = abValue
	ElseIf aiSlot == 4
		_postCombatPrimeSlot05 = abValue
	ElseIf aiSlot == 5
		_postCombatPrimeSlot06 = abValue
	ElseIf aiSlot == 6
		_postCombatPrimeSlot07 = abValue
	ElseIf aiSlot == 7
		_postCombatPrimeSlot08 = abValue
	ElseIf aiSlot == 8
		_postCombatPrimeSlot09 = abValue
	ElseIf aiSlot == 9
		_postCombatPrimeSlot10 = abValue
	EndIf
EndFunction

Function MarkPostCombatPrimeNeeded(Actor akActor, String asReason)
	If akActor == None
		Return
	EndIf

	Int slotIndex = FindSlotIndex(akActor)
	If slotIndex < 0
		Return
	EndIf

	SetPostCombatPrimeSlot(slotIndex, True)
	Debug.Trace("[TFD][TeammateRegistry] post-combat follow prime armed slot=" + slotIndex + " actor=" + akActor + " reason=" + asReason)
EndFunction

Bool Function RunPostCombatFollowPrimeIfNeeded(Actor akActor, Int aiSlot)
	If akActor == None
		Return False
	EndIf

	If !SlotNeedsPostCombatPrime(aiSlot)
		Return False
	EndIf

	If HasRegisteredRosterCombatPressure(None)
		Return False
	EndIf

	If akActor.IsDead() || akActor.IsBleedingOut() || akActor.IsDisabled()
		SetPostCombatPrimeSlot(aiSlot, False)
		Return False
	EndIf

	If akActor.IsInCombat() || akActor.GetCombatTarget() != None
		Return False
	EndIf

	ReferenceAlias slotAlias = GetSlotByIndex(aiSlot)
	If slotAlias == None
		SetPostCombatPrimeSlot(aiSlot, False)
		Return False
	EndIf

	SetPostCombatPrimeSlot(aiSlot, False)
	TraceCombatDiag("post_combat_follow_prime_before", akActor, "post_combat_follow_prime")
	slotAlias.Clear()
	slotAlias.ForceRefTo(akActor)
	PrimeConvertedPackageAfterRegister(akActor, "post_combat_follow_prime", True)
	TraceCombatDiag("post_combat_follow_prime_after", akActor, "post_combat_follow_prime")
	Debug.Trace("[TFD][TeammateRegistry] post-combat follow prime applied slot=" + aiSlot + " actor=" + akActor)
	Return True
EndFunction


Bool Function ShouldAbortInFlightPackageRepair(Actor akActor, String asReason)
	If ShouldBlockPrimePackageTouchNow(akActor, asReason)
		_lastPrimePackageSuppressedByCombatBehavior = True
		TraceCombatDiag("prime_inflight_package_touch_abort_r87", akActor, asReason)
		Debug.Trace("[TFD][TeammateRegistry] PrimeConvertedPackage package touch aborted by R87 firewall actor=" + akActor + " reason=" + asReason)
		TraceRosterSnapshotIfNeeded("prime_abort_" + asReason)
		Return True
	EndIf

	If ShouldSuppressSoftRepairDuringCombatBehavior(akActor, asReason)
		_lastPrimePackageSuppressedByCombatBehavior = True
		TraceCombatDiag("prime_inflight_repair_abort", akActor, asReason)
		Debug.Trace("[TFD][TeammateRegistry] PrimeConvertedPackage in-flight repair aborted by combat behavior actor=" + akActor + " reason=" + asReason)
		TraceRosterSnapshotIfNeeded("prime_soft_abort_" + asReason)
		Return True
	EndIf

	Return False
EndFunction

Bool Function IsValidCombatBehaviorCommitActor(Actor akActor)
	If akActor == None
		Return False
	EndIf

	If akActor.IsDead() || akActor.IsBleedingOut() || akActor.IsDisabled()
		Return False
	EndIf

	If HasActiveTFDTeammateMarker(akActor)
		EnsureActiveTeammateContract(akActor, "combat_behavior_commit_actor")
		Return True
	EndIf

	If IsRegistered(akActor)
		Return True
	EndIf

	If akActor.IsPlayerTeammate()
		Return True
	EndIf

	If HasFollowerAnchorFaction(akActor)
		Return True
	EndIf

	Return False
EndFunction

Float Function GetAssistTargetCacheKeepSeconds()
	Return 8.00
EndFunction

Function StoreCachedAssistTarget(Actor akTarget)
	If akTarget == None
		_cachedAssistTarget = None
		_cachedAssistTargetUntil = 0.0
		Return
	EndIf

	_cachedAssistTarget = akTarget
	_cachedAssistTargetUntil = Utility.GetCurrentRealTime() + GetAssistTargetCacheKeepSeconds()
	OpenAssistAlertWindow("cached_assist_target")
EndFunction

Bool Function IsCachedAssistTargetUsable(Actor akActor)
	If _cachedAssistTarget == None
		Return False
	EndIf

	If Utility.GetCurrentRealTime() > _cachedAssistTargetUntil
		_cachedAssistTarget = None
		_cachedAssistTargetUntil = 0.0
		Return False
	EndIf

	Return IsValidCombatBehaviorCommitTarget(akActor, _cachedAssistTarget)
EndFunction

Bool Function HasLiveCombatBehaviorThreatContext(Actor akActor, Actor akTarget)
	If akActor == None || akTarget == None
		Return False
	EndIf

	Actor playerRef = GetPlayerActor()
	If playerRef == None
		Return False
	EndIf

	If playerRef.IsDead() || playerRef.IsBleedingOut()
		Return False
	EndIf

	Actor threatTarget = akTarget.GetCombatTarget()
	If threatTarget == playerRef
		Return True
	EndIf

	If IsLikelyTeammateActor(threatTarget)
		Return True
	EndIf

	Actor playerTarget = playerRef.GetCombatTarget()
	If playerTarget == akTarget && (playerRef.IsInCombat() || akTarget.IsInCombat())
		Return True
	EndIf

	Bool playerHostilePair = akTarget.IsHostileToActor(playerRef) || playerRef.IsHostileToActor(akTarget)
	Bool actorHostilePair = akTarget.IsHostileToActor(akActor) || akActor.IsHostileToActor(akTarget)

	If playerHostilePair
		If akTarget.IsInCombat() || playerRef.IsInCombat() || akActor.IsInCombat()
			Return True
		EndIf

		If akTarget.IsWeaponDrawn() || playerRef.IsWeaponDrawn() || akActor.IsWeaponDrawn()
			Return True
		EndIf
	EndIf

	If actorHostilePair
		If akTarget.IsInCombat() || akActor.IsInCombat() || playerRef.IsInCombat()
			Return True
		EndIf

		If akTarget.IsWeaponDrawn() || akActor.IsWeaponDrawn() || playerRef.IsWeaponDrawn()
			Return True
		EndIf
	EndIf

	Return False
EndFunction

Bool Function IsValidCombatBehaviorCommitTarget(Actor akActor, Actor akTarget)
	If akActor == None || akTarget == None
		Return False
	EndIf

	If akActor == akTarget
		Return False
	EndIf

	If !IsValidCombatBehaviorCommitActor(akActor)
		Return False
	EndIf

	If akTarget.IsDead() || akTarget.IsBleedingOut() || akTarget.IsDisabled()
		Return False
	EndIf

	If IsLikelyTeammateActor(akTarget)
		Return False
	EndIf

	Actor playerRef = GetPlayerActor()
	If playerRef == None
		Return False
	EndIf

	If playerRef.IsDead() || playerRef.IsBleedingOut()
		Return False
	EndIf

	If akTarget == playerRef
		Return False
	EndIf

	Bool hostile = False
	If akActor.IsHostileToActor(akTarget)
		hostile = True
	EndIf

	If akTarget.IsHostileToActor(akActor)
		hostile = True
	EndIf

	If akTarget.IsHostileToActor(playerRef)
		hostile = True
	EndIf

	If playerRef.IsHostileToActor(akTarget)
		hostile = True
	EndIf

	If !hostile
		Return False
	EndIf

	Return HasLiveCombatBehaviorThreatContext(akActor, akTarget)
EndFunction

Actor Function ResolveCombatBehaviorCommitTarget(Actor akActor, String asReason)
	If akActor == None
		Return None
	EndIf

	Actor nativeTarget = TFDCombatBehaviorNative.GetPendingCombatAssistTarget(akActor)
	If IsValidCombatBehaviorCommitTarget(akActor, nativeTarget)
		Debug.Trace("[TFD][CombatBehaviorPapyrus] target resolved source=native_pending actor=" + akActor + " target=" + nativeTarget + " request=" + asReason)
		Return nativeTarget
	EndIf

	Actor actorTarget = akActor.GetCombatTarget()
	If IsValidCombatBehaviorCommitTarget(akActor, actorTarget)
		Debug.Trace("[TFD][CombatBehaviorPapyrus] target resolved source=actor_combat_target actor=" + akActor + " target=" + actorTarget + " request=" + asReason)
		Return actorTarget
	EndIf

	Actor playerRef = GetPlayerActor()
	If playerRef != None
		Actor playerTarget = playerRef.GetCombatTarget()
		If IsValidCombatBehaviorCommitTarget(akActor, playerTarget)
			Debug.Trace("[TFD][CombatBehaviorPapyrus] target resolved source=player_combat_target actor=" + akActor + " target=" + playerTarget + " request=" + asReason)
			Return playerTarget
		EndIf
	EndIf

	If IsCachedAssistTargetUsable(akActor)
		Debug.Trace("[TFD][CombatBehaviorPapyrus] target resolved source=cached_assist actor=" + akActor + " target=" + _cachedAssistTarget + " request=" + asReason)
		Return _cachedAssistTarget
	EndIf

	Debug.Trace("[TFD][CombatBehaviorPapyrus] target resolve failed actor=" + akActor + " nativeTarget=" + nativeTarget + " actorTarget=" + actorTarget + " request=" + asReason)
	Return None
EndFunction

Bool Function CommitCombatBehaviorTarget(Actor akActor, String asReason)
	If akActor == None
		Return False
	EndIf

	TraceCombatDiag("combat_behavior_commit_enter", akActor, asReason)

	If !akActor.Is3DLoaded()
		Debug.Trace("[TFD][CombatBehaviorPapyrus] commit rejected actor=" + akActor + " reason=not_loaded request=" + asReason)
		Return False
	EndIf

	If HasActiveTFDTeammateMarker(akActor)
		EnsureActiveTeammateContract(akActor, "combat_behavior_commit")
	EndIf

	If !IsValidCombatBehaviorCommitActor(akActor)
		Debug.Trace("[TFD][CombatBehaviorPapyrus] commit rejected actor=" + akActor + " reason=invalid_commit_actor request=" + asReason + " tfdMarker=" + BoolText(HasActiveTFDTeammateMarker(akActor)) + " registered=" + BoolText(IsRegistered(akActor)) + " playerTeammate=" + BoolText(akActor.IsPlayerTeammate()) + " followerAnchor=" + BoolText(HasFollowerAnchorFaction(akActor)))
		Return False
	EndIf

	Actor target = ResolveCombatBehaviorCommitTarget(akActor, asReason)
	If !IsValidCombatBehaviorCommitTarget(akActor, target)
		Debug.Trace("[TFD][CombatBehaviorPapyrus] commit rejected actor=" + akActor + " reason=invalid_target target=" + target + " request=" + asReason)
		Return False
	EndIf

	Actor currentTarget = akActor.GetCombatTarget()
	If akActor.IsInCombat() && IsValidCombatBehaviorCommitTarget(akActor, currentTarget)
		If currentTarget == target
			If !akActor.IsWeaponDrawn()
				akActor.DrawWeapon()
			EndIf
			Debug.Trace("[TFD][CombatBehaviorPapyrus] commit skipped actor=" + akActor + " reason=already_in_combat target=" + currentTarget + " request=" + asReason)
			Return True
		EndIf

		Debug.Trace("[TFD][CombatBehaviorPapyrus] commit retarget actor=" + akActor + " from=" + currentTarget + " to=" + target + " request=" + asReason)
	EndIf

	StoreCachedAssistTarget(target)

	TraceCombatDiag("combat_behavior_startcombat_before", akActor, asReason)
	akActor.StartCombat(target)
	If !akActor.IsWeaponDrawn()
		akActor.DrawWeapon()
	EndIf
	TraceCombatDiag("combat_behavior_startcombat_after", akActor, asReason)

	If !akActor.IsInCombat()
		Utility.Wait(0.05)
		Actor retryTarget = ResolveCombatBehaviorCommitTarget(akActor, asReason)
		If IsValidCombatBehaviorCommitTarget(akActor, retryTarget)
			TraceCombatDiag("combat_behavior_startcombat_retry_before", akActor, asReason)
			akActor.StartCombat(retryTarget)
			TraceCombatDiag("combat_behavior_startcombat_retry_after", akActor, asReason)
		EndIf
	EndIf

	Actor finalTarget = akActor.GetCombatTarget()
	Bool finalOk = IsValidCombatBehaviorCommitTarget(akActor, finalTarget)
	If !finalOk && akActor.IsInCombat() && finalTarget == None && !HasLiveCombatBehaviorThreatContext(akActor, target)
		akActor.StopCombat()
		Debug.Trace("[TFD][CombatBehaviorPapyrus] commit cleared stale combat actor=" + akActor + " target=" + target + " request=" + asReason)
	EndIf

	Debug.Trace("[TFD][CombatBehaviorPapyrus] commit actor=" + akActor + " target=" + target + " request=" + asReason + " actorInCombat=" + BoolText(akActor.IsInCombat()) + " actorTarget=" + akActor.GetCombatTarget() + " finalOk=" + BoolText(finalOk))
	Return finalOk
EndFunction

Float Function GetNormalUpdateInterval()
	Return 1.00
EndFunction

Float Function GetAssistUpdateInterval()
	Return 0.35
EndFunction

Event OnInit()
	EnsureInit()
	EnsureConvertedFollowDefaults()
	Debug.Trace("[TFD][TeammateRegistry] ScriptVersion " + ScriptVersion() + " event=OnInit")
	RegisterBridgeEvents()
	RegisterForSingleUpdate(GetNormalUpdateInterval())
EndEvent

Event OnPlayerLoadGame()
	EnsureInit()
	EnsureConvertedFollowDefaults()
	Debug.Trace("[TFD][TeammateRegistry] ScriptVersion " + ScriptVersion() + " event=OnPlayerLoadGame")
	RegisterBridgeEvents()
	RegisterForSingleUpdate(0.50)
EndEvent

Event OnUpdate()
	EnsureInit()
	EnsureConvertedFollowDefaults()

	If !_eventLocked
		PruneInvalidTeammates()
		RefreshAssistAlertWindow()
		RefreshAssistTargetCache()
		UpdateAssistCombat()
		UpdateConvertedFollowMaintenance()
		TraceRosterSnapshotIfNeeded("update")
	EndIf

	If ShouldRunAssistUpdate()
		RegisterForSingleUpdate(GetAssistUpdateInterval())
	Else
		RegisterForSingleUpdate(GetNormalUpdateInterval())
	EndIf
EndEvent

Event OnBridgeEvent(String eventName, String strArg, Float numArg, Form sender)
	Actor a = sender as Actor

	If eventName == "TFDCombatBehaviorCommit"
		; R86 diagnostic: ignore direct combat behavior commit events too.
		; This keeps the test free from Papyrus StartCombat fallback.
		If a != None
			Debug.Trace("[TFD][CombatBehaviorPapyrus] direct bridge commit ignored by R86 vanilla assist isolation actor=" + a + " strArg=" + strArg + " numArg=" + numArg)
		Else
			Debug.Trace("[TFD][CombatBehaviorPapyrus] direct bridge commit ignored by R86 vanilla assist isolation reason=no_actor strArg=" + strArg)
		EndIf
		Return
	EndIf

	If eventName == "TFDHumanoidTeammateAssign"
		If a != None
			If HasActiveTFDTeammateMarker(a)
				EnsureActiveTeammateContract(a, "humanoid_assign_" + strArg)
			EndIf

			If strArg == "combat_behavior_commit"
				; R86 diagnostic: native normal-combat behavior is disabled.
				; Do not use Papyrus StartCombat as a replacement, so the test isolates the vanilla follower package stack.
				Debug.Trace("[TFD][CombatBehaviorPapyrus] bridge commit ignored by R86 vanilla assist isolation actor=" + a + " strArg=" + strArg + " numArg=" + numArg)
				Return
			EndIf

			Bool softAssign = IsSoftHumanoidAssignReason(strArg)
			Bool ok = False

			If softAssign
				If IsConvertedPackageRepairReason(strArg)
					; R58: post-load catchup may arrive after the actor is already in the alias,
					; but the converted enemy can still carry a stale AI process.
					; Repair package stack without clearing the alias during dialogue refreshes.
					ok = RepairConvertedPackageFromBridge(a, strArg)
				Else
					; Routine manual dialogue refresh must not clear/re-force alias.
					ok = RegisterOrRefreshTeammate(a)
				EndIf
			Else
				; Initial recruit/native conversion still gets one real rebind after marker faction is valid.
				String hardReason = strArg
				If hardReason == ""
					hardReason = "native_assign_rebind"
				EndIf
				ok = ForceRegisterOrRefreshConvertedTeammate(a, hardReason)
			EndIf

			Debug.Trace("[TFD][TeammateRegistry] Humanoid assign actor=" + a + " ok=" + BoolText(ok) + " soft=" + BoolText(softAssign) + " tfdMarker=" + BoolText(HasTFDTeammateMarker(a)) + " strArg=" + strArg + " numArg=" + numArg)
		Else
			Debug.Trace("[TFD][TeammateRegistry] Humanoid assign ignored reason=no_actor strArg=" + strArg)
		EndIf
		Return
	EndIf

	If eventName == "TFDCreatureTeammateAssign"
		If a != None
			Bool okCreature = RegisterOrRefreshTeammate(a)
			Debug.Trace("[TFD][TeammateRegistry] Creature assign actor=" + a + " ok=" + BoolText(okCreature) + " strArg=" + strArg + " numArg=" + numArg)
		Else
			Debug.Trace("[TFD][TeammateRegistry] Creature assign ignored reason=no_actor strArg=" + strArg)
		EndIf
		Return
	EndIf

	If eventName == "TFDCreatureTeammateUnassign"
		If a != None
			Bool okUnregister = UnregisterTeammate(a)
			Debug.Trace("[TFD][TeammateRegistry] Creature unassign actor=" + a + " ok=" + BoolText(okUnregister) + " strArg=" + strArg + " numArg=" + numArg)
		EndIf
		Return
	EndIf
EndEvent

Function RegisterBridgeEvents()
	UnregisterForAllModEvents()
	RegisterForModEvent("TFDHumanoidTeammateAssign", "OnBridgeEvent")
	RegisterForModEvent("TFDCombatBehaviorCommit", "OnBridgeEvent")
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

Bool Function SyncConvertedFollowerAnchorFactions(Actor akActor, String asReason = "follower_anchor_sync")
	If akActor == None
		Return False
	EndIf

	Bool changed = False
	Bool activeTeammate = HasActiveTFDTeammateMarker(akActor)
	Bool expiredTeammate = HasExpiredTeammateMarker(akActor)

	If activeTeammate
		If CurrentFollowerFaction != None
			If !akActor.IsInFaction(CurrentFollowerFaction)
				akActor.AddToFaction(CurrentFollowerFaction)
				akActor.SetFactionRank(CurrentFollowerFaction, 0)
				changed = True
			EndIf
		EndIf

		If PlayerFollowerFaction != None
			If !akActor.IsInFaction(PlayerFollowerFaction)
				akActor.AddToFaction(PlayerFollowerFaction)
				akActor.SetFactionRank(PlayerFollowerFaction, 0)
				changed = True
			EndIf
		EndIf

		If changed
			Debug.Trace("[TFD][TeammateRegistry] Converted follower anchors added actor=" + akActor + " reason=" + asReason + " currentFollower=" + BoolText(CurrentFollowerFaction != None && akActor.IsInFaction(CurrentFollowerFaction)) + " playerFollower=" + BoolText(PlayerFollowerFaction != None && akActor.IsInFaction(PlayerFollowerFaction)))
		EndIf
		Return changed
	EndIf

	; R63: expired TFD teammates must remain dialogue-managed, but should not keep
	; vanilla follower anchor factions. Otherwise an expired contract can still behave
	; like an active follower/combat ally.
	If expiredTeammate
		If CurrentFollowerFaction != None
			If akActor.IsInFaction(CurrentFollowerFaction)
				akActor.RemoveFromFaction(CurrentFollowerFaction)
				changed = True
			EndIf
		EndIf

		If PlayerFollowerFaction != None
			If akActor.IsInFaction(PlayerFollowerFaction)
				akActor.RemoveFromFaction(PlayerFollowerFaction)
				changed = True
			EndIf
		EndIf

		If changed
			Debug.Trace("[TFD][TeammateRegistry] Converted follower anchors removed actor=" + akActor + " reason=" + asReason + " expired=TRUE")
		EndIf
	EndIf

	Return changed
EndFunction

Bool Function EnsureActiveTeammateContract(Actor akActor, String asReason = "active_teammate_contract")
	EnsureInit()

	If akActor == None
		Return False
	EndIf

	If akActor.IsDead() || akActor.IsDisabled()
		Return False
	EndIf

	If !HasActiveTFDTeammateMarker(akActor)
		Return False
	EndIf

	Actor playerRef = GetPlayerActor()
	If playerRef == None
		Return False
	EndIf

	Bool changed = False
	Bool playerTeammateBefore = akActor.IsPlayerTeammate()
	Bool currentFollowerBefore = CurrentFollowerFaction != None && akActor.IsInFaction(CurrentFollowerFaction)
	Bool playerFollowerBefore = PlayerFollowerFaction != None && akActor.IsInFaction(PlayerFollowerFaction)
	Int actorRankBefore = akActor.GetRelationshipRank(playerRef)
	Int playerRankBefore = playerRef.GetRelationshipRank(akActor)

	If !akActor.IsPlayerTeammate()
		akActor.SetPlayerTeammate(True, False)
		changed = True
	EndIf

	If actorRankBefore < 3
		akActor.SetRelationshipRank(playerRef, 3)
		changed = True
	EndIf

	If playerRankBefore < 3
		playerRef.SetRelationshipRank(akActor, 3)
		changed = True
	EndIf

	If SyncConvertedFollowerAnchorFactions(akActor, asReason)
		changed = True
	EndIf

	If changed
		Debug.Trace("[TFD][TeammateContract] repair active actor=" + akActor + " reason=" + asReason + " playerTeammateBefore=" + BoolText(playerTeammateBefore) + " playerTeammateAfter=" + BoolText(akActor.IsPlayerTeammate()) + " actorRankBefore=" + actorRankBefore + " playerRankBefore=" + playerRankBefore + " currentFollowerBefore=" + BoolText(currentFollowerBefore) + " currentFollowerAfter=" + BoolText(CurrentFollowerFaction != None && akActor.IsInFaction(CurrentFollowerFaction)) + " playerFollowerBefore=" + BoolText(playerFollowerBefore) + " playerFollowerAfter=" + BoolText(PlayerFollowerFaction != None && akActor.IsInFaction(PlayerFollowerFaction)) + " registered=" + BoolText(IsRegistered(akActor)))
	EndIf

	Return changed
EndFunction

Bool Function EnsureConvertedPlayerAlliance(Actor akActor, String asReason = "converted_alliance")
	EnsureInit()

	If akActor == None
		Return False
	EndIf

	If akActor.IsDead() || akActor.IsDisabled()
		Return False
	EndIf

	If !HasActiveTFDTeammateMarker(akActor)
		; Still clean up expired actor follower anchors if needed.
		Return SyncConvertedFollowerAnchorFactions(akActor, asReason)
	EndIf

	Actor playerRef = GetPlayerActor()
	If playerRef == None
		Return False
	EndIf

	Bool changed = False
	Int actorRankBefore = akActor.GetRelationshipRank(playerRef)
	Int playerRankBefore = playerRef.GetRelationshipRank(akActor)
	Bool playerTeammateBefore = akActor.IsPlayerTeammate()

	If !akActor.IsPlayerTeammate()
		akActor.SetPlayerTeammate(True, False)
		changed = True
	EndIf

	; R62: SetPlayerTeammate alone is not enough for converted enemies.
	; Their AI assistance needs an actual friend/ally relationship with the player.
	If actorRankBefore < 3
		akActor.SetRelationshipRank(playerRef, 3)
		changed = True
	EndIf

	If playerRankBefore < 3
		playerRef.SetRelationshipRank(akActor, 3)
		changed = True
	EndIf

	; R63: converted humanoids also need the same follower anchor factions used by
	; vanilla follower systems. This is deliberately TFD-owned only; natural followers
	; are still kept out of TFD aliases by R61.
	If SyncConvertedFollowerAnchorFactions(akActor, asReason)
		changed = True
	EndIf

	If changed
		Debug.Trace("[TFD][TeammateRegistry] Converted alliance repaired actor=" + akActor + " reason=" + asReason + " actorRankBefore=" + actorRankBefore + " playerRankBefore=" + playerRankBefore + " playerTeammateBefore=" + BoolText(playerTeammateBefore) + " playerTeammate=" + BoolText(akActor.IsPlayerTeammate()) + " activeMarker=" + BoolText(HasActiveTFDTeammateMarker(akActor)) + " currentFollower=" + BoolText(CurrentFollowerFaction != None && akActor.IsInFaction(CurrentFollowerFaction)) + " playerFollower=" + BoolText(PlayerFollowerFaction != None && akActor.IsInFaction(PlayerFollowerFaction)))
	EndIf

	Return changed
EndFunction

Function EnsureConvertedFollowDefaults()
	; Existing saves can keep newly added properties at zero/false. Keep the maintenance path alive.
	EnableConvertedFollowMaintenance = True

	If ConvertedFollowNudgeInterval < 1.00
		ConvertedFollowNudgeInterval = 3.00
	EndIf

	If ConvertedFollowEvaluateDistance < 2048.0
		ConvertedFollowEvaluateDistance = 2048.0
	EndIf

	If ConvertedFollowCatchUpDistance < 4096.0
		ConvertedFollowCatchUpDistance = 6000.0
	EndIf

	If ConvertedFollowCatchUpOffset < 256.0
		ConvertedFollowCatchUpOffset = 512.0
	EndIf
EndFunction

Bool Function ShouldPrimeConvertedPackageHard(String asReason)
	If asReason == "defeated_humanoid_recruit"
		Return True
	EndIf

	If asReason == "after_pleasure_recruit_commit"
		Return True
	EndIf

	If asReason == "mod_event_precombat_recruit_commit"
		Return True
	EndIf

	If asReason == "mod_event_precombat_recruit_commit_fallback"
		Return True
	EndIf

	If asReason == "native_assign_rebind"
		Return True
	EndIf

	If asReason == "register_teammate"
		Return True
	EndIf

	; R86 diagnostic: routine repair/cell-load reasons must not hard-toggle AI.
	; We are isolating the vanilla follower package/combat stack.
	Return False
EndFunction

Function PrimeConvertedPackageAfterRegister(Actor akActor, String asReason, Bool abAllowHardReset)
	_lastPrimePackageSuppressedByCombatBehavior = False

	If akActor == None
		Return
	EndIf

	If akActor.IsDead() || akActor.IsDisabled()
		Return
	EndIf

	If !HasTFDTeammateMarker(akActor)
		Return
	EndIf

	Bool allianceChanged = EnsureConvertedPlayerAlliance(akActor, asReason)

	TraceCombatDiag("prime_enter", akActor, asReason)

	If IsR86DiagnosticPackageInterferenceReason(asReason)
		Debug.Trace("[TFD][TeammateRegistry] PrimeConvertedPackage skipped by R88 vanilla assist safe follow prime actor=" + akActor + " reason=" + asReason + " allianceChanged=" + BoolText(allianceChanged))
		Return
	EndIf

	If ShouldBlockPrimePackageTouchNow(akActor, asReason)
		_lastPrimePackageSuppressedByCombatBehavior = True
		TraceCombatDiag("prime_package_touch_blocked_r88", akActor, asReason)
		Debug.Trace("[TFD][TeammateRegistry] PrimeConvertedPackage package touch blocked by R88 real-combat firewall actor=" + akActor + " reason=" + asReason + " allianceChanged=" + BoolText(allianceChanged))
		TraceRosterSnapshotIfNeeded("prime_blocked_" + asReason)
		Return
	EndIf

	If ShouldSuppressSoftRepairDuringCombatBehavior(akActor, asReason)
		_lastPrimePackageSuppressedByCombatBehavior = True
		TraceCombatDiag("prime_soft_repair_suppressed_combat_behavior", akActor, asReason)
		Debug.Trace("[TFD][TeammateRegistry] PrimeConvertedPackage suppressed by combat behavior actor=" + akActor + " reason=" + asReason)
		TraceRosterSnapshotIfNeeded("prime_soft_suppressed_" + asReason)
		Return
	EndIf

	If akActor.IsInCombat()
		TraceCombatDiag("prime_skipped_actor_in_combat_r88", akActor, asReason)
		Debug.Trace("[TFD][TeammateRegistry] PrimeConvertedPackage skipped actor already in combat actor=" + akActor + " reason=" + asReason + " target=" + akActor.GetCombatTarget())
		Return
	EndIf

	If akActor.Is3DLoaded()
		If ShouldAbortInFlightPackageRepair(akActor, asReason)
			Return
		EndIf

		Bool hardRequested = abAllowHardReset && ShouldPrimeConvertedPackageHard(asReason)
		If hardRequested
			; R87: never EnableAI(false/true) here. R86 logs showed a 0.05s wait can stretch into many seconds
			; under Papyrus load, leaving the actor AI-disabled during combat entry. ForceRefTo + one EvaluatePackage
			; is enough for the vanilla alias package stack and avoids freezing one teammate out of the fight.
			TraceCombatDiag("prime_hard_ai_toggle_skipped_r88", akActor, asReason)
			Debug.Trace("[TFD][TeammateRegistry] PrimeConvertedPackage hard AI toggle skipped by R88 actor=" + akActor + " reason=" + asReason)
		EndIf

		If ShouldAbortInFlightPackageRepair(akActor, asReason)
			Return
		EndIf

		TraceCombatDiag("prime_eval_before", akActor, asReason)
		akActor.EvaluatePackage()
		TraceCombatDiag("prime_eval_after", akActor, asReason)
	EndIf

	Debug.Trace("[TFD][TeammateRegistry] PrimeConvertedPackage actor=" + akActor + " reason=" + asReason + " hardRequested=" + BoolText(abAllowHardReset && ShouldPrimeConvertedPackageHard(asReason)) + " hardToggle=FALSE tfdMarker=" + BoolText(HasTFDTeammateMarker(akActor)) + " playerTeammate=" + BoolText(akActor.IsPlayerTeammate()) + " allianceChanged=" + BoolText(allianceChanged))
EndFunction

Bool Function RepairConvertedPackageFromBridge(Actor akActor, String asReason)
	EnsureInit()

	If akActor == None
		Return False
	EndIf

	If akActor.IsDead() || akActor.IsDisabled()
		Debug.Trace("[TFD][TeammateRegistry] Converted package repair rejected actor=" + akActor + " reason=dead_or_disabled request=" + asReason)
		Return False
	EndIf

	If _eventLocked
		Bool lockedRegistered = IsRegistered(akActor)
		Debug.Trace("[TFD][TeammateRegistry] Converted package repair deferred actor=" + akActor + " reason=event_locked registered=" + BoolText(lockedRegistered) + " request=" + asReason)
		Return lockedRegistered
	EndIf

	If !ShouldOwnAliasActor(akActor)
		Debug.Trace("[TFD][TeammateRegistry] Converted package repair rejected actor=" + akActor + " reason=not_tfd_owned request=" + asReason + " playerTeammate=" + BoolText(akActor.IsPlayerTeammate()) + " followerAnchor=" + BoolText(HasFollowerAnchorFaction(akActor)))
		Return False
	EndIf

	If HasActiveTFDTeammateMarker(akActor)
		EnsureActiveTeammateContract(akActor, "bridge_repair_contract_" + asReason)
	EndIf

	If IsR86DiagnosticPackageInterferenceReason(asReason)
		Debug.Trace("[TFD][TeammateRegistry] Converted package repair skipped by R86 vanilla assist isolation actor=" + akActor + " reason=" + asReason + " registered=" + BoolText(IsRegistered(akActor)))
		Return IsRegistered(akActor)
	EndIf

	If !IsRegistered(akActor)
		Return RegisterTeammate(akActor)
	EndIf

	If ShouldSuppressSoftRepairDuringCombatBehavior(akActor, asReason)
		TraceCombatDiag("bridge_repair_suppressed_combat_behavior", akActor, asReason)
		Debug.Trace("[TFD][TeammateRegistry] Converted package repair suppressed by combat behavior actor=" + akActor + " reason=" + asReason + " registered=TRUE")
		Return True
	EndIf

	TraceCombatDiag("bridge_repair_before_prime", akActor, asReason)
	PrimeConvertedPackageAfterRegister(akActor, asReason, True)
	TraceCombatDiag("bridge_repair_after_prime", akActor, asReason)

	If _lastPrimePackageSuppressedByCombatBehavior
		Debug.Trace("[TFD][TeammateRegistry] Converted package repair aborted by combat behavior actor=" + akActor + " reason=" + asReason + " registered=TRUE")
		Return True
	EndIf

	Debug.Trace("[TFD][TeammateRegistry] Converted package repair actor=" + akActor + " reason=" + asReason + " registered=TRUE tfdMarker=TRUE")
	Return True
EndFunction

Function UpdateConvertedFollowMaintenance()
	If !EnableConvertedFollowMaintenance
		Return
	EndIf

	Float nowTime = Utility.GetCurrentRealTime()
	If nowTime < _nextConvertedFollowNudgeAt
		Return
	EndIf

	Float useInterval = ConvertedFollowNudgeInterval
	If useInterval < 0.25
		useInterval = 0.25
	EndIf
	_nextConvertedFollowNudgeAt = nowTime + useInterval

	Actor playerRef = GetPlayerActor()
	If playerRef == None
		Return
	EndIf

	If playerRef.IsDead()
		Return
	EndIf

	Int i = 0
	While i < GetMaxSlots()
		Actor teammate = GetTeammateBySlot(i)
		If teammate != None
			MaintainConvertedFollowForActor(teammate, playerRef, i)
		EndIf
		i += 1
	EndWhile
EndFunction

Function MaintainConvertedFollowForActor(Actor akActor, Actor akPlayer, Int aiSlot)
	If akActor == None || akPlayer == None
		Return
	EndIf

	If akActor == akPlayer
		Return
	EndIf

	If akActor.IsDead() || akActor.IsBleedingOut() || akActor.IsDisabled()
		Return
	EndIf

	If !HasTFDTeammateMarker(akActor)
		Return
	EndIf

	; R88: keep R86 vanilla-assist isolation, but allow a safe follow-package nudge
	; when there is no concrete combat pressure. R87 blocked the initial prime too often,
	; so this gives idle converted teammates a way to settle back into follow without
	; StopCombat, MoveTo, AI toggle, or Papyrus StartCombat.
	If HasActiveTFDTeammateMarker(akActor)
		EnsureActiveTeammateContract(akActor, "follow_maintenance_r90_contract_safe")
	Else
		EnsureConvertedPlayerAlliance(akActor, "follow_maintenance_r90_contract_safe")
	EndIf

	If RunPostCombatFollowPrimeIfNeeded(akActor, aiSlot)
		Return
	EndIf

	If !ShouldBlockPrimePackageTouchNow(akActor, "follow_maintenance_r90_safe_eval") && !ShouldSuppressSoftRepairDuringCombatBehavior(akActor, "follow_maintenance_r90_safe_eval")
		If !akActor.IsInCombat() && akActor.GetCombatTarget() == None && akActor.Is3DLoaded()
			Float distanceToPlayerSafe = akActor.GetDistance(akPlayer)
			If distanceToPlayerSafe > 512.0
				TraceCombatDiag("follow_maintenance_safe_eval_before_r90", akActor, "follow_maintenance")
				akActor.EvaluatePackage()
				TraceCombatDiag("follow_maintenance_safe_eval_after_r90", akActor, "follow_maintenance")
			EndIf
		EndIf
	EndIf
	Return

	If ShouldSuppressSoftRepairDuringCombatBehavior(akActor, "follow_maintenance")
		TraceCombatDiag("follow_maintenance_suppressed_combat_behavior", akActor, "follow_maintenance")
		Return
	EndIf

	Bool changed = False
	Bool moved = False
	Bool combatCleared = False
	Bool validCombatTarget = False
	Bool diagRelevant = akActor.IsInCombat() || akActor.GetCombatTarget() != None || akPlayer.IsInCombat()

	If diagRelevant
		TraceCombatDiag("follow_maintenance_enter", akActor, "follow_maintenance")
	EndIf

	If HasActiveTFDTeammateMarker(akActor)
		If EnsureActiveTeammateContract(akActor, "follow_maintenance")
			changed = True
		EndIf
	ElseIf EnsureConvertedPlayerAlliance(akActor, "follow_maintenance")
		changed = True
	EndIf

	If akActor.IsInCombat()
		Actor combatTarget = akActor.GetCombatTarget()
		If combatTarget != None && combatTarget != akPlayer && !IsLikelyTeammateActor(combatTarget)
			validCombatTarget = True
		Else
			TraceCombatDiag("follow_maintenance_stopcombat_before", akActor, "follow_maintenance")
			akActor.StopCombat()
			akActor.StopCombatAlarm()
			TraceCombatDiag("follow_maintenance_stopcombat_after", akActor, "follow_maintenance")
			combatCleared = True
			changed = True
		EndIf
	EndIf

	If validCombatTarget
		Return
	EndIf

	Float distanceToPlayer = akActor.GetDistance(akPlayer)
	Bool actorLoaded = akActor.Is3DLoaded()

	Float catchUpDistance = ConvertedFollowCatchUpDistance
	If catchUpDistance < 4096.0
		catchUpDistance = 6000.0
	EndIf

	; R23: do not teleport converted followers during normal follow maintenance.
	; MoveTo is opt-in emergency recovery only, for unloaded or truly far actors.
	If EnableConvertedFollowMoveTo
		If !actorLoaded || distanceToPlayer > catchUpDistance
			Float slotOffset = aiSlot * 96.0
			Float xOffset = ConvertedFollowCatchUpOffset + slotOffset
			akActor.MoveTo(akPlayer, xOffset, -256.0, 0.0, True)
			moved = True
			changed = True
		EndIf
	EndIf

	Float evalDistance = ConvertedFollowEvaluateDistance
	If evalDistance < 2048.0
		evalDistance = 2048.0
	EndIf

	; R35: do not re-evaluate every few seconds while the actor is already close enough.
	; Frequent EvaluatePackage calls can look like the follow package is lepas-pasang.
	If changed || !actorLoaded || distanceToPlayer > evalDistance
		If diagRelevant
			TraceCombatDiag("follow_maintenance_eval_before", akActor, "follow_maintenance")
		EndIf
		akActor.EvaluatePackage()
		If diagRelevant
			TraceCombatDiag("follow_maintenance_eval_after", akActor, "follow_maintenance")
		EndIf
	EndIf

	If moved
		Debug.Trace("[TFD][TeammateRegistry] Converted follow emergency moveto actor=" + akActor + " slot=" + aiSlot + " dist=" + distanceToPlayer + " loaded=" + BoolText(actorLoaded) + " combatCleared=" + BoolText(combatCleared))
	EndIf
EndFunction

Bool Function ShouldRunAssistUpdate()
	Actor playerRef = GetPlayerActor()
	If playerRef == None
		Return False
	EndIf

	If playerRef.IsDead()
		Return False
	EndIf

	If GetStandingRegisteredCount() <= 0
		Return False
	EndIf

	; R89: normal combat assist is no longer fully disabled.
	; Keep the vanilla follower package stack as owner, but run a light target-retention tick
	; while the player/roster has real combat pressure or a short-lived cached target.
	If playerRef.IsBleedingOut()
		Return True
	EndIf

	Actor playerTarget = playerRef.GetCombatTarget()
	If IsValidAssistTarget(playerTarget)
		Return True
	EndIf

	If playerRef.IsInCombat()
		Return True
	EndIf

	If _cachedAssistTarget != None
		If Utility.GetCurrentRealTime() <= _cachedAssistTargetUntil && IsValidAssistTarget(_cachedAssistTarget)
			Return True
		EndIf
	EndIf

	If HasAssistAlertWindow()
		Return True
	EndIf

	Int i = 0
	While i < GetMaxSlots()
		Actor teammate = GetTeammateBySlot(i)
		If teammate != None
			If !teammate.IsDead() && !teammate.IsBleedingOut() && !teammate.IsDisabled()
				If teammate.IsInCombat()
					Return True
				EndIf

				Actor teammateTarget = teammate.GetCombatTarget()
				If IsValidAssistTarget(teammateTarget)
					Return True
				EndIf
			EndIf
		EndIf
		i += 1
	EndWhile

	Return False
EndFunction

Function RefreshAssistTargetCache()
	Actor liveTarget = ResolveLiveAssistTarget()
	If IsValidAssistTarget(liveTarget)
		StoreCachedAssistTarget(liveTarget)
	ElseIf Utility.GetCurrentRealTime() > _cachedAssistTargetUntil || !IsValidAssistTarget(_cachedAssistTarget)
		StoreCachedAssistTarget(None)
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

	; R90: R89 only retained an already-known target. When the current target goes down,
	; vanilla can briefly leave every teammate with target=None while another hostile is still red/on radar.
	; Use a strict nearby-threat scan only while real combat pressure exists.
	Actor scannedTarget = FindNearbyAssistThreat("resolve_live_assist")
	If IsValidScannedAssistThreat(scannedTarget)
		Return scannedTarget
	EndIf

	Return None
EndFunction

Actor Function ResolveSharedAssistTarget()
	Actor liveTarget = ResolveLiveAssistTarget()
	If IsValidAssistTarget(liveTarget)
		StoreCachedAssistTarget(liveTarget)
		Return liveTarget
	EndIf

	If _cachedAssistTarget != None && Utility.GetCurrentRealTime() <= _cachedAssistTargetUntil && IsValidAssistTarget(_cachedAssistTarget)
		Return _cachedAssistTarget
	EndIf

	If Utility.GetCurrentRealTime() > _cachedAssistTargetUntil
		StoreCachedAssistTarget(None)
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
	Bool hasSharedTarget = IsValidAssistTarget(sharedTarget)

	Int i = 0
	While i < GetMaxSlots()
		Actor teammate = GetTeammateBySlot(i)
		If teammate != None
			If !teammate.IsDead() && !teammate.IsBleedingOut() && !teammate.IsDisabled()
				Actor teammateTarget = teammate.GetCombatTarget()
				If hasSharedTarget || IsValidAssistTarget(teammateTarget)
					NudgeAssistCombat(teammate, sharedTarget)
				EndIf
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
	TraceCombatDiag("papyrus_assist_enter", akActor, "assist_update")
	If target == None
		; No concrete target means no assist commit. Do not EvaluatePackage here,
		; because that can interrupt follow/combat package settling and looks like idle/sandbox drift.
		TraceCombatDiag("papyrus_assist_no_target", akActor, "assist_update")
		Return
	EndIf

	StoreCachedAssistTarget(target)

	If !akActor.IsInCombat()
		TraceCombatDiag("papyrus_assist_startcombat_before", akActor, "assist_update")
		akActor.StartCombat(target)
		TraceCombatDiag("papyrus_assist_startcombat_after", akActor, "assist_update")
	ElseIf akActor.GetCombatTarget() != target
		TraceCombatDiag("papyrus_assist_retarget_before", akActor, "assist_update")
		akActor.StartCombat(target)
		TraceCombatDiag("papyrus_assist_retarget_after", akActor, "assist_update")
	EndIf

	If !akActor.IsWeaponDrawn()
		akActor.DrawWeapon()
	EndIf

	; R89: no EvaluatePackage after StartCombat/retarget.
	; Vanilla follower package remains owner; this tick only retains/refreshes combat target.
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

Bool Function HasActiveTFDTeammateMarker(Actor akActor)
	If akActor == None
		Return False
	EndIf

	If TFDTeammateFaction != None
		If akActor.IsInFaction(TFDTeammateFaction)
			Return True
		EndIf
	EndIf

	Return False
EndFunction

Bool Function HasExpiredTeammateMarker(Actor akActor)
	If akActor == None
		Return False
	EndIf

	If TFDExpiredTeammate != None
		If akActor.IsInFaction(TFDExpiredTeammate)
			Return True
		EndIf
	EndIf

	Return False
EndFunction

Bool Function HasTFDTeammateMarker(Actor akActor)
	If akActor == None
		Return False
	EndIf

	If TFDTeammateFaction != None
		If akActor.IsInFaction(TFDTeammateFaction)
			Return True
		EndIf
	EndIf

	If TFDExpiredTeammate != None
		If akActor.IsInFaction(TFDExpiredTeammate)
			Return True
		EndIf
	EndIf

	Return False
EndFunction

Bool Function ShouldOwnAliasActor(Actor akActor)
	; R61: only TFD-converted humanoids should occupy TFDPlayerTeammateQuest aliases.
	; Natural vanilla/framework followers can still be recognized as player-side actors
	; by native code, but this quest must not apply TFDTeammatePackage to them.
	Return HasTFDTeammateMarker(akActor)
EndFunction

Bool Function IsLikelyTeammateActor(Actor akActor)
	If akActor == None
		Return False
	EndIf

	If akActor.IsDead() || akActor.IsDisabled()
		Return False
	EndIf

	If HasTFDTeammateMarker(akActor)
		Return True
	EndIf

	If !akActor.Is3DLoaded()
		Return IsRegistered(akActor)
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

	If akActor.IsDead() || akActor.IsDisabled()
		Debug.Trace("[TFD][TeammateRegistry] RegisterTeammate rejected actor=" + akActor + " reason=dead_or_disabled")
		Return False
	EndIf

	If !ShouldOwnAliasActor(akActor)
		Debug.Trace("[TFD][TeammateRegistry] RegisterTeammate rejected actor=" + akActor + " reason=not_tfd_owned playerTeammate=" + BoolText(akActor.IsPlayerTeammate()) + " followerAnchor=" + BoolText(HasFollowerAnchorFaction(akActor)))
		Return False
	EndIf

	If HasActiveTFDTeammateMarker(akActor)
		EnsureActiveTeammateContract(akActor, "register_teammate_contract")
	EndIf

	If IsRegistered(akActor)
		Return ForceRefreshRegisteredTeammate(akActor, "already_registered")
	EndIf

	Int emptyIndex = FindEmptySlotIndex()
	If emptyIndex < 0
		Debug.Trace("[TFD][TeammateRegistry] RegisterTeammate failed actor=" + akActor + " reason=no_empty_slot")
		Return False
	EndIf

	ReferenceAlias slotAlias = GetSlotByIndex(emptyIndex)
	If slotAlias == None
		Debug.Trace("[TFD][TeammateRegistry] RegisterTeammate failed actor=" + akActor + " reason=slot_alias_none index=" + emptyIndex)
		Return False
	EndIf

	If HasTFDTeammateMarker(akActor)
		EnsureConvertedPlayerAlliance(akActor, "register_teammate")
	EndIf

	slotAlias.ForceRefTo(akActor)

	If HasTFDTeammateMarker(akActor)
		PrimeConvertedPackageAfterRegister(akActor, "register_teammate", True)
		If _lastPrimePackageSuppressedByCombatBehavior
			MarkPostCombatPrimeNeeded(akActor, "register_teammate_blocked")
		EndIf
	Else
		akActor.EvaluatePackage()
	EndIf

	Debug.Trace("[TFD][TeammateRegistry] RegisterTeammate success actor=" + akActor + " slot=" + emptyIndex + " tfdMarker=" + BoolText(HasTFDTeammateMarker(akActor)))
	Return True
EndFunction

Bool Function ForceRebindConvertedTeammate(Actor akActor, String asReason = "converted_rebind")
	EnsureInit()

	If akActor == None
		Return False
	EndIf

	If akActor.IsDead() || akActor.IsDisabled()
		Debug.Trace("[TFD][TeammateRegistry] RebindConvertedTeammate rejected actor=" + akActor + " reason=dead_or_disabled reasonArg=" + asReason)
		Return False
	EndIf

	If !HasTFDTeammateMarker(akActor)
		Return False
	EndIf

	Int slotIndex = FindSlotIndex(akActor)
	If slotIndex < 0
		Return RegisterTeammate(akActor)
	EndIf

	ReferenceAlias slotAlias = GetSlotByIndex(slotIndex)
	If slotAlias == None
		Return False
	EndIf

	EnsureActiveTeammateContract(akActor, asReason)

	If ShouldBlockPrimePackageTouchNow(akActor, asReason)
		If ShouldPrimeConvertedPackageHard(asReason)
			MarkPostCombatPrimeNeeded(akActor, asReason + "_blocked")
		EndIf
		Debug.Trace("[TFD][TeammateRegistry] RebindConvertedTeammate skipped by R90 real-combat firewall slot=" + slotIndex + " actor=" + akActor + " reason=" + asReason + " tfdMarker=" + BoolText(HasTFDTeammateMarker(akActor)) + " playerTeammate=" + BoolText(akActor.IsPlayerTeammate()))
		TraceRosterSnapshotIfNeeded("rebind_blocked_" + asReason)
		Return True
	EndIf

	; R87: keep the old clear/ForceRefTo repair, but remove the wait gap.
	; A delayed Papyrus wait after Clear can leave a valid teammate temporarily out of alias ownership.
	slotAlias.Clear()
	slotAlias.ForceRefTo(akActor)
	PrimeConvertedPackageAfterRegister(akActor, asReason, True)
	If _lastPrimePackageSuppressedByCombatBehavior && ShouldPrimeConvertedPackageHard(asReason)
		MarkPostCombatPrimeNeeded(akActor, asReason + "_prime_suppressed")
	EndIf

	Debug.Trace("[TFD][TeammateRegistry] RebindConvertedTeammate slot=" + slotIndex + " actor=" + akActor + " reason=" + asReason + " tfdMarker=" + BoolText(HasTFDTeammateMarker(akActor)) + " playerTeammate=" + BoolText(akActor.IsPlayerTeammate()))
	Return True
EndFunction

Bool Function ForceRefreshRegisteredTeammate(Actor akActor, String asReason = "refresh")
	EnsureInit()

	If akActor == None
		Return False
	EndIf

	If akActor.IsDead() || akActor.IsDisabled()
		Debug.Trace("[TFD][TeammateRegistry] RefreshRegisteredTeammate rejected actor=" + akActor + " reason=dead_or_disabled reasonArg=" + asReason)
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

	Bool marker = HasTFDTeammateMarker(akActor)
	Bool changed = False
	Actor currentSlotActor = slotAlias.GetActorReference()

	If marker
		If HasActiveTFDTeammateMarker(akActor)
			If EnsureActiveTeammateContract(akActor, asReason)
				changed = True
			EndIf
		ElseIf EnsureConvertedPlayerAlliance(akActor, asReason)
			changed = True
		EndIf
	EndIf

	If currentSlotActor != akActor
		; Slot mismatch is real damage, so repair the alias and evaluate once.
		slotAlias.ForceRefTo(akActor)
		akActor.EvaluatePackage()
		Debug.Trace("[TFD][TeammateRegistry] RefreshRegisteredTeammate repaired slot=" + slotIndex + " actor=" + akActor + " reason=" + asReason + " tfdMarker=" + BoolText(marker))
		Return True
	EndIf

	If changed
		PrimeConvertedPackageAfterRegister(akActor, asReason, False)
		Debug.Trace("[TFD][TeammateRegistry] RefreshRegisteredTeammate statefix slot=" + slotIndex + " actor=" + akActor + " reason=" + asReason + " tfdMarker=" + BoolText(marker))
	ElseIf asReason != "register_or_refresh"
		Debug.Trace("[TFD][TeammateRegistry] RefreshRegisteredTeammate passive slot=" + slotIndex + " actor=" + akActor + " reason=" + asReason + " tfdMarker=" + BoolText(marker))
	EndIf

	Return True
EndFunction

Bool Function RegisterOrRefreshTeammate(Actor akActor)
	; R27: keep this legacy one-argument API.
	; TFDTeammateRegistryBridgeAlias.pex calls this every update with exactly one argument.
	; Do not add extra parameters here, or Papyrus will throw runtime argument-count errors.
	Return RegisterOrRefreshTeammateInternal(akActor, False, "register_or_refresh")
EndFunction

Bool Function ForceRegisterOrRefreshConvertedTeammate(Actor akActor, String asReason = "native_assign_rebind")
	Return RegisterOrRefreshTeammateInternal(akActor, True, asReason)
EndFunction

Bool Function RegisterOrRefreshTeammateInternal(Actor akActor, Bool abForceConvertedRebind, String asReason)
	EnsureInit()

	If akActor == None
		Return False
	EndIf

	If akActor.IsDead() || akActor.IsDisabled()
		Debug.Trace("[TFD][TeammateRegistry] RegisterOrRefresh rejected actor=" + akActor + " reason=dead_or_disabled request=" + asReason)
		Return False
	EndIf

	If _eventLocked
		Bool lockedRegistered = IsRegistered(akActor)
		Debug.Trace("[TFD][TeammateRegistry] RegisterOrRefresh deferred actor=" + akActor + " reason=event_locked registered=" + BoolText(lockedRegistered))
		Return lockedRegistered
	EndIf

	If !ShouldOwnAliasActor(akActor)
		Debug.Trace("[TFD][TeammateRegistry] RegisterOrRefresh rejected actor=" + akActor + " reason=not_tfd_owned tfdMarker=" + BoolText(HasTFDTeammateMarker(akActor)) + " playerTeammate=" + BoolText(akActor.IsPlayerTeammate()) + " followerAnchor=" + BoolText(HasFollowerAnchorFaction(akActor)) + " loaded=" + BoolText(akActor.Is3DLoaded()))
		Return False
	EndIf

	If HasActiveTFDTeammateMarker(akActor)
		EnsureActiveTeammateContract(akActor, "register_or_refresh_contract_" + asReason)
	EndIf

	If !IsLikelyTeammateActor(akActor)
		Debug.Trace("[TFD][TeammateRegistry] RegisterOrRefresh rejected actor=" + akActor + " reason=not_likely_teammate tfdMarker=" + BoolText(HasTFDTeammateMarker(akActor)) + " playerTeammate=" + BoolText(akActor.IsPlayerTeammate()) + " loaded=" + BoolText(akActor.Is3DLoaded()) + " dead=" + BoolText(akActor.IsDead()) + " bleeding=" + BoolText(akActor.IsBleedingOut()) + " disabled=" + BoolText(akActor.IsDisabled()))
		Return False
	EndIf

	If IsRegistered(akActor)
		If abForceConvertedRebind && HasTFDTeammateMarker(akActor)
			Return ForceRebindConvertedTeammate(akActor, asReason)
		EndIf
		Return ForceRefreshRegisteredTeammate(akActor, asReason)
	EndIf

	Return RegisterTeammate(akActor)
EndFunction

Bool Function UnregisterTeammate(Actor akActor)
	EnsureInit()

	If akActor == None
		Return False
	EndIf

	If _eventLocked
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
		StoreCachedAssistTarget(None)
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

	StoreCachedAssistTarget(None)
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
				If slotActor.IsDead() || slotActor.IsDisabled()
					Debug.Trace("[TFD][TeammateRegistry] PruneInvalid slot=" + i + " actor=" + slotActor + " reason=dead_or_disabled tfdMarker=" + BoolText(HasTFDTeammateMarker(slotActor)))
					slotAlias.Clear()
					If _cachedAssistTarget == slotActor
						StoreCachedAssistTarget(None)
					EndIf
				ElseIf slotActor.Is3DLoaded()
					If ShouldOwnAliasActor(slotActor)
						Bool repairedContract = False
						If HasActiveTFDTeammateMarker(slotActor)
							repairedContract = EnsureActiveTeammateContract(slotActor, "prune_invalid_marker_repair")
						Else
							repairedContract = EnsureConvertedPlayerAlliance(slotActor, "prune_invalid_marker_repair")
						EndIf

						If repairedContract
							If !slotActor.IsInCombat() && !ShouldBlockPrimePackageTouchNow(slotActor, "prune_invalid_marker_repair") && !ShouldSuppressSoftRepairDuringCombatBehavior(slotActor, "prune_invalid_marker_repair")
								slotActor.EvaluatePackage()
							ElseIf ShouldBlockPrimePackageTouchNow(slotActor, "prune_invalid_marker_repair")
								Debug.Trace("[TFD][TeammateRegistry] PruneInvalid package touch skipped by R87 firewall slot=" + i + " actor=" + slotActor)
								TraceRosterSnapshotIfNeeded("prune_repair_blocked")
							EndIf
							Debug.Trace("[TFD][TeammateRegistry] PruneInvalid protected_tfd_marker repair_contract slot=" + i + " actor=" + slotActor)
						EndIf
					Else
						Debug.Trace("[TFD][TeammateRegistry] PruneInvalid slot=" + i + " actor=" + slotActor + " reason=not_tfd_owned tfdMarker=" + BoolText(HasTFDTeammateMarker(slotActor)) + " playerTeammate=" + BoolText(slotActor.IsPlayerTeammate()) + " followerAnchor=" + BoolText(HasFollowerAnchorFaction(slotActor)))
						slotAlias.Clear()
						If _cachedAssistTarget == slotActor
							StoreCachedAssistTarget(None)
						EndIf
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