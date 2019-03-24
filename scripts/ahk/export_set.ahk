; AutoHotkey
; Opens Terminal and exports EA's SET file.

; Initialize variables.
EA = %1%
if (!EA)
  EA := "EA"

; Execute the terminal.
Run, "terminal.exe" "/skipupdate /portable"
Process, Wait, "terminal.exe", 10
if ErrorLevel {
    MsgBox, Cannot open Terminal app.
    Process, Close, terminal.exe
    ExitApp
}

; Wait till the window is active.
WinWaitActive, ahk_class MetaQuotes::MetaTrader::4.00
IfWinNotActive, ahk_class MetaQuotes::MetaTrader::4.00
{
  WinActivate, ahk_class MetaQuotes::MetaTrader::4.00
}

; Close any popups.
Sleep, 200
Send, {Esc}, {Esc}
Sleep, 200
Send, {Esc}, {Esc}
Sleep, 200

; View Strategy Tester, if not present.
Sleep, 500
ControlGet, IsVisible, Visible, , Button1, ahk_class MetaQuotes::MetaTrader::4.00
if !IsVisible {
  Sleep, 500
  Send, ^r
  Sleep, 500
}
Sleep, 500

; Press _Expert properties_ button.
ControlClick, Button1, ahk_class MetaQuotes::MetaTrader::4.00
if ErrorLevel {
    MsgBox, Cannot find Expert properties.
    Process, Close, terminal.exe
    ExitApp
}
Sleep, 200
WinActivate, ahk_class #32770
WinWaitActive, ahk_class #32770
Sleep, 200

; Select Inputs tab.
SendMessage, 0x1330, 1,, SysTabControl321, ahk_class #32770 ; 0x1330 is TCM_SETCURFOCUS.
if ErrorLevel {
    MsgBox, Cannot find Inputs tab.
    Process, Close, terminal.exe
    ExitApp
}
Sleep 200  ; This line and the next are necessary only for certain tab controls.
SendMessage, 0x130C, 1,, SysTabControl321, ahk_class #32770 ; 0x130C is TCM_SETCURSEL.
Sleep 500  ; This line and the next are necessary only for certain tab controls.

; Press _Save_ in Inputs tab.
WinActivate, ahk_class #32770
ControlClick, &Save, ahk_class #32770
if ErrorLevel {
    MsgBox, Cannot find Save button.
    Process, Close, terminal.exe
    ExitApp
}
Sleep, 1000

; Type filename, and confirm.
ControlSend, Edit1, {Control down}a{Control up}%EA%{Enter}, ahk_class #32770
if ErrorLevel {
    MsgBox, Cannot type the filename.
    Process, Close, terminal.exe
    ExitApp
}

; If asked to replace the file, confirm.
Sleep, 500
ControlGet, Handle, Hwnd, , Button1, ahk_class #32770
if (Handle) {
  ControlClick, , ahk_id %Handle%
}
Sleep, 500

; Press Accept.
ControlClick, Button5, ahk_class #32770
Sleep, 500

; Close Terminal.
Send, !fx, !{F4} ; File->Exit, Alt-F4
WinWaitClose, ahk_exe terminal.exe, 2
Process, Close, terminal.exe
