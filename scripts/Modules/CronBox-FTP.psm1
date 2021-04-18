#!/usr/bin/pwsh
# @(#)--------------------------------------------------------------------------
# @(#)Shell		: /usr/bin/pwsh
# @(#)Auteur		: PVaissiere
# @(#)Nom		: CronBox-Ftp.psm1
# @(#)Date		: 2021/04/18
# @(#)Version		: 0.5.6
# @(#)
# @(#)Resume		: Module des functions Ftp
# @(#)
# @(#)Liste des fonctions
# @(#)			Add-FtpPathValues
# @(#)			Assert-Libraries
# @(#)			Assert-PortFtp
# @(#)			Get-FtpChildItem
# @(#)			Get-FtpPathValues
# @(#)			Get-PathLibrariesValue
# @(#)			Initialize-FtpToLocal
# @(#)			Initialize-ModuleFtp
# @(#)			Optimize-FtpDirectories
# @(#)			Set-FtpCommands
# @(#)			Set-FtpConnector
# @(#)			Set-FtpPasswordValue
# @(#)			Set-FtpPortValue
# @(#)			Set-FtpTypeValue
# @(#)			Set-FtpUrlValue
# @(#)			Set-FtpUserValue
# @(#)			Start-FtpCommands
# @(#)			Sync-FtpToLocal
# @(#)			Test-FtpPath
# @(#)--------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# --- Définition des variables du module
# ------------------------------------------------------------------------------
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'ChrSeparateur' -Value ( [System.IO.Path]::DirectorySeparatorChar ) -Description 'caractère séparateur répertoire'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'ChrSeparateurAlt' -Value ( [System.IO.Path]::AltDirectorySeparatorChar ) -Description 'alt caractère séparateur répertoire'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'CmdLftpConnect' -Value ( [String]'£FtpType£://£FtpUser£:"£FtpPassword£"@£FtpUrl£:£FtpPort£' ) -Description 'Variable de connexion pour ltfp'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'CmdLftpConnector' -Value ( [String]'' ) -Description 'Variable de connexion pour ltfp'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'CmdLftpMirror' -Value @( "mirror -v -c --no-empty-dirs --Remove-source-files --Remove-source-dirs '£From£' '£To£'" ) -Description 'Commande de mirroir entre deux élèment'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'CmdLftpQuit' -Value @( 'quit' ) -Description 'Commande de sortie lftp'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'CmdLftpSet' -Value  @( 'set file:charset utf8', 'set ftp:charset iso8859-1', 'set sftp:auto-confirm yes', 'set ssl:verify-certificate no' ) -Description 'Commandes préparation à la connexion lftp'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'FtpObjects' -Value ( [Object[]]@() ) -Description 'Liste des objets distants'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'FtpPassword' -Value ( [String]'' ) -Description 'Mot de passe du compte de l`utilisateur ftp de la seedbox'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'FtpPath' -Value ( [Object[]]@() ) -Description 'Liste des répertoires Ftp et Locaux'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'FtpPort' -Value ( [String]'' ) -Description 'Port utilisé pour l`accès à seedbox. standart ftp:21 | standart sftp 22'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'FtpType' -Value ( [String]'' ) -Description 'Type ftp ou sftp de la seedbox'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'FtpUrl' -Value ( [String]'' ) -Description 'Url vers le ftp de la seedbox.'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'FtpUser' -Value ( [String]'' ) -Description 'Compte de l`utilisateur ftp de la seedbox'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'MsgModuleFtp' -Value ( [Hashtable]@{
	'ChkFtpPath' =		'=== [CHECK] Test présence {0}'
	'ChkFtpToLocal' =	'=== [CHECK] Vérifie le contenu des librairies distantes'
	'ChkPortFtp' =		'=== [CHECK] Test connexion {0}:{1}'
	'ChkPortFtpKO' =	' : Test KO'
	'ChkPortFtpOK' =	' : Test OK'
	'ErrAssertLib' =	"Aucune Variables FtpPath n'est valable. Le module ne peux aller plus loin"
	'ErrFtpCommands' =	'Connextion ftp en erreur£{0}'
	'ErrFtpConnector1' =	"La variable définition d'ouverture ftp n'est pas disponible"
	'ErrFtpConnector2' =	"La variable {0} n'a pas été trouvé."
	'ErrFtpPassword' =	"La variable FtpPassword est vide.£Ajouter Set-FtpPasswordValue -Value 'VotreValeur' avant Initialize-ModuleFtp"
	'ErrFtpPath' =		"Aucune variable FtpPath n'a été définie"
	'ErrFtpPathDouble' =	'Variable {0} dans Add-FtpPathValues ont été trouvé en double ou plus : {1}'
	'ErrFtpPort' =		"La variable FtpPort est vide.£Ajouter Set-FtpPortValue -Value 'VotreValeur' avant Initialize-ModuleFtp"
	'ErrFtpToLocal' =	'=== [ERREUR] La variable {0} na pas été trouvé.'
	'ErrFtpType' =		"La variable FtpType est vide.£Ajouter Set-FtpTypeValue -Value 'VotreValeur' avant Initialize-ModuleFtp"
	'ErrFtpUrl' =		"La variable FtpUrl est vide.£Ajouter Set-FtpUrlValue -Value 'VotreValeur' avant Initialize-ModuleFtp"
	'ErrFtpUser' =		"La variable FtpUser est vide.£Ajouter Set-FtpUserValue -Value 'VotreValeur' avant Initialize-ModuleFtp"
	'ErrModuleCommun' =	"Le module CronBox-Commun et ses fonctions n'a pas été trouvé£Merci de vérifier le chargement des modules."
	'ErrModuleFtp' =	"La fonction {0} ne peux pas être appelé avant Initialize-ModuleFtp"
	'ErrModuleLog' =	"Le module CronBox-Log et ses fonctions n'a pas été trouvé£Merci de vérifier le chargement des modules."
	'ErrModuleLogInit' =	'Le module Log doit être initié avant le module Ftp'
	'ErrPathBetween' =	"Le répertoire 'between' dans le répertoire {0} n'a pas été trouvé"
	'ErrScriptsEtc' =	"Le répertoire etc dans le répertoire scripts n'a pas été trouvé"
	'NfoAssertLib' =	'=== [INFO] Test des variables libraries'
	'NfoFtpToLocal' =	'=== [INFO] Migration des fichiers de {0} vers {1}'
	'NfoFtpToLocal2' =	'=== [INFO] Aucun contenu trouvé'
	'NfoOptDistRm' =	'=== [INFO] Suppression distant : {0}'
	'WrgAssertLibDistant' =	'=== [WARNING] Le répertoire Distant {0} non trouvé'
	'WrgAssertLibLocal' =	'=== [WARNING] Le répertoire local {0} non trouvé'
} ) -Description 'Variable des messages'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'PathBetween' -Value ( [String]'' ) -Description 'Chemin vers le fichier de configuration des libraries'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'PathLibraries' -Value $env:CRONLIBRARIES -Description 'Chemin du répertoire des libraries'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'PathLibrariesConf' -Value ( [String]'' ) -Description 'Chemin vers le fichier de configuration des libraries'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'PathScripts' -Value $env:CRONSCRIPTS -Description 'Chemin du répertoire des libraries'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'SwtModuleFtp' -Value ( [Switch]$false) -Description 'Switch si Initialize-ModuleFtp a été lancé'

# ------------------------------------------------------------------------------
# --- Définition des fonctions
# ------------------------------------------------------------------------------
Function Add-FtpPathValues {
<#
.SYNOPSIS
Ajoute un ensemble de valeur qui défini une nouvelle librairie.

.DESCRIPTION
Permet l'ajout des valeurs qui définie l'ensemble d'une nouvelle librairie.

.PARAMETER LocalPath
Paramètre qui définie le répertoire local.

.PARAMETER DistantPath
Paramètre qui définie le répertoire distant.

.PARAMETER Name
Paramètre qui définie le nom de cet ensemble.

.PARAMETER Type
Paramètre qui définie le type de cet ensemble.

.INPUTS
Les valeurs ne peuvent pas être passé par le pipeline.
#>
	[CmdletBinding()]
	Param (
	[Parameter(Mandatory=$true,
	ValueFromPipeline=$false)]
		[String]$LocalPath,
	[Parameter(Mandatory=$true,
	ValueFromPipeline=$false)]
	[String]$DistantPath,
	[Parameter(Mandatory=$true,
	ValueFromPipeline=$false)]
		[String]$Name,
	[Parameter(Mandatory=$false,
	ValueFromPipeline=$false)]
		[String]$Type
	)

	$Object = New-Object PSObject
	$Object | Add-Member -MemberType 'NoteProperty' -Name 'LocalPath' -Value $LocalPath
	$Object | Add-Member -MemberType 'NoteProperty' -Name 'DistantPath' -Value $DistantPath
	$Object | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value $Name
	$Object | Add-Member -MemberType 'NoteProperty' -Name 'Type' -Value $Type
	$Script:FtpPath += $Object
}

Function Assert-Libraries {
<#
.SYNOPSIS
Vérifie toutes les librairies.

.DESCRIPTION
Permet de tester et filtrer les librairies fonctionnelles
locales et distantes et stocke cela dans un fichier pour 
raccourcir la durée du test.

.PARAMETER Force
Paramètre qui permet de forcer l'ensemble des tests.

.INPUTS
Les valeurs ne peuvent pas être passé par le pipeline.
#>

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false,
		ValueFromPipeline=$false)]
		[Alias("Forcer")]
			[Switch]$Force = $false
	)

	If ( Test-Path -Path $Script:PathLibrariesConf -PathType Leaf ) {
		If ( (Get-ChildItem -Path $Script:PathLibrariesConf).Length -ne 0 ) {
			If ( [Bool](Compare-Object -ReferenceObject ($Script:FtpPath | ConvertTo-Csv) -DifferenceObject (Get-Content -Path $Script:PathLibrariesConf -Encoding utf8) ) ) {
				$DoIt = $true		
			} Else {
				$DoIt = $false
			}
		} Else {
			$DoIt = $true	
		}
	} Else {
		$DoIt = $true
	}

	If ( $DoIt -or $Force ) {
		Write-Log -Value $Script:MsgModuleFtp.NfoAssertLib
		$TmpFtpPath = $Script:FtpPath | ForEach-Object {
			If ( Test-Path -Path $_.LocalPath -PathType Container ) {
				$TestLocal = $true
			} Else {
				Write-Log -Value ( $Script:MsgModuleFtp.WrgAssertLibLocal -f $_.LocalPath )
				$TestLocal = $false
			}
			If ( Test-FtpPath -Path $_.DistantPath ) {
				$TestDistant = $true
			} Else {
				Write-Log -Value ( $Script:MsgModuleFtp.WrgAssertLibDistant -f $_.DistantPath )
				$TestDistant = $false
			}
			If ( $TestLocal -and $TestDistant) {
				$_
			}
		}
		If ($TmpFtpPath) {
			$TmpFtpPath | Export-Csv -Path $Script:PathLibrariesConf -Encoding utf8
		} Else {
			Throw ( $Script:MsgModuleFtp.ErrAssertLib )
		}
		$Script:FtpPath = $TmpFtpPath
	}
}

Function Assert-PortFtp {
<#
.SYNOPSIS
Vérifie si le port TCP de la seedbox est ouvert.

.DESCRIPTION
Vérifie si le port TCP de la seedbox est ouvert.
#>
	
	Write-Log -Value ( $Script:MsgModuleFtp.ChkPortFtp -f $Script:FtpUrl, $Script:FtpPort ) -DisableNewLine
	Try {
		$Client = New-Object System.Net.Sockets.TcpClient($Script:FtpUrl, $Script:FtpPort)
		$Client.Close()
	}
	Catch {
		Write-Log -Value $Script:MsgModuleFtp.ChkPortFtpKO -DisableTime
		Throw ( $_.Exception.Message )
	}
	Write-Log -Value $Script:MsgModuleFtp.ChkPortFtpOK -DisableTime
}

Function Get-FtpChildItem {
<#
.SYNOPSIS
Get-ChilItem pour serveur Ftp via lftp

.DESCRIPTION
Récupère la liste des fichiers et répertoires distant et
le retourne sous forme d'objet[] 

.PARAMETER Path
Chemin ftp a cataloguer.

.PARAMETER Recurse
.
#>

	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$false,
		ValueFromPipeline=$false)]
		[Alias("Chemin")]
			[String]$Path,
		[Parameter(Mandatory=$false,
		ValueFromPipeline=$false)]
		[Alias("Recurrent")]
			[Switch]$Recurse = $false
	)

	Try {
		# --- Traitement et récupération via LFtp
		If ( $Path ) {
			$TmpPath = $Path -replace "'", "\'"
			$Command = "ls '$TmpPath'"
		} Else {
			$Command = 'ls'
		}
		[Object[]]$Out = Start-FtpCommands -Command $Command -Retour
	}
	Catch {
		Throw ( ( ( $_.ScriptStackTrace -split '\r?\n' )[0] -replace '\<ScriptBlock\>\,\s','' ) + '£' + $_.Exception.Message )
	}
	
	If ($Out) {
		# --- Traitement des lignes extraite de la liste d'affichage
		[Object[]]$Object = $Out | ForEach-Object {
			$String = $_ -replace '(^\s+|\s+$)','' -replace '\s+',' '
			$String = $String -Split (' ')

			# --- Préparation de variables
			[String]$Permissions = $String[0]
			[Bool]$PSIsContainer = ($Permissions -match '^d') ? $true : $false
			[String]$User = ($String[1] -Split ('/'))[0]
			[String]$Group = ($String[1] -Split ('/'))[1]
			[Decimal]$Length = $String[2]
			[DateTime]$LastWriteTime = [DateTime]::ParseExact($String[3] + " " + $String[4], 'yyyy-MM-dd HH:mm:ss', $null)
			[String]$Name = $_.Substring( $_.IndexOf( $String[5] ),$_.Length - $_.IndexOf( $String[5] ) )
			[String]$FullName = ($Path -match "\\$|\/$") ? "$Path$Name" : "$Path/$Name"

			# --- Enregistrement en objet
			$SubObject = New-Object PSObject
			$SubObject | Add-Member -MemberType 'NoteProperty' -Name 'Permissions' -Value $Permissions
			$SubObject | Add-Member -MemberType 'NoteProperty' -Name 'LastWriteTime' -Value $LastWriteTime
			$SubObject | Add-Member -MemberType 'NoteProperty' -Name 'Length' -Value $Length
			$SubObject | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value $Name
			$SubObject | Add-Member -MemberType 'NoteProperty' -Name 'Path' -Value $Path
			$SubObject | Add-Member -MemberType 'NoteProperty' -Name 'FullName' -Value $FullName
			$SubObject | Add-Member -MemberType 'NoteProperty' -Name 'User' -Value $User
			$SubObject | Add-Member -MemberType 'NoteProperty' -Name 'Group' -Value $Group
			$SubObject | Add-Member -MemberType 'NoteProperty' -Name 'PSIsContainer' -Value $PSIsContainer
			$SubObject
		}
		# --- Scanne les sous répertoires si Recurse
		If ($Recurse -and [Bool]($Object | Where-Object { $_.PSIsContainer -eq $true })) {
			$Object += $Object | Where-Object { $_.PSIsContainer -eq $true } | ForEach-Object {
				$RecursePath = ($_.Path + $Script:ChrSeparateur + $_.Name) -replace "\$Script:ChrSeparateur+", "$Script:ChrSeparateur"
				Try {
					Get-FtpChildItem -Path $RecursePath -Recurse
				}
				Catch{
					Throw ( ( ( $_.ScriptStackTrace -split '\r?\n' )[0] -replace '\<ScriptBlock\>\,\s','' ) + '£' + $_.Exception.Message )
				}
			}
		}
	} Else {
		[Object[]]$Object = $null
	}

	If ( $null -ne $Object ) {
		$DefaultProperties = @( 'Permissions','LastWriteTime','Length', 'Name' )
		$DefaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet( 'DefaultDisplayPropertySet', [String[]]$DefaultProperties )
		$PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@( $DefaultDisplayPropertySet )
		$Object | Add-Member MemberSet PSStandardMembers $PSStandardMembers -Force
	}

	Return $Object | Sort-Object -Property Path
}

Function Get-FtpPathValues {
<#
.SYNOPSIS
Renvoi la liste des répertoires distants et Locaux.

.DESCRIPTION
Retourne la liste des répertoires distants et Locaux après vérification.
#>

	If ( -not $Script:SwtModuleFtp ) {
		Throw ( $Script:CronBoxCommunMsg.ErrModuleFtp -f $MyInvocation.MyCommand )
	}
	Return (Get-Variable -Scope 'Script' -Name 'FtpPath' -ValueOnly)
}

Function Get-PathLibrariesValue {
<#
.SYNOPSIS
Renvoi le répertoire des librairies.

.DESCRIPTION
Renvoi le répertoire local où sont toutes les librairies.
#>

	Return (Get-Variable -Scope 'Script' -Name 'PathLibraries' -ValueOnly)
}

Function Initialize-FtpToLocal {
<#
.SYNOPSIS
Vérification des librairies distantes.

.DESCRIPTION
Scanne les librairies à la recherche d'éléments à traiter
#>

	Write-Log -Value $Script:MsgModuleFtp.ChkFtpToLocal
	[Object[]]$Result = $Script:FtpPath | ForEach-Object {
		$LocalPath = $_.LocalPath
		$DistantPath = $_.DistantPath
		$Name = $_.Name
		$Type = $_.Type
		Try {
			$Files = Get-FtpChildItem -Path $DistantPath -Recurse
		}
		Catch {
			Throw ( ( ( $_.ScriptStackTrace -split '\r?\n' )[0] -replace '\<ScriptBlock\>\,\s','' ) + '£' + $_.Exception.Message )
		}
		If ( [Bool]($Files) ) {
			$Files | ForEach-Object {
				$Object = New-Object PSObject
				$Object | Add-Member -MemberType 'NoteProperty' -Name 'LocalPath' -Value $LocalPath
				$Object | Add-Member -MemberType 'NoteProperty' -Name 'DistantPath' -Value $DistantPath
				$Object | Add-Member -MemberType 'NoteProperty' -Name 'Name' -Value $Name
				$Object | Add-Member -MemberType 'NoteProperty' -Name 'Type' -Value $Type
				$Object | Add-Member -MemberType 'NoteProperty' -Name 'File' -Value $_
				$Object
			}
		}
	}
	Return $Result
}

Function Initialize-ModuleFtp {
<#
.SYNOPSIS
Permet la vérification de tous les prérequis du module CronBox-Ftp

.DESCRIPTION
Vérifie si la fonction extérieure Assert-PathName est disponible
Vérifie si les variables FtpPassword, FtpPort, FtpType, FtpUrl et FtpUser sont défini,
Vérifie si le port du Ftp est ouvert,
Vérifie si des variables FtpPath ont été défini
Vérifie si le module Log est démarré,
Vérifie si le port du Ftp est ouvert.
#>

	# --- Vérification si le module CronBox-Commun est chargé
	IF ( -not [Bool]( Get-Command -Module CronBox-Commun ) ) {
		Throw ( $Script:MsgModuleFtp.ErrModuleCommun )
	}

	# --- Vérification si le module CronBox-Log est chargé
	IF ( -not [Bool]( Get-Command -Module CronBox-Log ) ) {
		Throw ( $Script:MsgModuleFtp.ErrModuleLog )
	}

	# --- Vérifie si la variable FtpPassword est défini
	If ( $Script:FtpPassword -eq '' ) {
		Throw ( $Script:MsgModuleFtp.ErrFtpPassword )
	}

	# --- Vérifie si la variable FtpPort est défini
	If ( $Script:FtpPort -eq '' ) {
		Throw ( $Script:MsgModuleFtp.ErrFtpPort )
	}

	# --- Vérifie si la variable FtpType est défini
	If ( $Script:FtpType -eq '' ) {
		Throw ( $Script:MsgModuleFtp.ErrFtpType )
	}

	# --- Vérifie si la variable FtpUrl est défini
	If ( $Script:FtpUrl -eq '' ) {
		Throw ( $Script:MsgModuleFtp.ErrFtpUrl )
	}

	# --- Vérifie si la variable FtpUser est défini
	If ( $Script:FtpUser -eq '' ) {
		Throw ( $Script:MsgModuleFtp.ErrFtpUser )
	}

	# --- Vérifie si le module Log est démarré
	If ( -not ( Get-ModuleLogValue ) ) {
		Throw ( $Script:MsgModuleFtp.ErrModuleLogInit )
	}

	# --- Vérifie si des variables FtpPath ont été défini
	If ( $Script:FtpPath.Count -eq 0 ) {
		Throw ( $Script:MsgModuleFtp.ErrFtpPath )
	}

	# --- Vérifie s'il y a des variables FtpPath LocalPath en double
	$Compare = Compare-object –referenceobject ($Script:FtpPath.LocalPath | Select-Object -Unique) –differenceobject $Script:FtpPath.LocalPath
	If ( [Bool]$Compare ) {
		$Compare =$Compare.InputObject | Group-Object
		Throw ( $Script:MsgModuleFtp.ErrFtpPathDouble -f 'LocalPath', $Compare.Name )
	}

	# --- Vérifie s'il y a des variables FtpPath DistantPath en double
	$Compare = Compare-object –referenceobject ($Script:FtpPath.DistantPath | Select-Object -Unique) –differenceobject $Script:FtpPath.DistantPath
	If ( [Bool]$Compare ) {
		$Compare =$Compare.InputObject | Group-Object
		Throw ( $Script:MsgModuleFtp.ErrFtpPathDouble -f 'DistantPath', $Compare.Name )
	}

	# --- Vérifie s'il y a des variables FtpPath Name en double
	$Compare = Compare-object –referenceobject ($Script:FtpPath.Name | Select-Object -Unique) –differenceobject $Script:FtpPath.Name
	If ( [Bool]$Compare ) {
		$Compare =$Compare.InputObject | Group-Object
		Throw ( $Script:MsgModuleFtp.ErrFtpPathDouble -f 'Name', $Compare.Name )
	}

	# --- Vérifie si répertoire /librairie/between est présent
	$Script:PathBetween = Assert-PathName -Path "$Script:PathLibraries/between"
	If ( -not ( Test-Path -Path $Script:PathBetween -PathType Container ) ) {
		Throw ( $Script:MsgModuleFtp.ErrPathBetween -f $Script:PathLibraries )
	}

	# --- Vérifie si répertoire /scripts/etc est présent
	$Path = Assert-PathName -Path "$Script:PathScripts/etc"
	If ( -not ( Test-Path -Path $Path -PathType Container ) ) {
		Throw ( $Script:MsgModuleFtp.ErrScriptsEtc )
	}

	Try {
		# --- Vérifie si le port du Ftp est ouvert
		Assert-PortFtp

		# --- Déclare la variable CmdLftpConnector
		Set-FtpConnector

		# --- Vérifie si les variables des libraries sont correct
		Set-Variable -Scope 'Script' -Name 'PathLibrariesConf' -Value "$($Path)Libraries.conf"
		Assert-Libraries
	}
	Catch {
		Throw ( ( ( $_.ScriptStackTrace -split '\r?\n' )[0] -replace '\<ScriptBlock\>\,\s','' ) + '£' + $_.Exception.Message )
	}

	Set-Variable -Scope 'Script' -Name 'SwtModuleFtp' -Value $true
}

Function Optimize-FtpDirectories {
<#
.SYNOPSIS
Optimise les répertoires par les divers filtres.

.DESCRIPTION
Supprime les fichiers par le Filtre Remove,
Supprime les répertoires vides.
#>

	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$true,
		ValueFromPipeline=$false)]
		[Alias("Fichiers")]
			[Object[]]$Result
	)

	[Object[]]$FiltreRemove = Get-FiltreRemoveValues
	If ( $FiltreRemove.Count -ne 0 ) {
		$RemoveFilter = [String]::Join( "|", $FiltreRemove.Regex )
		# --- Recherche des fichiers a purger
		$RemoveFiles = $Result | Where-Object { $_.File.Name -match $RemoveFilter }

		# --- Purger les fichiers filtré
		If ( $RemoveFiles ) {
			$Command = $RemoveFiles.File | ForEach-Object {
				Write-Log -Value ($Script:MsgModuleFtp.NfoOptDistRm -f $_.FullName)
				"rm '$($_.FullName)'"
			}
			Try {
				Start-FtpCommands -Command $Command
			}
			Catch {
				Throw ( ( ( $_.ScriptStackTrace -split '\r?\n' )[0] -replace '\<ScriptBlock\>\,\s','' ) + '£' + $_.Exception.Message )
			}

			$Result = $Result | Where-Object { $_.File.Name -notmatch $RemoveFilter }
		}
	}

	# --- Recherche des répértoire vide a purger
	$RemoveDirs = $Result.File | Where-Object { $_.PSIsContainer -and ($Result.File | Where-Object { -not $_.PSIsContainer }).Path -notcontains $_.FullName } | ForEach-Object {
		$DirectoryToDel = $true
		$Directory = $_
		$Result.File | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
			If ( $_.Path -match "^$($Directory.FullName)$Script:ChrSeparateur*" ) {
				$DirectoryToDel = $false
			}
		}
		If ( $DirectoryToDel ) {
			$Directory
		}
	} | Sort-Object -Property FullName -Descending

	# --- Purger les répertoires vides
	If ( $RemoveDirs ) {
		$Command = $RemoveDirs | ForEach-Object {
			Write-Log -Value ($Script:MsgModuleFtp.NfoOptDistRm -f $_.FullName)
			$TmpPath = $_.FullName -replace "'", "\'"
			"rmdir '$TmpPath'"
		}
		Try {
			Start-FtpCommands -Command $Command
		}
		Catch {
			Throw ( ( ( $_.ScriptStackTrace -split '\r?\n' )[0] -replace '\<ScriptBlock\>\,\s','' ) + '£' + $_.Exception.Message )
		}

		$Result = $Result | Where-Object { $RemoveDirs -notcontains $_.File }
	}

	Return $Result
}

Function Set-FtpCommands {
<#
.SYNOPSIS
Prépare la chaine de variables.

.DESCRIPTION
Traitement de la chaine pour la rendre compatible avec LFtp.

.PARAMETER Command
Commande(s) a inserrer entre les commandes standard de connexion.
#>

	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$true,
		ValueFromPipeline=$false)]
		[Alias("Commandes")]
			[String[]]$Command
	)

	# --- Prépare la chaine de variables
	$Delimiter = ";"
	$TmpCommand = $Script:CmdLftpSet
	$TmpCommand += $Command
	$TmpCommand += $Script:CmdLftpQuit

	# --- Traitement de la chaine pour la rendre compatible avec LFtp
	$TmpCommand = [String]::Join($Delimiter, $TmpCommand)

	# --- Ajoute des doubles guillemets si la commande n'est pas entouré avec
	If ($TmpCommand -notmatch '^\"') {
		$TmpCommand = '"' + $TmpCommand
	}
	If ($TmpCommand -notmatch '\"$') {
		$TmpCommand += '"'
	}

	# --- Retour de la ligne de commandes
	Return $TmpCommand
}

Function Set-FtpConnector {
<#
.SYNOPSIS
Compile les variables pour donner une chaine de connexion LFtp

.DESCRIPTION
Compile les variables pour donner une chaine de connexion LFtp
#>

	If ( $Script:CmdLftpConnect -eq '' ) {
		Throw ( $Script:MsgModuleFtp.ErrFtpConnector1 )
	}
	$Script:CmdLftpConnector = $Script:CmdLftpConnect
	$Delimiter = '\£'
	$Search = $Delimiter + "\w+" + $Delimiter
	[Regex]::Matches( $Script:CmdLftpConnector, $Search ) | ForEach-Object {
		$SubSearch = $_.Value
		$Name = $SubSearch -replace $Delimiter,''
		Try {
			$MyVar = ( Get-Variable -Scope 'Script' -Name $Name -ErrorAction Stop ).Value
		}
		Catch {
			Throw ( $Script:MsgModuleFtp.ErrFtpConnector2 -f $Name )
		}
		$Script:CmdLftpConnector = $Script:CmdLftpConnector -replace $SubSearch, $Myvar
	}
}

Function Set-FtpPasswordValue {
<#
.SYNOPSIS
Définie la valeur du mot de passe pour l'accès au Ftp.

.DESCRIPTION
Permet d'établir la variable FtpPassword qui définie
le mot de passe utilisé pour le Ftp.

.PARAMETER Value
Valeur pour la définition de la variable FtpPassword

.INPUTS
La valeur ne peux pas être passé par le pipeline

.EXAMPLE
PS>Set-FtpPasswordValue -Value "MonMotDePasse"
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false,
		ValueFromPipeline=$false)]
			[String]$Value
	)
	Set-Variable -Scope 'Script' -Name 'FtpPassword' -Value $Value
}

Function Set-FtpPortValue {
<#
.SYNOPSIS
Définie la valeur du port pour l'accès au Ftp.

.DESCRIPTION
Permet d'établir la variable FtpPort qui définie
le port utilisé pour le Ftp.

.PARAMETER Value
Valeur pour la définition de la variable FtpPort

.INPUTS
La valeur ne peux pas être passé par le pipeline

.EXAMPLE
PS>Set-FtpPortValue -Value "22"
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false,
		ValueFromPipeline=$false)]
			[String]$Value
	)
	Set-Variable -Scope 'Script' -Name 'FtpPort' -Value $Value
}

Function Set-FtpTypeValue {
<#
.SYNOPSIS
Définie le type de connexion pour l'accès au Ftp.

.DESCRIPTION
Permet d'établir la variable FtpType qui définie
le type d'accès à utiliser pour le Ftp.
ftp ou sftp

.PARAMETER Value
Valeur pour la définition de la variable FtpType

.INPUTS
La valeur ne peux pas être passé par le pipeline

.EXAMPLE
PS>Set-FtpTypeValue -Value "sftp"
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false,
		ValueFromPipeline=$false)]
			[String]$Value
	)
	Set-Variable -Scope 'Script' -Name 'FtpType' -Value $Value
}

Function Set-FtpUrlValue {
<#
.SYNOPSIS
Définie l'url de connexion pour l'accès au Ftp.

.DESCRIPTION
Permet d'établir la variable FtpUrl qui définie
l'url à utiliser pour le Ftp.

.PARAMETER Value
Valeur pour la définition de la variable FtpUrl

.INPUTS
La valeur ne peux pas être passé par le pipeline

.EXAMPLE
PS>Set-FtpUrlValue -Value "84.83.82.81"

.EXAMPLE
PS>Set-FtpUrlValue -Value "mon.adresse.com"
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false,
		ValueFromPipeline=$false)]
			[String]$Value
	)
	Set-Variable -Scope 'Script' -Name 'FtpUrl' -Value $Value
}

Function Set-FtpUserValue {
<#
.SYNOPSIS
Définie l'url de connexion pour l'accès au Ftp.

.DESCRIPTION
Permet d'établir la variable FtpUser qui définie
l'url à utiliser pour le Ftp.

.PARAMETER Value
Valeur pour la définition de la variable FtpUser

.INPUTS
La valeur ne peux pas être passé par le pipeline

.EXAMPLE
PS>Set-FtpUserValue -Value "MonCompte"
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false,
		ValueFromPipeline=$false)]
			[String]$Value
	)
	Set-Variable -Scope 'Script' -Name 'FtpUser' -Value $Value
}

Function Start-FtpCommands {
<#
.SYNOPSIS
Exécution de la commande ftp complete.

.DESCRIPTION
Permet de lancer l'exécutable extérieure ftp avec les commandes passer en paramètre.

.PARAMETER Command
Commande(s) a passer dans le Ftp.

.PARAMETER Retour
Option si des valeurs doivent être retourné.

.PARAMETER Stream
Option si les valeurs doivent être dans le journal au fil de l'eau.
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true,
		ValueFromPipeline=$false)]
		[Alias("Commands", "Cmd")]
			[String[]]$Command,
		[Parameter(Mandatory=$false,
		ValueFromPipeline=$false)]
			[Switch]$Retour = $false,
		[Parameter(Mandatory=$false,
		ValueFromPipeline=$false)]
			[Switch]$Stream = $false
	)

	If ( ( -not $Script:SwtModuleFtp -and $Script:PathLibrariesConf -eq '' ) ) {
		Throw ( $Script:CronBoxCommunMsg.ErrModuleFtp -f $MyInvocation.MyCommand )
	}

	# --- Préparation des paramètres d'invocation
	[String]$Command = Set-FtpCommands -Command $Command
	$StartInfo = New-Object -TypeName System.Diagnostics.ProcessStartInfo -Property @{
		FileName = 'lftp'
		Arguments = "$($Script:CmdLftpConnector) -e $Command"
		UseShellExecute = $false
		RedirectStandardOutput = $true
		RedirectStandardError = $true
		CreateNoWindow = $true
	}

	# --- Creation  & assignation nouveau process
	$Process = New-Object System.Diagnostics.Process
	$Process.StartInfo = $StartInfo

	# --- Inscription des actions par événements
	$ScriptCmd = {
		If ( -not [String]::IsNullOrEmpty($EventArgs.Data)) {
			$Event.MessageData.AppendLine($EventArgs.Data)
		}
	}

	If ( $Retour ) {
		$StdOutBuilder = New-Object -TypeName System.Text.StringBuilder
		$StdOutEvent = Register-ObjectEvent -InputObject $Process -Action $ScriptCmd -EventName 'OutputDataReceived' -MessageData $StdOutBuilder
	}

	If ( $Stream ) {
		$ScriptStream = {
			If ( -not [String]::IsNullOrEmpty($EventArgs.Data)) {
				Write-Log -Value $Event.SourceEventArgs.Data
			}
		}
		$StdStmEvent = Register-ObjectEvent -InputObject $Process -Action $ScriptStream -EventName 'OutputDataReceived'
	}
	
	$StdErrBuilder = New-Object -TypeName System.Text.StringBuilder
	$StdErrEvent = Register-ObjectEvent -InputObject $Process -Action $ScriptCmd -EventName 'ErrorDataReceived' -MessageData $StdErrBuilder

	# --- Démarrage du process et des lectures asynchrones des flux
	[Void]$Process.Start()
	$Process.BeginOutputReadLine()
	$Process.BeginErrorReadLine()

	# --- Boucle d'attente de sortie
	Do {
		Start-Sleep -Seconds 1
	} While ( -not $Process.HasExited )

	# --- Exclusion des actions par événements
	If ( $Retour ) {
		Unregister-Event -SourceIdentifier $StdOutEvent.Name
	}
	If ( $Stream ) {
		Unregister-Event -SourceIdentifier $StdStmEvent.Name
	}
	Unregister-Event -SourceIdentifier $StdErrEvent.Name

	# --- Gestion si sortie en erreur
	If ( $Process.ExitCode -ne 0 ) {
		Throw ( $Script:MsgModuleFtp.ErrFtpCommands -f $StdErrBuilder )
	}

	# --- Gestion si sortie en erreur
	If ( $Retour ) {
		[Object[]]$Out = $StdOutBuilder -split '\r?\n' | Where-Object { $_ }
		Return $Out
	}
}

Function Sync-FtpToLocal {
<#
.SYNOPSIS
Synopsis de synchronisation des répertoires distants vers les locaux.

.DESCRIPTION
Scénario des différents traitements pour la récupération du contenu des librairies distantes.
#>
	# --- Recherche le contenu des librairies distantes
	Try {
		$Result = Initialize-FtpToLocal
		If ( $Result ) {
			# --- Supprime les fichiers par filtre et les répertoires vides
			$Result = Optimize-FtpDirectories -Result $Result
	
			# --- Traitement de chaque librairies restant après Optimize-FtpDirectories
			$Script:FtpPath | Where-Object { ( $Result.DistantPath | Select-Object -Unique ) -contains $_.DistantPath }  | ForEach-Object {
				$From = $_.DistantPath
				$To = Assert-PathName -Path "$($Script:PathBetween)/$($_.Name)"
				New-Directory -Path $To
				Write-Log -Value ( $Script:MsgModuleFtp.NfoFtpToLocal -f $From, $To )
				$Command = $Script:CmdLftpMirror
				$Delimiter = '\£'
				$Search = $Delimiter + "\w+" + $Delimiter
				[Regex]::Matches( $Command, $Search ) | ForEach-Object {
					$SubSearch = $_.Value
					$Name = $SubSearch -replace $Delimiter,''
					$MyVar = ( Get-Variable -Name $Name -ErrorAction SilentlyContinue ).Value
					If ( -not $MyVar ) {
						Throw ( $Script:MsgModuleFtp.NfoFtpToLocal -f $Name )
					}
					$Command = $Command -replace $SubSearch, $Myvar
				}
				Start-FtpCommands -Command $Command -Stream
				Optimize-Directories -Path $To
			}
		} Else {
			Write-Log -Value $Script:MsgModuleFtp.NfoFtpToLocal2
			Optimize-Directories -Path $Script:PathBetween -Purge
		}
	}
	Catch {
		Throw ( ( ( $_.ScriptStackTrace -split '\r?\n' )[0] -replace '\<ScriptBlock\>\,\s','' ) + '£' + $_.Exception.Message )
	}
}

Function Test-FtpPath {
<#
.SYNOPSIS
Vérifie l'existance d'un répertoire distant.

.DESCRIPTION
Liste, depuis le répertoire parent, les sous-répertoires et compare avec celui demandé.

.PARAMETER Path
Chemin vers le répertoire à tester.
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false,
		ValueFromPipeline=$false)]
		[Alias("Chemin")]
			[String]$Path
	)

	Write-Log -Value ( $Script:MsgModuleFtp.ChkFtpPath -f $Path )
	Try {
		$Parent = Assert-PathName -Path (Split-Path -Path $Path -ErrorAction Stop )
		$Leaf = Split-Path -Path $Path -Leaf
	}
	Catch {
		$Parent = '/'
	}
# TODO : Vérif comportement si Parent déjà / donc leaf et résultat ?
	Try {
		If ( -not [Bool]( $Script:FtpObjects | Where-Object { $_.Name -like $Leaf -and $_.PSIsContainer -eq $true -and $Path -match $_.FullName } ) ) {
			[Object[]]$Out = Get-FtpChildItem -Path $Parent
			$Out | ForEach-Object {
				If ( -not ( $Script:FtpObjects.FullName -contains $_.FullName -and $Script:FtpObjects.PSIsContainer -contains $_.PSIsContainer ) ) {
					$Script:FtpObjects += $_
				}
			}
			Return [Bool]( $Script:FtpObjects | Where-Object { $_.Name -like $Leaf -and $_.PSIsContainer -eq $true -and $Path -match $_.FullName } )
		}
	}
	Catch {
		Throw ( ( ( $_.ScriptStackTrace -split '\r?\n' )[0] -replace '\<ScriptBlock\>\,\s','' ) + '£' + $_.Exception.Message )
	}
	Return $true
}
