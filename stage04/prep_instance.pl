#!/usr/bin/perl

my $distro = "UBUNTU";
my $distro_ver = "LUCID";
my $arch = "64";
my $source = "BZR";

if( @ARGV > 1 ){
	$distro = uc(shift @ARGV);
	$distro_ver = uc(shift @ARGV);
	$arch = shift @ARGV;
	$source = uc(shift @ARGV);
};

print "\n";
print "DISTRO\t$distro\n";
print "DISTRO_VER\t$distro_ver\n";
print "ARCH\t$arch\n";
print "SOURCE\t$source\n";
print "\n";


### temp add to help locate qa-server
print "echo \"192.168.51.150 qa-server\" >> /etc/hosts";
system("echo \"192.168.51.150 qa-server\" >> /etc/hosts");
print "\n";

###
###
###
print "Adjusting REPO\n";

if( $distro eq "UBUNTU" ){
	print "Adjusting /etc/apt/sources.list\n";
	my $from = "us.archive.ubuntu.com";
	my $to = "mirror.eucalyptus";
	my $file = "/etc/apt/sources.list";
	my_sed( $from, $to, $file);
	$from = "archive.ubuntu.com";
	$to = "mirror.eucalyptus";
	my_sed( $from, $to, $file);
	system("cat $file");
	print "\n";
}elsif( $distro eq "CENTOS" ) {
	print "Adjusting /etc/yum.repo.d\n";
	my $from = "mirrorlist=";
	my $to = "#mirrorlist=";
	my $file = "/etc/yum.repos.d/CentOS-Base.repo";
	my_sed( $from, $to, $file);
	$from = "#baseurl=";
	$to = "baseurl=";
	my_sed( $from, $to, $file);
	$from = "mirror.centos.org";
	$to = "mirror.eucalyptus";
	my_sed( $from, $to, $file);
	system("cat $file");
	print "\n";	
}elsif( $distro eq "RHEL" ) {
	print "RHEL Registration\n";
	pre_ops_download_rhel_regist_scripts();
	sleep(5);
	pre_ops_rhel_register_image();
};


###
###
###
print "Updating the System\n";

if( $distro eq "UBUNTU" ){
	print("apt-get -y update\n");
	system("apt-get -y update");
}elsif( $distro eq "CENTOS" || $distro eq "RHEL" ) {
	print("yum -y update\n");
	system("yum -y update");
};


###
###
###
print "Adjusting /etc/localtime\n";

if( $distro eq "UBUNTU" ){

	print "ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime\n";
	system("ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime");

	print "Installing ntp\n";
	print("apt-get -y install ntpdate ntp\n");
	system("apt-get -y install ntpdate ntp");

	print "Adjusting Time\n";
	print "/etc/init.d/ntp stop\n";
	system("/etc/init.d/ntp stop");

	print "ntpdate pool.ntp.org\n";
	system("ntpdate pool.ntp.org");

	print "/etc/init.d/ntp start\n";
	system("/etc/init.d/ntp start");

}elsif( $distro eq "CENTOS" || $distro eq "RHEL" ) {

	print "Adjusting /etc/localtime\n";
	print "ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime\n";
	system("ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime");

	print "Installing ntp\n";
	print("yum -y install ntp\n");
	system("yum -y install ntp");

	print "Adjusting Time\n";
	print "ntpdate pool.ntp.org\n";
	system("ntpdate pool.ntp.org");

	print "/etc/init.d/ntpd start\n";
	system("/etc/init.d/ntpd start");
};

###
###
###
print "Adjusting Locales\n";

if( $distro eq "UBUNTU" ){

	print("apt-get -y install locales\n");
	system("apt-get -y install locales");

	print "Reconfiguring Locales\n";

	print("export LANGUAGE=en_US.UTF-8\n");
	system("export LANGUAGE=en_US.UTF-8");
	$ENV{'LANGUAGE'} = "en_US.UTF-8";

	print("export LANG=en_US.UTF-8\n");
	system("export LANG=en_US.UTF-8");
	$ENV{'LANG'} = "en_US.UTF-8";

	print("export LC_ALL=en_US.UTF-8\n");
	system("export LC_ALL=en_US.UTF-8");
	$ENV{'LC_ALL'} = "en_US.UTF-8";

	print("locale-gen en_US.UTF-8\n");
	system("locale-gen en_US.UTF-8");

	print("dpkg-reconfigure locales\n");
	system("dpkg-reconfigure locales");
};

###
###
###
print "Installing a few packages\n";

if( $distro eq "UBUNTU" ){

	print "Installing zip\n";

	print("apt-get -y install zip\n");
	system("apt-get -y install zip");

	print "Installing wget\n";
	print("apt-get -y install wget\n");
	system("apt-get -y install wget");

}elsif( $distro eq "CENTOS" || $distro eq "RHEL" ) {

	print "Installing zip and unzip\n";
	
	print("yum -y install zip unzip\n");
	system("yum -y install zip unzip");

	print "Installing wget\n";
	print("yum -y install wget\n");
	system("yum -y install wget");

};

print "Downloading QA machine's id_rsa\n";
print("wget http://qa-server/kickstart/rsa/id_rsa\n");
system("wget http://qa-server/kickstart/rsa/id_rsa");

print "chmod 400 ./id_rsa\n";
system("chmod 400 ./id_rsa");

print "mv ./id_rsa /root/.ssh/.\n";
system("mv ./id_rsa /root/.ssh/.");


print "\n";

exit(0);

1;


##################################### SUBROUTINEs ###########################################


sub pre_ops_download_rhel_regist_scripts{

	system("mkdir -p  /root/rhel_regist_scripts");

	chdir("/root/rhel_regist_scripts");

	system("wget http://qa-server/4qa/4_rhel/rhn_register.sh");
	system("wget http://qa-server/4qa/4_rhel/rhn_register_6_0.sh");
	system("wget http://qa-server/4qa/4_rhel/rhn_childchannels.sh");
	system("wget http://qa-server/4qa/4_rhel/rhn_childchannels.py");
	system("wget http://qa-server/4qa/4_rhel/rhn_childchannels_5_5_i386.sh");
	system("wget http://qa-server/4qa/4_rhel/rhn_childchannels_5_5_i386.py");
	system("wget http://qa-server/4qa/4_rhel/rhn_deletesystem.sh");
	system("wget http://qa-server/4qa/4_rhel/rhn_deletesystem.py");

	system("chmod 755 rhn_*");

	chdir($ENV{'PWD'});

	return 0;
};


sub pre_ops_rhel_register_image{

        my $distro_ver = lc($ENV{'QA_DISTRO_VER'});
	my $arch = $ENV{'QA_ARCH'};

	chdir("/root/rhel_regist_scripts");
	
	print "\nRegistering RHEL image to RHN\n";
	
	if( $distro_ver eq "5.5" ){
		system("./rhn_register.sh");
	}else{
		system("./rhn_register_6_0.sh");
	};

	sleep(10);

	if( $distro_ver eq "5.5" ){
		if( $arch eq "64" ){
			system("./rhn_childchannels.sh");
		}else{
			system("./rhn_childchannels_5_5_i386.sh");
		};
	}else{
		### NO OP
	};

	chdir($ENV{'PWD'});

	return 0;
};



sub pre_ops_rhel_de_register_image{

	chdir("/root/rhel_regist_scripts");
	
	print "\nDe-Registering RHEL image to RHN\n";
	system("./rhn_deletesystem.sh");

	chdir($ENV{'PWD'});

	return 0;

};


sub create_extra_repo{
	my ($name, $url) = @_;
	my $distro = $ENV{'QA_DISTRO'};
	my $distro_ver = lc($ENV{'QA_DISTRO_VER'});

	$url =~ s/\$/\\\$/g;

	if( $distro eq "CENTOS" || $distro eq "FEDORA" || $distro eq "RHEL" ){
		my $repo_file = "/etc/yum.repos.d/" . $name . ".repo";
		run_cmd("(echo \"[$name]\" >> $repo_file)");
		run_cmd("(echo \"name=Extra Repo - $name\" >> $repo_file)");
		run_cmd("(echo \"baseurl=$url\" >> $repo_file)");
		run_cmd("(echo \"enabled=1\" >> $repo_file)");
		run_cmd("(echo \"gpgcheck=0\" >> $repo_file)");
		run_cmd("yum -y update");
	}elsif( $distro eq "OPENSUSE" ){
		run_cmd("zypper ar --refresh $url $name");
		run_cmd("zypper --no-gpg-checks refresh $name");
		run_cmd("zypper -n update");
	}elsif( $distro eq "UBUNTU" ){
		run_cmd("( echo deb $url $distro_ver universe >> /etc/apt/sources.list )");
		run_cmd("apt-get -y update");
	}elsif( $distro eq "DEBIAN" ){
		run_cmd("( echo deb $url $distro_ver main >> /etc/apt/sources.list )");
		run_cmd("apt-get -y update");
	};

	return 0;
};



# To make 'sed' command human-readable
# my_sed( target_text, new_text, filename);
#   --->
#        sed --in-place 's/ <target_text> / <new_text> /' <filename>
sub my_sed{

        my ($from, $to, $file) = @_;

        $from =~ s/([\'\"\/])/\\$1/g;
        $to =~ s/([\'\"\/])/\\$1/g;

        my $cmd = "sed --in-place 's/" . $from . "/" . $to . "/' " . $file;

        system($cmd);

        return 0;
};

1;
