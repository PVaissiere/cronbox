#!/bin/bash
# @(#)--------------------------------------------------------------------------
# @(#)Shell		: /bin/bash
# @(#)Auteur		: PVaissiere
# @(#)Nom		: init.sh
# @(#)Date		: 2021/04/18
# @(#)Version		: 0.5.4
# @(#)
# @(#)Resume		: Script d'initialisation du pod
# @(#)--------------------------------------------------------------------------

echo '# ------------------------------------------------------------------------------'
echo '# --- Initialisation du POD'
echo '# ------------------------------------------------------------------------------'

echo '# --- Déclaration des variables pour les jobs CRON'
declare -p | grep -vP '\s-+.{0,1}r+.*\s' > /container.env

echo '# --- Lancement du service CRON'
cron

EtcPath="${CRONSCRIPTS}etc/"
if [ -d $LibrariesFile ]
then
	Librariesconf="${EtcPath}Libraries.conf"
	if [ -f $Librariesconf ]
	then
		echo '# --- Supression du fichier des librairies'
		rm $Librariesconf
	fi
	if [ -d /cronbox/ ]
	then
		echo '# --- Mode débug activé'
		if [ ! -d /cronbox/etc ]
		then
			echo "# --- Debug : Ajout lien symbolique vers ${EtcPath}"
			ln -s ${EtcPath} /cronbox/etc
			
		fi
	fi
fi

# --- Supression des anciens fichiers cron-*.lck
if [ -d $CRONLOGS ]
then
	find $CRONLOGS -name "cron-*.lck" -exec rm {} \;
fi

echo '# --- Finalisation : Lancement Bash'
echo '# ------------------------------------------------------------------------------'
/bin/bash
