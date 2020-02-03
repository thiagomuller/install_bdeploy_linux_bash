#!/bin/bash

installationKind=-1
username=''
password=''
passHostname=-1
userDefinedHostname=''

read_instalation_kind_from_user()
{
	echo Wellcome to the BDeploy installer
	echo Which option would you like to use:
	echo 1 - Install BDeploy as Master
	echo 2 - Install Bdeploy as Slave
	echo 3 - Register a Slave on a Master node
	echo 4 - Uninstall all bdeploy stuff from this machine
	read installationKind	
}

create_necessary_directories()
{
        echo Creating necessary directories for bdeploy installation
        cd /
        mkdir /BDeploy
        mkdir /BDEPLOY_TOKENFILE
        touch /BDEPLOY_TOKENFILE/token.txt
        echo Created necessary directories
}

install_necessary_packages()
{
        echo Installing necessary packages for bdeploy installation
        yum install wget zip unzip net-tools vim -y
        echo Installed necessary packages

}


download_bdeploy_from_web()
{
        echo Downloading bdeploy from the web
        cd /BDeploy
        wget https://github.com/bdeployteam/bdeploy/releases/download/v1.3.1/bdeploy-linux64-1.3.1.zip
        bdeploy_zip_file=/BDeploy/bdeploy-linux64-1.3.1.zip
	while [ ! -f "$bdeploy_zip_file"  ]
	do
		sleep 10
	done
	unzip bdeploy-linux64-1.3.1.zip
	rm -f bdeploy-linux64-1.3.1.zip

}

create_environment_variables()
{
	cd /
	export BDEPLOY_ROOT=/BDEPLOY_ROOT/
	export BDEPLOY_REMOTE=https://$(hostname):7701/api
	export BDEPLOY_TOKENFILE=/BDEPLOY_TOKENFILE/token.txt
	export PATH=$PATH:/BDeploy/bdeploy-linux64-1.3.1/bin/
	echo '#BDeploy System Variables' >> /etc/bashrc
	echo export BDEPLOY_ROOT=/BDEPLOY_ROOT/ >> /etc/bashrc
	echo export BDEPLOY_REMOTE=https://$(hostname):7701/api >> /etc/bashrc
	echo export BDEPLOY_TOKENFILE=/BDEPLOY_TOKENFILE/token.txt >> /etc/bashrc
	echo export PATH=$PATH:/BDeploy/bdeploy-linux64-1.3.1/bin/ >> /etc/bashrc
	source /etc/bashrc
}

delete_bdeploy_root_directory_if_exists()
{
	if [ -d "$BDEPLOY_ROOT" ]
	then
		rm -R --force /BDEPLOY_ROOT/
	fi
}

init_bdeploy_master_node()
{
	delete_bdeploy_root_directory_if_exists
	cd /
	bdeploy init --root=$BDEPLOY_ROOT --hostname=$(hostname) --tokenFile=$BDEPLOY_TOKENFILE
}

create_username_and_password_for_bdeploy()
{
	bdeploy user --add=$username --password=$password
}

get_username_and_password_from_user()
{
	echo What will be the username set on this bdeploy installation?
	read username
	echo What will be the password set on this bdeploy installation?
	read password
}

verify_if_user_wants_to_set_hostname()
{
	echo Do you want to use the hostname set on this machine, or do you want to pass the hostname manually?
	echo 1 - Use machine hostname
	echo 2 - Pass the hostname
	read passHostname
	if [ $passHostname -eq 2 ]
	then
		echo Please type the desired hostname
		read userDefinedHostname
		sed -i 's/$(hostname)/$hostname/' /etc/hostname
	fi
}

remove_all_bdeploy_directories()
{
	rm -R --force /BDEPLOY_ROOT
	rm -R --force /BDEPLOY_TOKENFILE
	rm -R --force /BDeploy/	
}

remove_bdeploy_entries_from_bashrc()
{
	sed -i '/#BDeploy System Variables/d' /etc/bashrc
	sed -i '/export BDEPLOY_/d' /etc/bashrc
	sed -i '/export PATH=/d' /etc/bashrc
}

open_bdeploy_ports_on_firewall()
{
	echo Opening ports for bdeploy on firewall
	firewall-cmd --permanent --zone=public --add-port=22/tcp > /dev/null 2>&1
	firewall-cmd --permanent --zone=public --add-port=1305/tcp > /dev/null 2>&1
	firewall-cmd --permanent --zone=public --add-port=1433/tcp > /dev/null 2>&1
	firewall-cmd --permanent --zone=public --add-port=4851/tcp > /dev/null 2>&1
	firewall-cmd --permanent --zone=public --add-port=5500/tcp > /dev/null 2>&1
	firewall-cmd --permanent --zone=public --add-port=8080/tcp > /dev/null 2>&1
	firewall-cmd --permanent --zone=public --add-port=8081/tcp > /dev/null 2>&1
	firewall-cmd --permanent --zone=public --add-port=8088/tcp > /dev/null 2>&1
	firewall-cmd --permanent --zone=public --add-port=8890/tcp > /dev/null 2>&1
	firewall-cmd --permanent --zone=public --add-port=9000/tcp > /dev/null 2>&1
	firewall-cmd --permanent --zone=public --add-port=9337/tcp > /dev/null 2>&1
	firewall-cmd --permanent --zone=public --add-port=9999/tcp > /dev/null 2>&1
	firewall-cmd --permanent --zone=public --add-port=21099/tcp > /dev/null 2>&1
	firewall-cmd --permanent --zone=public --add-port=21100/tcp > /dev/null 2>&1
	firewall-cmd --permanent --zone=public --add-port=21200/tcp > /dev/null 2>&1
	firewall-cmd --permanent --zone=public --add-port=22223/tcp > /dev/null 2>&1
	firewall-cmd --permanent --zone=public --add-port=22400-22649/tcp > /dev/null 2>&1
	firewall-cmd --permanent --zone=public --add-port=28222/tcp > /dev/null 2>&1
	firewall-cmd --permanent --zone=public --add-port=28223/tcp > /dev/null 2>&1
	firewall-cmd --permanent --zone=public --add-port=61616/tcp > /dev/null 2>&1
	firewall-cmd --permanent --zone=public --add-port=4679/tcp > /dev/null 2>&1
	firewall-cmd --permanent --zone=public --add-port=631/tcp > /dev/null 2>&1
	firewall-cmd --permanent --zone=public --add-port=3000/tcp > /dev/null 2>&1
	firewall-cmd --permanent --zone=public --add-port=5432/tcp > /dev/null 2>&1
	firewall-cmd --permanent --zone=public --add-port=1521/tcp > /dev/null 2>&1
	firewall-cmd --permanent --zone=public --add-port=7701/tcp > /dev/null 2>&1
	firewall-cmd --reload

}

modify_bdeploy_service_file()
{
	nodeType=$1
	if [ $nodeType == "master" ]
	then
		sed -i 's/APPLICATION_USER/root/' /BDeploy/bdeploy-linux64-1.3.1/etc/bdeploy-minion.service
		sed -i 's/\[Master|Slave\]/Master/' /BDeploy/bdeploy-linux64-1.3.1/etc/bdeploy-minion.service
		sed -i 's/\[master|slave\]/master/' /BDeploy/bdeploy-linux64-1.3.1/etc/bdeploy-minion.service
	 	sed -i 's/opt\/bdeploy\/master\/bin\/bdeploy/BDeploy\/bdeploy-linux64-1.3.1\/bin\/bdeploy/' /BDeploy/bdeploy-linux64-1.3.1/etc/bdeploy-minion.service
	 	sed -i 's/--root=\/opt\/bdeploy\/data/--root=\/BDEPLOY_ROOT/' /BDeploy/bdeploy-linux64-1.3.1/etc/bdeploy-minion.service
	fi
	if [ $nodeType == "slave" ]
	then
		sed -i 's/APPLICATION_USER/root/' /BDeploy/bdeploy-linux64-1.3.1/etc/bdeploy-minion.service
	 	sed -i 's/\[Master|Slave\]/Slave' /BDeploy/bdeploy-linux64-1.3.1/etc/bdeploy-minion.service
		sed -i 's/\[master|slave\]/slave' /BDeploy/bdeploy-linux64-1.3.1/etc/bdeploy-minion.service
	 	sed -i 's/opt\/bdeploy\/master\/bin\/bdeploy/BDeploy\/bdeploy-linux64-1.3.1\/bin\/bdeploy/' /BDeploy/bdeploy-linux64-1.3.1/etc/bdeploy-minion.service
	 	sed -i 's/--root=\/opt\/bdeploy\/data/--root=\/BDEPLOY_ROOT/' /BDeploy/bdeploy-linux64-1.3.1/etc/bdeploy-minion.service
	fi 	
}

copy_bdeploy_service_file_to_system()
{
	cp /BDeploy/bdeploy-linux64-1.3.1/etc/bdeploy-minion.service /etc/systemd/system/
}

enable_and_start_bdeploy_service()
{
	sudo systemctl enable bdeploy-minion.service
	sudo systemctl start bdeploy-minion.service
}

read_instalation_kind_from_user
if [ $installationKind -eq 1 ]  
then	
	verify_if_user_wants_to_set_hostname
	create_necessary_directories
	install_necessary_packages
	download_bdeploy_from_web
	create_environment_variables
	init_bdeploy_master_node
	get_username_and_password_from_user
	create_username_and_password_for_bdeploy
	open_bdeploy_ports_on_firewall
	modify_bdeploy_service_file master
	copy_bdeploy_service_file_to_system
	enable_and_start_bdeploy_service
fi

if [ $installationKind -eq 4 ]
then
	remove_all_bdeploy_directories
	remove_bdeploy_entries_from_bashrc
	sudo reboot
fi	
