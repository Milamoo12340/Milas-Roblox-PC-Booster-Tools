#SingleInstance, Force
CoordMode,Mouse,Screen
SetMouseDelay,-1
SetTitleMatchMode,2
SetBatchLines,10ms
global BC:={}
BC:={1:"Black",2:"Teal",3:"222222",4:"333333"}
global counter:=0,LC_1:="Silver",LC_2:="Maroon",LC_3:="0xE48904",LC_4:="0x37DC04",Off_Light,Standby_Light,On_Light
,Last_Selected:=1,Selected_Tab:=1,CheckBox_Background_Color:="Black",CheckBox_Color_On:="Teal",CheckBox_Color_Off:="Silver"
,W_9:=null,Target_X:=null,Target_Y:=null,P_8:=80,P_9:=80,S_6:=0,Click_Delay:=1,Turbo_Mode:=0,Current_Light:=1
Trim_Color:="Teal",Always:=1,Use_Target:=1,Stop:=0
Gui,1:+AlwaysOnTop -Caption Border
Gui,1:Color,Black,Black
Gui,1:Add,Progress,x0 y0 w350 h250 Background%Trim_Color% cBlack,100
Gui,1:Add,Progress,x5 y5 w10 h10 Background%Trim_Color% c%LC_2% vOff_Light,100
Gui,1:Add,Progress,x20 y5 w10 h10 Background%Trim_Color% c%LC_1% vStandBy_Light,100
Gui,1:Add,Progress,x35 y5 w10 h10 Background%Trim_Color% c%LC_1% vOn_Light,100
Gui,1:Add,Progress, x310 y3 w14 h14 Background%Trim_Color% c333333 ,100
Gui,1:Font,cTeal s12 Bold Q5,
Gui,1:Add,Text,x310 y2 w14 Center BackgroundTrans,-
Gui,1:Add,Progress, x330 y3 w14 h14 Background%Trim_Color% c333333 ,100
Gui,1:Font,cTeal s8  Q5,
Gui,1:Add,Text,x330 y3 w14 Center BackgroundTrans,X
Gui,1:Font,cTeal s12 Underline  Italic  Q5,Narkisim
Gui,1:Add,Text,x50 y2 w250 Center BackgroundTrans ,Smart Clicker v1.1.0
Gui,1:Add,Progress,x5 y20 w340 h225 Background%Trim_Color% c272829,100 
Gui,1:Add,Progress,x10 y30 w330 h40 Background%Trim_Color% c222222,100
Gui,1:Add,Progress,% "x19 y34 w72 h32 Background" BC.1
Gui,1:Add,Progress,% "x19 y34 w70 h30 Hidden v1_Button_Background Background" BC.2
Gui,1:Add,Progress,% "x20 y35 w70 h30 v1_Button Background"BC.4
Gui,1:Font,
Gui,1:Font,cTeal s10 Q5,Microsoft YaHei UI
Gui,1:Add,Text,x20 y40 w70 Center BackgroundTrans v1_Button_Text,Main
Gui,1:Add,Progress,% "x99 y34 w72 h32 Background" BC.1
Gui,1:Add,Progress,% "x99 y34 w70 h30 v2_Button_Background Background" BC.2
Gui,1:Add,Progress,% "x100 y35 w70 h30 v2_Button Background" BC.3
Gui,1:Add,Text,x100 y40 w70 Center BackgroundTrans v2_Button_Text ,Window
Gui,1:Add,Progress,% "x179 y34 w72 h32 Background" BC.1
Gui,1:Add,Progress,% "x179 y34 w70 h30 v3_Button_Background Background" BC.2
Gui,1:Add,Progress,% "x180 y35 w70 h30 v3_Button Background" BC.3
Gui,1:Add,Text,x180 y40 w70 Center BackgroundTrans v3_Button_Text,Position
Gui,1:Add,Progress,% "x259 y34 w72 h32 Background" BC.1
Gui,1:Add,Progress,% "x259 y34 w70 h30 v4_Button_Background Background" BC.2
Gui,1:Add,Progress,% "x260 y35 w70 h30 v4_Button Background" BC.3
Gui,1:Add,Text,x260 y40 w70 Center BackgroundTrans v4_Button_Text,Speed
Gui,1:Add,Progress,x15 y80 w320 h100 Background%Trim_Color% c222222 ,100
Gui,1:Add,Progress,x25 y100 w15 h15 Border Background%CheckBox_Background_Color% c%CheckBox_Color_On% vM_1,100
Gui,1:Font,
Gui,1:Font,cSilver s10 Q5,Microsoft YaHei UI
Gui,1:Add,Text,x45 yp-3 BackgroundTrans vM_2,AlwaysOnTop
Gui,1:Add,Progress,x25 y130 w15 h15 Border Background%CheckBox_Background_Color% c%CheckBox_Color_On% vM_3,100
Gui,1:Add,Text,x45 yp-3 BackgroundTrans vM_4,Use Target Window
Gui,1:Font,cTeal s10 Q5,Microsoft YaHei UI
Gui,1:Add,Progress,% "x193 y90 w114 h27 vM_5 Background"BC.1
Gui,1:Add,Progress,% "x193 y90 w112 h25 vM_6 Background"BC.2
Gui,1:Add,Progress,% "x195 y92 w110 h23 vM_7 Background"BC.3
Gui,1:Add,Text,x195 y92 w110 h23 BackgroundTrans Center vM_8,FAQ
Gui,1:Add,Progress,% "x183 y125 w134 h40 vM_9 Background"BC.1
Gui,1:Add,Progress,% "x183 y125 w132 h38 vM_10 Background"BC.2
Gui,1:Add,Progress,% "x185 y127 w130 h36 vM_11 Background"BC.3
Gui,1:Add,Text,x185 y126 w130 h36 BackgroundTrans Center vM_12,Get More Free `nAuto Clickers
Gui,1:Add,Progress,% "x30 y95 w104 h34 Hidden vW_1 Background" BC.1
Gui,1:Add,Progress,% "x30 y95 w102 h32 Hidden vW_2 Background" BC.2
Gui,1:Add,Progress,% "x32 y97 w100 h30 Hidden vW_3 Background" BC.3
Gui,1:Font,cTeal s10 Q5,Microsoft YaHei UI
Gui,1:Add,Text,x32 y102 w100 BackgroundTrans Center Hidden vW_4, Set Window
Gui,1:Add,Progress,% "x215 y95 w104 h34 Hidden vW_5 Background" BC.1
Gui,1:Add,Progress,% "x215 y95 w102 h32 Hidden vW_6 Background" BC.2
Gui,1:Add,Progress,% "x217 y97 w100 h30 Hidden vW_7 Background" BC.3
Gui,1:Add,Text,x217 y102 w100 BackgroundTrans Center Hidden vW_8, Update
Gui,1:Font,
Gui,1:Add,Edit,cWhite x30 y140 w290 r1 Center Hidden vW_9,% W_9
Gui,1:Font,cTeal s10 Q5,Microsoft YaHei UI
Gui,1:Add,Progress,% "x70 y88 w100 h25 Hidden vP_1 Background" BC.1
Gui,1:Add,Progress,% "x70 y88 w98 h23 Hidden vP_2 Background" BC.2
Gui,1:Add,Progress,% "x72 y90 w96 h21 Hidden vP_3 Background" BC.3
Gui,1:Add,Text,x72 y90 w96 BackgroundTrans Center Hidden vP_4,Set Position
Gui,1:Font,
Gui,1:Add,Edit,cWhite x195 y90 w80 r1 Center ReadOnly Hidden vP_5,% Target_X " " Target_Y
Gui,1:Font,cSilver s10 Q5,Microsoft YaHei UI
Gui,1:Add,Text,x30 y125 BackgroundTrans Hidden vP_6, Box Width:
Gui,1:Add,Text,x30 y150 BackgroundTrans Hidden vP_7, Box Height:
Gui,1:Font,
Gui,1:Add,Edit,cWhite x115 y125 w60 r1 Center Number Hidden vP_8 gSubmit_All,% P_8
Gui,1:Add,Edit,cWhite x115 y150 w60 r1 Center Number Hidden vP_9 gSubmit_All,% P_9
Gui,1:Add,Progress,% "x210 y127 w100 h40 Hidden vP_10 Background" BC.1
Gui,1:Add,Progress,% "x210 y127 w98 h38 Hidden vP_11 Background" BC.2
Gui,1:Add,Progress,% "x212 y129 w96 h36 Hidden vP_12 Background" BC.3
Gui,1:Font,cTeal s10 Q5,Microsoft YaHei UI
Gui,1:Add,Text,x212 y138 w96 BackgroundTrans Center Hidden vP_13,Preview
Gui,1:Add,Progress, x40 y90 w15 h15 Border Hidden Background%CheckBox_Background_Color% c%CheckBox_Color_On% vS_1 ,100
Gui,1:Font,cSilver s10 Q5,Microsoft YaHei UI
Gui,1:Add,Text,x60 y87 BackgroundTrans Hidden vS_2 ,Use Click Delay
Gui,1:Add,Progress, x195 y90 w15 h15 Border Hidden Background%CheckBox_Background_Color% c%CheckBox_Color_Off% vS_3 ,100
Gui,1:Add,Text,x215 y87 BackgroundTrans Hidden vS_4 ,Turbo Mode
Gui,1:Add,Text,x60 y130 BackgroundTrans Hidden vS_5 ,Click Delay:
Gui,1:Font,
Gui,1:Add,Edit,cWhite x150 y130 w80 r1 Center Number Hidden vS_6 gSubmit_All, % S_6
Gui,1:Font,cSilver s10 Q5,Microsoft YaHei UI
Gui,1:Add,Text,x240 y130 BackgroundTrans Hidden vS_7 ,(in ms)
Gui,1:Add,Progress,% "x15 y195 w150 h40 Background" BC.1
Gui,1:Add,Progress,% "x15 y195 w148 h38 vStart_1 Background" BC.2
Gui,1:Add,Progress,% "x17 y197 w146 h36 vStart_2 Background" BC.3
Gui,1:Font,cTeal s16 Q5,Microsoft YaHei UI
Gui,1:Add,Text,x17 y200 w146 BackgroundTrans Center vStart_3,Start
Gui,1:Add,Progress,% "x185 y195 w150 h40 Background" BC.1
Gui,1:Add,Progress,% "x185 y195 w148 h38 vStop_1 Background" BC.2
Gui,1:Add,Progress,% "x187 y197 w146 h36 vStop_2 Background" BC.3
Gui,1:Add,Text,x187 y200 w146 BackgroundTrans Center vStop_3,Stop
Gui,2:Color,yellow
Gui,2:Add,Text,x50 y0 w250 h20 Border gMove_Window
Gui,2:Add,Text,x310 y3 w14 h14 Border gWin_Min
Gui,2:Add,Text,x330 y3 w14 h14 Border gGuiClose
Gui,2:Add,Text,x20 y35 w70 h30 Border gMain_Tab
Gui,2:Add,Text,x100 y35 w70 h30 Border gWindow_Tab
Gui,2:Add,Text,x180 y35 w70 h30 Border gLocation_Tab
Gui,2:Add,Text,x260 y35 w70 h30 Border gSpeed_Tab
Gui,2:Add,Text,x25 y100 w110 h20 Border vM_13 gAlways_On_Top
Gui,2:Add,Text,x25 y130 w140 h20 Border vM_14 gUse_Target_Window
Gui,2:Add,Text,x195 y92 w110 h23 Border vM_15 gGo_Faq
Gui,2:Add,Text,x185 y127 w130 h36 Border vM_16 gGet_More
Gui,2:Add,Text,x32 y97 w100 h30 vW_10 Border Hidden gSet_Target_Window
Gui,2:Add,Text,x217 y97 w100 h30 vW_11 Border Hidden gUpdate_Window
Gui,2:Add,Text,x30 y140 w290 h25 vW_12 Border Hidden gEdit_Target_Window
Gui,2:Add,Text,x72 y90 w96 h21 Border Hidden vP_14 gSet_Click_Location
Gui,2:Add,Text,x195 y90 w80 h22 Border Hidden vP_15
Gui,2:Add,Text,x115 y125 w60 h22 Border Hidden vP_16 gFocus_Box_Width
Gui,2:Add,Text,x115 y150 w60 h22 Border Hidden vP_17 gFocus_Box_Height
Gui,2:Add,Text,x212 y129 w96 h36 Border Hidden vP_18 gPreview_Click_Box
Gui,2:Add,Text,x40 y90 w120 h15 Border Hidden vS_8 gUse_Click_Delay
Gui,2:Add,Text,x195 y90 w120 h15 Border Hidden vS_9 gUse_Turbo_Mode
Gui,2:Add,Text,x150 y130 w80 h21 Border Hidden vS_10 gFocus_Click_Delay
Gui,2:Add,Text,x17 y197 w146 h36 Border gStart_Clicker
Gui,2:Add,Text,x187 y197 w146 h36 Border gStop_Clicker
Sleep,300
Gui,1:Show,w350 h250,HB Smart Clicker
WinGetPos,x,y,,,HB Smart Clicker
Gui,2:+AlwaysOnTop -Caption Border +Owner1 +LastFound
WinSet,Transparent,1
sleep,300
Gui,2:Show,x%x% y%y% w350 h250,Smart Clicker v1.1.0
return
Go_Faq:
	Button_Press(M_6,M_7,M_8,Stop)
	Show_Message("5")
	return
Get_More:
	Button_Press(M_10,M_11,M_12,Stop)
	Try{
		Run,https://www.youtube.com/watch?v=hhtnClgSwbQ&list=PLPI5C2_hIGGw7poIqgox3rDnyocwTxcY_
	}
	return
GuiClose:
	ExitApp
Win_Min:
	WinMinimize,HB Smart Clicker
	return
Move_Window:
	WIN_MOVE()
	return
Submit_All:
	Gui,1:Submit,NoHide
	return
Main_Tab:
	Change_Tabs("1")
	return
Window_Tab:
	Change_Tabs("2")
	return
Location_Tab:
	Change_Tabs("3")
	return
Speed_Tab:
	Change_Tabs("4")
	return
Use_Target_Window:
	Change_CheckBox(Use_Target,M_3,Stop)
	return
Always_On_Top:
	Change_CheckBox(Always,M_1,Stop,!Always)
	return
Set_Target_Window:
	Button_Press(W_2,W_3,W_4,Stop)
	W_9:=Set_Window()
	GuiControl,1:,W_9,% W_9
	return
Update_Window:
	Button_Press(W_6,W_7,W_8,Stop)
	Gui,1:Submit,NoHide
	return
Edit_Target_Window:
	GuiControl,1:Focus,W_9
	return
Set_Click_Location:
	Button_Press(P_2,P_3,P_4,Stop)
	Set_Click_Position()
	GuiControl,1:,P_5,% Target_X " " Target_Y
	return
Focus_Box_Width:
	GuiControl,1:Focus,P_8
	return
Focus_Box_Height:
	GuiControl,1:Focus,P_9
	return
Preview_Click_Box:
	Button_Press(P_11,P_12,P_13,Stop)
	if(Target_X!=null)
		Show_Preview_Box()
	else 
		Show_Message("1")
	return
Use_Click_Delay:
	Change_CheckBox(Click_Delay,S_1,Stop)
	return
Use_Turbo_Mode:
	Change_CheckBox(Turbo_Mode,S_3,Stop)
	return
Focus_Click_Delay:
	GuiControl,1:Focus,S_6
	return
Start_Clicker:
	Button_Press(Start_1,Start_2,Start_3,Stop)
	Run_Auto_Clicker()
	return
Stop_Clicker:
	Button_Press(Stop_1,Stop_2,Stop_3,Stop)
	return
Run_Auto_Clicker()	{
		global
		Stop:=0
		if(Target_X=null)	{
				Show_Message("2")
				return
			}
		if(W_9=null&&Use_Target=1)	{
				Show_Message("3")
				return
			}
		if(P_8<=4||P_9<=4||P_8=null||P_9=null)	{
				Show_Message("4")
				return
			}
		if(Turbo_Mode=1)
			SetBatchLines,-1
		else
			SetBatchLines,10ms
		Current_Light:=2
		Change_Lights(LC_1,LC_3,LC_1)
		While Stop=0	{
				if(Use_Target=1)	{
						If WinActive(W_9)
							Click_Function()
					}
				else if(Use_Target=0)
					Click_Function()
			}
		Current_Light:=1
		Change_Lights(LC_2,LC_1,LC_1)	
	}
Click_Function()	{
		t8:=P_8//2,t9:=P_9//2
		MouseGetPos,tx,ty
		if(tx>=(Target_X-t8)&&tx<=(Target_X+t8)&&ty>=(Target_Y-t9)&&ty<=(Target_Y+t9))	{
				if(Current_Light!=3)	{
						Current_Light:=3
						Change_Lights(LC_1,LC_1,LC_4)
					}
				Click, %Target_X% %Target_Y%
				if(Click_Delay=1)
					sleep, %S_6%
			}
		else if(Current_Light!=2)	{
				Current_Light:=2
				Change_Lights(LC_1,LC_3,LC_1)
			}
	}
Change_Lights(L_1,L_2,L_3)	{
		GuiControl,1:+c%L_1%,Off_Light
		GuiControl,1:+c%L_2%,Standby_Light
		GuiControl,1:+c%L_3%,On_Light
	}
Show_Message(Message_Number)   {
		Gui,1:+OwnDialogs
		if(Message_Number=1)
			msgbox,,Dumbass Alert!!!!,You need to set a click location before you can preview where you are going to click!
		else if(Message_Number=2)
			msgbox,48,Missing Info!,You need to select a click position before you can start the auto clicker.
		else if(Message_Number=3)
			msgbox,48,Missing Info!,You need to select a target window.
		else if(Message_Number=4)
			msgbox,48,Missing Info!,Something is wrong with the box size.`nMake sure that the box size is greater than 4x4px
		                            .`nvalues under 20x20px should not be used.
		else if(Message_Number=5)							
			MsgBox, 64, FAQ, Smart Clicker v1.1 By Hellbent aka CivReborn`n`nForget How To Set Up?`nVisit CivReborn On YouTube for setup video
			.`n`nHotkeys:`nThis is a auto pause auto clicker and has no need for most hotkeys
			.`nHowever`, you can exit this program at any time by pressing`nctrl+shift+alt+ESC						
	}
Show_Preview_Box()	{
		x1:=Target_X-(P_8//2),y1:=Target_Y-(P_9//2)
		WinMinimize,HB Smart Clicker
		Gui,3:Destroy
		Gui,3:+AlwaysOnTop -Caption Border +LastFound +Owner1
		Gui,3:Color,00FF00
		WinSet,Transparent,100
		Gui,3:Show,x%x1% y%y1% w%P_8% h%P_9%
		sleep,2500
		WinActivate,HB Smart Clicker
		Gui,3:Destroy
	}
Set_Click_Position()	{
		Loop	{
				ToolTip,Click the position you want to set.
				if(!GetKeyState("LButton")&&!isPressed)
					isPressed:=1
				else if(GetKeyState("LButton")&&isPressed)	{
						MouseGetPos,Target_X,Target_Y
						ToolTip,
						break
					}
			}
	}
Set_Window()	{
		i:=0
		Loop	{
				ToolTip,Click on the target window twice to lock it.
				if(!GetkeyState("LButton")&&!isPressed)
					isPressed:=1
				else if(GetkeyState("LButton")&&isPressed=1)	{
						i++,isPressed:=0
						if(i>=2)	{
								WinGetTitle,Target,A
								ToolTip,
								break
							}
					}
			}
		return Target	
	}
Button_Press(ByRef E_1,ByRef E_2,ByRef E_3,ByRef Halt)	{
		Halt:=1
		GuiControl,% "1:+Background" BC.4,E_2
		GuiControl,1:+Redraw,E_3
		While GetKeyState("LButton")
			sleep, 150
		GuiControl,% "1:+Background" BC.3,E_2
		GuiControl,1:+Redraw,E_3
	}
Change_CheckBox(ByRef Check_Value,ByRef Control_Name,ByRef Halt,ByRef AOT:=2)	{
		if(AOT=1)
			Gui,1:+AlwaysOnTop
		else if(AOT=0)
			Gui,1:-AlwaysOnTop
		Check_Value:=!Check_Value,Halt:=1
		if Check_Value
			GuiControl,1:+c%CheckBox_Color_On%,Control_Name
		else
			GuiControl,1:+c%CheckBox_Color_Off%,Control_Name
	}
Change_Tabs(New_Tab)	{
		if(Selected_Tab!=New_Tab)	{
				Selected_Tab:=New_Tab
				Fix_Tabs()
				Remove_Window()
				Add_Tab()
				Last_Selected:=Selected_Tab
			}
	}
Add_Tab()	{
		if(Selected_Tab=1)
			Loop_1:=12,Loop_2:=4,Letter:="M"
		else if(Selected_Tab=2)
			Loop_1:=9,Loop_2:=3,Letter:="W"
		else if(Selected_Tab=3)
			Loop_1:=13,Loop_2:=5,Letter:="P"
		else if(Selected_Tab=4)
			Loop_1:=7,Loop_2:=3,Letter:="S"
		i:=1
		Loop % Loop_1	{
				GuiControl,1:Show,%Letter%_%i%
				i++
			}
		Loop % Loop_2	{
				GuiControl,2:Show,%Letter%_%i%
				i++
			}
	}
Remove_Window()	{
		if(Last_Selected=1)
			Loop_1:=12,Loop_2:=4,Letter:="M"
		else if(Last_Selected=2)
			Loop_1:=9,Loop_2:=3,Letter:="W"
		else if(Last_Selected=3)
			Loop_1:=13,Loop_2:=5,Letter:="P"
		else if(Last_Selected=4)
			Loop_1:=7,Loop_2:=3,Letter:="S"
		i:=1
		Loop % Loop_1	{
				GuiControl,1:Hide,%Letter%_%i%
				i++
			}
		Loop % Loop_2	{
				GuiControl,2:Hide,%Letter%_%i%
				i++
			}
	}
Fix_Tabs()	{
		GuiControl,1:Show,%Last_Selected%_Button_Background
		GuiControl,% "1:+Background" BC.3,%Last_Selected%_Button
		GuiControl,1:+ReDraw,%Last_Selected%_Button_Text
		GuiControl,1:Hide,%Selected_Tab%_Button_Background
		GuiControl,% "1:+Background" BC.4,%Selected_Tab%_Button
		GuiControl,1:+ReDraw,%Selected_Tab%_Button_Text
	}
WIN_MOVE()	{
		PostMessage,0xA1,2
		While(GetKeyState("LButton"))
			sleep,10
		;~ WinGetPos,x,y,,,A
		WinGetPos,x,y,,,Smart Clicker v1.1.0
		Gui,1:Show,x%x% y%y%
	}
*^+!ESC::ExitApp