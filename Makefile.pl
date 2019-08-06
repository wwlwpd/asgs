#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long qw(GetOptionsFromArray);
use Cwd qw(getcwd);

package Makefile;

use constant EXIT_SUCCESS => 0;

# copy existing environment
local %ENV = %ENV;

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
        q{home},
        q{machinename=s},
        q{o|output_file=s} => \$opts_ref->{output_file},
        q{path=s},
    );

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
        if (not $self->run_precondition_check) {
          print qq{precondition for "$op->{name}" FAILED, stopping. Please fix and rerun.\n};
        }

        # run command or clean_command (looks for --clean)
        local $@;
        my $ok = eval { $self->_run_command( $op, $opts_ref ) };

        # verify step completed successfully
        if ( $self->run_postcondition_check( $op, $opts_ref ) ) {
          print qq{"$op->{name}" was completed successfully\n};
        }
        else {
          print qq{postcondition for "$op->{name}" FAILED, stopping. Please fix and rerun.\n};
        }
        chdir $start_dir;
    }

    return EXIT_SUCCESS;
}

sub run_precondition_check {
    my ( $self, $op, $opts_ref ) = @_;
    # skips check if --clean or precondition check doesn't exist in step's definition
    return 1 if $opts_ref->{clean} or not $op->{precondition_check} or $op->{precondition_check}->( $op, $opts_ref );
    return undef;
}

sub run_postcondition_check {
    my ( $self, $op, $opts_ref ) = @_;
    # skips check if --clean or postcondition check doesn't exist in step's definition
    return 1 if $opts_ref->{clean} or not $op->{postcondition_check} or $op->{postcondition_check}->( $op, $opts_ref );
    return undef;
}

sub _run_command {
    my ( $self, $op, $opts_ref ) = @_;
    my $compiler     = $opts_ref->{compiler};
    my $install_path = $opts_ref->{install_path};

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

sub _setup_ENV {
    my ( $self, $op, $opts_ref ) = @_;
    my $install_path = $opts_ref->{install_path};
  SETUP_ENV:
    foreach my $envar ( keys %{ $op->{export_ENV} } ) {
        if ( $ENV{$envar} and not $op->{export_ENV}->{$envar}->{replace} ) {

            # prepend
            my $s = $op->{export_ENV}->{$envar}->{separator};
            $ENV{$envar} = sprintf( $op->{export_ENV}->{$envar}->{value}, $install_path ) . qq{$s} . $ENV{$envar};
        }
        else {
            # add anew
            $ENV{$envar} = sprintf( $op->{export_ENV}->{$envar}->{value}, $install_path );
        }
    }
    return 1;
}

sub get_steps {
    my ( $self, $opts_ref ) = @_;
    my $install_path = $opts_ref->{install_path};
    my $compiler     = $opts_ref->{compiler};
    my $machinename  = $opts_ref->{machinename};
    return [
        {
            name          => q{Build NETCDF and HDF5},
            pwd           => q{./install},
            command       => qq{install-hdf5-netcdf4.sh $install_path $compiler},    # %s is the install path argument
            clean_command => q{install-hdf5-netcdf4.sh clean},
            export_ENV    => {
                LD_LIBRARY_PATH => { value => q{%s/lib},       separator => q{:} },
                LD_INCLUDE_PATH => { value => q{%s/lib},       separator => q{:} },
                PATH            => { value => q{%s/bin},       separator => q{:} },
                CPPFLAGS        => { value => q{-I%s/include}, separator => q{ }, replace => 1 },
                LDFLAGS         => { value => q{-L%s/lib},     separator => q{ }, replace => 1 },
            },
            precondition_check  => sub { 1 },                                       # must eval to true to proceed
            postcondition_check => sub {
                my ( $op, $install_path ) = @_;
                my $b = qq{$install_path/bin};
                return -e qq{$b/h5diff} && -e qq{$b/nc-config} && -e qq{$b/nf-config};
            },
            descriptions => q{Downloads and builds the versions of HDF5 and NetCDF that have been tested to work on all platforms for ASGS.},
        },
        {
            name                 => q{wgrib2},
            pwd                  => q{./},
            command              => qq{make NETCDFPATH=$install_path NETCDF=enable NETCDF4=enable NETCDF4_COMPRESSION=enable MACHINENAME=$machinename compiler=gfortran},
            clean_command        => q{make clean},
            precondition_check  => sub { 1 },
            postcondition_check => sub { my ( $op, $opts_ref ) = @_; return -e qq{./wgrib2}; },
            descriptions         => q{Downloads and builds wgrib2 on all platforms for ASGS. Note: gfortran is required, so any compiler option passed is overridden.},
        },
        {
            name                 => q{output/cpra_postproc},
            pwd                  => q{./output/cpra_postproc},
            command              => qq{make NETCDFPATH=$install_path NETCDF=enable NETCDF4=enable NETCDF4_COMPRESSION=enable MACHINENAME=$machinename compiler=$compiler},
            clean_command        => q{make clean},
            precondition_check  => sub { 1 },
            postcondition_check => sub { my ( $op, $opts_ref ) = @_; return -e qq{./FigureGen}; },
            descriptions         => q{Runs the makefile and builds associated utilities in the output/cpra_postproc directory},
        },
        {
            name                 => q{output},
            pwd                  => q{./output},
            command              => qq{make NETCDFPATH=$install_path NETCDF=enable NETCDF4=enable NETCDF4_COMPRESSION=enable MACHINENAME=$machinename compiler=$compiler},
            clean_command        => q{make clean},
            precondition_check  => sub { 1 },
            postcondition_check => sub { my ( $op, $opts_ref ) = @_; return -e qq{./netcdf2adcirc.x}; },
            descriptions         => q{Runs the makefile and builds all associated utilities in the output/ directory.},
        },
        {
            name                 => q{util},
            pwd                  => q{./util},
            command              => qq{make -f makefile NETCDFPATH=$install_path NETCDF=enable NETCDF4=enable NETCDF4_COMPRESSION=enable MACHINENAME=$machinename compiler=$compiler},
            clean_command        => q{make clean},
            precondition_check  => sub { 1 },
            postcondition_check => sub { my ( $op, $opts_ref ) = @_; return -e qq{./makeMax.x}; },
            descriptions         => q{Runs the makefile and builds associated utilities in the util/ directory.},
        },
        {
            name                 => q{util/input/mesh},
            pwd                  => qq{./util/input/mesh},
            command              => qq{make NETCDFPATH=$install_path NETCDF=enable NETCDF4=enable NETCDF4_COMPRESSION=enable MACHINENAME=$machinename compiler=$compiler},
            clean_command        => q{make clean},
            precondition_check  => sub { 1 },
            postcondition_check => sub { my ( $op, $opts_ref ) = @_; return -e qq{./boundaryFinder.x}; },
            descriptions         => q{Runs the makefile and builds associated utilities in the util/input/mesh directory.},
        },
        {
            name                 => q{util/input/nodalattr},
            pwd                  => q{./util/input/nodalattr},
            command              => qq{make NETCDFPATH=$install_path NETCDF=enable NETCDF4=enable NETCDF4_COMPRESSION=enable MACHINENAME=$machinename compiler=$compiler},
            clean_command        => q{make clean},
            precondition_check  => sub { 1 },
            postcondition_check => sub { my ( $op, $opts_ref ) = @_; return -e qq{./convertna.x}; },
            descriptions         => q{Runs the makefile and builds associated utilities in the util/input/nodalattr directory.},
        },
    ];
}

1;

__END__

=head1 NAME

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 OPTIONS

=head1 ENVIRONMENT AND CONFIGURATION

=head1 BUGS

