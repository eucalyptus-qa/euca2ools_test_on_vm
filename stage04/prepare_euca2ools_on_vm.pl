#!/usr/bin/perl

use strict;

open (STDERR, ">&STDOUT");

$ENV{'QA_WHICH_TEST'} = "dan_test_euca2ools_on_vm_temp";

my $ec2timeout = 30;
my $numtries=300;
my $done=0;


my ($type, $id, $emi, $pub, $priv, $state, $key, @tmp);
my @privips;
my @keys;
my @states;
my @ids;
my $cmd;

my $trycount=0;
my $kyo_try = 20;


while($trycount < $numtries && !$done) {

	# get the ids
	system("date");
	$cmd = "runat $ec2timeout euca-describe-instances";
	my $runcount=0;
	my $count=0;
	open(RFH, "$cmd|");
	while(<RFH>) {
		chomp;
		my $line = $_;
		my ($type, $id, $emi, $pub, $priv, $state, $key, @tmp) = split(/\s+/, $line);
		if ($type  eq "INSTANCE") {
			print "INST INFO: $id $priv $key $state\n";
			if ($id && $state && $pub && ($state eq "pending" || $state eq "running")) {
				$privips[$count] = $priv;
				$keys[$count] = $key;
				$states[$count] = $state;
				$ids[$count] = $id;
				if ($state eq "running") {
					$runcount++;
				};
				$count++;
			};
		};
	};
	close(RFH);

	if ( ($runcount != 0) && ($runcount == $count)) {
		print "all '$count' instances are running\n";
		$done++;
	}else{
		print "\tattempt $trycount/$numtries; found that '$runcount' out of '$count' instances are running\n";
	};

    	$trycount++;
};

print "\n";

if (@ids < 1 || !$done) {
    print "ERROR: could not get ids from euca-describe-instances\n";
    exit(1);
};

my $theid = $ids[0];
my $existingip = "";


print "\n";
print "euca-describe-instances $theid\n";
system("euca-describe-instances $theid");
print "\n";


my $kyo_count = 0;
	
while( $kyo_count < $kyo_try ){
	system("date");
	$cmd = "runat $ec2timeout euca-describe-instances $theid | grep INST | awk '{print \$4}'";
	print "CMD: $cmd\n";
	open(RFH, "$cmd|");
	while(<RFH>) {
		chomp;
		my $line = $_;
		if ($line) {
			$existingip = $line;
		} else {
			$existingip = "";
		};
	};
	close(RFH);

	# KYO's ADDITION
	if( $existingip eq "" || $existingip =~ /0\.0\.0\.0/ ){
		$kyo_count++;
		sleep(10);
	}else{
		$kyo_count = $kyo_try;          #EXIT the loop
	};
	print "\n";
};
        
if ($existingip eq "" || $existingip =~ /0\.0\.0\.0/) {
	print "ERROR: could not get current public IP from instance '$cmd'\n";
	exit(1);
};    

my $theip = $existingip;

### At this point below,
### $theid = instance' id
### $theip = instance's ip
### $keys[0] = instance's private key ID

print "\n";
print "ID $theid\n";
print "IP $theip\n";
print "\n";

### Default values are for UBUNTU LUCID 64 BZR
my $target_distro = "UBUNTU";
my $target_version = "LUCID";
my $target_arch = "64";
my $target_source = "BZR";

### read input file
read_input_file();

### Detect the euca2ools test setup description
if( is_euca2ools_test_setup_from_memo() ){
	my $test_desc = $ENV{'QA_MEMO_EUCA2OOLS_TEST_SETUP'};
	if( $test_desc =~ /(.+)\s+(.+)\s+(\d+)\s+(\w+)/){
		$target_distro = uc($1);
		$target_version = uc($2);
		$target_arch = $3;
		$target_source = uc($4);
	};
};

print "\n";
print "TARGET DISTRO\t$target_distro\n";
print "TARGET VER\t$target_version\n";
print "TARGET ARCH\t$target_arch\n";
print "TARGET SOURCE\t$target_source\n";
print "\n";

### Write the target information to ../artifacts
my $target_info_filename = uc($target_distro) . "_" . uc($target_version) . "_" . uc($target_arch) . "_" . uc($target_source) . ".info";
system("touch ../artifacts/$target_info_filename");

### Default values are for UBUNTU 64
my $prep_script = "prep_instance.pl";
my $install_script = "install_euca2ools_on_vm.pl";

my $target_repo = "";

if( $target_source eq "REPO" && is_euca2ools_repo_for_test_from_memo() ){
	$target_repo = $ENV{'QA_MEMO_EUCA2OOLS_REPO_FOR_TEST'};
	print "\n";
	print "TARGET REPO\t$target_repo\n";
	print "\n";
	$install_script = "install_euca2ools_from_repo_on_vm.pl";

	my $this_clc_ip = $ENV{'QA_CLC_IP'};
	my $temp_line = `ssh -o StrictHostKeyChecking=no root\@$this_clc_ip "cat /root/euca_builder/bzr_log.txt | grep Automatic \" `;
	chomp($temp_line);
	my $uid = 0;
	if( $temp_line =~ /\((\S+)\s+(\d+)\)/ ){
		$uid = $2;
	};

	if( $uid > 0 ){
		$target_repo =~ s/latest-success/$uid/;
		print "\n";
		print "Converted Repo:\n";
		print "TARGET REPO\t$target_repo\n";
		print "\n";
	};
};

print "\n";
print "PREP SCRIPT\t$prep_script\n";
print "INSTALL SCRPT\t$install_script\n";
print "\n";



### Basic SSH connection check
$cmd = "ssh -o StrictHostKeyChecking=no -i $keys[0].priv root\@$theip '/sbin/ifconfig eth0 | grep \'inet \''";

### run_the_command( COMMAND, TIMEOUT PER COMMAND, RETRY );
$done = run_the_command( $cmd , 30, 10);

if (!$done) {
	handle_failed_command( $theid, $ec2timeout );
};
print "\n";



### Copy $prep_script script over
$cmd = "scp -o StrictHostKeyChecking=no -i $keys[0].priv ./$prep_script  root\@$theip:/root/.";

### run_the_command( COMMAND, TIMEOUT PER COMMAND, RETRY );
$done = run_the_command( $cmd , 120, 3);

if (!$done) {
	handle_failed_command( $theid, $ec2timeout );
};
print "\n";


### Run $prep_script script
$cmd = "ssh -o StrictHostKeyChecking=no -i $keys[0].priv root\@$theip \"cd /root; chmod 755 $prep_script; perl ./$prep_script $target_distro $target_version $target_arch $target_source\"";

### run_the_command( COMMAND, TIMEOUT PER COMMAND, RETRY );
$done = run_the_command( $cmd , 900, 3);

if (!$done) {
	handle_failed_command( $theid, $ec2timeout );
};
print "\n";


### Copy over $install_script 
$cmd = "scp -o StrictHostKeyChecking=no -i $keys[0].priv ./$install_script root\@$theip:/root/.";

### run_the_command( COMMAND, TIMEOUT PER COMMAND, RETRY );
$done = run_the_command( $cmd , 120, 3);

if (!$done) {
	handle_failed_command( $theid, $ec2timeout );
};
print "\n";


### Run $install_script script
$cmd = "ssh -o StrictHostKeyChecking=no -i $keys[0].priv root\@$theip \"cd /root; chmod 755 $install_script; perl ./$install_script $target_distro $target_version $target_arch $target_source $target_repo\"";

### run_the_command( COMMAND, TIMEOUT PER COMMAND, RETRY );
$done = run_the_command( $cmd , 900, 1);

if (!$done) {
	handle_failed_command( $theid, $ec2timeout );
};
print "\n";


### Download the dan_test_euca2ool.tar.gz
$cmd = "ssh -o StrictHostKeyChecking=no -i $keys[0].priv root\@$theip \"cd /root; wget http://qa-server/4qa/4_euca2ools/$ENV{'QA_WHICH_TEST'}.tar.gz\"";

### run_the_command( COMMAND, TIMEOUT PER COMMAND, RETRY );
$done = run_the_command( $cmd , 480, 2);

if (!$done) {
	handle_failed_command( $theid, $ec2timeout );
};
print "\n";


### Untar the tarball $ENV{'QA_WHICH_TEST'}.tar.gz
$cmd = "ssh -o StrictHostKeyChecking=no -i $keys[0].priv root\@$theip \"cd /root; tar zxvf $ENV{'QA_WHICH_TEST'}.tar.gz\"";

### run_the_command( COMMAND, TIMEOUT PER COMMAND, RETRY );
$done = run_the_command( $cmd , 180, 3);

if (!$done) {
	handle_failed_command( $theid, $ec2timeout );
};
print "\n";


### Copy over the input file to dan_test_euca2ool
$cmd = "scp -o StrictHostKeyChecking=no -i $keys[0].priv ../input/2b_tested.lst root\@$theip:/root/$ENV{'QA_WHICH_TEST'}/input/.";

### run_the_command( COMMAND, TIMEOUT PER COMMAND, RETRY );
$done = run_the_command( $cmd , 120, 1);

if (!$done) {
	handle_failed_command( $theid, $ec2timeout );
};
print "\n";


print "\n";
print "[TEST_REPORT] Finished Running of prepare_euca2ools_on_vm.pl\n\n";

exit(0);





########################## SUB-ROUTINES ######################################33


sub run_the_command{
	my $this_cmd = shift @_;
	my $this_timeout = shift @_;
	my $this_try_num = shift @_;

	$this_cmd = "runat $this_timeout " . $this_cmd;

	my $trycount = 0;
	my $is_done = 0;

	while(!$is_done && $trycount < $this_try_num){
		system("date");
		print "[Trial Count $trycount]\nCOMMAND: $this_cmd\n";
		my $rc = system($this_cmd);
		if (!$rc) {
			$is_done = 1;
		};
		$trycount++;
		sleep(1);
	};

	return $is_done;

};


sub handle_failed_command{

	my $this_id = shift @_;
	my $this_timeout = shift @_;

	system("date");
	$cmd = "runat $this_timeout euca-get-console-output $this_id";
	my $rc = system("$cmd > out.$$");
	if (!$rc) {
		$cmd = "cat out.$$";
		$rc = system("$cmd");
		if (!$rc) {
			print "WARN: VM crash\n";
		};
	} else {
		print "ERROR: could not get console output for ID=$this_id\n";
	};
	system("rm -f out.$$");

	exit(1);
};



sub is_custom_load_image_desc_from_memo{
	$ENV{'QA_MEMO_CUSTOM_LOAD_IMAGE_DESC'} = "";
        if( $ENV{'QA_MEMO'} =~ /^CUSTOM_LOAD_IMAGE_DESC=(.+)\n/m ){
                my $extra = $1;
                $extra =~ s/\r//g;
                print "FOUND in MEMO\n";
                print "CUSTOM_LOAD_IMAGE_DESC=$extra\n";
                $ENV{'QA_MEMO_CUSTOM_LOAD_IMAGE_DESC'} = $extra;
                return 1;
        };
        return 0;
};


sub is_euca2ools_test_setup_from_memo{
        $ENV{'QA_MEMO_EUCA2OOLS_TEST_SETUP'} = "";
        if( $ENV{'QA_MEMO'} =~ /^EUCA2OOLS_TEST_SETUP=(.+)\n/m ){
                my $extra = $1;
                $extra =~ s/\r//g;
                print "FOUND in MEMO\n";
                print "EUCA2OOLS_TEST_SETUP=$extra\n";
                $ENV{'QA_MEMO_EUCA2OOLS_TEST_SETUP'} = $extra;
                return 1;
        };
        return 0;
};

sub is_euca2ools_repo_for_test_from_memo{
        $ENV{'QA_MEMO_EUCA2OOLS_REPO_FOR_TEST_SETUP'} = "";
        if( $ENV{'QA_MEMO'} =~ /^EUCA2OOLS_REPO_FOR_TEST=(.+)\n/m ){
                my $extra = $1;
                $extra =~ s/\r//g;
                print "FOUND in MEMO\n";
                print "EUCA2OOLS_REPO_FOR_TEST=$extra\n";
                $ENV{'QA_MEMO_EUCA2OOLS_REPO_FOR_TEST'} = $extra;
                return 1;
        };
        return 0;
};



# Read input values from input.txt
sub read_input_file{

	my $is_memo = 0;
	my $memo = "";

	open( INPUT, "< ../input/2b_tested.lst" ) || die $!;

	my $line;
	while( $line = <INPUT> ){
		chomp($line);
		if( $is_memo ){
			if( $line ne "END_MEMO" ){
				$memo .= $line . "\n";
			};
		};

        	if( $line =~ /^([\d\.]+)\t(.+)\t(.+)\t(\d+)\t(.+)\t\[(.+)\]/ ){
			my $qa_ip = $1;
			my $qa_distro = $2;
			my $qa_distro_ver = $3;
			my $qa_arch = $4;
			my $qa_source = $5;
			my $qa_roll = $6;

			my $this_roll = lc($6);
			if( $this_roll =~ /clc/ ){
				print "\n";
				print "IP $qa_ip [Distro $qa_distro, Version $qa_distro_ver, ARCH $qa_arch] is built from $qa_source as Eucalyptus-$qa_roll\n";
				$ENV{'QA_CLC_IP'} = $qa_ip;
				$ENV{'QA_DISTRO'} = $qa_distro;
				$ENV{'QA_DISTRO_VER'} = $qa_distro_ver;
				$ENV{'QA_ARCH'} = $qa_arch;
				$ENV{'QA_SOURCE'} = $qa_source;
				$ENV{'QA_ROLL'} = $qa_roll;
			};
		}elsif( $line =~ /^MEMO/ ){
			$is_memo = 1;
		}elsif( $line =~ /^END_MEMO/ ){
			$is_memo = 0;
		};
	};	

	close(INPUT);

	$ENV{'QA_MEMO'} = $memo;

	return 0;
};


