VERSION 5.00
Begin VB.Form toolpanel_MoveSize 
   Appearance      =   0  'Flat
   BackColor       =   &H80000005&
   BorderStyle     =   0  'None
   ClientHeight    =   1515
   ClientLeft      =   0
   ClientTop       =   0
   ClientWidth     =   16650
   BeginProperty Font 
      Name            =   "Tahoma"
      Size            =   9.75
      Charset         =   0
      Weight          =   400
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   101
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   1110
   ShowInTaskbar   =   0   'False
   Visible         =   0   'False
   Begin PhotoDemon.buttonStripVertical btsMoveOptions 
      Height          =   1320
      Left            =   120
      TabIndex        =   14
      Top             =   60
      Width           =   2295
      _ExtentX        =   4048
      _ExtentY        =   2328
   End
   Begin VB.PictureBox picMoveContainer 
      Appearance      =   0  'Flat
      BackColor       =   &H00FFFFFF&
      BorderStyle     =   0  'None
      ForeColor       =   &H80000008&
      Height          =   1455
      Index           =   1
      Left            =   2520
      ScaleHeight     =   97
      ScaleMode       =   3  'Pixel
      ScaleWidth      =   833
      TabIndex        =   13
      Top             =   0
      Width           =   12495
      Begin PhotoDemon.sliderTextCombo sltLayerAngle 
         Height          =   480
         Left            =   120
         TabIndex        =   15
         Top             =   420
         Width           =   4095
         _ExtentX        =   7223
         _ExtentY        =   847
         Min             =   -360
         Max             =   360
         SigDigits       =   2
      End
      Begin PhotoDemon.pdLabel lblOptions 
         Height          =   240
         Index           =   2
         Left            =   120
         Top             =   60
         Width           =   5370
         _ExtentX        =   9472
         _ExtentY        =   503
         Caption         =   "angle test:"
      End
   End
   Begin VB.PictureBox picMoveContainer 
      Appearance      =   0  'Flat
      BackColor       =   &H00FFFFFF&
      BorderStyle     =   0  'None
      ForeColor       =   &H80000008&
      Height          =   1455
      Index           =   2
      Left            =   2520
      ScaleHeight     =   97
      ScaleMode       =   3  'Pixel
      ScaleWidth      =   833
      TabIndex        =   9
      Top             =   0
      Width           =   12495
      Begin PhotoDemon.pdLabel lblOptions 
         Height          =   240
         Index           =   0
         Left            =   120
         Top             =   60
         Width           =   5370
         _ExtentX        =   9472
         _ExtentY        =   503
         Caption         =   "interaction options:"
      End
      Begin PhotoDemon.smartCheckBox chkAutoActivateLayer 
         Height          =   330
         Left            =   120
         TabIndex        =   10
         Top             =   360
         Width           =   5370
         _ExtentX        =   9472
         _ExtentY        =   582
         Caption         =   "automatically activate layer beneath mouse"
      End
      Begin PhotoDemon.smartCheckBox chkIgnoreTransparent 
         Height          =   330
         Left            =   120
         TabIndex        =   11
         Top             =   720
         Width           =   5370
         _ExtentX        =   9472
         _ExtentY        =   582
         Caption         =   "ignore transparent pixels when auto-activating layers"
      End
      Begin PhotoDemon.smartCheckBox chkLayerBorder 
         Height          =   330
         Left            =   5640
         TabIndex        =   12
         Top             =   360
         Width           =   5370
         _ExtentX        =   9472
         _ExtentY        =   582
         Caption         =   "show layer borders"
      End
      Begin PhotoDemon.smartCheckBox chkLayerNodes 
         Height          =   330
         Left            =   5640
         TabIndex        =   0
         Top             =   720
         Width           =   5370
         _ExtentX        =   9472
         _ExtentY        =   582
         Caption         =   "show move/size (corner) nodes"
      End
      Begin PhotoDemon.pdLabel lblOptions 
         Height          =   240
         Index           =   1
         Left            =   5640
         Top             =   60
         Width           =   5370
         _ExtentX        =   9472
         _ExtentY        =   503
         Caption         =   "display options:"
      End
      Begin PhotoDemon.smartCheckBox chkRotateNode 
         Height          =   330
         Left            =   5640
         TabIndex        =   16
         Top             =   1080
         Width           =   5370
         _ExtentX        =   9472
         _ExtentY        =   582
         Caption         =   "show rotation node"
      End
   End
   Begin VB.PictureBox picMoveContainer 
      Appearance      =   0  'Flat
      BackColor       =   &H00FFFFFF&
      BorderStyle     =   0  'None
      ForeColor       =   &H80000008&
      Height          =   1455
      Index           =   0
      Left            =   2520
      ScaleHeight     =   97
      ScaleMode       =   3  'Pixel
      ScaleWidth      =   833
      TabIndex        =   1
      Top             =   0
      Width           =   12495
      Begin PhotoDemon.pdComboBox cboLayerResizeQuality 
         Height          =   300
         Left            =   5190
         TabIndex        =   2
         Top             =   420
         Width           =   2775
         _ExtentX        =   4895
         _ExtentY        =   529
      End
      Begin PhotoDemon.textUpDown tudLayerMove 
         Height          =   345
         Index           =   0
         Left            =   120
         TabIndex        =   3
         Top             =   420
         Width           =   2055
         _ExtentX        =   3625
         _ExtentY        =   609
      End
      Begin PhotoDemon.pdLabel lblOptions 
         Height          =   240
         Index           =   9
         Left            =   120
         Top             =   60
         Width           =   2370
         _ExtentX        =   4180
         _ExtentY        =   503
         Caption         =   "layer position (x, y):"
      End
      Begin PhotoDemon.pdLabel lblOptions 
         Height          =   240
         Index           =   10
         Left            =   2640
         Top             =   60
         Width           =   2370
         _ExtentX        =   4180
         _ExtentY        =   503
         Caption         =   "layer size (w, h):"
      End
      Begin PhotoDemon.textUpDown tudLayerMove 
         Height          =   345
         Index           =   1
         Left            =   120
         TabIndex        =   4
         Top             =   840
         Width           =   2055
         _ExtentX        =   3625
         _ExtentY        =   609
      End
      Begin PhotoDemon.textUpDown tudLayerMove 
         Height          =   345
         Index           =   2
         Left            =   2640
         TabIndex        =   5
         Top             =   420
         Width           =   2055
         _ExtentX        =   3625
         _ExtentY        =   609
      End
      Begin PhotoDemon.textUpDown tudLayerMove 
         Height          =   345
         Index           =   3
         Left            =   2640
         TabIndex        =   6
         Top             =   840
         Width           =   2055
         _ExtentX        =   3625
         _ExtentY        =   609
      End
      Begin PhotoDemon.pdButtonToolbox cmdLayerMove 
         Height          =   570
         Index           =   0
         Left            =   8400
         TabIndex        =   7
         Top             =   420
         Width           =   660
         _ExtentX        =   1164
         _ExtentY        =   1005
         AutoToggle      =   -1  'True
      End
      Begin PhotoDemon.pdButtonToolbox cmdLayerMove 
         Height          =   570
         Index           =   1
         Left            =   9240
         TabIndex        =   8
         Top             =   420
         Width           =   660
         _ExtentX        =   1164
         _ExtentY        =   1005
         AutoToggle      =   -1  'True
      End
      Begin PhotoDemon.pdLabel lblOptions 
         Height          =   240
         Index           =   11
         Left            =   5190
         Top             =   60
         Width           =   3090
         _ExtentX        =   5450
         _ExtentY        =   503
         Caption         =   "non-destructive resize quality:"
      End
      Begin PhotoDemon.pdLabel lblOptions 
         Height          =   240
         Index           =   12
         Left            =   8400
         Top             =   60
         Width           =   3360
         _ExtentX        =   5927
         _ExtentY        =   503
         Caption         =   "non-destructive resize options:"
      End
   End
End
Attribute VB_Name = "toolpanel_MoveSize"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'***************************************************************************
'PhotoDemon Move/Size Tool Panel
'Copyright 2013-2015 by Tanner Helland
'Created: 02/Oct/13
'Last updated: 13/May/15
'Last update: finish migrating all relevant controls to this dedicated form
'
'This form includes all user-editable settings for the Move/Size canvas tool.
'
'All source code in this file is licensed under a modified BSD license.  This means you may use the code in your own
' projects IF you provide attribution.  For more information, please visit http://photodemon.org/about/license/
'
'***************************************************************************


Option Explicit

'The value of all controls on this form are saved and loaded to file by this class
Private WithEvents lastUsedSettings As pdLastUsedSettings
Attribute lastUsedSettings.VB_VarHelpID = -1

'Two sub-panels are available on the "move options" panel
Private Sub btsMoveOptions_Click(ByVal buttonIndex As Long)
    
    Dim i As Long
    
    For i = 0 To picMoveContainer.UBound
        picMoveContainer(i).Visible = CBool(i = buttonIndex)
    Next i
    
End Sub

Private Sub cboLayerResizeQuality_Click()
    
    'If tool changes are not allowed, exit.
    ' NOTE: this will also check tool busy status, via Tool_Support.getToolBusyState
    If Not Tool_Support.canvasToolsAllowed Then Exit Sub
    
    'Mark the tool engine as busy
    Tool_Support.setToolBusyState True
    
    'Apply the new quality mode
    pdImages(g_CurrentImage).getActiveLayer.setLayerResizeQuality cboLayerResizeQuality.ListIndex
    
    'Free the tool engine
    Tool_Support.setToolBusyState False
    
    'Redraw the viewport
    Viewport_Engine.Stage2_CompositeAllLayers pdImages(g_CurrentImage), FormMain.mainCanvas(0)
    
End Sub

Private Sub chkAutoActivateLayer_Click()
    If CBool(chkAutoActivateLayer) Then
        If Not chkIgnoreTransparent.Enabled Then chkIgnoreTransparent.Enabled = True
    Else
        If chkIgnoreTransparent.Enabled Then chkIgnoreTransparent.Enabled = False
    End If
End Sub

'Show/hide layer borders while using the move tool
Private Sub chkLayerBorder_Click()
    Viewport_Engine.Stage5_FlipBufferAndDrawUI pdImages(g_CurrentImage), FormMain.mainCanvas(0)
End Sub

'Show/hide layer transform nodes while using the move tool
Private Sub chkLayerNodes_Click()
    Viewport_Engine.Stage5_FlipBufferAndDrawUI pdImages(g_CurrentImage), FormMain.mainCanvas(0)
End Sub

Private Sub chkRotateNode_Click()
    Viewport_Engine.Stage5_FlipBufferAndDrawUI pdImages(g_CurrentImage), FormMain.mainCanvas(0)
End Sub

Private Sub cmdLayerMove_Click(Index As Integer)
    
    Select Case Index
    
        'Reset layer to original size
        Case 0
            Process "Reset layer size", , buildParams(pdImages(g_CurrentImage).getActiveLayerIndex), UNDO_LAYERHEADER
        
        'Make non-destructive resize permanent
        Case 1
            Process "Make layer size permanent", , buildParams(pdImages(g_CurrentImage).getActiveLayerIndex), UNDO_LAYER
    
    End Select
    
End Sub

Private Sub Form_Load()
        
    'Initialize move tool panels
    btsMoveOptions.AddItem "position", 0
    btsMoveOptions.AddItem "transformations", 1
    btsMoveOptions.AddItem "display", 2
    btsMoveOptions.ListIndex = 0
    btsMoveOptions_Click 0
    
    cmdLayerMove(0).AssignImage "CMDBAR_RESET", , 50
    cmdLayerMove(1).AssignImage "TO_APPLY", , 50
    
    cmdLayerMove(0).assignTooltip "Reset layer to original size"
    cmdLayerMove(1).assignTooltip "Make current layer size permanent.  This action is never required, but if viewport rendering is sluggish, it may improve performance."
    
    cboLayerResizeQuality.Clear
    cboLayerResizeQuality.AddItem "Nearest neighbor", 0
    cboLayerResizeQuality.AddItem "Bilinear", 1
    cboLayerResizeQuality.AddItem "Bicubic", 2
    cboLayerResizeQuality.ListIndex = 1
        
    'Load any last-used settings for this form
    Set lastUsedSettings = New pdLastUsedSettings
    lastUsedSettings.setParentForm Me
    lastUsedSettings.loadAllControlValues
    
    'Update everything against the current theme.  This will also set tooltips for various controls.
    updateAgainstCurrentTheme
    
End Sub

Private Sub Form_QueryUnload(Cancel As Integer, UnloadMode As Integer)
    
    'Save all last-used settings to file
    lastUsedSettings.saveAllControlValues
    lastUsedSettings.setParentForm Nothing
    
End Sub

Private Sub sltLayerAngle_Change()
    
    'If tool changes are not allowed, exit.
    ' NOTE: this will also check tool busy status, via Tool_Support.getToolBusyState
    If Not Tool_Support.canvasToolsAllowed Then Exit Sub
    
    'Mark the tool engine as busy
    Tool_Support.setToolBusyState True
    
    'Notify the layer of the setting change
    pdImages(g_CurrentImage).getActiveLayer.setLayerAngle sltLayerAngle.Value
    
    'Free the tool engine
    Tool_Support.setToolBusyState False
    
    'Redraw the viewport
    Viewport_Engine.Stage2_CompositeAllLayers pdImages(g_CurrentImage), FormMain.mainCanvas(0)
    
End Sub

Private Sub sltLayerAngle_GotFocusAPI()
    If g_OpenImageCount = 0 Then Exit Sub
    Processor.flagInitialNDFXState_Generic pgp_Angle, sltLayerAngle.Value, pdImages(g_CurrentImage).getActiveLayerID
End Sub

Private Sub sltLayerAngle_LostFocusAPI()
    Processor.flagFinalNDFXState_Generic pgp_Angle, sltLayerAngle.Value
End Sub

Private Sub tudLayerMove_Change(Index As Integer)
    
    'If tool changes are not allowed, exit.
    ' NOTE: this will also check tool busy status, via Tool_Support.getToolBusyState
    If Not Tool_Support.canvasToolsAllowed Then Exit Sub
    
    'Mark the tool engine as busy
    Tool_Support.setToolBusyState True
    
    Select Case Index
    
        'Layer position (x)
        Case 0
            pdImages(g_CurrentImage).getActiveLayer.setLayerOffsetX tudLayerMove(Index).Value
        
        'Layer position (y)
        Case 1
            pdImages(g_CurrentImage).getActiveLayer.setLayerOffsetY tudLayerMove(Index).Value
        
        'Layer width
        Case 2
            pdImages(g_CurrentImage).getActiveLayer.setLayerCanvasXModifier tudLayerMove(Index).Value / pdImages(g_CurrentImage).getActiveLayer.getLayerWidth(False)
            
        'Layer height
        Case 3
            pdImages(g_CurrentImage).getActiveLayer.setLayerCanvasYModifier tudLayerMove(Index).Value / pdImages(g_CurrentImage).getActiveLayer.getLayerHeight(False)
        
    End Select
    
    'Free the tool engine
    Tool_Support.setToolBusyState False
    
    'Redraw the viewport
    Viewport_Engine.Stage2_CompositeAllLayers pdImages(g_CurrentImage), FormMain.mainCanvas(0)

End Sub

'Non-destructive resizing requires the synchronization of several menus, as well.  Because it's time-consuming to invoke
' syncInterfaceToCurrentImage, we only call it when the user releases the mouse.
Private Sub tudLayerMove_FinalChange(Index As Integer)
    
    'If tool changes are not allowed, exit.
    ' NOTE: this will also check tool busy status, via Tool_Support.getToolBusyState
    If Not Tool_Support.canvasToolsAllowed Then Exit Sub
    
    Select Case Index
        
        Case 2, 3
            syncInterfaceToCurrentImage
        
        Case Else
        
    End Select
    
End Sub

'Updating against the current theme accomplishes a number of things:
' 1) All user-drawn controls are redrawn according to the current g_Themer settings.
' 2) All tooltips and captions are translated according to the current language.
' 3) MakeFormPretty is called, which redraws the form itself according to any theme and/or system settings.
'
'This function is called at least once, at Form_Load, but can be called again if the active language or theme changes.
Public Sub updateAgainstCurrentTheme()

    'Start by redrawing the form according to current theme and translation settings.  (This function also takes care of
    ' any common controls that may still exist in the program.)
    makeFormPretty Me

End Sub
