#!/usr/bin/perl

use strict;

print "\nRunning Script install_euca2ools_from_repo_on_vm.pl\n";
print "\n";

my $distro = "UBUNTU";
my $distro_ver = "LUCID";
my $arch = "64";
my $source = "BZR";
my $repo = "";

if( @ARGV > 0 ){
	$distro = uc(shift @ARGV);
	$distro_ver = uc(shift @ARGV);
	$arch = shift @ARGV;
	$source = shift @ARGV;
};

### EXTRA ARGUMENT
if( @ARGV > 0 ){
	$repo = shift @ARGV;
};

print "\n";
print "DISTRO\t$distro\n";
print "DISTRO_VER\t$distro_ver\n";
print "ARCH\t$arch\n";

if( $repo ne "" ){
	print "\n";
	print "REPO\t$repo\n";
};
print "\n";

$ENV{'QA_MEMO_EUCA2OOLS_REPO_FOR_TEST'} = $repo;


### uninstall existing packages for speical case
if( $distro eq "UBUNTU" ){
	system("apt-get -y remove euca2ools");
	system("apt-get -y autoremove");
}elsif( $distro eq "CENTOS" || $distro eq "RHEL" ){
	system("yum -y remove euca2ools");
};


install_euca2ools_from_repo($distro, $distro_ver, $arch);

exit(0);

1;



############################ SUBROUTINES #############################################


sub ubuntu_euca2ools_repo_install{

        if( $ENV{'QA_MEMO_EUCA2OOLS_REPO_FOR_TEST'} ne "" ){
                my $euca2ools_repo = $ENV{'QA_MEMO_EUCA2OOLS_REPO_FOR_TEST'};
                system("( echo deb $euca2ools_repo lucid universe >> /etc/apt/sources.list )");
        }else{
                system("( echo deb http://192.168.7.65/qa-pkg-storage/qa-euca2ools-pkgbuild/latest-success/phase3/ubuntu/lucid/ lucid universe >> /etc/apt/sources.list )");
	};

	system("apt-get update");

	system("apt-get --force-yes -y install gcc");

	system("apt-get --force-yes -y install euca2ools");

	return 0;
};


sub debian_euca2ools_repo_install{
	
        if( $ENV{'QA_MEMO_EUCA2OOLS_REPO_FOR_TEST'} ne "" ){
                my $euca2ools_repo = $ENV{'QA_MEMO_EUCA2OOLS_REPO_FOR_TEST'};
                system("( echo deb $euca2ools_repo squeeze main  >> /etc/apt/sources.list )");
        }else{
                system("( echo deb http://192.168.7.65/auto-repo/nightly/current-euca2ools-debian squeeze main  >> /etc/apt/sources.list )");
	};

	system("apt-get update");

	system("apt-get --force-yes -y install gcc");

	system("apt-get --force-yes -y install euca2ools");

	return 0;
};


sub opensuse_euca2ools_repo_install{
	
        if( $ENV{'QA_MEMO_EUCA2OOLS_REPO_FOR_TEST'} ne "" ){
                my $euca2ools_repo = $ENV{'QA_MEMO_EUCA2OOLS_REPO_FOR_TEST'};
                system("zypper ar --refresh $euca2ools_repo Euca2ools");
	}else{
                system("zypper ar --refresh http://192.168.7.65/auto-repo/nightly/current-euca2ools-opensuse Euca2ools");
	};

	system("zypper --no-gpg-checks refresh Euca2ools");

	system("zypper -n in gcc");

	system("zypper -n in euca2ools");

	return 0;
};


sub centos_euca2ools_repo_install{

	system("rm -f /etc/yum.repos.d/euca2ools.repo");

	system("touch /etc/yum.repos.d/euca2ools.repo");
	system("(echo \"[euca2ools]\" >> /etc/yum.repos.d/euca2ools.repo)");
	system("(echo \"name=Euca2ools\" >> /etc/yum.repos.d/euca2ools.repo)");

        if( $ENV{'QA_MEMO_EUCA2OOLS_REPO_FOR_TEST'} ne "" ){
                my $euca2ools_repo = $ENV{'QA_MEMO_EUCA2OOLS_REPO_FOR_TEST'};
		system("(echo \"baseurl=" . $euca2ools_repo ."\" >> /etc/yum.repos.d/euca2ools.repo)");
	}else{
		system("(echo \"baseurl=http://192.168.7.65/qa-pkg-storage/qa-euca2ools-pkgbuild/latest-success/phase3/centos/5/x86_64/\" >> /etc/yum.repos.d/euca2ools.repo)");
	};
	system("(echo \"enabled=1\" >> /etc/yum.repos.d/euca2ools.repo)");


	system("yum update");

	system("yum -y install gcc");

	system("yum -y install euca2ools --nogpgcheck");

	return 0;
};


sub fedora_euca2ools_repo_install{

	system("rm -f /etc/yum.repos.d/euca2ools.repo");

	system("touch /etc/yum.repos.d/euca2ools.repo");
	system("(echo \"[euca2ools]\" >> /etc/yum.repos.d/euca2ools.repo)");
	system("(echo \"name=Euca2ools\" >> /etc/yum.repos.d/euca2ools.repo)");

        if( $ENV{'QA_MEMO_EUCA2OOLS_REPO_FOR_TEST'} ne "" ){
                my $euca2ools_repo = $ENV{'QA_MEMO_EUCA2OOLS_REPO_FOR_TEST'};
		system("(echo \"baseurl=" . $euca2ools_repo . "\" >> /etc/yum.repos.d/euca2ools.repo)");
	}else{
		system("(echo \"baseurl=http://192.168.7.65/qa-pkg-storage/qa-euca2ools-pkgbuild/latest-success/phase3/centos/5/x86_64/\" >> /etc/yum.repos.d/euca2ools.repo)");
	};

	system("(echo \"enabled=1\" >> /etc/yum.repos.d/euca2ools.repo)");

	system("yum update");

	system("yum -y install gcc");

	system("yum -y install euca2ools --nogpgcheck");

	return 0;
};


sub rhel_euca2ools_repo_install{

	system("rm -f /etc/yum.repos.d/euca2ools.repo");

	system("touch /etc/yum.repos.d/euca2ools.repo");
	system("(echo \"[euca2ools]\" >> /etc/yum.repos.d/euca2ools.repo)");
	system("(echo \"name=Euca2ools\" >> /etc/yum.repos.d/euca2ools.repo)");

        if( $ENV{'QA_MEMO_EUCA2OOLS_REPO_FOR_TEST'} ne "" ){
                my $euca2ools_repo = $ENV{'QA_MEMO_EUCA2OOLS_REPO_FOR_TEST'};
		system("(echo \"baseurl=" . $euca2ools_repo ."\" >> /etc/yum.repos.d/euca2ools.repo)");
	}else{
		system("(echo \"baseurl=http://192.168.7.65/qa-pkg-storage/qa-euca2ools-pkgbuild/latest-success/phase3/centos/5/x86_64/\" >> /etc/yum.repos.d/euca2ools.repo)");
	};
	system("(echo \"enabled=1\" >> /etc/yum.repos.d/euca2ools.repo)");


	system("yum update");

	system("yum -y install gcc");

	system("yum -y install euca2ools --nogpgcheck");

	return 0;
};


sub install_euca2ools_from_repo{

	my $distro = shift @_;
	my $distro_ver = shift @_;
	my $arch = shift @_;

	my $name = "";
	my $url = "";


	if( $distro eq "UBUNTU"){

		### boto repo
		$name = "boto";
		$url = "http://mirror.eucalyptus/auto-repo/". lc($distro_ver) ."/boto";
		create_extra_repo($distro, $distro_ver, $name, $url);		

		### rampart repo
		$name = "rampart";
		$url = "http://mirror.eucalyptus/auto-repo/". lc($distro_ver) ."/rampart";
		create_extra_repo($distro, $distro_ver, $name, $url);		

		### m2crypto repo
		$name = "m2crypto";
		$url = "http://mirror.eucalyptus/auto-repo/". lc($distro_ver)  ."/m2crypto";
		create_extra_repo($distro, $distro_ver, $name, $url);		

		ubuntu_euca2ools_repo_install();

	}elsif( $distro eq "DEBIAN" ){

		### boto repo
		$name = "boto";
		$url = "http://mirror.eucalyptus/auto-repo/". lc($distro_ver) ."/boto";
		create_extra_repo($distro, $distro_ver, $name, $url);		

		### rampart repo
		$name = "rampart";
		$url = "http://mirror.eucalyptus/auto-repo/". lc($distro_ver) ."/rampart";
		create_extra_repo($distro, $distro_ver, $name, $url);		

		### m2crypto repo
		$name = "m2crypto";
		$url = "http://mirror.eucalyptus/auto-repo/". lc($distro_ver)  ."/m2crypto";
		create_extra_repo($distro, $distro_ver, $name, $url);

		debian_euca2ools_repo_install();

	}elsif( $distro eq "OPENSUSE" ){

		opensuse_euca2ools_repo_install();

	}elsif( $distro eq "CENTOS" ){

		### runtime-deps repo
		$name = "runtime-deps";
		if( $arch eq "64" ){
			$url = "http://mirror.eucalyptus/gholms/packaging/runtime-deps/centos/5/x86_64/";
		}else{
			$url = "http://mirror.eucalyptus/gholms/packaging/runtime-deps/centos/5/i386/";
		};
		create_extra_repo($distro, $distro_ver, $name, $url);		

		### epel repo
		$name = "epel";
		$url = "http://192.168.7.65/epel/\$releasever/\$basearch";
		create_extra_repo($distro, $distro_ver, $name, $url);		

		centos_euca2ools_repo_install();

	}elsif( $distro eq "FEDORA" ){

		### runtime-deps repo
		$name = "runtime-deps";
		if( $arch eq "64" ){
			$url = "http://mirror.eucalyptus/gholms/packaging/runtime-deps/centos/5/x86_64/";
		}else{
			$url = "http://mirror.eucalyptus/gholms/packaging/runtime-deps/centos/5/i386/";
		};
		create_extra_repo($distro, $distro_ver, $name, $url);		

		### epel repo
		$name = "epel";
		$url = "http://192.168.7.65/epel/\$releasever/\$basearch";
		create_extra_repo($distro, $distro_ver, $name, $url);		

		fedora_euca2ools_repo_install();

	}elsif( $distro eq "RHEL" ){

		### runtime-deps repo
		$name = "runtime-deps";
		if( $arch eq "64" ){
			$url = "http://mirror.eucalyptus/gholms/packaging/runtime-deps/centos/5/x86_64/";
		}else{
			$url = "http://mirror.eucalyptus/gholms/packaging/runtime-deps/centos/5/i386/";
		};
		create_extra_repo($distro, $distro_ver, $name, $url);		

		### epel repo
		$name = "epel";
		$url = "http://192.168.7.65/epel/\$releasever/\$basearch";
		create_extra_repo($distro, $distro_ver, $name, $url);		

		rhel_euca2ools_repo_install();

		### De-register after installing euca2ools
		pre_ops_rhel_de_register_image();

	}else{
		return 1;
	};

	return 0;
};



sub create_extra_repo{
	my ($distro, $distro_ver, $name, $url) = @_;

	$distro_ver = lc($distro_ver);

	$url =~ s/\$/\\\$/g;

	if( $distro eq "CENTOS" || $distro eq "FEDORA" || $distro eq "RHEL" ){
		my $repo_file = "/etc/yum.repos.d/" . $name . ".repo";
		system("(echo \"[$name]\" >> $repo_file)");
		system("(echo \"name=Extra Repo - $name\" >> $repo_file)");
		system("(echo \"baseurl=$url\" >> $repo_file)");
		system("(echo \"enabled=1\" >> $repo_file)");
		system("(echo \"gpgcheck=0\" >> $repo_file)");
		system("yum -y update");
	}elsif( $distro eq "OPENSUSE" ){
		system("zypper ar --refresh $url $name");
		system("zypper --no-gpg-checks refresh $name");
		system("zypper -n update");
	}elsif( $distro eq "UBUNTU" ){
		system("( echo deb $url $distro_ver universe >> /etc/apt/sources.list )");
		system("apt-get -y update");
	}elsif( $distro eq "DEBIAN" ){
		system("( echo deb $url $distro_ver main >> /etc/apt/sources.list )");
		system("apt-get -y update");
	};

	return 0;
};



sub pre_ops_rhel_de_register_image{

	chdir("/root/rhel_regist_scripts");
	
	print "\nDe-Registering RHEL image to RHN\n";
	system("./rhn_deletesystem.sh");

	chdir($ENV{'PWD'});

	return 0;

};




1;

