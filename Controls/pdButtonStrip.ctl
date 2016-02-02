VERSION 5.00
Begin VB.UserControl pdButtonStrip 
   BackColor       =   &H00FFFFFF&
   ClientHeight    =   765
   ClientLeft      =   0
   ClientTop       =   0
   ClientWidth     =   2745
   BeginProperty Font 
      Name            =   "Tahoma"
      Size            =   8.25
      Charset         =   0
      Weight          =   400
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   HasDC           =   0   'False
   ScaleHeight     =   51
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   183
   ToolboxBitmap   =   "pdButtonStrip.ctx":0000
End
Attribute VB_Name = "pdButtonStrip"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'***************************************************************************
'PhotoDemon "Button Strip" control
'Copyright 2014-2016 by Tanner Helland
'Created: 13/September/14
'Last updated: 23/January/16
'Last update: add caption support; large overhaul of rendering logic to better work with dark themes
'
'In a surprise to precisely no one, PhotoDemon has some unique needs when it comes to user controls - needs that
' the intrinsic VB controls can't handle.  These range from the obnoxious (lack of an "autosize" property for
' anything but labels) to the critical (no Unicode support).
'
'As such, I've created many of my own UCs for the program.  All are owner-drawn, with the goal of maintaining
' visual fidelity across the program, while also enabling key features like Unicode support.
'
'A few notes on this button strip control, specifically:
'
' 1) The control supports an arbitrary number of button captions.  Captions are auto-wrapped, but DrawText requires word breaks to do this,
'     so you can't rely on hyphenation for over-long words - plan accordingly!
' 2) High DPI settings are handled automatically.
' 3) A hand cursor is automatically applied, and clicks on individual buttons are returned via the Click event.
' 4) Coloration is automatically handled by PD's internal theming engine.
' 5) When the control receives focus via keyboard, a special focus rect is drawn.  Focus via mouse is conveyed via text glow.
'
'All source code in this file is licensed under a modified BSD license.  This means you may use the code in your own
' projects IF you provide attribution.  For more information, please visit http://photodemon.org/about/license/
'
'***************************************************************************

Option Explicit

'This control really only needs one event raised - Click
Public Event Click(ByVal buttonIndex As Long)

'These events are provided as a convenience, for hosts who may want to reroute mousewheel events to some other control.
' (In PD, the metadata browser does this.)
Public Event MouseWheelVertical(ByVal Button As PDMouseButtonConstants, ByVal Shift As ShiftConstants, ByVal x As Long, ByVal y As Long, ByVal scrollAmount As Double)

'Because VB focus events are wonky, especially when we use CreateWindow within a UC, this control raises its own
' specialized focus events.  If you need to track focus, use these instead of the default VB functions.
Public Event GotFocusAPI()
Public Event LostFocusAPI()

'Rather than use an StdFont container (which requires VB to create redundant font objects), we track font properties manually,
' via dedicated properties.
Private m_FontSize As Single
Private m_FontBold As Boolean

'Now that this control supports a title caption (which sits above the button itself), we separately track the region of the
' control corresponding to the "buttonstrip" only.
Private m_ButtonStripRect As RECT, m_MouseInButtonStrip As Boolean

'Current button indices
Private m_ButtonIndex As Long
Private m_ButtonHoverIndex As Long
Private m_ButtonMouseDown As Long

'Array of current button entries
Private Type buttonEntry
    btCaptionEn As String           'Current button caption, in its original English
    btCaptionTranslated As String   'Current button caption, translated into the active language (if English is active, this is a copy of btCaptionEn)
    btBounds As RECT                'Boundaries of this button (full clickable area, inclusive - meaning 1px border NOT included)
    btCaptionRect As RECT           'Bounding rect of the caption.  This is dynamically calculated by the UpdateControlLayout function
    btImages As pdDIB               'Optional image(s) to use with the button; this class is ignored if the button has no image
    btImageWidth As Long            'If an image is loaded, these will store the image's width and height
    btImageHeight As Long
    btImageCoords As POINTAPI       '(x, y) position where the button image is painted (if an image exists)
    btFontSize As Single            'If a button caption fits just fine, this value is 0.  If a translation is active and a button caption must be shrunk,
                                    ' this value will be non-zero, and the button renderer must use it when rendering the button.
End Type

Private m_Buttons() As buttonEntry
Private m_numOfButtons As Long

'Index of which button has the focus.  The user can use arrow keys to move focus between buttons.
Private m_FocusRectActive As Long

'Color mode.  Buttons with text are easier to read if the background color is extremely dark and text is inverted over the top.
' On the main window interface, we use some button strips that are image-only, and the images are lost on such a dark background.
' For these, we specify an alternate coloring mode.
Public Enum PD_BTS_COLOR_SCHEME
    CM_DEFAULT = 0
    CM_LIGHT = 1
End Enum

#If False Then
    Private Const CM_DEFAULT = 0, CM_LIGHT = 1
#End If

Private m_ColoringMode As PD_BTS_COLOR_SCHEME

'User control support class.  Historically, many classes (and associated subclassers) were required by each user control,
' but I've since attempted to wrap these into a single master control support class.
Private WithEvents ucSupport As pdUCSupport
Attribute ucSupport.VB_VarHelpID = -1

'Padding between images (if any) and text.  This is automatically adjusted according to DPI, so set this value as it would be at the
' Windows default of 96 DPI
Private Const IMG_TEXT_PADDING As Long = 4

'Local list of themable colors.  This list includes all potential colors used by the control, regardless of state change
' or internal control settings.  The list is updated by calling the UpdateColorList function.
' (Note also that this list does not include variants, e.g. "BorderColor" vs "BorderColor_Hovered".  Variant values are
'  automatically calculated by the color management class, and they are retrieved by passing boolean modifiers to that
'  class, rather than treating every imaginable variant as a separate constant.)
Private Enum BTS_COLOR_LIST
    [_First] = 0
    BTS_Background = 0
    BTS_SelectedItemFill = 1
    BTS_UnselectedItemFill = 2
    BTS_SelectedItemBorder = 3
    BTS_UnselectedItemBorder = 4
    BTS_SelectedText = 5
    BTS_UnselectedText = 6
    BTS_Light_Background = 7
    BTS_Light_SelectedItemFill = 8
    BTS_Light_UnselectedItemFill = 9
    BTS_Light_SelectedItemBorder = 10
    BTS_Light_UnselectedItemBorder = 11
    BTS_Light_SelectedText = 12
    BTS_Light_UnselectedText = 13
    [_Last] = 13
    [_Count] = 14
End Enum

'Color retrieval and storage is handled by a dedicated class; this allows us to optimize theme interactions,
' without worrying about the details locally.
Private m_Colors As pdThemeColors

'Caption is handled just like the common control label's caption property.  It is valid at design-time, and any translation,
' if present, will not be processed until run-time.
' IMPORTANT NOTE: only the ENGLISH caption is returned.  I don't have a reason for returning a translated caption (if any),
'                  but I can revisit in the future if it ever becomes relevant.
Public Property Get Caption() As String
Attribute Caption.VB_UserMemId = -518
    Caption = ucSupport.GetCaptionText()
End Property

Public Property Let Caption(ByRef newCaption As String)
    ucSupport.SetCaptionText newCaption
    PropertyChanged "Caption"
End Property

'The Enabled property is a bit unique; see http://msdn.microsoft.com/en-us/library/aa261357%28v=vs.60%29.aspx
Public Property Get Enabled() As Boolean
Attribute Enabled.VB_UserMemId = -514
    Enabled = UserControl.Enabled
End Property

Public Property Let Enabled(ByVal newValue As Boolean)
    UserControl.Enabled = newValue
    PropertyChanged "Enabled"
    RedrawBackBuffer
End Property

'Color scheme should be left at default values *except* for image-only strips
Public Property Get ColorScheme() As PD_BTS_COLOR_SCHEME
    ColorScheme = m_ColoringMode
End Property

Public Property Let ColorScheme(ByVal newScheme As PD_BTS_COLOR_SCHEME)
    If m_ColoringMode <> newScheme Then
        m_ColoringMode = newScheme
        RedrawBackBuffer
    End If
End Property

'Font settings are handled via dedicated properties, to avoid the need for an internal VB font object
Public Property Get FontBold() As Boolean
    FontBold = m_FontBold
End Property

Public Property Let FontBold(ByVal newBoldSetting As Boolean)
    If newBoldSetting <> m_FontBold Then
        m_FontBold = newBoldSetting
        UpdateControlLayout
        PropertyChanged "FontBold"
    End If
End Property

Public Property Get FontSize() As Single
    FontSize = m_FontSize
End Property

Public Property Let FontSize(ByVal newSize As Single)
    If newSize <> m_FontSize Then
        m_FontSize = newSize
        UpdateControlLayout
        PropertyChanged "FontSize"
    End If
End Property

Public Property Get FontSizeCaption() As Single
    FontSizeCaption = ucSupport.GetCaptionFontSize()
End Property

Public Property Let FontSizeCaption(ByVal newSize As Single)
    ucSupport.SetCaptionFontSize newSize
    PropertyChanged "FontSizeCaption"
End Property

'When the control receives focus, if the focus isn't received via mouse click, display a focus rect around the active button
Private Sub ucSupport_GotFocusAPI()
    
    'If the mouse is *not* over the user control, assume focus was set via keyboard
    If Not ucSupport.DoIHaveFocus Then
        m_FocusRectActive = m_ButtonIndex
        RedrawBackBuffer
    End If
    
    RaiseEvent GotFocusAPI
    
End Sub

'When the control loses focus, erase any focus rects it may have active
Private Sub ucSupport_LostFocusAPI()
    
    'If a focus rect has been drawn, remove it now
    If (m_FocusRectActive >= 0) Then
        m_FocusRectActive = -1
        RedrawBackBuffer
    End If
    
    RaiseEvent LostFocusAPI

End Sub

'A few key events are also handled
Private Sub ucSupport_KeyDownCustom(ByVal Shift As ShiftConstants, ByVal vkCode As Long, markEventHandled As Boolean)

    If (vkCode = VK_RIGHT) Then
        
        'See if a focus rect is already active
        If (m_FocusRectActive >= 0) Then
            m_FocusRectActive = m_FocusRectActive + 1
        Else
            m_FocusRectActive = m_ButtonIndex + 1
        End If
        
        'Bounds-check the new m_FocusRectActive index
        If m_FocusRectActive >= m_numOfButtons Then m_FocusRectActive = 0
        
        'Redraw the button strip
        RedrawBackBuffer
        
    ElseIf (vkCode = VK_LEFT) Then
    
        'See if a focus rect is already active
        If (m_FocusRectActive >= 0) Then
            m_FocusRectActive = m_FocusRectActive - 1
        Else
            m_FocusRectActive = m_ButtonIndex - 1
        End If
        
        'Bounds-check the new m_FocusRectActive index
        If m_FocusRectActive < 0 Then m_FocusRectActive = m_numOfButtons - 1
        
        'Redraw the button strip
        RedrawBackBuffer
        
    'If a focus rect is active, and space is pressed, activate the button with focus
    ElseIf (vkCode = VK_SPACE) Then

        If m_FocusRectActive >= 0 Then ListIndex = m_FocusRectActive
        
    End If

End Sub

'To improve responsiveness, MouseDown is used instead of Click
Private Sub ucSupport_MouseDownCustom(ByVal Button As PDMouseButtonConstants, ByVal Shift As ShiftConstants, ByVal x As Long, ByVal y As Long)
        
    Dim mouseClickIndex As Long
    mouseClickIndex = IsMouseOverButton(x, y)
    
    'Disable any keyboard-generated focus rectangles
    m_FocusRectActive = -1
    
    If Me.Enabled And (mouseClickIndex >= 0) Then
        If m_ButtonIndex <> mouseClickIndex Then
            ListIndex = mouseClickIndex
        End If
        m_ButtonMouseDown = mouseClickIndex
    Else
        m_ButtonMouseDown = -1
    End If
    
    RedrawBackBuffer

End Sub

'When the mouse leaves the UC, we must repaint the control (as it's no longer hovered)
Private Sub ucSupport_MouseLeave(ByVal Button As PDMouseButtonConstants, ByVal Shift As ShiftConstants, ByVal x As Long, ByVal y As Long)
    m_ButtonHoverIndex = -1
    m_ButtonMouseDown = -1
    RedrawBackBuffer
    ucSupport.RequestCursor IDC_DEFAULT
    UpdateCursor -100, -100
End Sub

'When the mouse enters the clickable portion of the UC, we must repaint the hovered button
Private Sub ucSupport_MouseMoveCustom(ByVal Button As PDMouseButtonConstants, ByVal Shift As ShiftConstants, ByVal x As Long, ByVal y As Long)
    
    UpdateCursor x, y
    
    'TODO 6.8: what to do if the mouse button is down...?  Possibly just exit this sub?
    
    'If the mouse is over the relevant portion of the user control, display the cursor as clickable
    Dim mouseHoverIndex As Long
    mouseHoverIndex = IsMouseOverButton(x, y)
    
    'Only refresh the control if the hover value has changed
    If mouseHoverIndex <> m_ButtonHoverIndex Then
    
        m_ButtonHoverIndex = mouseHoverIndex
    
        'If the mouse is not currently hovering a button, set a default arrow cursor and exit
        If mouseHoverIndex = -1 Then
            ucSupport.RequestCursor IDC_ARROW
            RedrawBackBuffer
        Else
            ucSupport.RequestCursor IDC_HAND
            RedrawBackBuffer
        End If
    
    End If
    
End Sub

Private Sub ucSupport_MouseUpCustom(ByVal Button As PDMouseButtonConstants, ByVal Shift As ShiftConstants, ByVal x As Long, ByVal y As Long, ByVal ClickEventAlsoFiring As Boolean)
    m_ButtonMouseDown = -1
    RedrawBackBuffer
End Sub

Private Sub ucSupport_MouseWheelVertical(ByVal Button As PDMouseButtonConstants, ByVal Shift As ShiftConstants, ByVal x As Long, ByVal y As Long, ByVal scrollAmount As Double)
    RaiseEvent MouseWheelVertical(Button, Shift, x, y, scrollAmount)
End Sub

Private Sub ucSupport_RepaintRequired(ByVal updateLayoutToo As Boolean)
    If updateLayoutToo Then UpdateControlLayout
    RedrawBackBuffer
End Sub

Private Sub ucSupport_WindowResize(ByVal newWidth As Long, ByVal newHeight As Long)
    UpdateControlLayout
    RedrawBackBuffer
End Sub

'See if the mouse is over the clickable portion of the control
Private Function IsMouseOverButton(ByVal mouseX As Single, ByVal mouseY As Single) As Long
    
    'Search each set of button coords, looking for a match
    Dim i As Long
    For i = 0 To m_numOfButtons - 1
    
        If Math_Functions.isPointInRect(mouseX, mouseY, m_Buttons(i).btBounds) Then
            IsMouseOverButton = i
            Exit Function
        End If
    
    Next i
    
    'No match was found; return -1
    IsMouseOverButton = -1

End Function

'hWnds aren't exposed by default
Public Property Get hWnd() As Long
Attribute hWnd.VB_UserMemId = -515
    hWnd = UserControl.hWnd
End Property

'Container hWnd must be exposed for external tooltip handling
Public Property Get ContainerHwnd() As Long
    ContainerHwnd = UserControl.ContainerHwnd
End Property

'The most relevant part of this control is this ListIndex property, which just like listboxes, controls which button in the strip
' is currently pressed.
Public Property Get ListIndex() As Long
    ListIndex = m_ButtonIndex
End Property

Public Property Let ListIndex(ByVal newIndex As Long)
    
    'Update our internal value tracker
    If m_ButtonIndex <> newIndex Then
    
        m_ButtonIndex = newIndex
        PropertyChanged "ListIndex"
        
        'Redraw the control; it's important to do this *before* raising the associated event, to maintain an impression of max responsiveness
        RedrawBackBuffer
        
        'Notify the user of the change by raising the CLICK event
        RaiseEvent Click(newIndex)
        
    End If
    
End Property

'ListCount is necessary for the command bar's "Randomize" feature
Public Property Get ListCount() As Long
    ListCount = m_numOfButtons
End Property

'To simplify translation handling, this public sub is used to add buttons to the UC.  An optional index can also be specified.
Public Sub AddItem(ByVal srcString As String, Optional ByVal itemIndex As Long = -1)

    'If an index was not requested, force the index to the current number of parameters.
    If itemIndex = -1 Then itemIndex = m_numOfButtons
    
    'Increase the button count and resize the array to match
    m_numOfButtons = m_numOfButtons + 1
    ReDim Preserve m_Buttons(0 To m_numOfButtons - 1) As buttonEntry
    
    'Shift all buttons above this one upward, as necessary.
    If itemIndex < m_numOfButtons - 1 Then
    
        Dim i As Long
        For i = m_numOfButtons - 1 To itemIndex Step -1
            m_Buttons(i) = m_Buttons(i - 1)
        Next i
    
    End If
    
    'Copy the new button into place
    m_Buttons(itemIndex).btCaptionEn = srcString
    
    'We must also determine a translated caption, if any
    If (Not (g_Language Is Nothing)) And (Len(srcString) <> 0) Then
    
        If g_Language.translationActive Then
            m_Buttons(itemIndex).btCaptionTranslated = g_Language.TranslateMessage(m_Buttons(itemIndex).btCaptionEn)
        Else
            m_Buttons(itemIndex).btCaptionTranslated = m_Buttons(itemIndex).btCaptionEn
        End If
    
    Else
        m_Buttons(itemIndex).btCaptionTranslated = m_Buttons(itemIndex).btCaptionEn
    End If
    
    'Erase any images previously assigned to this button
    With m_Buttons(itemIndex)
        Set .btImages = Nothing
        .btImageWidth = 0
        .btImageHeight = 0
    End With
    
    'Before we can redraw the control, we need to recalculate all button positions - do that now!
    UpdateControlLayout

End Sub

'Assign a DIB to a button entry.  Disabled and hover states are automatically generated.
Public Sub AssignImageToItem(ByVal itemIndex As Long, Optional ByVal resName As String = "", Optional ByRef srcDIB As pdDIB)
    
    'Load the requested resource DIB, as necessary
    If Len(resName) <> 0 Then loadResourceToDIB resName, srcDIB
    
    'Cache the width and height of the DIB; it serves as our reference measurements for subsequent blt operations.
    ' (We also check for these != 0 to verify that an image was successfully loaded.)
    m_Buttons(itemIndex).btImageWidth = srcDIB.getDIBWidth
    m_Buttons(itemIndex).btImageHeight = srcDIB.getDIBHeight
    
    'Create a vertical sprite-sheet DIB, and mark it as having premultiplied alpha
    If m_Buttons(itemIndex).btImages Is Nothing Then Set m_Buttons(itemIndex).btImages = New pdDIB
    
    With m_Buttons(itemIndex)
        .btImages.createBlank .btImageWidth, .btImageHeight * 3, srcDIB.getDIBColorDepth, 0, 0
        .btImages.setInitialAlphaPremultiplicationState True
        
        'Copy this normal-state DIB into place at the top of the sheet
        BitBlt .btImages.getDIBDC, 0, 0, .btImageWidth, .btImageHeight, srcDIB.getDIBDC, 0, 0, vbSrcCopy
        
        'Next, make a copy of the source DIB.
        Dim tmpDIB As pdDIB
        Set tmpDIB = New pdDIB
        tmpDIB.createFromExistingDIB srcDIB
        
        'Convert this to a brighter, "glowing" version; we'll use this when rendering a hovered state.
        ScaleDIBRGBValues tmpDIB, UC_HOVER_BRIGHTNESS, True
        
        'Copy this DIB into position #2, beneath the base DIB
        BitBlt .btImages.getDIBDC, 0, .btImageHeight, .btImageWidth, .btImageHeight, tmpDIB.getDIBDC, 0, 0, vbSrcCopy
        
        'Finally, create a grayscale copy of the original image.  This will serve as the "disabled state" copy.
        tmpDIB.createFromExistingDIB srcDIB
        GrayscaleDIB tmpDIB, True
        
        'Place it into position #3, beneath the previous two DIBs
        BitBlt .btImages.getDIBDC, 0, .btImageHeight * 2, .btImageWidth, .btImageHeight, tmpDIB.getDIBDC, 0, 0, vbSrcCopy
        
        'Free whatever DIBs we can.  (If the caller passed us the source DIB, we trust them to release it.)
        Set tmpDIB = Nothing
        If Len(resName) <> 0 Then Set srcDIB = Nothing
    End With
    
    'Update the control layout to account for this new button
    UpdateControlLayout

End Sub

'INITIALIZE control
Private Sub UserControl_Initialize()
    
    m_numOfButtons = 0
    
    'Initialize a master user control support class
    Set ucSupport = New pdUCSupport
    ucSupport.RegisterControl UserControl.hWnd
    
    'Request some additional input functionality (custom mouse and key events)
    ucSupport.RequestExtraFunctionality True, True
    ucSupport.SpecifyRequiredKeys VK_RIGHT, VK_LEFT, VK_SPACE
    
    'Enable title caption support, so we don't need an attached label
    ucSupport.RequestCaptionSupport
    
    'Prep the color manager and load default colors
    Set m_Colors = New pdThemeColors
    Dim colorCount As BTS_COLOR_LIST: colorCount = [_Count]
    m_Colors.InitializeColorList "ButtonStrip", colorCount
    If Not g_IsProgramRunning Then UpdateColorList
    
    'Set various UI trackers to default values.
    m_FocusRectActive = -1
    m_ButtonHoverIndex = -1
    m_ButtonMouseDown = -1
                    
End Sub

'Set default properties
Private Sub UserControl_InitProperties()
    Caption = ""
    ColorScheme = CM_DEFAULT
    FontBold = False
    FontSize = 10
    FontSizeCaption = 12#
    ListIndex = 0
End Sub

'At run-time, painting is handled by the support class.  In the IDE, however, we must rely on VB's internal paint event.
Private Sub UserControl_Paint()
    ucSupport.RequestIDERepaint UserControl.hDC
End Sub

Private Sub UserControl_ReadProperties(PropBag As PropertyBag)
    With PropBag
        Caption = .ReadProperty("Caption", "")
        ColorScheme = .ReadProperty("ColorScheme", CM_DEFAULT)
        FontBold = .ReadProperty("FontBold", False)
        FontSize = .ReadProperty("FontSize", 10)
        FontSizeCaption = .ReadProperty("FontSizeCaption", 12#)
        ListIndex = .ReadProperty("ListIndex", 0)
    End With
End Sub

Private Sub UserControl_Resize()
    If Not g_IsProgramRunning Then ucSupport.RequestRepaint True
End Sub

'Store all associated properties
Private Sub UserControl_WriteProperties(PropBag As PropertyBag)
    With PropBag
        .WriteProperty "Caption", ucSupport.GetCaptionText, ""
        .WriteProperty "ColorScheme", m_ColoringMode, CM_DEFAULT
        .WriteProperty "FontBold", m_FontBold, False
        .WriteProperty "FontSize", m_FontSize, 10
        .WriteProperty "FontSizeCaption", ucSupport.GetCaptionFontSize, 12#
        .WriteProperty "ListIndex", ListIndex, 0
    End With
End Sub

'Because this control automatically forces all internal buttons to identical sizes, we have to recalculate a number
' of internal sizing metrics whenever the control size changes.
Private Sub UpdateControlLayout()
    
    'Retrieve DPI-aware control dimensions from the support class
    Dim bWidth As Long, bHeight As Long
    bWidth = ucSupport.GetBackBufferWidth
    bHeight = ucSupport.GetBackBufferHeight
    
    'Next, determine the positioning of the caption, if present.  (ucSupport.GetCaptionBottom tells us where the
    ' caption text ends vertically.)
    With m_ButtonStripRect
        If ucSupport.IsCaptionActive Then
            .Top = ucSupport.GetCaptionBottom + 2
            .Left = FixDPI(8)
        Else
            .Top = 1
            .Left = 1
        End If
        .Bottom = bHeight - 1
        .Right = bWidth - 1
    End With
    
    'Reset the width/height values to match our newly calculated rect; this simplifies subsequent steps
    bWidth = m_ButtonStripRect.Right - m_ButtonStripRect.Left
    bHeight = m_ButtonStripRect.Bottom - m_ButtonStripRect.Top
    
    'We now need to figure out the size of individual buttons within the strip.  While we could make these proportional
    ' to the text length of each button, I am instead taking the simpler route for now, and making all buttons a uniform size.
    
    'Start by calculating a set size for each button.  We will calculate these as floating-point, to avoid compounded
    ' truncation errors as we move from button to button.
    Dim buttonWidth As Double, buttonHeight As Double
    
    'Button height is easy - assume a 1px border on top and bottom, and give each button access to all space in-between.
    buttonHeight = bHeight - 2
    
    'Button width is trickier.  We have a 1px border around the whole control, and then (n-1) borders on the interior.
    If m_numOfButtons > 0 Then
        buttonWidth = (bWidth - 2 - (m_numOfButtons - 1)) / m_numOfButtons
    Else
        buttonWidth = bWidth - 2
    End If
    
    'Using these values, populate a boundary rect for each button, and store it.  (This makes the render step much faster.)
    Dim i As Long
    For i = 0 To m_numOfButtons - 1
    
        With m_Buttons(i).btBounds
            '.Left is calculated as: 1px left border, plus 1px border for any preceding buttons, plus preceding button widths
            .Left = m_ButtonStripRect.Left + 1 + i + (buttonWidth * i)
            .Top = m_ButtonStripRect.Top + 1
            .Bottom = .Top + buttonHeight
        End With
    
    Next i
    
    'Now, we're going to do something odd.  To avoid truncation errors, we're going to dynamically calculate RIGHT bounds
    ' by looping back through the array, and assigning right values to match the left value calculated for the next
    ' button in line.  The final button receives special consideration.
    If m_numOfButtons > 0 Then
    
        m_Buttons(m_numOfButtons - 1).btBounds.Right = m_ButtonStripRect.Right - 2
        
        If m_numOfButtons > 1 Then
        
            For i = 1 To m_numOfButtons - 1
                m_Buttons(i - 1).btBounds.Right = m_Buttons(i).btBounds.Left - 2
            Next i
        
        End If
        
    End If
    
    'Each button now has its boundaries precisely calculated.  Next, we want to precalculate all text positioning inside
    ' each button.  Because text positioning varies by caption, we are also going to pre-cache these values, to further
    ' reduce the amount of work we need to do in the render loop.
    Dim tmpPoint As POINTAPI
    Dim strWidth As Long, strHeight As Long
    
    'Rather than create and manage our own font object(s), we borrow font objects from the global PD font cache.
    Dim tmpFont As pdFont
    
    For i = 0 To m_numOfButtons - 1
    
        'Reset font size for this button
        m_Buttons(i).btFontSize = 0
        
        'Calculate the width of this button (which may deviate by 1px between buttons, due to integer truncation)
        buttonWidth = m_Buttons(i).btBounds.Right - m_Buttons(i).btBounds.Left
        
        'Next, we are going to calculate all text metrics.  We can skip this step for buttons without captions.
        If Len(m_Buttons(i).btCaptionTranslated) <> 0 Then
        
            'If a button has an image, we have to alter its sizing somewhat.  To make sure word-wrap is calculated correctly,
            ' remove the width of the image, plus padding, in advance.
            If Not (m_Buttons(i).btImages Is Nothing) Then
                buttonWidth = buttonWidth - (m_Buttons(i).btImageWidth + FixDPI(IMG_TEXT_PADDING))
            End If
            
            'Retrieve the expected size of the string, in pixels
            Set tmpFont = Font_Management.GetMatchingUIFont(m_FontSize, m_FontBold)
            strWidth = tmpFont.GetWidthOfString(m_Buttons(i).btCaptionTranslated)
            
            'If the string is too long for its containing button, activate word wrap and measure again
            If strWidth > buttonWidth Then
                
                strWidth = buttonWidth
                strHeight = tmpFont.GetHeightOfWordwrapString(m_Buttons(i).btCaptionTranslated, strWidth)
                
                'As a failsafe for ultra-long captions, restrict their size to the button size.  Truncation will (necessarily) occur.
                If (strHeight > buttonHeight) Then
                    strHeight = buttonHeight
                    
                'As a second failsafe, if word-wrapping didn't solve the problem (because the text is a single word, for example, as is common
                ' in German), we will forcibly set a smaller font size for this caption alone.
                ElseIf tmpFont.GetHeightOfWordwrapString(m_Buttons(i).btCaptionTranslated, strWidth) = tmpFont.GetHeightOfString(m_Buttons(i).btCaptionTranslated) Then
                    m_Buttons(i).btFontSize = tmpFont.GetMaxFontSizeToFitStringWidth(m_Buttons(i).btCaptionTranslated, buttonWidth, m_FontSize)
                    Set tmpFont = Font_Management.GetMatchingUIFont(m_Buttons(i).btFontSize, m_FontBold)
                    strHeight = tmpFont.GetHeightOfString(m_Buttons(i).btCaptionTranslated)
                End If
                
            Else
                strHeight = tmpFont.GetHeightOfString(m_Buttons(i).btCaptionTranslated)
            End If
            
            'Release our copy of this global PD UI font
            Set tmpFont = Nothing
            
        End If
        
        'Use the size of the string, the size of the button's image (if any), and the size of the button itself to determine
        ' optimal painting position (using top-left alignment).
        With m_Buttons(i)
            
            'Again, handling branches according to the presence of a caption
            If Len(.btCaptionTranslated) <> 0 Then
            
                'No image...
                If (.btImages Is Nothing) Then
                    .btCaptionRect.Left = .btBounds.Left
                
                'Image...
                Else
                    If strWidth < buttonWidth Then
                        .btCaptionRect.Left = .btBounds.Left + m_Buttons(i).btImageWidth + FixDPI(IMG_TEXT_PADDING)
                    Else
                        .btCaptionRect.Left = .btBounds.Left + m_Buttons(i).btImageWidth + FixDPI(IMG_TEXT_PADDING) * 2
                    End If
                End If
                
                .btCaptionRect.Top = .btBounds.Top + (buttonHeight - strHeight) \ 2
                .btCaptionRect.Right = .btBounds.Right
                .btCaptionRect.Bottom = .btBounds.Bottom
                
            End If
        
            'Calculate a position for the button image, if any
            If Not (.btImages Is Nothing) Then
                
                'X-positioning is dependent on the presence of a caption.  If a caption exists, it gets placement preference.
                If Len(.btCaptionTranslated) <> 0 Then
                
                    If strWidth < buttonWidth Then
                        .btImageCoords.x = .btBounds.Left + ((.btCaptionRect.Right - .btCaptionRect.Left) - strWidth) \ 2
                    Else
                        .btImageCoords.x = .btBounds.Left + FixDPI(IMG_TEXT_PADDING)
                    End If
                    
                'If no caption exists, center the image horizontally
                Else
                    .btImageCoords.x = .btBounds.Left + ((.btBounds.Right - .btBounds.Left) - .btImageWidth) \ 2
                End If
                
                .btImageCoords.y = .btBounds.Top + (buttonHeight - .btImageHeight) \ 2
            
            End If
        
        End With
        
    Next i
    
    'With all metrics successfully measured, we can now recreate the back buffer
    If ucSupport.AmIVisible Then RedrawBackBuffer
            
End Sub

'Because the control may consist of a non-clickable region (the caption) and a clickable region (the buttonstrip),
' we can't blindly assign a hand cursor to the entire control.
Private Sub UpdateCursor(ByVal x As Single, ByVal y As Single)
    If Math_Functions.isPointInRect(x, y, m_ButtonStripRect) Then
        ucSupport.RequestCursor IDC_HAND
    Else
        ucSupport.RequestCursor IDC_DEFAULT
    End If
End Sub

'Use this function to completely redraw the back buffer from scratch.  Note that this is computationally expensive compared to just flipping the
' existing buffer to the screen, so only redraw the backbuffer if the control state has somehow changed.
Private Sub RedrawBackBuffer()
    
    'Request the back buffer DC, and ask the support module to erase any existing rendering for us.
    Dim bufferDC As Long, bWidth As Long, bHeight As Long
    bufferDC = ucSupport.GetBackBufferDC(True)
    bWidth = ucSupport.GetBackBufferWidth
    bHeight = ucSupport.GetBackBufferHeight
    
    'NOTE: if a title caption exists, it has already been drawn.  We just need to draw the clickable button portion.
    
    'To improve rendering performance, we cache all colors locally prior to rendering
    Dim btnColorBackground As Long
    Dim btnColorSelectedBorder As Long, btnColorSelectedFill As Long
    Dim btnColorSelectedBorderHover As Long, btnColorSelectedFillHover As Long
    Dim btnColorUnselectedBorder As Long, btnColorUnselectedFill As Long
    Dim btnColorUnselectedBorderHover As Long, btnColorUnselectedFillHover As Long
    Dim fontColorSelected As Long, fontColorSelectedHover As Long
    Dim fontColorUnselected As Long, fontColorUnselectedHover As Long
    
    Dim curColor As Long
    Dim isButtonSelected As Boolean, isButtonHovered As Boolean
    Dim enabledState As Boolean
    enabledState = Me.Enabled
        
    'Note also that this control has a unique "ColorScheme" property that is used for image-only button strips
    ' (as the default "invert" coloring tends to drown out the images themselves).
    If m_ColoringMode = CM_DEFAULT Then
        btnColorBackground = m_Colors.RetrieveColor(BTS_Background, enabledState, False, False)
        btnColorUnselectedBorder = m_Colors.RetrieveColor(BTS_UnselectedItemBorder, enabledState, False, False)
        btnColorUnselectedFill = m_Colors.RetrieveColor(BTS_UnselectedItemFill, enabledState, False, False)
        btnColorUnselectedBorderHover = m_Colors.RetrieveColor(BTS_UnselectedItemBorder, enabledState, False, True)
        btnColorUnselectedFillHover = m_Colors.RetrieveColor(BTS_UnselectedItemFill, enabledState, False, True)
        btnColorSelectedBorder = m_Colors.RetrieveColor(BTS_SelectedItemBorder, enabledState, False, False)
        btnColorSelectedFill = m_Colors.RetrieveColor(BTS_SelectedItemFill, enabledState, False, False)
        btnColorSelectedBorderHover = m_Colors.RetrieveColor(BTS_SelectedItemBorder, enabledState, False, True)
        btnColorSelectedFillHover = m_Colors.RetrieveColor(BTS_SelectedItemFill, enabledState, False, True)
    Else
        btnColorBackground = m_Colors.RetrieveColor(BTS_Light_Background, enabledState, False, False)
        btnColorUnselectedBorder = m_Colors.RetrieveColor(BTS_Light_UnselectedItemBorder, enabledState, False, False)
        btnColorUnselectedFill = m_Colors.RetrieveColor(BTS_Light_UnselectedItemFill, enabledState, False, False)
        btnColorUnselectedBorderHover = m_Colors.RetrieveColor(BTS_Light_UnselectedItemBorder, enabledState, False, True)
        btnColorUnselectedFillHover = m_Colors.RetrieveColor(BTS_Light_UnselectedItemFill, enabledState, False, True)
        btnColorSelectedBorder = m_Colors.RetrieveColor(BTS_Light_SelectedItemBorder, enabledState, False, False)
        btnColorSelectedFill = m_Colors.RetrieveColor(BTS_Light_SelectedItemFill, enabledState, False, False)
        btnColorSelectedBorderHover = m_Colors.RetrieveColor(BTS_Light_SelectedItemBorder, enabledState, False, True)
        btnColorSelectedFillHover = m_Colors.RetrieveColor(BTS_Light_SelectedItemFill, enabledState, False, True)
    End If
    
    '"Light mode" colors are only used for icon-only button strips, so font colors aren't affected by it.
    fontColorSelected = m_Colors.RetrieveColor(BTS_SelectedText, enabledState, False, False)
    fontColorSelectedHover = m_Colors.RetrieveColor(BTS_SelectedText, enabledState, False, True)
    fontColorUnselected = m_Colors.RetrieveColor(BTS_UnselectedText, enabledState, False, False)
    fontColorUnselectedHover = m_Colors.RetrieveColor(BTS_UnselectedText, enabledState, False, True)
    
    'Start by filling the desired background color, then rendering a single-pixel unselected border around the control.
    ' (The border will be overwritten with Selected or Hovered borders, as necessary.)
    With m_ButtonStripRect
        GDI_Plus.GDIPlusFillRectToDC bufferDC, .Left, .Top, (.Right - .Left) - 1, (.Bottom - .Top) - 1, btnColorBackground
        GDI_Plus.GDIPlusDrawRectOutlineToDC bufferDC, .Left, .Top, .Right - 1, .Bottom - 1, btnColorUnselectedBorder, 255, 1
    End With
    
    'This control doesn't maintain its own fonts; instead, it borrows it from the public PD UI font cache, as necessary
    Dim tmpFont As pdFont
    
    'Next, each individual button is rendered in turn.
    If m_numOfButtons > 0 Then
    
        Dim i As Long
        For i = 0 To m_numOfButtons - 1
            
            isButtonSelected = CBool(i = m_ButtonIndex)
            isButtonHovered = CBool(i = m_ButtonHoverIndex)
            
            With m_Buttons(i)
            
                'Fill the current button with its target fill color
                If isButtonSelected Then curColor = btnColorSelectedFill Else curColor = btnColorUnselectedFill
                GDI_Plus.GDIPlusFillRectToDC bufferDC, .btBounds.Left, .btBounds.Top, .btBounds.Right - .btBounds.Left + 1, .btBounds.Bottom - .btBounds.Top, curColor
                
                'For performance reasons, we only render each button's right-side border at this stage, and we always start
                ' with the inactive border color.
                If i < (m_numOfButtons - 1) Then
                    GDI_Plus.GDIPlusDrawLineToDC bufferDC, .btBounds.Right + 1, m_ButtonStripRect.Top, .btBounds.Right + 1, .btBounds.Bottom, btnColorUnselectedBorder, 255, 1
                End If
                
                'Active/hover changes are only rendered if the control is enabled
                If enabledState Then
                
                    'If this is the selected button (.ListIndex), paint its border with a special color.
                    ' (Note that we skip this step if the button is hovered, because the hover rect is drawn LAST to ensure that it overlaps
                    '  the surrounding buttons correctly.)
                    If isButtonSelected Then
                        If (Not isButtonHovered) Or (m_ColoringMode = CM_LIGHT) Then GDI_Plus.GDIPlusDrawRectOutlineToDC bufferDC, .btBounds.Left - 1, .btBounds.Top - 1, .btBounds.Right + 1, .btBounds.Bottom, btnColorSelectedBorder, 255, 1
                        
                    'If the user is hovering an inactive button, and we're in "light" color mode, paint the button immediately
                    Else
                        If isButtonHovered And (m_ColoringMode = CM_LIGHT) Then
                            GDI_Plus.GDIPlusDrawRectOutlineToDC bufferDC, .btBounds.Left - 1, .btBounds.Top - 1, .btBounds.Right + 1, .btBounds.Bottom, btnColorUnselectedBorderHover, 255, 1, False, LineJoinMiter
                        End If
                    End If
                    
                    'If this button has received focus via keyboard, paint it with a special interior border
                    If i = m_FocusRectActive Then
                        GDI_Plus.GDIPlusDrawRectOutlineToDC bufferDC, .btBounds.Left + 2, .btBounds.Top + 2, .btBounds.Right - 2, .btBounds.Bottom - 3, btnColorSelectedBorder, 255, 1
                    End If
                    
                End If
                
                'Paint the button's caption, if one exists
                If Len(.btCaptionTranslated) <> 0 Then
                
                    If isButtonSelected Then
                        If isButtonHovered Then curColor = fontColorSelectedHover Else curColor = fontColorSelected
                    Else
                        If isButtonHovered Then curColor = fontColorUnselectedHover Else curColor = fontColorUnselected
                    End If
                    
                    'Borrow a relevant UI font from the public UI font cache, then render the button caption using the clipping
                    ' rect we already calculated in previous steps.
                    
                    '(Remember that a font size of "0" means that text fits inside this button at the control's default font size)
                    If .btFontSize = 0 Then
                        Set tmpFont = Font_Management.GetMatchingUIFont(m_FontSize, m_FontBold)
                        
                    'Text does not fit the button area; use the custom font size we calculated in a previous step
                    Else
                        Set tmpFont = Font_Management.GetMatchingUIFont(.btFontSize, m_FontBold)
                    End If
                    
                    'Render the text onto the button
                    tmpFont.SetFontColor curColor
                    tmpFont.AttachToDC bufferDC
                    tmpFont.SetTextAlignment vbLeftJustify
                    tmpFont.DrawCenteredTextToRect .btCaptionTranslated, .btCaptionRect
                    tmpFont.ReleaseFromDC
                    
                End If
                
                'Paint the button image, if any, while branching for enabled/disabled/hovered variants
                If Not (.btImages Is Nothing) Then
                    
                    'Determine which image from the spritesheet to use.  (This is just a pixel offset.)
                    Dim pxOffset As Long
                    If enabledState Then
                        If isButtonHovered Then pxOffset = .btImageHeight Else pxOffset = 0
                    Else
                        pxOffset = .btImageHeight * 2
                    End If
                    
                    .btImages.alphaBlendToDCEx bufferDC, .btImageCoords.x, .btImageCoords.y, .btImageWidth, .btImageHeight, 0, pxOffset, .btImageWidth, .btImageHeight
                    
                End If
                
            End With
        
        'This button has been rendered successfully.  Move on to the next one.
        Next i
        
        'In normal coloring mode, the hover rect is drawn last; because it's chunkier than normal borders, we must ensure that it overlaps
        ' neighboring buttons correctly.
        If (m_ButtonHoverIndex >= 0) And (m_ColoringMode = CM_DEFAULT) Then
        
            'Color changes when the active button is hovered, to indicate no change will be made.
            If m_ButtonHoverIndex = m_ButtonIndex Then curColor = btnColorSelectedBorderHover Else curColor = btnColorUnselectedBorderHover
            With m_Buttons(m_ButtonHoverIndex).btBounds
                GDI_Plus.GDIPlusDrawRectOutlineToDC bufferDC, .Left - 1, .Top - 1, .Right + 1, .Bottom, curColor, 255, 3, False, LineJoinMiter
            End With
            
        End If
        
    End If
    
    'Paint the final result to the screen, as relevant
    ucSupport.RequestRepaint
    
End Sub

'External functions can call this to request a redraw.  This is helpful for live-updating theme settings, as in the Preferences dialog,
' and/or retranslating all button captions against the current language.
Public Sub UpdateAgainstCurrentTheme()
    
    'Determine if translations are active.  If they are, retrieve translated captions for all buttons within the control.
    If g_IsProgramRunning Then
        
        'See if translations are necessary.
        Dim isTranslationActive As Boolean
            
        If Not (g_Language Is Nothing) Then
            If g_Language.translationActive Then
                isTranslationActive = True
            Else
                isTranslationActive = False
            End If
        Else
            isTranslationActive = False
        End If
        
        'Apply the new translations, if any.
        Dim i As Long
        For i = 0 To m_numOfButtons - 1
            If isTranslationActive Then
                m_Buttons(i).btCaptionTranslated = g_Language.TranslateMessage(m_Buttons(i).btCaptionEn)
            Else
                m_Buttons(i).btCaptionTranslated = m_Buttons(i).btCaptionEn
            End If
        Next i
        
    End If
    
    'Update all text managed by the support class (e.g. tooltips)
    If g_IsProgramRunning Then ucSupport.UpdateAgainstThemeAndLanguage
    
    'This control requests quite a few colors from the central themer; update its color cache now
    UpdateColorList
    
    'Because translations can change text layout, we need to recalculate font metrics prior to redrawing the button
    UpdateControlLayout
    
End Sub

'Before the control is rendered, we need to retrieve all painting colors from PD's primary theming class.  Note that this
' step must also be called if/when PD's visual theme settings change.
Private Sub UpdateColorList()
    
    'Color list retrieval is pretty darn easy - just load each color one at a time, and leave the rest to the color class.
    ' It will build an internal hash table of the colors we request, which makes rendering much faster.
    Dim ColorValues As BTS_COLOR_LIST
    
    With m_Colors
        .LoadThemeColor BTS_Background, "Background", IDE_WHITE
        .LoadThemeColor BTS_SelectedItemFill, "SelectedItemFill", IDE_BLUE
        .LoadThemeColor BTS_UnselectedItemFill, "UnselectedItemFill", IDE_WHITE
        .LoadThemeColor BTS_SelectedItemBorder, "SelectedItemBorder", IDE_BLUE
        .LoadThemeColor BTS_UnselectedItemBorder, "UnselectedItemBorder", IDE_BLUE
        .LoadThemeColor BTS_SelectedText, "SelectedText", IDE_WHITE
        .LoadThemeColor BTS_UnselectedText, "UnselectedText", IDE_GRAY
        .LoadThemeColor BTS_Light_Background, "BackgroundLightMode", IDE_WHITE
        .LoadThemeColor BTS_Light_SelectedItemFill, "SelectedItemFillLightMode", IDE_LIGHTBLUE
        .LoadThemeColor BTS_Light_UnselectedItemFill, "UnselectedItemFillLightMode", IDE_WHITE
        .LoadThemeColor BTS_Light_SelectedItemBorder, "SelectedItemBorderLightMode", IDE_LIGHTBLUE
        .LoadThemeColor BTS_Light_UnselectedItemBorder, "UnselectedItemBorderLightMode", IDE_LIGHTBLUE
        .LoadThemeColor BTS_Light_SelectedText, "SelectedTextLightMode", IDE_BLUE
        .LoadThemeColor BTS_Light_UnselectedText, "UnselectedTextLightMode", IDE_GRAY
    End With
    
End Sub

'Due to complex interactions between user controls and PD's translation engine, tooltips require this dedicated function.
' (IMPORTANT NOTE: the tooltip class will handle translations automatically.  Always pass the original English text!)
Public Sub AssignTooltip(ByVal newTooltip As String, Optional ByVal newTooltipTitle As String, Optional ByVal newTooltipIcon As TT_ICON_TYPE = TTI_NONE)
    ucSupport.AssignTooltip UserControl.ContainerHwnd, newTooltip, newTooltipTitle, newTooltipIcon
End Sub

