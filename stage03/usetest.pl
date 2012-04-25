#!/usr/bin/perl

open (STDERR, ">&STDOUT");

$ec2timeout = 30;
$numtries=300;
$trycount=0;
$done=0;

$kyo_try = 20;

$mode = shift @ARGV;

if( $mode eq "" ){
        my $this_mode = `cat ../input/2b_tested.lst | grep NETWORK`;
        chomp($this_mode);
        if( $this_mode =~ /^NETWORK\s+(\S+)/ ){
                $mode = lc($1);
        };
};

print "Mode:\t$mode \n\n";

if ($mode eq "system" || $mode eq "static") {
    $managed = 0;
} else {
    $managed = 1;
}

while($trycount < $numtries && !$done) {
# get the ids
    system("date");
    $cmd = "runat $ec2timeout euca-describe-instances";
    $runcount=0;
    $count=0;
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
		}
		$count++;
	    }
	}
    }
    close(RFH);

    if ( ($runcount != 0) && ($runcount == $count)) {
	print "all '$count' instances are running\n";
	$done++;
    } else {
	print "\tattempt $trycount/$numtries; found that '$runcount' out of '$count' instances are running\n";
    }
    $trycount++;
    print "\n";
    sleep(10);
};

if (@ids < 1 || !$done) {
    print "ERROR: could not get ids from euca-describe-instances\n";
    exit(1);
}

# choose anaddrs
if ($managed) {
    	$count=0;
    	system("date");
	$cmd = "runat $ec2timeout euca-describe-addresses | grep admin";
    	open(RFH, "$cmd|");
    	while(<RFH>) {
		chomp;
		my $line = $_;
		my ($tmp, $ip) = split(/\s+/, $line);
		if ($ip) {
			$ips[$count] = $ip;
	    		$count++;
		};
    	};
    	close(RFH);
    	if (@ips < 1) {
		print "ERROR: could not get any addrs from euca-describe-addresses\n";
		exit(1);
    	};
    
    	$theip = $ips[int(rand(@ips))];
    	$theid = $ids[int(rand(@ids))];

	$kyo_count = 0;
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
			}
    		}
    		close(RFH);

		# KYO's ADDITION
		if( $existingip eq "" || $existingip =~ /0\.0\.0\.0/ ){
			$kyo_count++;
			sleep(10);
		}else{
			$kyo_count = $kyo_try;		#EXIT the loop
		};
	};
    	if ($existingip eq "" || $existingip =~ /0\.0\.0\.0/) {
		print "ERROR: could not get current public IP from instance '$cmd'\n";
		exit(1);
    	}

#    system("date");
	
	$cmd = "runat $ec2timeout euca-disassociate-address $existingip";

#    $rc = system($cmd);
#    if ($rc) {
#	print "ERROR: could not disassociate address '$cmd'\n";
#	exit(1);
#    }
    
    	system("date");

	$cmd = "runat $ec2timeout euca-associate-address $theip -i $theid";
    
	$rc = system($cmd);
    	if ($rc) {
		print "ERROR: could not associate address '$cmd'\n";
		exit(1);
    	}

} else {
	## NOT MANAGED MODE
    	$theid = $ids[int(rand(@ids))];

	$kyo_count = 0;
	
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
			}
	    	};
	    	close(RFH);

                # KYO's ADDITION
                if( $existingip eq "" || $existingip =~ /0\.0\.0\.0/ ){
                        $kyo_count++;
			sleep(10);
                }else{
                        $kyo_count = $kyo_try;          #EXIT the loop
                };
        };
        if ($existingip eq "" || $existingip =~ /0\.0\.0\.0/) {
                print "ERROR: could not get current public IP from instance '$cmd'\n";
                exit(1);
        }
    

    	$theip = $existingip;
};


for ($i=0; $i<@ids; $i++) {
#    print "INSTANCE: $ids[$i], $privips[$i], $keys[$i], $states[$i]\n";
    if (($theid eq $ids[$i]) && ($states[$i] eq "running")) {
	$cmd = "runat $ec2timeout ssh -o StrictHostKeyChecking=no -i $keys[$i].priv root\@$theip '/sbin/ifconfig eth0 | grep \'inet \''";
	print "$cmd\n";
	$trycount=0;
	$done=0;
	while(!$done && $trycount < 100){
	    system("date");
	    $rc = system($cmd);
	    if (!$rc) {
		$done++;
	    }
	    $trycount++;
	}
	if (!$done) {
	    system("date");
	    $cmd = "runat $ec2timeout euca-get-console-output $theid";
	    $rc = system("$cmd > out.$$");
	    if (!$rc) {
		$cmd = "grep -i sshd out.$$";
		$rc = system("$cmd");
		system("rm -f out.$$");
		if (!$rc) {
		    print "ERROR: could not ssh to instance '$cmd'\n";
		    exit(1);
		} else {
		    print "WARN: VM crash\n";
		}
	    } else {
		print "ERROR: could not get console output for ID=$theid\n";
		system("rm -f out.$$");
		exit (1);
	    }
	    system("rm -f out.$$");
	}
    }
}
#print "associated IP and ran command\n";
exit(0);
