**Big World Setup (BWS) : Mod Manager for Infinity Engine Games and Baldur's Gate/Enhanced Edition Trilogy by dabus**

**Issue reporting is closed:**

Since there is no active BWS code maintainer, there is no point reporting issues because there is no one who can fix them.

Community support: <http://www.shsforums.net/topic/56670-big-world-setup-an-attempt-to-update-the-program>

Community support: <https://forums.beamdog.com/discussion/44476/tool-big-world-setup-bws-mod-manager-for-baldurs-gate-enhanced-edition-trilogy-for-windows/p1>

Mod requests: <http://www.shsforums.net/topic/58006-big-world-setup-mod-request-template>

! Don't use BitBucket's web-interface to edit files because it doesn't save non-ANSI characters properly

**Download:**                 : <https://bitbucket.org/BigWorldSetup/bigworldsetup/get/master.zip>

![gRmfnLY[1].png](https://bitbucket.org/repo/kKX5Xg/images/3720385461-gRmfnLY%5B1%5D.png)

**Download:**                 : <https://bitbucket.org/BigWorldSetup/bigworldsetup/get/master.zip>

Instruction/FAQ          : <https://forums.beamdog.com/discussion/comment/704157>

Discussion               : <http://www.shsforums.net/topic/56670-big-world-setup-an-attempt-to-update-the-program>

Mod Request Template     : <http://www.shsforums.net/topic/58006-big-world-setup-mod-request-template>

Change History           : <https://bitbucket.org/BigWorldSetup/bigworldsetup/commits/all>

### Contributors ###

dabus(author), agb1, AL|EN, Quiet

### How do I contribute? ###

- learn git basics (<https://git-scm.com/videos> <https://git-scm.com/book/en/v2>)
- fork BWS repository using "SourceTree" or "SmartGit" or other preferred tool
- add mods/make other changes (see FAQ in the Docs folder of the BWS package!)
- create a pull request to submit changes from your fork back to the main project

### Features ###

- downloading mods (please see remarks!)
- easy mod installation for BGT and EET
- correct install order of mods/components
- handle mod and components conflicts
- apply community fixes from [Big World Fixpack](<https://github.com/BiGWorldProject/BiG-World-Fixpack>)
- easy backup creation/restoring
- ability to add you own mods

### Supported games ###

Active:

- Baldur's Gate: Enhanced Edition (standalone game)
- Baldur's Gate II: Enhanced Edition (standalone game)
- Enhanced Edition Trilogy ( BG1:EE + SoD + BG2:EE ) (planned: IWD1:EE + partial IWD2-in-EET)
- Planescape: Torment Enhanced Edition
- Icewind Dale: Enhanced Edition

Not maintained:

- Baldur's Gate 2 (classic standalone game)
- Baldur’s Gate Trilogy ( Classic BG1 + Classic BG2 )
- Icewind Dale
- Icewind Dale II
- Planescape: Torment

### Supported mods ###

- Almost all of them! (use the Mod Request Template link above if there is a mod you want added)

### Getting started ###

1. Download Big World Setup zip archive and extract it anywhere you want (but not in your game folder!)
2. Close any open games and game editors to avoid interference with the installation process
3. Disable your antivirus (only while you are installing - don't forget to re-enable it after!)
4. Disable User Account Control (if you don't do this, the automated installation can get stuck!)
5. Execute "BWS.vbs"
6. Optional: use "BWS-NoAutoUpdate.vbs", this will skip the auto-update feature, use only when you modify BWS files or preforming some tests

### Technical information

- AutoIt3
- AutoIt3 UDFs
- 7-Zip, wget, Scite4AutoIt3, PDFtoText, The Gimp
- Parts of Holgers Tristate GUI TreeView
- w0uters ReduceMemory
- Parts of MrCreatoRs CheckFileSize
- and many others I can't remember...
