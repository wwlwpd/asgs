#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long qw(GetOptionsFromArray);
use Cwd qw(getcwd);

package Makefile;

use constant EXIT_SUCCESS => 0;

# copy existing environment
local %ENV = %ENV;
our $affected_ENVs = {};

exit __PACKAGE__->run( \@ARGV // [] ) if not caller;

sub run {
    my ( $self, $args_ref ) = @_;
    my $HOME     = ( getpwuid $> )[7];
    my $opts_ref = {
        compiler     => q{gfortran},
        install_path => qq{$HOME/opt},
        home         => $HOME,
    };
    my $ret = Getopt::Long::GetOptionsFromArray(
        $args_ref,
        $opts_ref,
        q{clean},
        q{compiler=s},
        q{dump-env},
        q{home},
        q{machinename=s},
        q{o|output_file=s} => \$opts_ref->{output_file},
        q{path=s},
    );

# TODO - use Validate::Tiny to validate options
    die                           if not $ret;

    my $start_dir = Cwd::getcwd();

    if ( $opts_ref->{output_file} ) {

        # touch, truncate
        open my $fh, q{>}, $opts_ref->{output_file} || die $!;
        close $fh;

        # reminder with helper command to view progress
        print qq{To see progress, use command:\n\ttail -f $opts_ref->{output_file}\n};
    }

  RUN_STEPS:
    foreach my $op ( @{ $self->get_steps($opts_ref) } ) {
        print $op->{name} . qq{\n};
        chdir $op->{pwd};

        # augment ENV based on $op->{export_ENV}
        $self->_setup_ENV( $op, $opts_ref );

        # precondition checking needs to be more robust and more clearly
        # defined (i.e., what to do on failure for subsequent runs
        # check is skipped if --clean or --dump-env is passed
        if ( not $self->run_precondition_check ) {
           die qq{pre condition for "$op->{name}" FAILED, stopping. Please fix and rerun.\n};
        }

        # run command or clean_command (looks for --clean and --dump-env)
        local $@;
        my $ok = eval { $self->_run_command( $op, $opts_ref ) };

        # verify step completed successfully
        # check is skipped if --clean is passed
        if ( $self->run_postcondition_check( $op, $opts_ref ) ) {
            print qq{"$op->{name}" was completed successfully\n};
        }
        else {
            die qq{post condition for "$op->{name}" FAILED, stopping. Please fix and rerun.\n};
        }
        chdir $start_dir;
    }

  FINALIZE:
    $self->_print_summary($opts_ref);

    return EXIT_SUCCESS;
}

sub run_precondition_check {
    my ( $self, $op, $opts_ref ) = @_;

    # skips check if --clean or precondition check doesn't exist in step's definition
    return 1 if $opts_ref->{'dump-env'} or $opts_ref->{clean} or not $op->{precondition_check} or $op->{precondition_check}->( $op, $opts_ref );
    return undef;
}

sub run_postcondition_check {
    my ( $self, $op, $opts_ref ) = @_;

    # skips check if --clean or postcondition check doesn't exist in step's definition
    return 1 if $opts_ref->{'dump-env'} or $opts_ref->{clean} or not $op->{postcondition_check} or $op->{postcondition_check}->( $op, $opts_ref );
    return undef;
}

sub _run_command {
    my ( $self, $op, $opts_ref ) = @_;
    my $compiler     = $opts_ref->{compiler};
    my $install_path = $opts_ref->{path};

    return 1 if $opts_ref->{'dump-env'};

    # choose command to run
    my $command = ( not $opts_ref->{clean} ) ? $op->{command} : $op->{clean_command};

    local $| = 1;

    # run command, use output capture option
    if ( $opts_ref->{output_file} ) {

        # open for appending
        open my $fh, q{>>}, $opts_ref->{output_file} || die $!;
        print $fh qq{$command\n};
        print $fh `$command > $opts_ref->{output_file} 2>&1`;
    }
    else {
        print qq{$command\n};
        print `$command 2>&1`;
    }

    return 1;
}

sub _print_summary {
    my ( $self, $opts_ref ) = @_;
    return 1 if $opts_ref->{clean};
    print q{-} x 45 . qq{\nSummary of updated environmental variables (these need to be added to ~/.bash_profile or similar):\n\n};
    foreach my $envar ( keys %$affected_ENVs ) {
        printf( qq{export %s=%s\n}, $envar, $ENV{$envar} );
    }
    return 1;
}

sub _setup_ENV {
    my ( $self, $op, $opts_ref ) = @_;
    my $install_path = $opts_ref->{path};
  SETUP_ENV:
    foreach my $envar ( keys %{ $op->{export_ENV} } ) {
        ++$affected_ENVs->{$envar};    # track all environmental variables that are touched
        if ( $ENV{$envar} and not $op->{export_ENV}->{$envar}->{replace} ) {

            # prepend
            my $s = $op->{export_ENV}->{$envar}->{separator};
            $ENV{$envar} = $op->{export_ENV}->{$envar}->{value} . qq{$s} . $ENV{$envar};
        }
        else {
            # replace
            $ENV{$envar} = $op->{export_ENV}->{$envar}->{value};
        }
    }
    return 1;
}

# note, user's environment is available via %ENV
sub get_steps {
    my ( $self, $opts_ref ) = @_;
    my $install_path = $opts_ref->{path};
    my $compiler     = $opts_ref->{compiler};
    my $machinename  = $opts_ref->{machinename};
    return [
        {
            name          => q{NetCDF, HDF5 libraries and utilities},
            pwd           => q{./install},
            command       => qq{echo hi && install-hdf5-netcdf4.sh $install_path $compiler},
            clean_command => qq{install-hdf5-netcdf4.sh $install_path clean},
            # augment existing %ENV
            export_ENV    => {
                LD_LIBRARY_PATH => { value => qq{$install_path/lib},       separator => q{:} },
                LD_INCLUDE_PATH => { value => qq{$install_path/lib},       separator => q{:} },
                PATH            => { value => qq{$install_path/bin},       separator => q{:} },
                CPPFLAGS        => { value => qq{-I$install_path/include}, separator => q{ }, replace => 1 },
                LDFLAGS         => { value => qq{-L$install_path/lib},     separator => q{ }, replace => 1 },
            },
            precondition_check  => sub { 1 },    # must eval to true to proceed
            postcondition_check => sub {
                my ( $op, $install_path ) = @_;
                my $b = qq{$install_path/bin};
                return -e qq{$b/h5diff} && -e qq{$b/nc-config} && -e qq{$b/nf-config};
            },
            descriptions => q{Downloads and builds the versions of HDF5 and NetCDF that have been tested to work on all platforms for ASGS.},
        },
        {
            name                => q{wgrib2},
            pwd                 => q{./},
            command             => qq{make NETCDFPATH=$install_path NETCDF=enable NETCDF4=enable NETCDF4_COMPRESSION=enable MACHINENAME=$machinename compiler=gfortran},
            clean_command       => q{make clean},
            precondition_check  => sub { 1 },
            postcondition_check => sub { my ( $op, $opts_ref ) = @_; return -e qq{./wgrib2}; },
            descriptions        => q{Downloads and builds wgrib2 on all platforms for ASGS. Note: gfortran is required, so any compiler option passed is overridden.},
        },
        {
            name                => q{output/cpra_postproc},
            pwd                 => q{./output/cpra_postproc},
            command             => qq{make NETCDFPATH=$install_path NETCDF=enable NETCDF4=enable NETCDF4_COMPRESSION=enable MACHINENAME=$machinename compiler=$compiler},
            clean_command       => q{make clean},
            precondition_check  => sub { 1 },
            postcondition_check => sub { my ( $op, $opts_ref ) = @_; return -e qq{./FigureGen}; },
            descriptions        => q{Runs the makefile and builds associated utilities in the output/cpra_postproc directory},
        },
        {
            name                => q{output},
            pwd                 => q{./output},
            command             => qq{make NETCDFPATH=$install_path NETCDF=enable NETCDF4=enable NETCDF4_COMPRESSION=enable MACHINENAME=$machinename compiler=$compiler},
            clean_command       => q{make clean},
            precondition_check  => sub { 1 },
            postcondition_check => sub { my ( $op, $opts_ref ) = @_; return -e qq{./netcdf2adcirc.x}; },
            descriptions        => q{Runs the makefile and builds all associated utilities in the output/ directory.},
        },
        {
            name                => q{util},
            pwd                 => q{./util},
            command             => qq{make -f makefile NETCDFPATH=$install_path NETCDF=enable NETCDF4=enable NETCDF4_COMPRESSION=enable MACHINENAME=$machinename compiler=$compiler},
            clean_command       => q{make clean},
            precondition_check  => sub { 1 },
            postcondition_check => sub { my ( $op, $opts_ref ) = @_; return -e qq{./makeMax.x}; },
            descriptions        => q{Runs the makefile and builds associated utilities in the util/ directory.},
        },
        {
            name                => q{util/input/mesh},
            pwd                 => qq{./util/input/mesh},
            command             => qq{make NETCDFPATH=$install_path NETCDF=enable NETCDF4=enable NETCDF4_COMPRESSION=enable MACHINENAME=$machinename compiler=$compiler},
            clean_command       => q{make clean},
            precondition_check  => sub { 1 },
            postcondition_check => sub { my ( $op, $opts_ref ) = @_; return -e qq{./boundaryFinder.x}; },
            descriptions        => q{Runs the makefile and builds associated utilities in the util/input/mesh directory.},
        },
        {
            name                => q{util/input/nodalattr},
            pwd                 => q{./util/input/nodalattr},
            command             => qq{make NETCDFPATH=$install_path NETCDF=enable NETCDF4=enable NETCDF4_COMPRESSION=enable MACHINENAME=$machinename compiler=$compiler},
            clean_command       => q{make clean},
            precondition_check  => sub { 1 },
            postcondition_check => sub { my ( $op, $opts_ref ) = @_; return -e qq{./convertna.x}; },
            descriptions        => q{Runs the makefile and builds associated utilities in the util/input/nodalattr directory.},
        },
    ];
}

1;

__END__

=head1 NAME

Makefile.pl

=head1 DESCRIPTION

This script is handles building all necessary utilities that are required for a functioning
ASGS environment. It can be extended by registering makefiles, scripts, or pure commands in
the C<get_steps> subroutine. Steps are processed in the order that they appear.

=head1 SYNOPSIS

Options generally reflect those values that are passed on to the various makefiles:

    ./Makefile.pl --path /some/path --machinename <MachineName> --compiler <SomeCompiler> [--home /path/other/than/user/$HOME -o path/to/save/output]

There is also a "clean" mode that will invoke the C<clean_command> for any step that defines it:

    ./Makefile.pl --clean

=head1 OPTIONS

Options translate loosely to the options that are required directly in the commands that each
step requires, and they can be added quite easily to accomodate new pieces of information.
Below is a summary of what's been added so far.

=over 3

=item C<--clean>

For each step, only the C<clean_command> (if defined) is run and then the script quits. The
purpose of this is to provide access to the the C<clean> target that makefiles generally
provide, but any command can be specificed in the step definition.

=item C<--compiler>

This option allows one to define the compiler family or group, as it is typically passed to
makefiles used by ASGS. The two most common values for this flag are going to be C<gfortran>
and C<intel>.  The step is not required to use this value. It is merely passed along so that
the C<command> string may have access to the value if it is needed.

=item C<--home>

The default is set to the effective user's actual home directory, which is the value that the
environmental variable $HOME is typically assigned. As with the C<--compiler> flag, this value
may or may not be used to define some part of a step.

=item C<--machinename>

This option allows one to define the C<machine> name, which is a common value that is used in
typical ASGS makefiles. It is made available for use when defining a step.

=item C<-o>

By default, the STDOUT and STDERR of a step's C<command> is sent to STDOUT. This default
provides a typical experience that one has as they watch the actions of a script or makefile
print to the foreground of an interactive session. Setting C<-o> and defining a path to a
file will instead write all resulting output of the steps' commands to the file specified.

=back

=head1 ENVIRONMENT AND CONFIGURATION

When a Perl script is executed, it stores the user's environmental variables (e.g., the
output of the C<env> command) into a global hash, %ENV. This script makes a local copy
of that hash so that it may use and modify it as each step requires.  Each step may define
a set of environmental variables it wishes to set and make available for subsequent
steps. Once %ENV is updated, all subsequent perl commands and spawned subshells will
have access to the modified %ENV. For example, when a Perl script runs a system command
using the backticks (e.g., `some command from the shell`), the environmental variables
and their values are governed by the %ENV global variable.

When a step builds a library that is a dependency for subsequent steps, it is a good
idea to leverage the C<export_ENV> key for each step to define the variable and what
it's new value should be.

A good example is the step that builds the NETCDF and HDF5 libraries, utlized extensively
by any utility that must read or modify ADCIRC output files, hot start files, or
external forcing data. Therefore, before the step is executed, the following variables
are updated in %ENV:

=over 3

=item LD_LIBRARY_PATH

=item LD_INCLUDE_PATH

=item PATH           

=item CPPFLAGS       

=item LDFLAGS        

=back

=head2 Exporting The Environment

Makefile.pl doesn't automatically update the user's environment as it exists after
all steps have been run successfully. Since there is the ability to export environmental
variables in each step (available for the current and subsequent steps), it might be desired
to be able to recreate this post-run.  To get a dump of the variables set, how they are
set, one may use the C<dump-env> option. Adding this to the set of options provided at
build time will produce the update variables as they appear at the end of a fully successful
running of all steps. 

=head1 ADDING AND MANAGING STEPS 

When adding a new step, it is important to consider where in the order of steps
it should appear. If it's a library used by many utilities (e.g., NetCDF or HDF5),
additional care must be made when specifying the step - in particular the
environmental variables that is standard for compilers utilize, such as C<LD_INCLUDE_PATH>
or C<LD_LIBRARY_PATH>.

The defined C<keys> to define when adding a step are as follow,

=over 3

=item C<name>

Short name for the step, doesn't have to be unique across steps and runs, but it's good
to make sure that the name is short and informative.

=item C<pwd>

The directory specified is the one from where the step's C<command> should be run.

=item C<command>

This is the primary command is run in the current step unless the C<--clean> flag
is specified. Options are passed from the commandline of Makefile.pl to the C<$opts_ref>
hash reference by using the C<Getops::Long> options definition in the C<run> subroutine.
Options can be added easily to the arguments list of Makefile.pl, but the general rule
of thumb should be that the options be kept to a minimum. Most of the complexity associated
with a step should be hidden within the step's makefile, script, or program supporting
the command.

=item C<clean_command> 

Defines the command used to C<clean> a directory tree.

=item C<postcondition_check> 

If this method is private, it is run after C<command>. If it fails, then appropriate.

=item C<precondition_check>

If this method is private, it is run before C<command>. If it fails, then appropriate
action should be taken to fix that.

=back

=head2 A Note about Interdependency Among Steps

This script has no means of enforcing dependency among scripts, but this can be added
if needed in the future. The steps are executed serially, but there is no limit to the
concurrency that each individiual step can have - for example, C<make> is very good at
concurrently running independent portions of the makefile if it is set up correctly
(and by using the C<-j> option).

It is assumed that each step MUST complete successfully, and this is why there is a
C<postcondition_check> method that can be customized to ensure that the expected
state after the step is complete has been satisfied. Failure of this method at any
step will result in the script stopping.  Similarly, each step is able to also define
a C<precondition_check> that also must be evaluate positively if the step itself is
to be attempted.
