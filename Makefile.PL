use ExtUtils::MakeMaker;
use POSIX qw(uname);

# Check this is a supported OS release
my ($sys, $rel) = (POSIX::uname())[0,2];
if ($sys ne "SunOS" || $rel !~ /^(5.6|5.7)$/)
   {
   die("Solaris:: is only supported on Solaris 2.6 & 2.7\n");
   }

WriteMakefile(
   NAME         => 'Solaris',
   VERSION      => '0.14',
   DIR          => [ 'Procfs' ],
#   EXE_FILES    => [ 'scripts/scr' ],
);
