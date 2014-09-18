#!/usr/bin/perl

use warnings;
use strict;

my $bcrypt_executable = "bcrypt";

sub bcrypt {
    my ($bcrypt_executable, $passphrase, $filename) = @_;

    # bcrypt [ARGS] INPUTFILE OUTPUTFILE
    open my $bcrypt, '|-', $bcrypt_executable, $filename, $filename
        or die "Couldn't start $bcrypt_executable: $!";
    print $bcrypt $passphrase . "\n";
    print $bcrypt $passphrase . "\n";
    
    close($bcrypt) # waits for bcrypt program to complete
        or die "Program failed; error $!, wait status $?\n";
}

sub get_filenames_recursive {
    my $path = shift;

    opendir (DIR, $path)
        or die "Unable to open $path: $!";

    my @files =
        # third: prepend full path
        map { $path . '/' . $_ }
        # second: remove . and ..
        grep { !/^\.{1,2}$/ }
        # get all files
        readdir (DIR);

    closedir (DIR);

    for my $i (0 .. $#files) {
        if (-d $files[$i]) {
            # recurisvely handle subdirectories
            push @files, get_filenames_recursive ($files[$i]);
	    splice @files, $i, 1;
        }
    }
    
    # return list of files
    return @files;
}

if ($#ARGV < 0) {
    print "Usage: bcryptrecursive [DIRECTORY]\n";
    exit;
}
$ARGV[0] =~ s|/\z||;

#ask user for passphrase
my $passphrase = "";
do {
    print "Enter your passphrase for encrypting/decrypting (8 characters or more):\n";
    chomp($passphrase = <STDIN>);
}
while (length($passphrase) < 8);

print "Enter passphrase again for confirmation: ";
chomp(my $passphrase2 = <STDIN>);

if ($passphrase ne $passphrase2) {
    print "Passphrases don't match! Exiting.\n";
    exit;
}

my @files = get_filenames_recursive $ARGV[0];
for (@files) {
    my $doing = "Encrypting";
    if ($_ =~ /\.bfe$/) {
        $doing = "Decrypting";
    }
    print "$doing: $_";
    bcrypt $bcrypt_executable, $passphrase, $_;
    print "... Done!\n";
}



