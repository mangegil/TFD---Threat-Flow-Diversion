Scriptname TFDCaptiveLootAliasScript extends ReferenceAlias

Bool Property FiredThisCycle Auto Hidden

Event OnInit()
	FiredThisCycle = False
EndEvent

Event OnPlayerLoadGame()
	FiredThisCycle = False
EndEvent

Event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
	If FiredThisCycle
		Return
	EndIf

	If akBaseItem == None
		Return
	EndIf

	If aiItemCount <= 0
		Return
	EndIf

	If akDestContainer != Game.GetPlayer()
		Return
	EndIf

	TFDCaptiveLootObjectiveScript objectiveQuest = GetOwningQuest() as TFDCaptiveLootObjectiveScript
	If objectiveQuest
		objectiveQuest.MarkLootTakenByPlayer()
		FiredThisCycle = True
	EndIf
EndEvent

Function ResetLootWatch()
	FiredThisCycle = False
EndFunction