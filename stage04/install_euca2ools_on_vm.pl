#!/usr/bin/perl

use strict;

local $| = 1;

my $distro = "UBUNTU";
my $distro_ver = "LUCID";
my $arch = "64";
my $source = "BZR";

my $bzr_name = "";
my $bzr_group = "";

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

print "\n";
print "BZR_NAME\t$bzr_name\n";
print "BZR_GROUP\t$bzr_group\n";


my $mypython = "python";

### Adjust python
if( $distro eq "CENTOS" ){
	$mypython = "python2.5";
}elsif( $distro eq "RHEL" ){
	$mypython = "python2.6";
};


### uninstall existing packages for speical case
if( $distro eq "UBUNTU" ){
	system("apt-get -y remove euca2ools");
	system("apt-get -y autoremove");
}elsif( $distro eq "CENTOS" || $distro eq "RHEL" ){
	system("yum -y remove euca2ools");
};


### install dependencies
if( $distro eq "UBUNTU" || $distro eq "DEBIAN" ){
	system("apt-get -y install python-dev swig libssl-dev make help2man gcc");
}elsif( $distro eq "OPENSUSE"  ){
}elsif( $distro eq "FEDORA" ){
}elsif( $distro eq "CENTOS" ){
	### From REPO
	system("yum -y install swig make gcc openssl-devel");

	### From Source
	system("wget http://qa-server/4qa/4_euca2ools/python25/help2man-1.33.1-2.noarch.rpm");
	system("rpm -i help2man-1.33.1-2.noarch.rpm");

	if( $arch eq "64" ){
		system("wget http://qa-server/4qa/4_euca2ools/python25/python25-2.5.1-bashton1.x86_64.rpm");
		system("wget http://qa-server/4qa/4_euca2ools/python25/python25-devel-2.5.1-bashton1.x86_64.rpm");
		system("wget http://qa-server/4qa/4_euca2ools/python25/python25-libs-2.5.1-bashton1.x86_64.rpm");

		system("rpm -i python25-libs-2.5.1-bashton1.x86_64.rpm python25-2.5.1-bashton1.x86_64.rpm");
		system("rpm -i python25-devel-2.5.1-bashton1.x86_64.rpm");

		system("cp /usr/include/openssl/opensslconf-x86_64.h /usr/include/");
	}else{
		system("wget http://qa-server/4qa/4_euca2ools/python25/python25-2.5.1-bashton1.i386.rpm");
                system("wget http://qa-server/4qa/4_euca2ools/python25/python25-devel-2.5.1-bashton1.i386.rpm");
                system("wget http://qa-server/4qa/4_euca2ools/python25/python25-libs-2.5.1-bashton1.i386.rpm");

                system("rpm -i python25-libs-2.5.1-bashton1.i386.rpm python25-2.5.1-bashton1.i386.rpm");
                system("rpm -i python25-devel-2.5.1-bashton1.i386.rpm");

		system("cp /usr/include/openssl/opensslconf-i386.h /usr/include/");
       	};

}elsif( $distro eq "RHEL" ){
	system("yum -y install swig make gcc openssl-devel");
	system("yum -y install python-devel");
};


###
### Create Directories for euca2ools and dependencies
###

system("mkdir -p /root/euca2ools-for-test/deps");


###
### install boto
###

### Go to the deps directory for euca2ools dependencies
chdir("/root/euca2ools-for-test/deps");

### Find out which boto to install, untar the boto tarball, and go to the directory
if( is_use_custom_boto_from_memo() == 1 ){
	my $custom_boto = $ENV{'QA_MEMO_USE_CUSTOM_BOTO'};
	system("wget -O boto-custom-version.tar.gz $custom_boto");
	system("tar zxvf ./boto-custom-version.tar.gz");
}else{
	system("wget http://qa-server/4qa/4_euca2ools/deps/boto-new-latest.tar.gz");
	system("tar zxvf boto-new-latest.tar.gz");
};

### Go to the boto source directory
my $boto_dir = get_directory_name_begins_with("boto");
chdir("./$boto_dir");

### install boto
system("$mypython setup.py install");

### Back to Home Base
chdir($ENV{'PWD'});



###
### install M2Crypto
###

### Go to the deps directory
chdir("/root/euca2ools-for-test/deps");

### Download the M2Crypto
system("wget http://qa-server/4qa/4_euca2ools/deps/M2Crypto-0.20.1.tar.gz");

### Untar M2Crypto tarball
system("tar zxvf M2Crypto-0.20.1.tar.gz");
chdir("./M2Crypto-0.20.1");

### install M2Crypto
system("$mypython setup.py install");

### Back to Home Base
chdir($ENV{'PWD'});



###
### install euca2ools
###


### Go to the directory euca2ools-for-test
chdir("/root/euca2ools-for-test");

### Download the latest euca2ools source tarball
system("wget http://qa-server/4qa/4_euca2ools/deps/euca2ools-main-latest.tar.gz");

### Untar euca2ools tarball
system("tar zxvf euca2ools-main-latest.tar.gz");

### The directory below might vary !!!
chdir("./euca2ools-main");

if( $distro eq "CENTOS" || $distro eq "RHEL" ){
	system("$mypython setup.py install");
}else{
	system("make");
};

### SPECIAL OP for RHEL
if( $distro eq "RHEL"){
	pre_ops_rhel_de_register_image();
};

### Back to Home Base
chdir($ENV{'PWD'});

print "\n";
print "[TEST_REPORT]\tFinished Running of install_ecau2ools_on_vm.pl\n\n";

exit(0);

sub is_use_custom_boto_from_memo{
	$ENV{'QA_MEMO_USE_CUSTOM_BOTO'} = "NO";
	if( $ENV{'QA_MEMO'} =~ /USE_CUSTOM_BOTO=(.+)\n/ ){
		my $extra = $1;
                $extra =~ s/\r//g;
                print "FOUND in MEMO\n";
                print "USE_CUSTOM_BOTO=$extra\n";
                $ENV{'QA_MEMO_USE_CUSTOM_BOTO'} = $extra;
                return 1;
        };
        return 0;
};

sub get_directory_name_begins_with{

        my $str = shift @_;
        my $result = "";

        my $this_dir = `ls`;
        chomp($this_dir);

        my @this_array = split(' ', $this_dir);

        foreach my $this_item (@this_array){
                if( $this_item =~ /^$str/ && !($this_item =~ /\.gz/ || $this_item =~ /\.tgz/) ){
                        $result = $this_item;
                };
        };

        return $result;

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

        system("$cmd");

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

