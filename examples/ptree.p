#!/usr/local/bin/perl -w

use strict;
use ExtUtils::testlib;
use Solaris::Procfs qw(:procfiles getpids);
use lib '.';

my $pid;
my %psargs   = ();
my %children = ();
my %ischild  = ();

my @pidlist  = (@ARGV ? @ARGV : getpids());

while (defined($pid = shift @pidlist) ) {

	my $psinfo = psinfo($pid);

	unless (defined $psinfo and ref $psinfo eq 'HASH') {

		warn "Cannot find process $pid\n";
		next;
	}

	my $parent = $psinfo->{pr_ppid};
	next unless $parent > 0;

	($psargs{$pid} = $psinfo->{pr_psargs}) =~ s/\n//gm;
	next unless $parent > 1;

	$children{$parent}->{$pid} = 1;

	push @pidlist, $parent unless exists $psargs{$parent};

	$ischild{$pid} = 1;
}


foreach $pid ( sort { $a <=> $b } keys %psargs ) {

	next if $ischild{$pid};
	print_pid($pid,0);
}

sub print_pid {

	my ($pid,$gen) = @_;

	printf( "%s%-5d %s\n", "  " x $gen, $pid, $psargs{$pid} );

	return unless defined $children{$pid};

	foreach ( sort { $a <=> $b } keys %{ $children{$pid} } ) {

		print_pid($_,$gen+1);
	}
}

