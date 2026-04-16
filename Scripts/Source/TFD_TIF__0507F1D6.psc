;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 3
Scriptname TFD_TIF__0507F1D6 Extends TopicInfo Hidden

;BEGIN FRAGMENT Fragment_1
Function Fragment_1(ObjectReference akSpeakerRef)
Actor akSpeaker = akSpeakerRef as Actor
;BEGIN CODE
;AFTER PLEASURE RECRUIT

TFDPleasureQuestScript pleasureCtrl = (TFDPleasureQuest as TFDPleasureQuestScript)
If pleasureCtrl != None
	pleasureCtrl.ChooseRecruit()
EndIf
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Quest Property TFDPleasureQuest Auto
