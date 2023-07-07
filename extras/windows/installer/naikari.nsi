;For testing the script
;SetCompress Off

;Enables Unicode installer to clear ANSI deprecation message 
Unicode true

;--------------------------------
;Needed include files
!include "MUI2.nsh"
!include "x64.nsh"
!include "LogicLib.nsh"

;--------------------------------
;Variables

Var StartMenuFolder

!define NAME "Naikari"
!define PACKAGE "${NAME}"
!define NAIKARI_DEV "Naikari Team"
!define NAIKARI_URL "https://naikari.github.io"

!define UNINSTALL_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall"

Name "${PACKAGE}"
OutFile "naikari-${SUFFIX}.exe"

InstallDir "$PROGRAMFILES64\${PACKAGE}"
InstallDirRegKey HKLM "SOFTWARE\${PACKAGE}" ""

RequestExecutionLevel admin
ShowInstDetails show
ShowUninstDetails show

;--------------------------------
;Interface Settings

;!define MUI_WELCOMEFINISHPAGE_BITMAP - A 164x314 px bitmap could go here.

!define MUI_ICON "logo.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\nsis3-uninstall.ico"

!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_RIGHT
!define MUI_HEADERIMAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Header\nsis3-grey-right.bmp"
!define MUI_HEADERIMAGE_UNBITMAP "${NSISDIR}\Contrib\Graphics\Header\orange-uninstall-r.bmp"

!define MUI_WELCOMEFINISHPAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Wizard\nsis3-grey.bmp"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Wizard\orange-uninstall.bmp"

!define MUI_ABORTWARNING

;--------------------------------
;Language Selection Dialog Settings

;Remember the installer language
!define MUI_LANGDLL_REGISTRY_ROOT "HKLM"
!define MUI_LANGDLL_REGISTRY_KEY "Software\${NAME}"
!define MUI_LANGDLL_REGISTRY_VALUENAME "Installer Language"

;--------------------------------
;Pages

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "$(gpl)"
!insertmacro MUI_PAGE_DIRECTORY

;Start Menu Folder Page Configuration
!define MUI_STARTMENUPAGE_REGISTRY_ROOT "HKLM"
!define MUI_STARTMENUPAGE_REGISTRY_KEY "Software\${NAME}"
!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "Start Menu Folder"
!define MUI_STARTMENUPAGE_DEFAULTFOLDER "${NAME}"

!insertmacro MUI_PAGE_STARTMENU Application $StartMenuFolder

!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_RUN $INSTDIR\naikari-${SUFFIX}.exe
!define MUI_FINISHPAGE_RUN_PARAMETERS
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

;--------------------------------
;Languages

!insertmacro MUI_LANGUAGE "English"

LicenseLangString gpl ${LANG_ENGLISH} "legal/gpl-3.0.txt"

;--------------------------------
;Installer Sections

Var PortID

Section "Naikari Engine and Data" BinarySection

  SectionIn RO

  SetOutPath "$INSTDIR"
  File /r bin\*
  File logo.ico

  SetShellVarContext all

  !insertmacro MUI_STARTMENU_WRITE_BEGIN Application

    ;Create start menu and desktop shortcuts
    CreateDirectory "$SMPROGRAMS\$StartMenuFolder"
    CreateShortCut "$SMPROGRAMS\$StartMenuFolder\${NAME}.lnk" "$INSTDIR\naikari-${SUFFIX}.exe"
    CreateShortCut "$DESKTOP\${NAME}.lnk" "$INSTDIR\naikari-${SUFFIX}.exe"

  !insertmacro MUI_STARTMENU_WRITE_END

  ;--------------------------------
  ;Create Registry Keys
  WriteRegStr HKLM "SOFTWARE\${NAME}" "" "$INSTDIR"
  WriteRegStr HKLM "${UNINSTALL_KEY}\${NAME}" "DisplayName" "${PACKAGE} (remove only)"
  WriteRegStr HKLM "${UNINSTALL_KEY}\${NAME}" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegStr HKLM "${UNINSTALL_KEY}\${NAME}" "QuietUninstallString" "$\"$INSTDIR\Uninstall.exe$\" /S"
  WriteRegStr HKLM "${UNINSTALL_KEY}\${NAME}" "Publisher" "${NAIKARI_DEV}"
  WriteRegStr HKLM "${UNINSTALL_KEY}\${NAME}" "DisplayVersion" "${VERSION}"
  WriteRegStr HKLM "${UNINSTALL_KEY}\${NAME}" "HelpLink" "${NAIKARI_URL}"
  WriteRegDWORD HKLM "${UNINSTALL_KEY}\${NAME}" "NoModify" 1
  WriteRegDWORD HKLM "${UNINSTALL_KEY}\${NAME}" "NoRepair" 1
  ;Create Uninstaller
  WriteUninstaller "uninstall.exe"

SectionEnd

;--------------------------------
;Uninstaller Section
Section Uninstall
  !insertmacro MUI_STARTMENU_GETFOLDER Application $StartMenuFolder
  DeleteRegKey HKLM "${UNINSTALL_KEY}\${NAME}"
  DeleteRegKey HKLM "SOFTWARE\${NAME}"
  Delete "$DESKTOP\${NAME}.lnk"
  RMDir /r "$INSTDIR"

  SetShellVarContext all
  RMDir /r "$SMPROGRAMS\${PACKAGE}"
SectionEnd

;--------------------------------
;Installer Functions

Function .onInit
  !insertmacro MUI_LANGDLL_DISPLAY
   
  ReadRegStr $R0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${NAME}" "UninstallString"
  ${Unless} ${Errors}
    ;If we get here we're already installed
    MessageBox MB_YESNO|MB_ICONEXCLAMATION "Naikari is already installed! Would you like to remove the old install first?" IDNO skip
    ExecWait $R0 $0
    ${Unless} $0 = 0 ;note: = not ==
      MessageBox MB_OK|MB_ICONSTOP "The uninstall failed!"
    ${EndUnless}
    skip:
  ${EndUnless}

FunctionEnd

;--------------------------------
;Uninstaller Functions

Function un.onInit

  !insertmacro MUI_UNGETLANGUAGE

FunctionEnd
