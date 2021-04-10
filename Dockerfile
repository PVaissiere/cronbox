# @(#)Auteur		: PVaissiere
# @(#)Nom		: Dockerfile
# @(#)Date		: 2021/04/05
# @(#)Version		: 0.4.6

# Définition de l'image de base
FROM debian:latest

# Mise à jour de l'image
RUN apt-get update \
&& apt-get upgrade -y \
&& apt-get install -y apt-utils

# Installation des applications tierce
RUN apt-get install -y cron lftp wget

# Configuration de la tâche cron
COPY /cron/cronbox /etc/cron.d/cronbox
RUN chmod 0644 /etc/cron.d/cronbox \
&& crontab /etc/cron.d/cronbox

# Variables d'environnement
ENV CRONSCRIPTS=/scripts/ \
	CRONLOGS=/logs \
	CRONLIBRARIES=/libraries

ENV PATH=$PATH:$CRONSCRIPTS

# Préparation des répertoires pour les volumes
RUN mkdir -p $CRONSCRIPTS $CRONLOGS $CRONLIBRARIES

# Copie des scripts et déclaration des volumes
COPY $CRONSCRIPTS $CRONSCRIPTS
RUN chmod -R 775 $CRONSCRIPTS $CRONLOGS $CRONLIBRARIES
VOLUME $CRONLOGS $CRONSCRIPTS/etc $CRONLIBRARIES/between

# DEBUG : Préparation des commandes alias et Installation des applications
RUN sed -i 's/# export LS_OPTIONS=/export LS_OPTIONS=/g' /root/.bashrc \
# && sed -i 's/# eval "/eval "/g' /root/.bashrc \
&& sed -i 's/# alias ls=/alias ls=/g' /root/.bashrc \
&& sed -i 's/# alias ll=/alias ll=/g' /root/.bashrc \
&& apt-get install -y nano procps

# Modification timezone Europe/Paris
RUN rm /etc/localtime \
&& ln -s /usr/share/zoneinfo/Europe/Paris /etc/localtime \
&& echo Europe/Paris > /etc/timezone 

# Installation Microsoft Powershell
RUN wget -P /tmp https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb \
&& dpkg -i /tmp/packages-microsoft-prod.deb \
&& apt-get update \
&& apt-get install -y powershell \
&& rm /tmp/packages-microsoft-prod.deb

# Demarrage du conteneur
CMD ["/bin/bash","-c","${CRONSCRIPTS}init.sh"]
