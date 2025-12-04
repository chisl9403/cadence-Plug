#
# Cadence Capture SVN Plugin
# Version: 1.1
# Date: 2025-12-04
# Author: Sloan Chi
#

package require Tcl 8.4

# Create namespace
namespace eval ::CaptureMenuPlugin {
    variable SvnPath "svn"
    variable autoShow 1
    variable configFile ""
    variable logFile ""
}

# Initialize log file
proc ::CaptureMenuPlugin::InitLog {} {
    variable logFile
    if {$logFile eq ""} {
        set logFile [file join [pwd] "capture_svn_plugin.log"]
    }
}

# Write log message (disabled for production)
proc ::CaptureMenuPlugin::Log {msg} {
    # Logging disabled
    return
}

# Get config file path
proc ::CaptureMenuPlugin::GetConfigFile {} {
    variable configFile
    if {$configFile eq ""} {
        if {[info exists ::env(USERPROFILE)]} {
            set configFile [file join $::env(USERPROFILE) ".capture_svn_config"]
        } elseif {[info exists ::env(HOME)]} {
            set configFile [file join $::env(HOME) ".capture_svn_config"]
        } else {
            set configFile [file join [pwd] ".capture_svn_config"]
        }
    }
    return $configFile
}

# Load configuration
proc ::CaptureMenuPlugin::LoadConfig {} {
    variable autoShow
    set autoShow 1
    set cfgFile [::CaptureMenuPlugin::GetConfigFile]
    if {[file exists $cfgFile]} {
        if {[catch {
            set fp [open $cfgFile r]
            set content [read $fp]
            close $fp
            foreach line [split $content "\n"] {
                if {[regexp {^autoShow=([01])$} $line -> value]} {
                    set autoShow $value
                }
            }
        }]} {
            set autoShow 1
        }
    }
}

# Save configuration
proc ::CaptureMenuPlugin::SaveConfig {} {
    variable autoShow
    set cfgFile [::CaptureMenuPlugin::GetConfigFile]
    if {[catch {
        set fp [open $cfgFile w]
        puts $fp "autoShow=$autoShow"
        close $fp
    }]} {
        # Ignore save errors
    }
}

# Toggle auto-show setting
proc ::CaptureMenuPlugin::ToggleAutoShow {} {
    variable autoShow
    set autoShow [expr {!$autoShow}]
    ::CaptureMenuPlugin::SaveConfig
    
    if {[catch {package require Tk}]} {
        return
    }
    
    set msg [expr {$autoShow ? "Auto-show enabled: Toolbar will show on startup" : "Auto-show disabled: Toolbar will NOT show on startup"}]
    catch {
        tk_messageBox -title "Settings" -message $msg -type ok -icon info
    }
}

# Get SVN executable path
proc ::CaptureMenuPlugin::GetSvnPath {} {
    variable SvnPath
    
    set commonPaths {
        "C:/Program Files/TortoiseSVN/bin/svn.exe"
        "C:/Program Files (x86)/TortoiseSVN/bin/svn.exe"
    }
    
    if {$SvnPath ne "svn" && [file exists $SvnPath]} {
        return $SvnPath
    }
    
    foreach path $commonPaths {
        if {[file exists $path]} {
            set SvnPath $path
            return $path
        }
    }
    
    if {![catch {exec where.exe svn 2>NUL} result]} {
        set foundPath [string trim [lindex [split $result "\n"] 0]]
        if {$foundPath ne ""} {
            return $foundPath
        }
    }
    
    if {[file exists "C:/Program Files/TortoiseSVN/bin/TortoiseProc.exe"]} {
        return "TORTOISE"
    }
    
    return ""
}

# Check if directory is SVN working copy
proc ::CaptureMenuPlugin::IsSvnWorkingCopy {path} {
    set svnDir [file join $path ".svn"]
    if {[file exists $svnDir] && [file isdirectory $svnDir]} {
        return 1
    }
    
    set currentPath $path
    for {set i 0} {$i < 5} {incr i} {
        set parentPath [file dirname $currentPath]
        if {$parentPath == $currentPath} { break }
        set svnDir [file join $parentPath ".svn"]
        if {[file exists $svnDir] && [file isdirectory $svnDir]} {
            return 1
        }
        set currentPath $parentPath
    }
    
    return 0
}

# Get design file path
proc ::CaptureMenuPlugin::GetDesignPath {} {
    catch {
        set session [DboSession_GetInstance]
        if {$session != ""} {
            set design [$session GetActiveDesign]
            if {$design != ""} {
                set schematic [$design GetRootSchematic]
                if {$schematic != ""} {
                    set dsnFile [$schematic GetPath]
                    if {$dsnFile != ""} {
                        return [file dirname $dsnFile]
                    }
                }
            }
        }
    }
    return [pwd]
}

# Show message box
proc ShowMessage {msg title {type 0}} {
    if {![catch {package require Tk}]} {
        catch {wm withdraw .}
        if {$type == 4} {
            set answer [tk_messageBox -type yesno -icon question -title $title -message $msg -parent .]
            return [expr {$answer eq "yes" ? 6 : 7}]
        } else {
            tk_messageBox -type ok -icon info -title $title -message $msg -parent .
            return 1
        }
    }
    return 1
}

# SVN Update Command
proc ::CaptureMenuPlugin::SvnUpdate {} {
    ::CaptureMenuPlugin::Log "SvnUpdate: Starting..."
    set designPath [::CaptureMenuPlugin::GetDesignPath]
    ::CaptureMenuPlugin::Log "SvnUpdate: Design path = $designPath"
    
    ::CaptureMenuPlugin::Log "SvnUpdate: Checking if SVN working copy..."
    set isSvn 0
    if {[catch {set isSvn [::CaptureMenuPlugin::IsSvnWorkingCopy $designPath]} err]} {
        ::CaptureMenuPlugin::Log "SvnUpdate: IsSvnWorkingCopy failed: $err"
        ShowMessage "Error checking SVN status:\n$err" "Error" 0
        return
    }
    ::CaptureMenuPlugin::Log "SvnUpdate: IsSvnWorkingCopy returned: $isSvn"
    
    if {!$isSvn} {
        ShowMessage "Not an SVN working copy:\n$designPath" "Error" 0
        return
    }
    
    ::CaptureMenuPlugin::Log "SvnUpdate: Getting SVN path..."
    set svnExe [::CaptureMenuPlugin::GetSvnPath]
    ::CaptureMenuPlugin::Log "SvnUpdate: SVN path = $svnExe"
    
    if {$svnExe == ""} {
        ::CaptureMenuPlugin::Log "SvnUpdate: SVN not found!"
        ShowMessage "SVN not found!" "Error" 0
        return
    }
    
    if {$svnExe == "TORTOISE"} {
        ::CaptureMenuPlugin::Log "SvnUpdate: Using TortoiseSVN..."
        set tortoisePath "C:/Program Files/TortoiseSVN/bin/TortoiseProc.exe"
        set cmdLine [list $tortoisePath /command:update /path:$designPath /closeonend:0]
        ::CaptureMenuPlugin::Log "SvnUpdate: Executing: $cmdLine"
        if {[catch { eval exec $cmdLine & } err]} {
            ::CaptureMenuPlugin::Log "SvnUpdate: Execution failed: $err"
        } else {
            ::CaptureMenuPlugin::Log "SvnUpdate: TortoiseSVN launched successfully"
        }
        return
    }
    
    if {[catch {
        set output [exec $svnExe update "$designPath" 2>@1]
        ShowMessage "SVN Update completed\n\n$output" "Success" 0
    } err]} {
        ShowMessage "Update failed:\n$err" "Error" 0
    }
}

# SVN Commit Command
proc ::CaptureMenuPlugin::SvnCommit {} {
    ::CaptureMenuPlugin::Log "SvnCommit: Starting..."
    set designPath [::CaptureMenuPlugin::GetDesignPath]
    ::CaptureMenuPlugin::Log "SvnCommit: Design path = $designPath"
    
    ::CaptureMenuPlugin::Log "SvnCommit: Checking if SVN working copy..."
    set isSvn 0
    if {[catch {set isSvn [::CaptureMenuPlugin::IsSvnWorkingCopy $designPath]} err]} {
        ::CaptureMenuPlugin::Log "SvnCommit: IsSvnWorkingCopy failed: $err"
        ShowMessage "Error checking SVN status:\n$err" "Error" 0
        return
    }
    ::CaptureMenuPlugin::Log "SvnCommit: IsSvnWorkingCopy returned: $isSvn"
    
    if {!$isSvn} {
        ShowMessage "Not an SVN working copy:\n$designPath" "Error" 0
        return
    }
    
    ::CaptureMenuPlugin::Log "SvnCommit: Getting SVN path..."
    set svnExe [::CaptureMenuPlugin::GetSvnPath]
    ::CaptureMenuPlugin::Log "SvnCommit: SVN path = $svnExe"
    
    if {$svnExe == ""} {
        ::CaptureMenuPlugin::Log "SvnCommit: SVN not found!"
        ShowMessage "SVN not found!" "Error" 0
        return
    }
    
    if {$svnExe == "TORTOISE"} {
        ::CaptureMenuPlugin::Log "SvnCommit: Using TortoiseSVN..."
        set tortoisePath "C:/Program Files/TortoiseSVN/bin/TortoiseProc.exe"
        set cmdLine [list $tortoisePath /command:commit /path:$designPath /closeonend:0]
        ::CaptureMenuPlugin::Log "SvnCommit: Executing: $cmdLine"
        if {[catch { eval exec $cmdLine & } err]} {
            ::CaptureMenuPlugin::Log "SvnCommit: Execution failed: $err"
        } else {
            ::CaptureMenuPlugin::Log "SvnCommit: TortoiseSVN launched successfully"
        }
        return
    }
    
    if {[catch {
        set output [exec $svnExe commit "$designPath" 2>@1]
        ShowMessage "SVN Commit completed\n\n$output" "Success" 0
    } err]} {
        ShowMessage "Commit failed:\n$err" "Error" 0
    }
}

# SVN Show Log Command
proc ::CaptureMenuPlugin::SvnLog {} {
    ::CaptureMenuPlugin::Log "SvnLog: Starting..."
    set designPath [::CaptureMenuPlugin::GetDesignPath]
    ::CaptureMenuPlugin::Log "SvnLog: Design path = $designPath"
    
    ::CaptureMenuPlugin::Log "SvnLog: Checking if SVN working copy..."
    set isSvn 0
    if {[catch {set isSvn [::CaptureMenuPlugin::IsSvnWorkingCopy $designPath]} err]} {
        ::CaptureMenuPlugin::Log "SvnLog: IsSvnWorkingCopy failed: $err"
        ShowMessage "Error checking SVN status:\n$err" "Error" 0
        return
    }
    ::CaptureMenuPlugin::Log "SvnLog: IsSvnWorkingCopy returned: $isSvn"
    
    if {!$isSvn} {
        ShowMessage "Not an SVN working copy:\n$designPath" "Error" 0
        return
    }
    
    ::CaptureMenuPlugin::Log "SvnLog: Getting SVN path..."
    set svnExe [::CaptureMenuPlugin::GetSvnPath]
    ::CaptureMenuPlugin::Log "SvnLog: SVN path = $svnExe"
    
    if {$svnExe == ""} {
        ::CaptureMenuPlugin::Log "SvnLog: SVN not found!"
        ShowMessage "SVN not found!" "Error" 0
        return
    }
    
    if {$svnExe == "TORTOISE"} {
        ::CaptureMenuPlugin::Log "SvnLog: Using TortoiseSVN..."
        set tortoisePath "C:/Program Files/TortoiseSVN/bin/TortoiseProc.exe"
        set cmdLine [list $tortoisePath /command:log /path:$designPath /closeonend:0]
        ::CaptureMenuPlugin::Log "SvnLog: Executing: $cmdLine"
        if {[catch { eval exec $cmdLine & } err]} {
            ::CaptureMenuPlugin::Log "SvnLog: Execution failed: $err"
        } else {
            ::CaptureMenuPlugin::Log "SvnLog: TortoiseSVN launched successfully"
        }
        return
    }
    
    if {[catch {
        set output [exec $svnExe log --limit 20 "$designPath" 2>@1]
        ShowMessage "SVN Log:\n\n$output" "Log" 0
    } err]} {
        ShowMessage "Log failed:\n$err" "Error" 0
    }
}

# SVN Cleanup Command
proc ::CaptureMenuPlugin::SvnCleanup {} {
    ::CaptureMenuPlugin::Log "SvnCleanup: Starting..."
    set designPath [::CaptureMenuPlugin::GetDesignPath]
    ::CaptureMenuPlugin::Log "SvnCleanup: Design path = $designPath"
    
    ::CaptureMenuPlugin::Log "SvnCleanup: Checking if SVN working copy..."
    set isSvn 0
    if {[catch {set isSvn [::CaptureMenuPlugin::IsSvnWorkingCopy $designPath]} err]} {
        ::CaptureMenuPlugin::Log "SvnCleanup: IsSvnWorkingCopy failed: $err"
        ShowMessage "Error checking SVN status:\n$err" "Error" 0
        return
    }
    ::CaptureMenuPlugin::Log "SvnCleanup: IsSvnWorkingCopy returned: $isSvn"
    
    if {!$isSvn} {
        ShowMessage "Not an SVN working copy:\n$designPath" "Error" 0
        return
    }
    
    ::CaptureMenuPlugin::Log "SvnCleanup: Getting SVN path..."
    set svnExe [::CaptureMenuPlugin::GetSvnPath]
    ::CaptureMenuPlugin::Log "SvnCleanup: SVN path = $svnExe"
    
    if {$svnExe == ""} {
        ::CaptureMenuPlugin::Log "SvnCleanup: SVN not found!"
        ShowMessage "SVN not found!" "Error" 0
        return
    }
    
    if {$svnExe == "TORTOISE"} {
        ::CaptureMenuPlugin::Log "SvnCleanup: Using TortoiseSVN..."
        set tortoisePath "C:/Program Files/TortoiseSVN/bin/TortoiseProc.exe"
        set cmdLine [list $tortoisePath /command:cleanup /path:$designPath /closeonend:0]
        ::CaptureMenuPlugin::Log "SvnCleanup: Executing: $cmdLine"
        if {[catch { eval exec $cmdLine & } err]} {
            ::CaptureMenuPlugin::Log "SvnCleanup: Execution failed: $err"
        } else {
            ::CaptureMenuPlugin::Log "SvnCleanup: TortoiseSVN launched successfully"
        }
        return
    }
    
    if {[catch {
        set output [exec $svnExe cleanup "$designPath" 2>@1]
        ShowMessage "SVN Cleanup completed\n\n$output" "Success" 0
    } err]} {
        ShowMessage "Cleanup failed:\n$err" "Error" 0
    }
}

# Settings
proc ::CaptureMenuPlugin::Settings {} {
    ::CaptureMenuPlugin::About
}

# About
proc ::CaptureMenuPlugin::About {} {
    set svnExe [::CaptureMenuPlugin::GetSvnPath]
    
    set msg "Cadence Capture SVN Plugin\n\n"
    append msg "Version: 1.1\n"
    append msg "Date: 2025-12-04\n"
    append msg "Author: Sloan Chi\n\n"
    
    append msg "--- Toolbar Buttons ---\n"
    append msg "U - SVN Update (Ctrl+U)\n"
    append msg "C - SVN Commit (Ctrl+M)\n"
    append msg "L - SVN Cleanup\n"
    append msg "S - SVN Show Log (Ctrl+H)\n"
    append msg "A - About Plugin\n\n"
    
    append msg "--- SVN Configuration ---\n"
    if {$svnExe == "TORTOISE"} {
        append msg "Mode: TortoiseSVN GUI\n"
        append msg "Path: C:/Program Files/TortoiseSVN/bin/TortoiseProc.exe"
    } elseif {$svnExe == ""} {
        append msg "Status: SVN NOT FOUND"
    } else {
        append msg "Mode: Command Line\n"
        append msg "Path: $svnExe"
    }
    
    ShowMessage $msg "About" 0
}

# Create floating menu window
proc ::CaptureMenuPlugin::CreateMenuWindow {} {
    ::CaptureMenuPlugin::Log "CreateMenuWindow: Starting..."
    
    if {[catch {package require Tk} err]} {
        ::CaptureMenuPlugin::Log "CreateMenuWindow: Failed to load Tk - $err"
        return
    }
    ::CaptureMenuPlugin::Log "CreateMenuWindow: Tk loaded successfully"
    
    # Withdraw the root window completely
    ::CaptureMenuPlugin::Log "CreateMenuWindow: Attempting to withdraw root window"
    catch {
        wm withdraw .
        ::CaptureMenuPlugin::Log "CreateMenuWindow: Root window withdrawn - wm withdraw executed"
        wm attributes . -alpha 0.0
        ::CaptureMenuPlugin::Log "CreateMenuWindow: Root window alpha set to 0.0"
    }
    
    if {[winfo exists .svnMenu]} {
        ::CaptureMenuPlugin::Log "CreateMenuWindow: .svnMenu already exists, showing it"
        wm deiconify .svnMenu
        raise .svnMenu
        return
    }
    
    ::CaptureMenuPlugin::Log "CreateMenuWindow: Creating new .svnMenu window"
    
    if {[catch {
        set screenWidth [winfo screenwidth .]
        set screenHeight [winfo screenheight .]
    }]} {
        set screenWidth 1920
        set screenHeight 1080
    }
    
    # Calculate taskbar height
    set taskbarHeight 40
    if {[catch {
        # Get work area (screen minus taskbar)
        set workHeight [winfo vrootheight .]
        if {$workHeight > 0 && $workHeight < $screenHeight} {
            set taskbarHeight [expr {$screenHeight - $workHeight}]
            ::CaptureMenuPlugin::Log "CreateMenuWindow: Detected taskbar height = $taskbarHeight"
        }
    }]} {
        ::CaptureMenuPlugin::Log "CreateMenuWindow: Using default taskbar height = $taskbarHeight"
    }
    
    set winWidth 130
    set winHeight 25
    set xPos [expr {$screenWidth - $winWidth - 5}]
    set yPos [expr {$screenHeight - $winHeight - $taskbarHeight - 21}]
    
    ::CaptureMenuPlugin::Log "CreateMenuWindow: Screen=${screenWidth}x${screenHeight}, Taskbar=${taskbarHeight}, Pos=${xPos},${yPos}"
    
    # Create as toplevel but make it a utility window
    ::CaptureMenuPlugin::Log "CreateMenuWindow: Creating toplevel .svnMenu"
    toplevel .svnMenu -class "TkSvnToolbar"
    
    # DON'T use transient - it causes geometry issues when parent is withdrawn
    # Just rely on -toolwindow to remove taskbar icon
    ::CaptureMenuPlugin::Log "CreateMenuWindow: Skipping transient (causes geometry bug with withdrawn parent)"
    
    # Now set window attributes
    ::CaptureMenuPlugin::Log "CreateMenuWindow: Setting window title"
    wm title .svnMenu "SVN"
    
    ::CaptureMenuPlugin::Log "CreateMenuWindow: Setting geometry ${winWidth}x${winHeight}+${xPos}+${yPos}"
    wm geometry .svnMenu "${winWidth}x${winHeight}+${xPos}+${yPos}"
    
    ::CaptureMenuPlugin::Log "CreateMenuWindow: Setting resizable 0 0"
    wm resizable .svnMenu 0 0
    
    # Create button frame directly (no custom title bar)
    frame .svnMenu.f -bg "#f0f0f0"
    pack .svnMenu.f -fill both -expand 1
    
    # SVN Update button (icon style)
    button .svnMenu.f.update -text "U" \
        -command {
            ::CaptureMenuPlugin::Log "Button: Update clicked"
            ::CaptureMenuPlugin::SvnUpdate
        } \
        -width 2 \
        -bg "#4CAF50" -fg white -font {Arial 8 bold} \
        -activebackground "#45a049" \
        -relief raised -borderwidth 1
    pack .svnMenu.f.update -side left -padx 1 -pady 1
    bind .svnMenu.f.update <Enter> {+wm title .svnMenu "SVN Update (Ctrl+U)"}
    bind .svnMenu.f.update <Leave> {+wm title .svnMenu "SVN"}
    
    # SVN Commit button (icon style)
    button .svnMenu.f.commit -text "C" \
        -command {
            ::CaptureMenuPlugin::Log "Button: Commit clicked"
            ::CaptureMenuPlugin::SvnCommit
        } \
        -width 2 \
        -bg "#2196F3" -fg white -font {Arial 8 bold} \
        -activebackground "#0b7dda" \
        -relief raised -borderwidth 1
    pack .svnMenu.f.commit -side left -padx 1 -pady 1
    bind .svnMenu.f.commit <Enter> {+wm title .svnMenu "SVN Commit (Ctrl+M)"}
    bind .svnMenu.f.commit <Leave> {+wm title .svnMenu "SVN"}
    
    # SVN Cleanup button (icon style)
    button .svnMenu.f.cleanup -text "L" \
        -command {
            ::CaptureMenuPlugin::Log "Button: Cleanup clicked"
            ::CaptureMenuPlugin::SvnCleanup
        } \
        -width 2 \
        -bg "#FF9800" -fg white -font {Arial 8 bold} \
        -activebackground "#e68900" \
        -relief raised -borderwidth 1
    pack .svnMenu.f.cleanup -side left -padx 1 -pady 1
    bind .svnMenu.f.cleanup <Enter> {+wm title .svnMenu "SVN Cleanup"}
    bind .svnMenu.f.cleanup <Leave> {+wm title .svnMenu "SVN"}
    
    # SVN Log button (icon style)
    button .svnMenu.f.log -text "S" \
        -command {
            ::CaptureMenuPlugin::Log "Button: Log clicked"
            ::CaptureMenuPlugin::SvnLog
        } \
        -width 2 \
        -bg "#9C27B0" -fg white -font {Arial 8 bold} \
        -activebackground "#7B1FA2" \
        -relief raised -borderwidth 1
    pack .svnMenu.f.log -side left -padx 1 -pady 1
    bind .svnMenu.f.log <Enter> {+wm title .svnMenu "SVN Show Log (Ctrl+H)"}
    bind .svnMenu.f.log <Leave> {+wm title .svnMenu "SVN"}
    
    # About button (icon style)
    button .svnMenu.f.settings -text "A" \
        -command {
            ::CaptureMenuPlugin::About
        } \
        -width 2 \
        -bg "#9E9E9E" -fg white -font {Arial 8 bold} \
        -activebackground "#757575" \
        -relief raised -borderwidth 1
    pack .svnMenu.f.settings -side left -padx 1 -pady 1
    bind .svnMenu.f.settings <Enter> {+wm title .svnMenu "About Plugin"}
    bind .svnMenu.f.settings <Leave> {+wm title .svnMenu "SVN"}
    
    # ALL content created - now set window attributes
    ::CaptureMenuPlugin::Log "CreateMenuWindow: All content created, now setting window attributes"
    
    # First ensure geometry is properly set
    update idletasks
    ::CaptureMenuPlugin::Log "CreateMenuWindow: After update idletasks, geometry: [wm geometry .svnMenu]"
    
    # Force geometry again to make sure
    wm geometry .svnMenu "${winWidth}x${winHeight}+${xPos}+${yPos}"
    ::CaptureMenuPlugin::Log "CreateMenuWindow: Geometry reset to ${winWidth}x${winHeight}+${xPos}+${yPos}"
    
    # Now set window decorations
    ::CaptureMenuPlugin::Log "CreateMenuWindow: Trying -toolwindow 1"
    if {[catch {wm attributes .svnMenu -toolwindow 1} err]} {
        ::CaptureMenuPlugin::Log "CreateMenuWindow: -toolwindow failed: $err"
    } else {
        ::CaptureMenuPlugin::Log "CreateMenuWindow: -toolwindow succeeded"
    }
    
    ::CaptureMenuPlugin::Log "CreateMenuWindow: Setting -topmost 1"
    wm attributes .svnMenu -topmost 1
    
    # DON'T use overrideredirect - it causes 1x1 geometry bug on Windows
    # Instead rely on -toolwindow which removes taskbar icon
    # System title bar will be hidden by our custom title bar covering it
    ::CaptureMenuPlugin::Log "CreateMenuWindow: Skipping overrideredirect due to Windows Tk geometry bug"
    ::CaptureMenuPlugin::Log "CreateMenuWindow: Final geometry: [wm geometry .svnMenu]"
    
    # Now show the window
    ::CaptureMenuPlugin::Log "CreateMenuWindow: Showing window"
    wm deiconify .svnMenu
    raise .svnMenu
    update
    
    ::CaptureMenuPlugin::Log "CreateMenuWindow: Window created successfully at ${xPos},${yPos} size ${winWidth}x${winHeight}"
    if {[catch {set mapped [winfo ismapped .svnMenu]} err]} {
        ::CaptureMenuPlugin::Log "CreateMenuWindow: Window state - exists: [winfo exists .svnMenu], ismapped error: $err"
    } else {
        ::CaptureMenuPlugin::Log "CreateMenuWindow: Window state - visible: $mapped, exists: [winfo exists .svnMenu]"
    }
}

# Show/Hide menu
proc ::CaptureMenuPlugin::ShowMenu {} {
    if {[catch {package require Tk}]} {
        return
    }
    if {[winfo exists .svnMenu]} {
        wm deiconify .svnMenu
        raise .svnMenu
    } else {
        ::CaptureMenuPlugin::CreateMenuWindow
    }
}

proc ::CaptureMenuPlugin::HideMenu {} {
    if {[catch {package require Tk}]} {
        return
    }
    if {[winfo exists .svnMenu]} {
        wm withdraw .svnMenu
    }
}

# Load config and auto-show on startup
::CaptureMenuPlugin::Log "=== Plugin Loading ==="

# Force autoShow to enabled
namespace eval ::CaptureMenuPlugin {
    variable autoShow
    set autoShow 1
}

# Always show menu on startup
::CaptureMenuPlugin::Log "Attempting to show menu..."

# Load Tk package
set tkLoaded 0
if {[catch {package require Tk} tkVersion]} {
    ::CaptureMenuPlugin::Log "Tk package load failed: $tkVersion"
} else {
    ::CaptureMenuPlugin::Log "Tk package loaded successfully, version: $tkVersion"
    set tkLoaded 1
}

if {$tkLoaded} {
    # Try immediate show
    ::CaptureMenuPlugin::Log "Calling ShowMenu immediately..."
    catch {::CaptureMenuPlugin::ShowMenu} err
    if {$err ne ""} {
        ::CaptureMenuPlugin::Log "Immediate ShowMenu error: $err"
    }
    
    # Also schedule delayed show as backup
    after 500 {
        ::CaptureMenuPlugin::Log "Delayed ShowMenu (500ms)"
        catch {::CaptureMenuPlugin::ShowMenu}
    }
    
    after 1500 {
        ::CaptureMenuPlugin::Log "Delayed ShowMenu (1500ms)"
        catch {::CaptureMenuPlugin::ShowMenu}
    }
}

# Register menu commands
::CaptureMenuPlugin::Log "=== Starting Menu Command Registration ==="

set tkAvailable 0
if {[catch {package require Tk} tkVer]} {
    ::CaptureMenuPlugin::Log "Tk package NOT available - error: $tkVer"
} else {
    set tkAvailable 1
    ::CaptureMenuPlugin::Log "Tk package available (version $tkVer) for menu registration"
}

if {$tkAvailable} {
    ::CaptureMenuPlugin::Log "Attempting to register: _cdnMenuPluginSvnUpdate"
    if {[catch {RegisterAction "_cdnMenuPluginSvnUpdate" "::CaptureMenuPlugin::SvnUpdate" "" "" ""} err]} {
        ::CaptureMenuPlugin::Log "Failed to register SvnUpdate: $err"
    } else {
        ::CaptureMenuPlugin::Log "Successfully registered SvnUpdate"
    }
    
    ::CaptureMenuPlugin::Log "Attempting to register: _cdnMenuPluginSvnCommit"
    if {[catch {RegisterAction "_cdnMenuPluginSvnCommit" "::CaptureMenuPlugin::SvnCommit" "" "" ""} err]} {
        ::CaptureMenuPlugin::Log "Failed to register SvnCommit: $err"
    } else {
        ::CaptureMenuPlugin::Log "Successfully registered SvnCommit"
    }
    
    ::CaptureMenuPlugin::Log "Attempting to register: _cdnMenuPluginSvnLog"
    if {[catch {RegisterAction "_cdnMenuPluginSvnLog" "::CaptureMenuPlugin::SvnLog" "" "" ""} err]} {
        ::CaptureMenuPlugin::Log "Failed to register SvnLog: $err"
    } else {
        ::CaptureMenuPlugin::Log "Successfully registered SvnLog"
    }
    
    ::CaptureMenuPlugin::Log "Attempting to register: _cdnMenuPluginShowMenu"
    if {[catch {RegisterAction "_cdnMenuPluginShowMenu" "::CaptureMenuPlugin::ShowMenu" "" "" ""} err]} {
        ::CaptureMenuPlugin::Log "Failed to register ShowMenu: $err"
    } else {
        ::CaptureMenuPlugin::Log "Successfully registered ShowMenu"
    }
    
    ::CaptureMenuPlugin::Log "Attempting to register: _cdnMenuPluginSettings"
    if {[catch {RegisterAction "_cdnMenuPluginSettings" "::CaptureMenuPlugin::Settings" "" "" ""} err]} {
        ::CaptureMenuPlugin::Log "Failed to register Settings: $err"
    } else {
        ::CaptureMenuPlugin::Log "Successfully registered Settings"
    }
    
    ::CaptureMenuPlugin::Log "Attempting to register: _cdnMenuPluginAbout"
    if {[catch {RegisterAction "_cdnMenuPluginAbout" "::CaptureMenuPlugin::About" "" "" ""} err]} {
        ::CaptureMenuPlugin::Log "Failed to register About: $err"
    } else {
        ::CaptureMenuPlugin::Log "Successfully registered About"
    }
    
    ::CaptureMenuPlugin::Log "Menu command registration complete"
} else {
    ::CaptureMenuPlugin::Log "Skipping menu registration - Tk not available"
}

::CaptureMenuPlugin::Log "=== Plugin Load Complete ==="

