;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 3
Scriptname TFD_TIF__0506FEAC Extends TopicInfo Hidden

;BEGIN FRAGMENT Fragment_0
Function Fragment_0(ObjectReference akSpeakerRef)
Actor akSpeaker = akSpeakerRef as Actor
;BEGIN CODE
TFDSystemEventQuestScript sys = (TFDSystemEventQuest as TFDSystemEventQuestScript)
(TFDCaptiveBridgeQuest as TFDCaptiveBridge).MarkCaptiveDialogueOwned(akSpeaker)
If sys != None
	sys.BeginDialogueRoute(sys.FLOW_CAPTIVE, sys.ENTRY_CAPTIVE_CALL, akSpeaker, "captivedialogue_entry")
	sys.MarkDialogueNegotiating(akSpeaker, "captivedialogue_main")
	sys.SetDialogueBranch(sys.BRANCH_MAIN, akSpeaker, "captivedialogue_main")
Else
	Debug.Trace("TFD_TIF__0506FEAC: TFDSystemEventQuest property is None")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Quest Property TFDCaptiveBridgeQuest Auto
Quest Property TFDSystemEventQuest Auto
