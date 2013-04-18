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

# Accepts one argument: the full path to a directory.
# Returns: A list of files that reside in that path.
sub process_files {
    my $path = shift;

    opendir (DIR, $path)
        or die "Unable to open $path: $!";

    # This is the same as:
    # LIST = map(EXP, grep(EXP, readdir()))
    my @files =
        # Third: Prepend the full path
        map { $path . '/' . $_ }
        # Second: take out '.' and '..'
        grep { !/^\.{1,2}$/ }
        # First: get all files
        readdir (DIR);

    closedir (DIR);

    for my $i (0 .. $#files) {
        if (-d $files[$i]) {
            # Add all of the new files from this directory
            # (and its subdirectories, and so on... if any)
            push @files, process_files ($files[$i]);
	    splice @files, $i, 1;

        } else {
            # Do whatever you want here =) .. if anything.
        }
    }
    # NOTE: we're returning the list of files
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

my @files = process_files $ARGV[0];
for (@files) {
    my $doing = "Encrypting";
    if ($_ =~ /\.bfe$/) {
        $doing = "Decrypting";
    }
    print "$doing: $_";
    bcrypt $bcrypt_executable, $passphrase, $_;
    print "... Done!\n";
}



