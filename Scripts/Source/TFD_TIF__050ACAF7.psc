;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 5
Scriptname TFD_TIF__050ACAF7 Extends TopicInfo Hidden

;BEGIN FRAGMENT Fragment_4
Function Fragment_4(ObjectReference akSpeakerRef)
Actor akSpeaker = akSpeakerRef as Actor
;BEGIN CODE
;AFTER PLEASURE REDO

TFDPleasureQuestScript pleasureCtrl = (TFDPleasureQuest as TFDPleasureQuestScript)
If pleasureCtrl != None
	pleasureCtrl.ChooseRedo()
EndIf
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Quest Property TFDPleasureQuest Auto
