;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 4
Scriptname TFD_TIF__0507F1D3 Extends TopicInfo Hidden

;BEGIN FRAGMENT Fragment_3
Function Fragment_3(ObjectReference akSpeakerRef)
Actor akSpeaker = akSpeakerRef as Actor
;BEGIN CODE
;AFTER PLEASURE JOIN ENEMY

TFDPleasureQuestScript pleasureCtrl = (TFDPleasureQuest as TFDPleasureQuestScript)
If pleasureCtrl != None
	pleasureCtrl.ChooseJoinEnemy()
EndIf
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Quest Property TFDPleasureQuest auto
