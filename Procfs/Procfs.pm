#---------------------------------------------------------------------------

package Solaris::Procfs;
package Solaris::Procfs::Process;   

# Copyright (c) 1999,2000 John Nolan. All rights reserved.
# This program is free software.  You may modify and/or
# distribute it under the same terms as Perl itself.
# This copyright notice must remain attached to the file.
#
# You can run this file through either pod2text, pod2man or
# pod2html to produce pretty documentation in text, manpage or
# html file format (these utilities are part of the
# Perl 5 distribution).

#-------------------------------------------------------------
package Solaris::Procfs;
#-------------------------------------------------------------

use vars qw($VERSION @ISA $AUTOLOAD);
use strict;
use DynaLoader;
use Carp;
use File::Find;

require Cwd;  # Don't use "use", otherwise we'll import the cwd() function

$VERSION = '0.10';
@ISA = qw(DynaLoader);

get_tty_list();

bootstrap Solaris::Procfs $VERSION;

#-------------------------------------------------------------
# Dispatch hash, used by the FETCH method to dispatch fetch
# operations to the appropriate internal function. 
#
# This is also used by the AUTOLOAD function of 
# Solaris::Procfs::Process, to send method calls 
# directly to the corresponding method in Solaris::Procfs. 
#
my $dispatcher = {

	'root'      => \&root,
	'cwd'       => \&cwd,
	'fd'        => \&fd,

	'prcred'    => \&_prcred,
	'sigact'    => \&_sigact,
	'status'    => \&_status,
	'lstatus'   => \&_lstatus,
	'psinfo'    => \&_psinfo,
	'lpsinfo'   => \&_lpsinfo,
	'usage'     => \&_usage,
	'lusage'    => \&_lusage,
	'map'       => \&_map,
	'rmap'      => \&_rmap,
	'lwp'       => \&_lwp,
	'auxv'      => \&_auxv,
};

foreach (keys %$dispatcher) {

	$dispatcher->{"Solaris::Procfs::$_"}          = $dispatcher->{$_};
	$dispatcher->{"Solaris::Procfs::Process::$_"} = $dispatcher->{$_};
}


#-------------------------------------------------------------
#
sub new {

	my ($proto, $pid) = @_;
	my $class = ref($proto) || $proto;

	my $self;

	if (defined $pid and $pid =~ /^\d+$/) {

#-#		print STDERR (caller 0)[3], 
#-#			": Invoking new() on Solaris::Procfs::Process for pid $pid\n";
		$self = new Solaris::Procfs::Process $pid ;

	} else {

#-#		print STDERR (caller 0)[3], 
#-#			": Creating object\n";
		$self = {};
		tie  %$self, $class;
		bless $self, $class;
	}

	return $self;     
}


#-------------------------------------------------------------
#
sub FETCH {

	my $self = "";
	my $index = "";
	($self, $index) = @_;

	return unless defined $index;

#-#	print STDERR (caller 0)[3], 
#-#		": Read \$index $index\n";

	if ($index =~ /^\d+$/) {

		if (not exists $self->{$index} or not defined $self->{$index} ) {

#-#			print STDERR (caller 0)[3], 
#-#				": creating object for pid $index\n";

			my $temp        = new Solaris::Procfs::Process $index ; 
			$self->{$index} = $temp;
		}

		return $self->{$index}

	} else {

#-#		print STDERR (caller 0)[3], 
#-#			": no such process as $index\n";

		return undef;
	}
}

#-------------------------------------------------------------
#
sub DELETE {

	my ($self, $index) = @_;

#-#	print STDERR (caller 0)[3], ": \$index is $index\n";

	# Can't remove the pid element
	#
	return if $index eq 'pid';

	return delete $self->{$index};
}

#-------------------------------------------------------------
#
sub EXISTS {

	my ($self, $index) = @_;
#-#	print STDERR (caller 0)[3], ": \$index is $index\n";
	return exists $self->{$index};
}

#-------------------------------------------------------------
#
sub STORE {

	my ($self, $index, $val) = @_;

	# Can't modify the pid element, if it's there.
	# It can only be defined at the time the hash is created. 
	#
	return if $index eq 'pid';

#-#	print STDERR (caller 0)[3], ": \$index is $index, \$val is $val\n";
	return $self->{$index};
}

#-------------------------------------------------------------
#
sub TIEHASH {

	my ($pkg) = @_;
	my $self = {};
#-#	print STDERR (caller 0)[3], ": \$self is $self, \$pkg is $pkg\n";
	return (bless $self, $pkg);
}

#-------------------------------------------------------------
#
sub NEXTKEY {

	my ($self) = @_;
#-#	print STDERR (caller 0)[3], ": \n";
	return each %{ $self };
}

#-------------------------------------------------------------
#
sub FIRSTKEY {

	my ($self) = @_;
#-#	print STDERR (caller 0)[3], ": \n";
	keys %{ $self };
	return each %{ $self };
}

#-------------------------------------------------------------
#
sub DESTROY {

	my ($self) = @_;
#-#	print STDERR (caller 0)[3], ": \$self is $self\n";
}

#-------------------------------------------------------------
#
sub CLEAR {

	my ($self) = @_;
#-#	print STDERR (caller 0)[3], ": \$self is $self\n";
}


#-------------------------------------------------------------
# Generate a hash mapping TTY numbers to paths.
# This code is called one time at module load time,
# and then the module accesses the hash $Solaris::Procfs::TTYDEVS.
# This code was inspired by similar code in the
# module Proc::ProcessTable by Daniel Urist. 
#
sub get_tty_list {

	undef %Solaris::Procfs::TTYDEVS;

	find(
		sub{
			my $rdev = (stat $File::Find::name)[6];
			$Solaris::Procfs::TTYDEVS{$rdev} = $File::Find::name if($rdev);
		},
		"/dev"
	);
}  

#-------------------------------------------------------------
#
sub getpids  { 

	my $arg = shift;
	my $pid = (ref($arg) ?  shift : $arg);

	unless (opendir (DIR, "/proc") ) {

		carp "Couldn't open directory /proc : $!";
		return;
	}

	my @pids = grep /^\d+$/, readdir DIR;

	close(DIR);

	return  @pids;
}

#-------------------------------------------------------------
#
sub cwd {

	my $arg = shift;
	my $pid = (ref($arg) ?  shift : $arg);

	my $hoo = Cwd::abs_path("/proc/$pid/cwd/.");
	my $path = $hoo;

	# Previous to 5.005, Cwd::abs_path() returned ""
	# when it actually meant to return "/".  
	#
	return unless defined $path;
	return "/" if $path eq "";
	return $path;
}

#-------------------------------------------------------------
#
sub root {

	my $arg = shift;
	my $pid = (ref($arg) ?  shift : $arg);

	my $path = Cwd::abs_path("/proc/$pid/root/.");

	# Previous to 5.005, Cwd::abs_path() returned ""
	# when it actually meant to return "/".  
	#
	return unless defined $path;
	return "/" if $path eq "";
	return $path;
}

#-------------------------------------------------------------
#
sub fd  { 

	my $arg = shift;
	my $pid = (ref($arg) ?  shift : $arg);
	my %retval;

	unless (opendir (DIR, "/proc/$pid/fd") ) {

		carp "Couldn't open directory /proc/$pid/fd : $!";
		return;
	}

	foreach ( grep /^\d+$/, readdir DIR ) {

		$retval{$_} = 
			-d "/proc/$pid/fd/$_"
				? Cwd::abs_path("/proc/$pid/fd/$_/.") 
				: ""
				; 
	}

	close (DIR);

	return \%retval;
}


#-------------------------------------------------------------
#
sub AUTOLOAD {

	my $arg = shift;
	my $pid = ref($arg) ? shift : $arg;

#-#	print STDERR (caller 0)[3], ": Want function $AUTOLOAD\n";

	if (exists $dispatcher->{$AUTOLOAD} ) {

		unless (defined $pid and $pid =~ /^\d+$/) {

			carp "$AUTOLOAD: Must specify pid as an integer";
			return;
		}

#-#		print STDERR (caller 0)[3], ": Delegating to function $AUTOLOAD\n";
		my $temp = &{ $dispatcher->{$AUTOLOAD} }($pid);
		return $temp;

	} else {
		carp ( 
			(caller 0)[3] .  
			": Attempt to invoke nonexistant function $AUTOLOAD\n" 
		);
		return;
	}
}


#-------------------------------------------------------------
package Solaris::Procfs::Process;
#-------------------------------------------------------------

use vars qw($VERSION @ISA $AUTOLOAD);
$VERSION = $Solaris::Procfs::VERSION;
@ISA = qw(Solaris::Procfs DynaLoader);

use Carp;

#-------------------------------------------------------------
#
sub new {

	my ($proto, $pid) = @_;
	my $class = ref($proto) || $proto;

#-#	print STDERR (caller 0)[3], ": Creating object for pid $pid\n";

	return unless defined $pid and $pid =~ /^\d+$/;

	my $self = {};
	tie  %$self, $class, $pid;
	bless $self, $class;
	return $self;     
}

#-------------------------------------------------------------
#
sub TIEHASH {

	my ($pkg,$pid) = @_;
	my $self = { pid => $pid };
#-#	print STDERR (caller 0)[3], ": \$self is $self, \$pkg is $pkg, \$pid is $pid\n";
	return (bless $self, $pkg);
}


#-------------------------------------------------------------
#
sub FETCH {

	my ($self, $index) = @_;
	return unless defined $index;

#-#	print STDERR (caller 0)[3], ": Read \$index $index, \$self->{pid} is $self->{pid}\n";

	if ($index eq "pid") {

#-#		print STDERR (caller 0)[3], ": Returning \$self->{$index} : $self->{$index}\n";
		return $self->{$index};

	} elsif ( -d "/proc/$self->{pid}" ) {

		if ( exists $self->{$index} ) {

#-#			print STDERR (caller 0)[3], ": Returning cached results\n";
			return $self->{$index};

		} elsif ( exists $dispatcher->{$index} ) {

#-#			print STDERR (caller 0)[3], ": Delegating to function\n";
			$self->{$index} = &{ $dispatcher->{$index} }( $self->{pid} ) ;
			return $self->{$index};

		} else {

#-#			print STDERR (caller 0)[3], ": No such function as $self->{$index}\n";
			return;  ## If the user requested a function not in Procfs
		}

	} else {   # if not -d "/proc/$self->{pid}" 
		
#-#		print STDERR (caller 0)[3], ": No such process as $self->{pid}\n";
		return;  ## If the process no longer exists under /proc
	}
}

#-------------------------------------------------------------
#
sub AUTOLOAD {

	my $self = shift;

#-#	print STDERR (caller 0)[3], ": Want function $AUTOLOAD\n";

	if (exists $dispatcher->{$AUTOLOAD} ) {

		unless (defined $self and ref($self) eq "Solaris::Procfs::Process") {

			# You can't call Solaris::Procfs::Process::psinfo
			# or any other function directly.  (Even though you can call
			# Solaris::Procfs::psinfo and friends.)
			#
			carp "$AUTOLOAD: Must be called as a method, not as a class function";
			return;
		}

#-#		print STDERR (caller 0)[3], ": Delegating to function $AUTOLOAD\n";
		my $temp = &{ $dispatcher->{$AUTOLOAD} }( $self->{pid} );
		return $temp;

	} else {
		carp ( 
			(caller 0)[3]  .  
			": Attempt to invoke nonexistant function $AUTOLOAD\n"
		);
		return;
	}
}


1;

__END__


=head1 NAME

Solaris::Procfs - access Solaris process information from Perl

=head1 SYNOPSIS

(See the EXAMPLES section below for more info.)

=head1 DESCRIPTION

This module is an interface the /proc filesystem 
on Solaris systems.

Each process on a Solaris system has a corresponding 
directory under /proc, named after the process id.  
In each of these directories are a series of files 
and subdirectories, which contain information about 
each process.  The proc(4) manpage gives complete details 
about these files.  Basically, the files contain one or 
more C structs with data about its corresponding process, 
maintained by the kernel.  

This module provides methods which access these files 
and convert the data structures contained in them 
into nested hashrefs.  This module has been tested 
on Solaris 2.6 and Solaris 7.  It will not work 
on Solaris 2.5.1 systems (yet). 

=head1 STATUS

This is pre-alpha software.  It is far from finished.  
Parts of it need extensive rewriting and testing.  
However, the core functionality does seem to work properly. 

Contributions and critiques would be warmly welcomed. 

This module has been tested on the following systems,
using gcc for builds:

	SunOS 5.7 (Solaris 7)   SPARC 
	SunOS 5.7 (Solaris 7)   x86
	SunOS 5.6 (Solaris 2.6) SPARC

It may not even build on other systems.


=head1 EXAMPLES

There are three different ways to invoke the functions in this module:
as object methods, as functions, or as a tied hash. 

As object methods:

	use Solaris::Procfs;
	my $p = new Solaris::Procfs;
	my $data = $p->psinfo($pid);

As functions:

	(not yet fully implemented)

As a tied hash:

	use Solaris::Procfs;
	my $p = new Solaris::Procfs;
	$p->{$pid}->{psinfo};

=head1 FUNCTIONS

This module defines functions which each correspond to 
the files available under the directories in /proc. 
Complete descriptions of these files are available
in the proc(4) manpage.  

Unless otherwise noted, the corresponding function in the 
Solaris::Procfs module simply returns the contents of the file 
in the form of a set of nested hashrefs.  Exceptions to this 
are listed below. 

These functions can also be accessed implcitly as elements 
in a tied hash.  When used this way, each process can be
accessed as if it were one giant Perl structure, containing
all the data related to that process id in the files
under /proc/{id}. 

=head2 as

Not yet implemented.  The 'as' file contains the address-space
image of the process. 

=head2 auxv

The 'auxv' file contains the initial values of the process's 
aux vector in an array of auxv_t structures (see <sys/auxv.h>). 

=head2 ctl

Not implemented.  The 'ctl' file is a write-only file to which 
structured messages are written directing the system to change 
some aspect of the process's state or control its behavior 
in some way. 

=head2 cwd

Returns a string containing the absolute path to
the process' current working directory.  The 'cwd' file
is a symbolic link to the process's current working directory. 

=head2 fd

Returns a hash whose keys are the process' open file descriptors,
and whose values are the absolute paths to the open files, as far 
as can be determined.  The 'fd' directory contains references 
to the open files of the process.  Each entry is a decimal number 
corresponding to an open file descriptor in the process. 

=head2 ldt

Not yet implemented.  The 'ldt' file exists only on x86 based machines. 
It is non-empty only if the process has established a local descriptor 
table (LDT).  If non-empty, the file contains the array of currently 
active LDT entries in an array of elements of type struct ssd, 
defined in <sys/sysi86.h>, one element for each active LDT entry.

=head2 lpsinfo

The 'lpsinfo' file contains a prheader structure followed by 
an array of lwpsinfo structures, one for each lwp in the process. 

=head2 lstatus

The 'lstatus' file contains a prheader structure followed 
by an array of lwpstatus structures, one for each lwp in the process. 

=head2 lusage

The 'lusage' file contains a prheader structure followed by an array  of
prusage structures, one for each lwp in the process plus an additional 
element at the beginning that contains the summation over all defunct lwps.

=head2 lwp

The 'lwp' directory contains entries each of which names 
an lwp within the process.  These entries are themselves 
directories containing additional files.  This function 
returns the contents of the files 'lwpstatus', 'lwpsinfo', 
and 'lwpusage', translated into a set of nested hashes.  
Interfaces to the files 'asrs', 'gwindoes', 'lwpctl' 
and 'xregs' have not been implemented. 

=head2 map

The 'map' file contains information about the virtual address map 
of the process.  The file contains an array of prmap structures, 
each of which describes a contiguous virtual address region 
in the address space of the traced process.  

=head2 object

Not yet implemented.  The 'object' directory containing read-only files 
with names corresponding to the entries in the map and pagedata files. 
Opening such a file yields a file descriptor for the underlying 
mapped file associated with an address-space mapping in the process.

=head2 pagedata

Not yet implemented.  Opening the 'pagedata' file enables tracking of 
address space references and modifications on a per-page basis. 

=head2 prcred

The 'prcred' file contains a description of the credentials 
associated with the process (UID, GID, etc.).

=head2 psinfo

The 'psinfo' file ontains miscellaneous information about the process 
and the representative lwp needed by the ps(1) command. 

=head2 status

The 'status' file ontains state information about the process and the
representative lwp.  

=head2 rmap

The 'rmap' file contains information about the reserved address 
ranges of the process.  Examples  of such reservations include 
the address ranges reserved for the process stack and the individual 
thread stacks of a multi-threaded process. 

=head2 root

Returns a string containing the absolute path to the process' root 
directory. The 'root' file is a symbolic link to the process' 
current working directory. 

=head2 sigact

The 'sigact' file contains an array of sigaction structures describing the
current dispositions of all signals associated with the
traced process (see sigaction(2)).

=head2 usage      

The 'usage' file contains process usage information 
described by a prusage structure. 

=head2 watch

Not yet implemented.  The 'watch' file contains an array of 
prwatch structures, one for each watched area established 
by the PCWATCH control operation. 

=head1 CHANGES

=over 4

=item * Version 0.10

	Initial release on CPAN

=back

=head1 TO DO

=over

=item *

Improve the documentation, test scripts and 
sample scripts.

=item *

Finish writing the Perl interface functions in Procfs.pm. 

=item *

Add functions which can read the 'as' file.  

=item *

Implement Perl functions which correspond to each of
the procutils binaries (under /usr/proc/bin).
These are described in the proc(1) manpage. 

=item *

Add support for Solaris 8, and make sure that this 
package will build properly on a variety of recent
Solaris flavors.

=item *

Add support for Solaris 2.5.1.  This will require 
a good bit of work, as the /proc filesystem is 
rather different under Solaris 2.5.1.   This item is
low on the priority list. 

=back

=head1 THANKS

Much of this code is modeled after code written by Alan Burlison, 
and I received some helpful and timely advice from Tye McQueen.  

Thanks to Daniel J. Urist for writing Proc::ProcessTable.
I used his method for keeping track of TTY numbers. 

=head1 AUTHOR

John Nolan jpnolan@sonic.net 1999, 2000.  
A copyright statment is contained in the source code itself. 

=cut

1;
