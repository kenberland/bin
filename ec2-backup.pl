#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Expect;
use POSIX qw(strftime);
use Data::Dumper;
use DateTime;
use DateTime::Format::Strptime;
use DateTime::Duration;
use Email::MIME;
use Email::Sender::Simple qw(sendmail);
use File::Slurp;
use Paws;

#$DB::single = 1;
my $dbg = 0;

if ($dbg) {
    $Expect::Exp_Internal = 1;
    $Expect::Log_Stdout = 1;
    $| = 1;
} else {
    $Expect::Log_Stdout = 0;
}

my $only_bring_up = 0;
my $only_bring_down = 0;
GetOptions(
    'only-bring-up'   => \$only_bring_up,
    'only-bring-down' => \$only_bring_down,
) or die "Usage: $0 [--only-bring-up | --only-bring-down]\n";

if ($only_bring_up && $only_bring_down) {
    die "Cannot specify both --only-bring-up and --only-bring-down\n";
}

my $keypair_name = "ec2_keypair_v02";
sub keypair_file { return "/home/ken/" . $keypair_name . ".pem"; }
my $ec2_keypair = keypair_file();
my $ami = "ami-9bce7af0"; #backup
#$ami = "ami-c80b0aa2"; # hearsay
my $volume = "vol-0a87c85fe9d38be27";
my $password_file = $volume . "_luks_passphrase";
my $local_password_file = "/crypt/" . $volume . "_luks_passphrase";
my $remote_password_file = "/root/" . $volume . "_luks_passphrase";
my $mntpoint = "herobkup";
my $volsize = "80";
my $device = "/dev/xvdf";
my $zone = 'us-east-1a';
my $continue = 1;
my $timeout = 180;
my $output="";
my $rsync_output;
my $max_days_keep = 10;
my $instance;
my $ec2ip;
my $ec2 = Paws->service('EC2', region => 'us-east-1');

{
    my $result = $ec2->DescribeInstances(Filters => [ { Name => 'image-id', Values => [$ami] } ]);

    if ( $#{$result->Reservations} >= 0 ){
	foreach (@{$result->Reservations->[0]->Instances}) {
	    if ($_->State->Name ne 'terminated'){
		if ($only_bring_down) {
		    # Find the running instance to bring down
		    $instance = $_->InstanceId;
		    $ec2ip = $_->PublicIpAddress;
		    &a2o("Found running instance $instance at $ec2ip to bring down.");
		} else {
		    $continue = 0;
		}
	    }
	}
    }
    if ($only_bring_down) {
	&printErrorAndDie("No running instance found to bring down", Dumper($result)) if (!$instance || !$ec2ip);
    } else {
	&printErrorAndDie("Some other instance is running", Dumper($result)) if (!$continue);
	&a2o("Continue, no instances are running.");
    }
}

if (!$only_bring_down) {
# === BRING-UP SECTION ===

{
    my $result = $ec2->DescribeVolumes(Filters => [ { Name => 'volume-id', Values => [$volume] } ]);
    if ( $result->Volumes->[0]->State eq 'Available') {
	$continue = 0 ;
    }
    &printErrorAndDie("$volume is not available.") if (!$continue);
    &a2o("Continue, volume is available.");
}

{
    # launch the instance
    my $result = $ec2->RunInstances(
        ImageId => 'ami-9bce7af0',
        KeyName => $keypair_name,
        MaxCount => 1,
        MinCount => 1,
        InstanceType => 't1.micro',
        SubnetId => 'subnet-f26d6885',
        SecurityGroupIds  => [
            'sg-e362f59b'
        ]
        );

    if ( @{$result->Instances} == 1 && length($result->Instances->[0]->InstanceId) == 19 ){
	$instance = $result->Instances->[0]->InstanceId;
    }
    $continue = 0 if (!$instance);
    &printErrorAndDie("Error launcing instance.", Dumper($result)) if (!$continue);
    &a2o("Continue, our newly created instance: ${instance}.");
}

{
    # get the info and confirm that it is running.
    $continue = 0;
    my $loop = 0;
    my $result;
    do {
	sleep(120) if ($loop > 0);
	$result = $ec2->DescribeInstances(Filters => [ { Name => 'instance-id', Values => [$instance] } ]);
	&a2o("Polling.. ", Dumper($result));
	if ( $result->Reservations && $result->Reservations->[0] && $result->Reservations->[0]->Instances && $result->Reservations->[0]->Instances->[0]->State->Name eq "running") {
	    $ec2ip = $result->Reservations->[0]->Instances->[0]->PublicIpAddress;
	    if ( $ec2ip && length($ec2ip) > 7 ){
		$continue = 1;
	    }
	}
	$loop++;
    } while ( $loop < 5 && !$continue);
    &printErrorAndDie("Instance IP could not be found", Dumper($result)) if (!$continue);
    &a2o("Continue, instance $instance is running at $ec2ip!");
}

{
    # attach the volume
    my $result = $ec2->AttachVolume(InstanceId => $instance, VolumeId => $volume, Device => $device);
    if ($result->State ne 'attaching'){
	$continue = 0;
    }
    &printErrorAndDie("Could not attach volume", $result) if (!$continue);
    &a2o("Continue, volume is attaching.");
}

{
    # wait for the volume to attach
    $continue = 0;
    my $loop = 0;
    my $result;
    do {
	sleep(30) if ($loop > 0);
	$result = $ec2->DescribeVolumes(Filters => [ { Name => 'volume-id', Values => [$volume] } ]);
	&a2o("Polling volume attachment..", Dumper($result));
	if ( $result->Volumes->[0]->Attachments
	     && $result->Volumes->[0]->Attachments->[0]->State eq 'attached'
	     && $result->Volumes->[0]->Attachments->[0]->InstanceId eq $instance) {
	    $continue = 1;
	}
	$loop++;
    } while ( $loop < 10 && !$continue);
    &printErrorAndDie("$volume did not attach to $instance.", Dumper($result)) if (!$continue);
    &a2o("Continue, " . $volume . " is attached to " . $instance);
}

&execSshCmdWithRetry('ubuntu', 'edit authorized_keys', 'sudo tail -c393 /root/.ssh/authorized_keys > /tmp/a', 10);
&execSshCmdWithRetry('ubuntu', 'replace authorized_keys', 'sudo cp /tmp/a /root/.ssh/authorized_keys', 5); 
&execSshCmd('root', 'install btrfs', 'apt-get install -y btrfs-tools');
&execSshCmdWithStdIn("root", "open the luks volume", "cryptsetup luksOpen ". $device . " " . $mntpoint, $local_password_file );
&execSshCmd("root", "make sure the volume opened", "ls -l /dev/mapper", ('-re', $mntpoint) );
&execSshCmd("root", "create the mount point", "mkdir /".$mntpoint);
&execSshCmd("root", "mount the volume", "mount -o compress /dev/mapper/".$mntpoint." /".$mntpoint);
&execSshCmd("root", "make sure the volume mounted", "mount", ('-re', $mntpoint) );

{
    # get df info
    my $command="/usr/bin/ssh";
    my @args=("-i", $ec2_keypair, "root\@".$ec2ip, "btrfs fi df /".$mntpoint);
    my @retvals=('-re',"System");
    my $expect = &expectSpecificReturnValue($command, \@args, \@retvals );
    if ( !$expect->match_number() ){
	$continue = 0;
    }
    &printErrorAndDie("Could not get df", $expect) if (!$continue);
    &a2o("Continue, df:".$expect->before().$expect->match().$expect->after());
}

# === END BRING-UP SECTION ===
} # end if (!$only_bring_down)

if ($only_bring_up) {
    &a2o("--only-bring-up: Instance $instance is up at $ec2ip. Exiting.");
    print "Instance: $instance\n";
    print "IP: $ec2ip\n";
    exit 0;
}

if (!$only_bring_down) {
# === BACKUP WORK SECTION ===

&doRsync();

# get a name for the snapshot

my $snap_name = strftime("%F", localtime);

#$DB::single = 1;

&execSshCmd("root", "take the snapshot " . $snap_name, "btrfs subvolume snapshot -r /".$mntpoint."/fs/ /".$mntpoint."/snapshots/".$snap_name);

my $snaplist;

{
    # confirm snapshot exists
    my $command="/usr/bin/ssh";
    my @args=("-i", $ec2_keypair, "root\@".$ec2ip, "ls -1 /".$mntpoint."/snapshots/");
    my @retvals=('-re',$snap_name);
    my $expect = &expectSpecificReturnValue($command, \@args, \@retvals );
    if ( !$expect->match_number() ){
	$continue = 0;
    } else {
	$snaplist = $expect->before() . "\n" . $expect->after();
    }
    &printErrorAndDie("Could not confirm snapshot taken", $expect) if (!$continue);
    &a2o("Continue, snapshot $snap_name confirmed.");
}

{
    # delete old snapshots
    my @snaps = split(/\s+/, $snaplist);
    my $snaps_removed = 0;
    foreach my $mySnap (@snaps){
	if ( $snaps_removed >= 4 ){
	    &a2o("Reached maximum of 4 snapshots removed per run.");
	    last;
	}
	if ( $mySnap =~ /(\d\d\d\d-\d\d-\d\d)/){
	    # how long ago was this?
	    my $Strp = new DateTime::Format::Strptime(
		pattern     => '%F',
		locale      => 'en_US',
		time_zone   => 'US/Central'
		);
	    my $then = $Strp->parse_datetime($1);
	    my $now = DateTime->now;
	    my $age = $now->subtract_datetime($then);
	    # &a2o("Snap: $1, is ". $age->{days}. " days old.");
	    if ($age->{days} > $max_days_keep ){
		# delete this snapshot
		&a2o("Delete old snap: $1, ". $age->{days}. " days old.");
		{
		    # btrfsctl -D 2011-01-25 /herobkup/snapshots/
		    my $command="/usr/bin/ssh";
		    my @args=("-i", $ec2_keypair, "root\@".$ec2ip, "btrfs subvolume delete /".$mntpoint."/snapshots/".$1);
		    my @retvals=('-re', qr/delete subvolume/i);
		    my $expect = &expectSpecificReturnValue($command, \@args, \@retvals );
		    if ( !$expect->match_number() ){
			&a2o("Problem removing snapshot $1.");
		    } else {
			&a2o("Snapshot $1 removed.");
			$snaps_removed++;
		    }
		}
	    }
	}
    }
}

# === END BACKUP WORK SECTION ===
} # end if (!$only_bring_down)

# === BRING-DOWN SECTION ===

&execSshCmd("root", "unmount the volume", "umount /".$mntpoint);

{
    # make sure the volume unmounted
    my $command="/usr/bin/ssh";
    my @args=("-i", $ec2_keypair, "root\@".$ec2ip, "mount");
    my @retvals=('-re', $mntpoint);
    my $loop = 1;
    my $expect;
    do {
	sleep(60) if ($loop > 1);
	&a2o("Attempt unmount...");
	$expect = &expectSpecificReturnValue($command, \@args, \@retvals );
	if ( $expect->match_number() ){
	    $continue = 0;
	} else {
	    $continue = 1;
	}
	$loop++;
    } while ( $loop < 30 && $expect->match_number() );
    &printErrorAndDie("Could not confirm the unmount", $expect) if (!$continue);
    &a2o("Continue, volume confirmed unmounted.");
}

&execSshCmd("root", "close the luks volume", "cryptsetup luksClose /dev/mapper/".$mntpoint);

{
    # detach the volume
    my $result = $ec2->DetachVolume(VolumeId => $volume);
    if ($result->State ne 'detaching'){
	$continue = 0;
    }
    &printErrorAndDie("Could not detach volume", $result) if (!$continue);
    &a2o("Continue, volume is detaching.");
}

sleep(120);

{
    my $result = $ec2->DescribeVolumes(Filters => [ { Name => 'volume-id', Values => [$volume] } ]);
    if ( $result->Volumes->[0]->State eq 'Available') {
	$continue = 0 ;
    }
    &printErrorAndDie("$volume is not available.", Dumper($result)) if (!$continue);
    &a2o("Continue, volume is available again.");
}

{
    # terminate the instance
    my $result = $ec2->TerminateInstances(InstanceIds => [$instance]);
    if ( $result->TerminatingInstances->[0]->CurrentState->Name ne "shutting-down"){
	$continue = 0 ;
    }
    &printErrorAndDie("Could not terminate the instance", $result) if (!$continue);
    &a2o("Done, instance terminated.");
}


sendEmail("Success", $output."\n".$rsync_output."\n");
exit;

sub sendKey {
    # send the key, tends to fail, try more than once
    my $try = 0;
    my $expect;
    while ($try < 3){
	my $command="/usr/bin/scp";
	my @args=( '-i', $ec2_keypair, $local_password_file, "root\@".$ec2ip.":");
	my @retvals=('-re', "100%");
	$expect = &expectSpecificReturnValue($command, \@args, \@retvals );
	if ( !$expect->match_number() ){
	    $continue = 0;
	    &a2o("Problem sending key, sleep and try again");
	    sleep(30);
	} else {
	    $continue = 1;
	    $try = 100000;
	}
	$try++;
    }
    &printErrorAndDie("Could not scp key to instance.", $expect) if (!$continue);
    &a2o("Continue, key sent.");
}

sub execSshCmdWithStdIn {
    my ($user, $description, $cmd, $input_file) = @_;
    my $ssh="/usr/bin/ssh";
    my @args=( '-oStrictHostKeyChecking=no', '-i', $ec2_keypair, $user."\@".$ec2ip, $cmd);
    my $pass = read_file($input_file);
    my @retvals=('-re', qr/error/i, '-re', qr/connection/i );
    my $expect = Expect->spawn($ssh, @args ) or die "Cannot spawn $ssh: $!\n";
    $expect->send($pass."\n");
    $expect->expect($timeout, @retvals );
    $expect->soft_close();
    if ($expect->match_number() ){
	$continue = 0;
    }
    &printErrorAndDie("Could not " . $description, $expect) if (!$continue);
    &a2o("Continue, " . $description );
    return($expect);
}

sub execSshCmdWithRetry {
    my ($user, $description, $cmd, $maxTries) = @_;
    my $ssh="/usr/bin/ssh";
    my @args=( '-oStrictHostKeyChecking=no', '-i', $ec2_keypair, $user."\@".$ec2ip, $cmd);
    my $try = 1;
    my @retvals=('-re', qr/error/i, '-re', qr/connection/i );
    my $output_expected = 0;
    my $expect;
    my $loop = 0;

    do {
	&a2o("Try " . $try . " for " . $description );
	sleep(10) if ($try > 1);
	$expect = &expectSpecificReturnValue($ssh, \@args, \@retvals );
	if (!defined $expect->match_number()) { # no match on "error" or "connection refused" is a success
	    $continue = 1;
	} else {
	    $continue = 0;
	}
	$try++;
    } while ( $loop < $maxTries && !$continue );

    &printErrorAndDie("Could not " . $description, $expect) if (!$continue);
    &a2o("Continue, " . $description );
    return($expect);
}

sub execSshCmd {
    my ($user, $description, $cmd, @retvals) = @_;
    my $ssh="/usr/bin/ssh";
    my @args=( '-oStrictHostKeyChecking=no', '-i', $ec2_keypair, $user."\@".$ec2ip, $cmd);
    my $output_expected = 1;
    if (!@retvals) {
	@retvals=('-re', qr/error/i, '-re', qr/connection/i );
	$output_expected = 0;
    }
    my $expect = &expectSpecificReturnValue($ssh, \@args, \@retvals );

    if ( $output_expected && !$expect->match_number() ){
	$continue = 0;
    }
    if ( !$output_expected && $expect->match_number() ){
	$continue = 0;
    }
    &printErrorAndDie("Could not " . $description, $expect) if (!$continue);
    &a2o("Continue, " . $description );
    return($expect);
}

sub printErrorAndDie {
    my ($es, $e) = @_;
    $continue = 1;
    # terminate the instance
    if ($instance){
	my $result = $ec2->TerminateInstances(InstanceIds => [$instance]);
	if ( $result->TerminatingInstances->[0]->CurrentState->Name ne "shutting-down"){
	    $continue = 0 ;
	}
	&a2o("Could not terminate the instance", $result) if (!$continue);
	&a2o("Done, instance terminated.");
    }
    sendEmail("Backup Failure", $es."\n".$e."\n".$output."\n");
    die "printErrorAndDie: $es :".Dumper($e);
}
    
sub returnExpectInstanceExpectSpecificReturnValue {
    my ($command, $args, $returnValues) = @_;
    my $expect = Expect->spawn($command, @{$args} ) or die "Cannot spawn $command: $!\n";
    $expect->expect($timeout, @{$returnValues} );
    return($expect);
}

sub expectSpecificReturnValue {
    my ($command, $args, $returnValues) = @_;
    my $expect = Expect->spawn($command, @{$args} ) or die "Cannot spawn $command: $!\n";
    $expect->expect($timeout, @{$returnValues} );
    my $retval = $expect;
    $expect->soft_close();
    return($retval);
}

sub a2o {
    my ($add) = (strftime("%T",localtime) )." ".join(' ',@_);
    $output = $output.$add."\n";
    if ($dbg) {
	print $add . "\n";
    }
}

sub sendEmail {
    my ($subject, $body) = @_;

    my $message = Email::MIME->create(
	header_str => [
	    From    => 'Ken Berland Robot<ken@hero.net>',
	    To      => 'Root <root@hero.net>',
	    Subject => $subject,
	],
	attributes => {
	    encoding => 'quoted-printable',
	    charset  => 'ISO-8859-1',
	},
	body_str => $body,
    );

    if ($dbg) {
	print $subject."\n";
	print $body."\n";
    } else {
	sendmail($message);
    }
}

sub doRsync {
    my $command="/usr/bin/rsync -e \"/usr/bin/ssh -i ".$ec2_keypair."\" -vaz --inplace --exclude-from=/root/hero_backup_exclude_paths.txt --numeric-ids --delete / root\@".$ec2ip.":/".$mntpoint."/fs";
    &a2o("Continue, do the rsync.\n$command\n");
    $rsync_output = `$command`;
}

