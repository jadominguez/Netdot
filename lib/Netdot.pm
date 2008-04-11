package Netdot;

use strict;
use warnings;

use Netdot::Meta;
use Netdot::Config;
use Netdot::Util::Log;
use Netdot::Util::Exception;
use Carp;
use Data::Dumper;

my $class = {};
$class->{_config} = Netdot::Config->new();
$class->{_meta}   = Netdot::Meta->new();
$class->{_log}    = Netdot::Util::Log->new(config => $class->{_config}->get('LOG_OPTIONS'));

my $IPV4 = '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}';
my $IPV6 = '(^([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}){1})|::'; # This is not strictly correct
my $HOCT = '[0-9A-Fa-f]{2}';
my $MAC  = "$HOCT\[.:-\]?$HOCT\[.:-\]?$HOCT\[.:-\]?$HOCT\[.:-\]?$HOCT\[.:-\]?$HOCT";
    
# Be sure to return 1
1;

=head1 NAME

Netdot - Network Documentation Tool

=head1 VERSION

Version 0.8

=cut

our $VERSION = "0.8";

=head1 SYNOPSIS

This module groups common functions used by Netdot\'s classes.
    
=head1 METHODS

=head2 meta - Get Netdot::Meta object

=cut
sub meta   { return $class->{_meta}  }

=head2 config - Get Netdot::Config object
=cut
sub config { return $class->{_config} }

=head2 log - Get Netdot::Util::Log object
=cut
sub log { return $class->{_log} }

sub throw_user {
    my $self = shift;
    my $logger = $class->{_log}->get_logger('Netdot');
    $logger->error( @_ );
    return Netdot::Util::Exception::User->throw(message=>@_);
}

sub throw_fatal {
    my $self = shift;
    my $logger = $class->{_log}->get_logger('Netdot');
    $logger->fatal( @_ );
    return Netdot::Util::Exception::Fatal->throw(message=>@_);
}

sub isa_class_method {
    my ($class, $method) = @_;
    if ( my $classname = ref($class) ){
	__PACKAGE__->throw_fatal("Invalid object method call to ".$classname."::".$method);
    }
    return 1;
}
sub isa_object_method {
    my ($self, $method) = @_;
    __PACKAGE__->throw_fatal("Invalid class method call to ".$self."::".$method)
	unless ref($self);
    return 1;
}
sub isa_netdot_exception {
    my $self = shift;
    return Netdot::Util::Exception->isa_netdot_exception(@_);
}

sub Dump { return Dumper(@_) };

sub get_ipv4_regex { return $IPV4 }

sub get_ipv6_regex { return $IPV6 }

sub get_mac_regex { return $MAC }

######################################################################
=head2 sec2dhms - Translate seconds into days, minutes, hours, seconds
	
   Arguments: 
     Integer (seconds)
   Returns:
    String like "0:0:41:40"
   Example:
    print Netdot->sec2dhms($seconds);
=cut   
sub sec2dhms {
    my ($self, $seconds) = @_;
    my @parts = gmtime($seconds);
    my @l;
    push @l, sprintf("%d days",  $parts[7]) if ( $parts[7] ); 
    push @l, sprintf("%d hours", $parts[2]) if ( $parts[2] ); 
    push @l, sprintf("%d min",   $parts[1]) if ( $parts[1] ); 
    push @l, sprintf("%d sec",   $parts[0]);
    my $string = join ', ', @l;
    return $string;
}

######################################################################
=head2 send_mail - Send mail to desired destination

    Useful to e-mail output from automatic processes

    Arguments (hash):
    - to      : destination email (defaults to NOCEMAIL from config file)
    - from    : orignin email (defaults to ADMINEMAIL from config file)
    - subject : subject of message
    - body    : body of message

    Returns true/false for success/failure

=cut
sub send_mail {
    my ($self, %args) = @_;
    my ($to, $from, $subject, $body) = 	@args{'to', 'from', 'subject', 'body'};
    
    my $SENDMAIL = $self->config->get('SENDMAIL');
    
    $to    ||= $self->config->get('NOCEMAIL');
    $from  ||= $self->config->get('ADMINEMAIL');
    
    if ( !open(SENDMAIL, "|$SENDMAIL -oi -t") ){
        $self->throw_fatal("send_mail: Can't fork for $SENDMAIL: $!");
    }

    print SENDMAIL <<EOF;
From: $from
To: $to
Subject: $subject
    
$body
    
EOF

close(SENDMAIL);
    return 1;

}

=head1 AUTHOR

Carlos Vicente, C<< <cvicente at ns.uoregon.edu> >>

=head1 BUGS

Please report any bugs or feature requests to
C<netdot-devel at ns.uoregon.edu>, or through the web interface at
L<http://netdot.uoregon.edu>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Netdot

You can also look for information at:

=over 4

=item * Netdot mailing lists

=back

L<http://ns.uoregon.edu/mailman/netdot-users>


=head1 ACKNOWLEDGEMENTS

The Network Services group at the University of Oregon and multiple other contributors.

=head1 COPYRIGHT & LICENSE

Copyright 2006 University of Oregon, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software Foundation,
Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=cut
