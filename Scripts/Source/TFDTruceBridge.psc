Scriptname TFDTruceBridge extends Quest

; Crowd bridge only.
; Speaker ownership stays in the active humanoid flow quest:
; - TFDPreCombatQuest Speaker
; - TFDInCombatBridge Speaker
; - TFDBleedoutQuest Speaker
;
; This quest only tracks supporting crowd actors that should stay calm
; and visually hold the negotiation perimeter.

ReferenceAlias Property Crowd01 Auto
ReferenceAlias Property Crowd02 Auto
ReferenceAlias Property Crowd03 Auto
ReferenceAlias Property Crowd04 Auto
ReferenceAlias Property Crowd05 Auto
ReferenceAlias Property Crowd06 Auto
ReferenceAlias Property Crowd07 Auto
ReferenceAlias Property Crowd08 Auto
ReferenceAlias Property Crowd09 Auto
ReferenceAlias Property Crowd10 Auto

Bool Property AllowAutoPackageEval = True Auto
Bool Property ClearAllOnPlayerLoadGame = True Auto
Float Property UpdateInterval = 0.35 Auto
Float Property PostLoadRetryInterval = 0.75 Auto
Int Property PostLoadRetryCount = 4 Auto

Int _pendingPostLoadRetries = 0

Function RegisterEvents()
    UnregisterForAllModEvents()
    RegisterForModEvent("TFDTruceAssign", "OnBridgeEvent")
    RegisterForModEvent("TFDTruceUnassign", "OnBridgeEvent")
    RegisterForModEvent("TFDTruceClearAll", "OnBridgeEvent")
    TraceDebug("RegisterEvents done")
EndFunction

Event OnInit()
    TraceDebug("OnInit")
    RegisterEvents()
    RegisterForSingleUpdate(UpdateInterval)
EndEvent

Event OnPlayerLoadGame()
    TraceDebug("OnPlayerLoadGame")

    if ClearAllOnPlayerLoadGame
        ClearAll()
    else
        PruneInvalidSlots()
    endif

    RegisterEvents()
    _pendingPostLoadRetries = PostLoadRetryCount
    RegisterForSingleUpdate(PostLoadRetryInterval)
EndEvent

Event OnBridgeEvent(String eventName, String strArg, Float numArg, Form sender)
    TraceDebug("OnBridgeEvent name=" + eventName + " sender=" + FormLabel(sender))

    if eventName == "TFDTruceAssign"
        Actor aAssign = sender as Actor
        if aAssign != None
            AssignActor(aAssign)
        else
            TraceDebug("Assign ignored: sender is not Actor")
        endif
        return
    endif

    if eventName == "TFDTruceUnassign"
        Actor aClear = sender as Actor
        if aClear != None
            ClearActor(aClear)
        else
            TraceDebug("Unassign ignored: sender is not Actor")
        endif
        return
    endif

    if eventName == "TFDTruceClearAll"
        ClearAll()
        return
    endif

    TraceDebug("Unknown bridge event ignored")
EndEvent

Event OnUpdate()
    if _pendingPostLoadRetries > 0
        _pendingPostLoadRetries -= 1
        PruneInvalidSlots()
        MaintainAllActors()
        RegisterForSingleUpdate(PostLoadRetryInterval)
        return
    endif

    MaintainAllActors()
    RegisterForSingleUpdate(UpdateInterval)
EndEvent

Function AssignActor(Actor a)
    if a == None
        TraceDebug("AssignActor ignored: actor=None")
        return
    endif

    PruneInvalidSlots()
    TraceDebug("AssignActor begin actor=" + ActorLabel(a))

    ReferenceAlias existing = FindSlotHolding(a)
    if existing != None
        TraceDebug("AssignActor actor already held by " + SlotName(existing))
        if AllowAutoPackageEval
            KickCrowdAI(a)
        endif
        return
    endif

    ReferenceAlias slot = FindFreeSlot()
    if slot == None
        TraceDebug("AssignActor failed: no free slot")
        DumpSlots("AssignActor no free slot")
        return
    endif

    slot.ForceRefTo(a)

    if slot.GetReference() == a
        TraceDebug("AssignActor ForceRefTo success slot=" + SlotName(slot) + " actor=" + ActorLabel(a))
    else
        TraceDebug("AssignActor ForceRefTo verify FAILED slot=" + SlotName(slot) + " now=" + FormLabel(slot.GetReference()))
    endif

    if AllowAutoPackageEval
        KickCrowdAI(a)
    endif

    DumpSlots("AssignActor after ForceRefTo")
EndFunction

Function ClearActor(Actor a)
    if a == None
        TraceDebug("ClearActor ignored: actor=None")
        return
    endif

    TraceDebug("ClearActor begin actor=" + ActorLabel(a))

    ReferenceAlias slot = FindSlotHolding(a)
    if slot == None
        TraceDebug("ClearActor no slot holds actor=" + ActorLabel(a))
        DumpSlots("ClearActor no slot")
        return
    endif

    if slot.GetReference() != None
        slot.Clear()
        TraceDebug("ClearActor cleared slot=" + SlotName(slot))
    endif

    RestoreNormalAI(a)
    DumpSlots("ClearActor after clear")
EndFunction

Function ClearAll()
    TraceDebug("ClearAll begin")
    DumpSlots("ClearAll before")

    Actor a1 = GetAliasActor(Crowd01)
    Actor a2 = GetAliasActor(Crowd02)
    Actor a3 = GetAliasActor(Crowd03)
    Actor a4 = GetAliasActor(Crowd04)
    Actor a5 = GetAliasActor(Crowd05)
    Actor a6 = GetAliasActor(Crowd06)
    Actor a7 = GetAliasActor(Crowd07)
    Actor a8 = GetAliasActor(Crowd08)
    Actor a9 = GetAliasActor(Crowd09)
    Actor a10 = GetAliasActor(Crowd10)

    ClearAlias(Crowd01)
    ClearAlias(Crowd02)
    ClearAlias(Crowd03)
    ClearAlias(Crowd04)
    ClearAlias(Crowd05)
    ClearAlias(Crowd06)
    ClearAlias(Crowd07)
    ClearAlias(Crowd08)
    ClearAlias(Crowd09)
    ClearAlias(Crowd10)

    RestoreNormalAI(a1)
    RestoreNormalAI(a2)
    RestoreNormalAI(a3)
    RestoreNormalAI(a4)
    RestoreNormalAI(a5)
    RestoreNormalAI(a6)
    RestoreNormalAI(a7)
    RestoreNormalAI(a8)
    RestoreNormalAI(a9)
    RestoreNormalAI(a10)

    DumpSlots("ClearAll after")
    TraceDebug("ClearAll end")
EndFunction

Function MaintainAllActors()
    PruneInvalidSlots()
    MaintainAliasActor(Crowd01)
    MaintainAliasActor(Crowd02)
    MaintainAliasActor(Crowd03)
    MaintainAliasActor(Crowd04)
    MaintainAliasActor(Crowd05)
    MaintainAliasActor(Crowd06)
    MaintainAliasActor(Crowd07)
    MaintainAliasActor(Crowd08)
    MaintainAliasActor(Crowd09)
    MaintainAliasActor(Crowd10)
EndFunction

Function MaintainAliasActor(ReferenceAlias al)
    Actor a = GetAliasActor(al)
    if a == None
        return
    endif

    if a.IsDead()
        TraceDebug("MaintainAliasActor dead -> clear alias=" + SlotName(al))
        al.Clear()
        return
    endif

    if !a.Is3DLoaded()
        return
    endif

    if a.IsInCombat()
        a.StopCombat()
        a.StopCombatAlarm()
        TraceDebug("MaintainAliasActor StopCombat actor=" + ActorLabel(a))
    endif

    if a.IsWeaponDrawn()
        a.SheatheWeapon()
        TraceDebug("MaintainAliasActor SheatheWeapon actor=" + ActorLabel(a))
    endif

    if AllowAutoPackageEval
        a.EvaluatePackage()
    endif
EndFunction

Function KickCrowdAI(Actor a)
    if a == None
        TraceDebug("KickCrowdAI ignored: actor=None")
        return
    endif

    TraceDebug("KickCrowdAI begin actor=" + ActorLabel(a) + " loaded=" + BoolLabel(a.Is3DLoaded()) + " inCombat=" + BoolLabel(a.IsInCombat()) + " weaponDrawn=" + BoolLabel(a.IsWeaponDrawn()))

    if !a.Is3DLoaded()
        TraceDebug("KickCrowdAI skip: actor 3D not loaded")
        return
    endif

    if a.IsInCombat()
        a.StopCombat()
        a.StopCombatAlarm()
        TraceDebug("KickCrowdAI StopCombat")
    endif

    if a.IsWeaponDrawn()
        a.SheatheWeapon()
        TraceDebug("KickCrowdAI SheatheWeapon")
    endif

    if AllowAutoPackageEval
        a.EvaluatePackage()
        TraceDebug("KickCrowdAI EvaluatePackage done")
    endif
EndFunction

Function RestoreNormalAI(Actor a)
    if a == None
        return
    endif

    TraceDebug("RestoreNormalAI begin actor=" + ActorLabel(a) + " loaded=" + BoolLabel(a.Is3DLoaded()) + " inCombat=" + BoolLabel(a.IsInCombat()) + " weaponDrawn=" + BoolLabel(a.IsWeaponDrawn()))

    if !a.Is3DLoaded()
        TraceDebug("RestoreNormalAI skip: actor 3D not loaded")
        return
    endif

    ; IMPORTANT:
    ; On unassign/clear, do NOT stop combat or force sheathe.
    ; Native side owns hostility recovery and rehostile decisions.
    ; This bridge only stops maintaining the calm surround state.
    a.EvaluatePackage()
    TraceDebug("RestoreNormalAI lightweight EvaluatePackage done")
EndFunction

Function PruneInvalidSlots()
    PruneAliasIfInvalid(Crowd01)
    PruneAliasIfInvalid(Crowd02)
    PruneAliasIfInvalid(Crowd03)
    PruneAliasIfInvalid(Crowd04)
    PruneAliasIfInvalid(Crowd05)
    PruneAliasIfInvalid(Crowd06)
    PruneAliasIfInvalid(Crowd07)
    PruneAliasIfInvalid(Crowd08)
    PruneAliasIfInvalid(Crowd09)
    PruneAliasIfInvalid(Crowd10)
EndFunction

Function PruneAliasIfInvalid(ReferenceAlias al)
    Actor a = GetAliasActor(al)
    if a == None
        if al != None && al.GetReference() != None
            al.Clear()
        endif
        return
    endif

    if a.IsDead()
        TraceDebug("PruneAliasIfInvalid dead -> clear alias=" + SlotName(al))
        al.Clear()
        return
    endif
EndFunction

Bool Function Contains(Actor a)
    return FindSlotHolding(a) != None
EndFunction

Bool Function HasFreeSlot()
    return FindFreeSlot() != None
EndFunction

Int Function GetUsedSlotCount()
    Int count = 0
    if GetAliasActor(Crowd01) != None
        count += 1
    endif
    if GetAliasActor(Crowd02) != None
        count += 1
    endif
    if GetAliasActor(Crowd03) != None
        count += 1
    endif
    if GetAliasActor(Crowd04) != None
        count += 1
    endif
    if GetAliasActor(Crowd05) != None
        count += 1
    endif
    if GetAliasActor(Crowd06) != None
        count += 1
    endif
    if GetAliasActor(Crowd07) != None
        count += 1
    endif
    if GetAliasActor(Crowd08) != None
        count += 1
    endif
    if GetAliasActor(Crowd09) != None
        count += 1
    endif
    if GetAliasActor(Crowd10) != None
        count += 1
    endif
    return count
EndFunction

Actor Function GetActorBySlotIndex(Int slotIndex)
    if slotIndex == 1
        return GetAliasActor(Crowd01)
    endif
    if slotIndex == 2
        return GetAliasActor(Crowd02)
    endif
    if slotIndex == 3
        return GetAliasActor(Crowd03)
    endif
    if slotIndex == 4
        return GetAliasActor(Crowd04)
    endif
    if slotIndex == 5
        return GetAliasActor(Crowd05)
    endif
    if slotIndex == 6
        return GetAliasActor(Crowd06)
    endif
    if slotIndex == 7
        return GetAliasActor(Crowd07)
    endif
    if slotIndex == 8
        return GetAliasActor(Crowd08)
    endif
    if slotIndex == 9
        return GetAliasActor(Crowd09)
    endif
    if slotIndex == 10
        return GetAliasActor(Crowd10)
    endif
    return None
EndFunction

Actor Function GetAliasActor(ReferenceAlias al)
    if al == None
        return None
    endif

    ObjectReference ref = al.GetReference()
    if ref == None
        return None
    endif

    return ref as Actor
EndFunction

Function ClearAlias(ReferenceAlias al)
    if al == None
        return
    endif

    if al.GetReference() != None
        al.Clear()
    endif
EndFunction

ReferenceAlias Function FindSlotHolding(Actor a)
    if a == None
        return None
    endif

    if GetAliasActor(Crowd01) == a
        return Crowd01
    endif
    if GetAliasActor(Crowd02) == a
        return Crowd02
    endif
    if GetAliasActor(Crowd03) == a
        return Crowd03
    endif
    if GetAliasActor(Crowd04) == a
        return Crowd04
    endif
    if GetAliasActor(Crowd05) == a
        return Crowd05
    endif
    if GetAliasActor(Crowd06) == a
        return Crowd06
    endif
    if GetAliasActor(Crowd07) == a
        return Crowd07
    endif
    if GetAliasActor(Crowd08) == a
        return Crowd08
    endif
    if GetAliasActor(Crowd09) == a
        return Crowd09
    endif
    if GetAliasActor(Crowd10) == a
        return Crowd10
    endif

    return None
EndFunction

ReferenceAlias Function FindFreeSlot()
    if Crowd01 != None && Crowd01.GetReference() == None
        return Crowd01
    endif
    if Crowd02 != None && Crowd02.GetReference() == None
        return Crowd02
    endif
    if Crowd03 != None && Crowd03.GetReference() == None
        return Crowd03
    endif
    if Crowd04 != None && Crowd04.GetReference() == None
        return Crowd04
    endif
    if Crowd05 != None && Crowd05.GetReference() == None
        return Crowd05
    endif
    if Crowd06 != None && Crowd06.GetReference() == None
        return Crowd06
    endif
    if Crowd07 != None && Crowd07.GetReference() == None
        return Crowd07
    endif
    if Crowd08 != None && Crowd08.GetReference() == None
        return Crowd08
    endif
    if Crowd09 != None && Crowd09.GetReference() == None
        return Crowd09
    endif
    if Crowd10 != None && Crowd10.GetReference() == None
        return Crowd10
    endif

    return None
EndFunction

Function DumpSlots(String reason)
    TraceDebug("DumpSlots reason=" + reason \
        + " | Crowd01=" + FormLabel(Crowd01.GetReference()) \
        + " | Crowd02=" + FormLabel(Crowd02.GetReference()) \
        + " | Crowd03=" + FormLabel(Crowd03.GetReference()) \
        + " | Crowd04=" + FormLabel(Crowd04.GetReference()) \
        + " | Crowd05=" + FormLabel(Crowd05.GetReference()) \
        + " | Crowd06=" + FormLabel(Crowd06.GetReference()) \
        + " | Crowd07=" + FormLabel(Crowd07.GetReference()) \
        + " | Crowd08=" + FormLabel(Crowd08.GetReference()) \
        + " | Crowd09=" + FormLabel(Crowd09.GetReference()) \
        + " | Crowd10=" + FormLabel(Crowd10.GetReference()))
EndFunction

String Function SlotName(ReferenceAlias al)
    if al == None
        return "None"
    endif

    if al == Crowd01
        return "Crowd01"
    endif
    if al == Crowd02
        return "Crowd02"
    endif
    if al == Crowd03
        return "Crowd03"
    endif
    if al == Crowd04
        return "Crowd04"
    endif
    if al == Crowd05
        return "Crowd05"
    endif
    if al == Crowd06
        return "Crowd06"
    endif
    if al == Crowd07
        return "Crowd07"
    endif
    if al == Crowd08
        return "Crowd08"
    endif
    if al == Crowd09
        return "Crowd09"
    endif
    if al == Crowd10
        return "Crowd10"
    endif

    return "UnknownSlot"
EndFunction

String Function ActorLabel(Actor a)
    if a == None
        return "None"
    endif

    return a + " | dead=" + BoolLabel(a.IsDead()) + " | loaded=" + BoolLabel(a.Is3DLoaded())
EndFunction

String Function FormLabel(Form f)
    if f == None
        return "None"
    endif
    return f as String
EndFunction

String Function BoolLabel(Bool b)
    if b
        return "1"
    endif
    return "0"
EndFunction

Function TraceDebug(String s)
    Debug.Trace("[TFDTruceBridge] " + s)
EndFunction