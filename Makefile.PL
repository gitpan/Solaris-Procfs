use ExtUtils::MakeMaker;
use POSIX qw(uname);

# Check this is a supported OS release
my ($sys, $rel) = (POSIX::uname())[0,2];

if ($sys ne "SunOS" || $rel !~ /^(5.6|5.7|5.8)$/) {

   die("Solaris::Procfs is only supported on Solaris 2.6, 7 and 8\n");
}

WriteMakefile(
   NAME         => 'Solaris',
   VERSION      => '0.20',
   DIR          => [ 'Procfs' ],
#  EXE_FILES    => [ 'Procfs/flags.pl' ],
);
