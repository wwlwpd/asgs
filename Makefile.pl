#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long qw(GetOptionsFromArray);

package Makefile;

use constant EXIT_SUCCESS => 0;

# copy existing environment
local %ENV = %ENV;
my $HOME = ( getpwuid $> )[7];

exit __PACKAGE__->run( \@ARGV // [] ) if not caller;

sub get_steps {
    return [
        {
            name       => q{Build NETCDF and HDF5},
            pwd        => q{./install},
            command    => q{install-hdf5-netcdf4.sh %s},    # %s is the install path argument
            export_ENV => {
                LD_LIBRARY_PATH => { value => q{%s/lib},       separator => q{:} },
                LD_INCLUDE_PATH => { value => q{%s/lib},       separator => q{:} },
                PATH            => { value => q{%s/bin},       separator => q{:} },
                CPPFLAGS        => { value => q{-I%s/include}, separator => q{ }, overwrite => 1 },
                LDFLAGS         => { value => q{-L%s/lib},     separator => q{ }, overwrite => 1 },
            },
            depends_check  => sub { 1 },                    # must eval to true to proceed
            verify_success => sub {
                my ( $op, $install_path ) = @_;
                my $b = qq{$install_path/bin};
                return -e qq{$b/h5diff} && -e qq{$b/nc-config} && -e qq{$b/nf-config};
            },
        }
    ];
}

sub run {
    my ( $self, $args_ref ) = @_;
    my $install_path = qq{$HOME/opt};
    my $compiler     = q{gfortran};
    my $ret          = Getopt::Long::GetOptionsFromArray(
        $args_ref,
        q{c|compiler=s} => \$compiler,
        q{p|path=s}     => \$install_path,
    );
    foreach my $op ( @{ $self->get_steps() } ) {
        print $op->{name} . qq{\n};
        chdir $op->{pwd};

        # augment ENV based on $op->{export_ENV}
        $self->_setup_ENV( $op, $install_path );

        # run command
        $self->_run_command( $op, $install_path );

        # verify step completed successfully
        print qq{step successful\n} if $self->_run_verification( $op, $install_path );
    }

    return EXIT_SUCCESS;
}

sub _run_verification {
    my ( $self, $op, $install_path ) = @_;
    return 1 if $op->{verify_success}->($op, $install_path);
    return undef;
}

sub _run_command {
    my ( $self, $op, $install_path ) = @_;
    my $command = sprintf( $op->{command}, $install_path );
    print qq{$command\n};
    local $| = 1;
    `$command > $HOME/test.out 2>&1`;
    return 1;
}

sub _setup_ENV {
    my ( $self, $op, $install_path ) = shift;
  SETUP_ENV:
    foreach my $envar ( keys %{ $op->{export_ENV} } ) {
        if ( $ENV{$envar} and not $op->{export_ENV}->{$envar}->{overwrite} ) {

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

1;

__END__
