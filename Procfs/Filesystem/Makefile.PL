use ExtUtils::MakeMaker;
use Config;
use POSIX qw(uname);

# Check this is a supported OS release
my ($sys, $rel) = (POSIX::uname())[0,2];
if ($sys ne "SunOS" || $rel !~ /^(5.5.1|5.6|5.7)$/)
   {
   die("Solaris::Procfs::Process is only supported on Solaris 2.5.1, 2.6 & 2.7\n");
   }


WriteMakefile(
   NAME         => 'Solaris::Procfs::Filesystem',
   VERSION_FROM => 'Filesystem.pm',
);
