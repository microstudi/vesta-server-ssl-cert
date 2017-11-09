#!/bin/bash
# info: check SSL certificates
# options: NONE
#
# The script checks for new LetsEncrypt certificates in /home/admin/conf/web/ssl.[SERVER-FQDN].*
# and it installs the new certificates for all services before restarting them.
#
# This script works for Ubuntu 16.04

# Notification email parameters
hostname=$(hostname -f)
# If you want to force the hostname (my case):
# hostname=yourhostname.tld
mailto='CHANGE THIS TO YOUR EMAIL ADDRESS'
mailsub="Server SSL Renewal: ${hostname}"

# Set the paths of SSL certificates to check
path2le=/home/admin/conf/web
path2ve=/usr/local/vesta/ssl

# Certificates to check
LEcrt="${path2le}/ssl.${hostname}.crt"
LEkey="${path2le}/ssl.${hostname}.key"
LEca="${path2le}/ssl.${hostname}.ca"
VEcrt="${path2ve}/certificate.crt"
VEkey="${path2ve}/certificate.key"
temp=$(tempfile)
cat $LEcrt > $temp
cat $LEca >> $temp

# Compare current certificate with auto generated ones from LetsEncrypt
if ! cmp --silent $temp $VEcrt
then
	echo CERTIFICATES DIFFERENT - UPDATING
	# Copy certificates
	cp --backup $temp $VEcrt
	cp --backup $LEkey $VEkey

	# Set correct owner and permissions for certificates
	chown root:mail $VEcrt $VEkey
	chmod 640 $VEcrt $VEkey

	systemctl restart vesta exim4 dovecot vsftpd

	# Notify
	which mail > /dev/null 2>&1 && echo "The server certificate at "$(hostname -f)" has been r
enewed successfully :)" | mail -s "$mailsub" "$mailto"
fi

rm $temp
