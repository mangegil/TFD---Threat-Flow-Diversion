Scriptname TFDCaptiveLootObjectiveScript extends Quest

ReferenceAlias Property LootTarget Auto
Int Property LootObjective = 10 Auto
Float Property PollInterval = 0.50 Auto
Float Property HideDelayAfterComplete = 1.00 Auto

Bool Property ObjectiveVisible Auto Hidden
Bool Property ObjectiveDone Auto Hidden
Bool Property PendingHideAfterComplete Auto Hidden
ObjectReference Property LastTarget Auto Hidden
Int Property BaselineTargetUnits Auto Hidden

Event OnInit()
	RefreshLootObjective()
	RegisterForSingleUpdate(PollInterval)
EndEvent

Event OnPlayerLoadGame()
	RefreshLootObjective()
	RegisterForSingleUpdate(PollInterval)
EndEvent

Event OnUpdate()
	If PendingHideAfterComplete
		PendingHideAfterComplete = False

		If ObjectiveVisible
			SetObjectiveDisplayed(LootObjective, False, False)
			ObjectiveVisible = False
		EndIf

		RegisterForSingleUpdate(PollInterval)
		Return
	EndIf

	RefreshLootObjective()
	RegisterForSingleUpdate(PollInterval)
EndEvent

ObjectReference Function GetCurrentLootTarget()
	If LootTarget
		Return LootTarget.GetReference()
	EndIf

	Return None
EndFunction

Int Function CountTotalItemUnits(ObjectReference targetRef)
	If targetRef == None
		Return 0
	EndIf

	Int totalUnits = 0
	Int itemCount = targetRef.GetNumItems()
	Int i = 0
	While i < itemCount
		Form itemForm = targetRef.GetNthForm(i)
		If itemForm
			Int stackCount = targetRef.GetItemCount(itemForm)
			If stackCount > 0
				totalUnits += stackCount
			EndIf
		EndIf
		i += 1
	EndWhile

	Return totalUnits
EndFunction

Function ResetAliasWatchIfPresent()
	TFDCaptiveLootAliasScript lootAliasScript = LootTarget as TFDCaptiveLootAliasScript
	If lootAliasScript
		lootAliasScript.ResetLootWatch()
	EndIf
EndFunction

Function ApplyTargetState(ObjectReference currentTarget)
	LastTarget = currentTarget
	ResetAliasWatchIfPresent()

	If currentTarget != None
		BaselineTargetUnits = CountTotalItemUnits(currentTarget)

		If ObjectiveDone
			SetObjectiveCompleted(LootObjective, False)
		EndIf

		ObjectiveDone = False
		PendingHideAfterComplete = False
		SetObjectiveDisplayed(LootObjective, True, True)
		ObjectiveVisible = True
		SetActive(True)
	Else
		ForceClear()
	EndIf
EndFunction

Function RefreshLootObjective()
	ObjectReference currentTarget = GetCurrentLootTarget()

	If currentTarget != LastTarget
		ApplyTargetState(currentTarget)
		Return
	EndIf

	If currentTarget != None && !ObjectiveDone
		Int currentUnits = CountTotalItemUnits(currentTarget)

		If BaselineTargetUnits <= 0
			BaselineTargetUnits = currentUnits
		ElseIf currentUnits < BaselineTargetUnits
			BaselineTargetUnits = currentUnits
			MarkLootTakenByPlayer()
			Return
		EndIf
	EndIf

	Bool shouldShow = (currentTarget != None) && !ObjectiveDone
	If shouldShow != ObjectiveVisible
		SetObjectiveDisplayed(LootObjective, shouldShow, shouldShow)
		ObjectiveVisible = shouldShow
	EndIf
EndFunction

Function MarkLootTakenByPlayer()
	ObjectReference currentTarget = GetCurrentLootTarget()
	If currentTarget == None
		Return
	EndIf

	If !ObjectiveVisible
		SetObjectiveDisplayed(LootObjective, True, False)
		ObjectiveVisible = True
	EndIf

	If !ObjectiveDone
		SetObjectiveCompleted(LootObjective, True)
		ObjectiveDone = True
	EndIf

	BaselineTargetUnits = CountTotalItemUnits(currentTarget)
	PendingHideAfterComplete = True
	UnregisterForUpdate()
	RegisterForSingleUpdate(HideDelayAfterComplete)
EndFunction

Function ForceClear()
	If ObjectiveVisible
		SetObjectiveDisplayed(LootObjective, False, False)
	EndIf

	If ObjectiveDone
		SetObjectiveCompleted(LootObjective, False)
	EndIf

	ObjectiveVisible = False
	ObjectiveDone = False
	PendingHideAfterComplete = False
	LastTarget = None
	BaselineTargetUnits = 0
	ResetAliasWatchIfPresent()
EndFunction