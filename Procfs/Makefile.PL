use ExtUtils::MakeMaker;
use Config;
use POSIX qw(uname);

# Check this is a supported OS release
my ($sys, $rel) = (POSIX::uname())[0,2];
if ($sys ne "SunOS" || $rel !~ /^(5.5.1|5.6|5.7)$/)
   {
   die("Solaris::Procfs is only supported on Solaris 2.5.1, 2.6 & 2.7\n");
   }


# Apparently gcc doesn't set the OS rel/ver macro, so we'll do it here
if ($Config{cc} =~ /gcc/)
   {
   if    ($rel eq "5.5.1") { $def .= "-D__SunOS_5_5_1 "; }
   elsif ($rel eq "5.6")   { $def .= "-D__SunOS_5_6 ";   }
   elsif ($rel eq "5.7")   { $def .= "-D__SunOS_5_7 ";   }
   }


# The procfs.h header file requires that file_offset_bits be
# set to 32 rather than 64. 
#
$def .= "-D_FILE_OFFSET_BITS=32 ";


WriteMakefile(
   NAME         => 'Solaris::Procfs',
   VERSION_FROM => 'Procfs.pm',
   LIBS         => [ '' ],
   INC          => '-Iinclude',
   OBJECT       => '$(O_FILES)',
   DEFINE       => $def,
  );
