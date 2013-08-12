VERSION 5.00
Begin VB.UserControl vbalHookControl 
   ClientHeight    =   720
   ClientLeft      =   0
   ClientTop       =   0
   ClientWidth     =   795
   InvisibleAtRuntime=   -1  'True
   ScaleHeight     =   720
   ScaleWidth      =   795
   Begin VB.Image imgIcon 
      Height          =   600
      Left            =   120
      Picture         =   "vbalHookControl.ctx":0000
      Top             =   60
      Width           =   675
   End
End
Attribute VB_Name = "vbalHookControl"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'Note: this file has been modified for use within PhotoDemon.  The original version of this code required a separate subclass/hook module, which I have
'      rewritten against cSelfSubHookCallback to improve IDE safety and reliability.

'You may download the original version of this code at:
' http://www.vbaccelerator.com/home/VB/Code/Libraries/Hooks/Accelerator_Control/article.asp

'To the best of my knowledge, this code is released under a CC-BY-1.0 license.  (Assumed from the footer text of vbaccelerator.com: "All contents of this web site are licensed under a Creative Commons Licence, except where otherwise noted.")
' You may access a complete copy of this license at the following link:
' http://creativecommons.org/licenses/by/1.0/

'Many thanks to Steve McMahon for this excellent set of code, which makes proper accelerator (hotkey) handling much easier.

Option Explicit

Private Declare Function GetAsyncKeyState Lib "user32" (ByVal vKey As Long) As Integer
Private Declare Function GetParent Lib "user32" (ByVal hWnd As Long) As Long
Private Declare Function GetActiveWindow Lib "user32" () As Long

Private Type tAccel
    eKeyCode As KeyCodeConstants
    eShift As ShiftConstants
    sKey As String
End Type

Private m_tAccel() As tAccel
Private m_iCount As Long

Private m_bEnabled As Boolean
Private m_bInstalled As Boolean
Private m_bRunTime As Boolean

Public Event KeyDown(ByVal KeyCode As KeyCodeConstants, ByVal Shift As ShiftConstants, ByRef bCancel As Boolean)
Attribute KeyDown.VB_Description = "Raised whenever a key is pressed in the application."
Public Event Accelerator(ByVal nIndex As Long, ByRef bCancel As Boolean)
Attribute Accelerator.VB_Description = "Raised when an Accelerator key owned by the control is pressed."
Public Event KeyUp(ByVal KeyCode As KeyCodeConstants, ByVal Shift As ShiftConstants)
Attribute KeyUp.VB_Description = "Raised whenever a key is released in the application."

'EDIT BY TANNER: I rewrote this control to use Paul Caton/LaVolpe's modified (and much more IDE-safe) subclassing.
Private m_Subclass As cSelfSubHookCallback
Private Const HC_ACTION = 0

Public Function AddAccelerator(ByVal KeyCode As KeyCodeConstants, ByVal Shift As ShiftConstants, Optional ByVal vKey As Variant) As Long
Attribute AddAccelerator.VB_Description = "Adds an accelerator to the control, returning the index of the accelerator added."
    Dim i As Long
    Dim iIdx As Long
    
    For i = 1 To m_iCount
        If m_tAccel(i).eKeyCode = KeyCode And m_tAccel(i).eShift = Shift Then
            iIdx = i
            Exit For
        End If
    Next i
    
    If iIdx = 0 Then
        If Not IsMissing(vKey) Then
            If Not IsEmpty(vKey) Then
                If Not pbIsUnique(vKey) Then
                Err.Raise 457, App.EXEName & ".vbalHookControl"
                Exit Function
                End If
            End If
        End If
        m_iCount = m_iCount + 1
        ReDim Preserve m_tAccel(1 To m_iCount) As tAccel
        iIdx = m_iCount
    End If
    
    With m_tAccel(iIdx)
        .sKey = vKey
        .eKeyCode = KeyCode
        .eShift = Shift
    End With
    
    AddAccelerator = iIdx
    
End Function

Public Function RemoveAccelerator(ByVal vKey As Variant) As Boolean
Attribute RemoveAccelerator.VB_Description = "Removes the specified accelerator key."
    
    Dim iIdx As Long
    Dim i As Long
    iIdx = Index(vKey)
    
    If iIdx > 0 Then
        If m_iCount > 1 Then
            For i = iIdx To m_iCount - 1
                LSet m_tAccel(i) = m_tAccel(i + 1)
            Next i
            ReDim Preserve m_tAccel(1 To m_iCount) As tAccel
        Else
            m_iCount = 0
            Erase m_tAccel
        End If
    End If

End Function

Private Function pbIsUnique(ByVal vKey As Variant) As Boolean
    Dim i As Long
    If Not IsObject(vKey) Then
        For i = 1 To m_iCount
            If m_tAccel(i).sKey = vKey Then Exit Function
        Next i
        pbIsUnique = True
    End If
End Function

Public Property Get Shift(ByVal vKey As Variant) As ShiftConstants
Attribute Shift.VB_Description = "Gets the Shift code used for the given accelerator."
    Dim iIdx As Long
    iIdx = Index(vKey)
    If iIdx > 0 Then
        Shift = m_tAccel(iIdx).eShift
    End If
End Property

Public Property Get KeyCode(ByVal vKey As Variant) As KeyCodeConstants
Attribute KeyCode.VB_Description = "Gets the KeyCode member of an Accelerator combination."
    Dim iIdx As Long
    iIdx = Index(vKey)
    If iIdx > 0 Then KeyCode = m_tAccel(iIdx).eKeyCode
End Property

Public Property Get Count() As Long
Attribute Count.VB_Description = "Gets the number of accelerators currently being managed by the control."
     Count = m_iCount
End Property

Public Property Get Index(ByVal vKey As Variant) As Long
Attribute Index.VB_Description = "Gets the index of the accelerator with the specified key."
    Dim iIdx As Long
    Dim lR As Long

    On Error GoTo ErrorHandler
    If IsNumeric(vKey) Then
        iIdx = CLng(vKey)
        If Err.Number = 0 Then
            If iIdx > 0 And iIdx <= m_iCount Then
                lR = iIdx
            End If
        End If
    Else
        For iIdx = 1 To m_iCount
            If m_tAccel(iIdx).sKey = vKey Then
                lR = iIdx
                Exit For
            End If
        Next iIdx
    End If
    If iIdx > 0 Then
        Index = iIdx
    Else
        Err.Raise 9, App.EXEName & ".vbalHookControl"
    End If
       
    Exit Property

ErrorHandler:
    Err.Raise 9, App.EXEName & ".vbalHookControl"
    Exit Property
End Property

Public Property Get Key(ByVal nIndex As Long) As String
Attribute Key.VB_Description = "Gets the Key used to identify an accelerator."
    If Index(nIndex) > 0 Then
        Key = m_tAccel(nIndex).sKey
    End If
End Property

Public Property Get IsActive() As Boolean
Attribute IsActive.VB_Description = "Gets whether the form holding the accelerator control is the active form on the system or not."
    If GetActiveWindow() = UserControl.Parent.hWnd Then
         IsActive = True
     End If
End Property

Public Property Get Enabled() As Boolean
Attribute Enabled.VB_Description = "Gets/sets whether the control responds to accelerator keys."
     Enabled = m_bEnabled
End Property

Public Property Let Enabled(ByVal bState As Boolean)
    If m_bEnabled <> bState Then
        m_bEnabled = bState
        If m_bRunTime Then
            pInstall m_bEnabled
        End If
        PropertyChanged "Enabled"
    End If
End Property

'Install or remove the keyboard hook
Private Sub pInstall(ByVal bState As Boolean)

    If bState Then
        
        'If the hook has not been installed, do so now
        If Not m_bInstalled Then
            If Not m_Subclass.shk_SetHook(WH_KEYBOARD, False, MSG_BEFORE, , , Me) Then Message "Failed to initialize custom hotkey handler."
            m_bInstalled = True
        End If
        
    Else
        
        'If a hook was previously installed, unhook it now
        If m_bInstalled Then
            m_Subclass.shk_TerminateHooks
            m_bInstalled = False
        End If
    
    End If
    
End Sub

Private Property Get ShiftState(ByVal bShift As Boolean, ByVal bAlt As Boolean, ByVal bControl As Boolean) As ShiftConstants
Dim Er As ShiftConstants
   Er = Abs(vbShiftMask * bShift)
   Er = Er Or Abs(vbAltMask * bAlt)
   Er = Er Or Abs(vbCtrlMask * bControl)
   ShiftState = Er
End Property

Private Sub UserControl_Initialize()
    'Instantiate the subclasser
    Set m_Subclass = New cSelfSubHookCallback
End Sub

Private Sub UserControl_ReadProperties(PropBag As PropertyBag)
   m_bRunTime = g_UserModeFix
   Enabled = PropBag.ReadProperty("Enabled", True)
End Sub

Private Sub UserControl_Resize()
   imgIcon.Move 0, 0
   UserControl.Width = imgIcon.Width
   UserControl.Height = imgIcon.Height
End Sub

Private Sub UserControl_Terminate()
   pInstall False
End Sub

Private Sub UserControl_WriteProperties(PropBag As PropertyBag)
   PropBag.WriteProperty "Enabled", m_bEnabled, True
End Sub

'This routine MUST BE KEPT as the final routine for this form. Its ordinal position determines its ability to hook properly.
' Hooking is required to track application-wide mouse presses
Private Sub myHookProc(ByVal bBefore As Boolean, ByRef bHandled As Boolean, ByRef lReturn As Long, ByVal nCode As Long, ByVal wParam As Long, ByVal lParam As Long, ByVal lHookType As eHookType, ByRef lParamUser As Long)
'*************************************************************************************************
' http://msdn2.microsoft.com/en-us/library/ms644990.aspx
'* bBefore    - Indicates whether the callback is before or after the next hook in chain.
'* bHandled   - In a before next hook in chain callback, setting bHandled to True will prevent the
'*              message being passed to the next hook in chain and (if set to do so).
'* lReturn    - Return value. For Before messages, set per the MSDN documentation for the hook type
'* nCode      - A code the hook procedure uses to determine how to process the message
'* wParam     - Message related data, hook type specific
'* lParam     - Message related data, hook type specific
'* lHookType  - Type of hook calling this callback
'* lParamUser - User-defined callback parameter. Change vartype as needed (i.e., Object, UDT, etc)
'*************************************************************************************************
    
    Dim bKeyUp As Boolean
    Dim bAlt As Boolean
    Dim bCtrl As Boolean
    Dim bShift As Boolean
    Dim bCancel As Boolean
    Dim iAccel As Long
    Dim eShiftCode As ShiftConstants
   
    On Error Resume Next
    
    If Not UserControl.EventsFrozen Then
    
        If nCode = HC_ACTION Then
        
            ' Key up or down:
            bKeyUp = ((lParam And &H80000000) = &H80000000)
            
            ' Alt pressed?
            bAlt = ((lParam And &H20000000) = &H20000000)
            
            ' Ctrl/Shift pressed?
            bCtrl = (GetAsyncKeyState(vbKeyControl) <> 0)
            bShift = (GetAsyncKeyState(vbKeyShift) <> 0)
            eShiftCode = ShiftState(bShift, bAlt, bCtrl)
            
            If bKeyUp Then
                RaiseEvent KeyUp(wParam, eShiftCode)
            Else
                
                RaiseEvent KeyDown(wParam, eShiftCode, bCancel)
                
                If Not bCancel Then
                   
                   For iAccel = 1 To m_iCount
                      With m_tAccel(iAccel)
                         If .eKeyCode = wParam Then
                            If .eShift = eShiftCode Then
                               RaiseEvent Accelerator(iAccel, bCancel)
                               Exit For
                            End If
                         End If
                      End With
                   Next iAccel
                   
                End If
                
                If bCancel Then bHandled = False
                
            End If
            
        End If
        
    End If
    
End Sub


