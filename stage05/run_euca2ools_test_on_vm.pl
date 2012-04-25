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
}

my $theid = $ids[0];
my $existingip = "";

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



### Basic SSH connection check
$cmd = "ssh -o StrictHostKeyChecking=no -i $keys[0].priv root\@$theip \"cd /root/$ENV{'QA_WHICH_TEST'}; perl ./run_test.pl $ENV{'QA_WHICH_TEST'}.conf\"";

### run_the_command( COMMAND, TIMEOUT PER COMMAND, RETRY );
$done = run_the_command( $cmd , 3600, 1);

if (!$done) {
	handle_failed_command( $theid, $ec2timeout );
};
print "\n";


print "\n";
print "[TEST_REPORT] Finished Running of run_euca2ools_test_on_vm.pl\n\n";

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
		$cmd = "grep -i sshd out.$$";
		$rc = system("$cmd");
		
		if (!$rc) {
			print "ERROR: could not ssh to instance '$cmd'\n";
		} else {
			print "WARN: VM crash\n";
		}
	} else {
		print "ERROR: could not get console output for ID=$this_id\n";
	};
	system("rm -f out.$$");

	exit(1);
};
