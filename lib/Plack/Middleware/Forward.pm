package Plack::Middleware::Forward;
use strict;
use warnings;
our $VERSION = '0.01';

use Plack::Request;
use Plack::Util qw/TRUE FALSE/;
use Plack::Util::Accessor qw/allow deny/;

use Scalar::Util;

sub prepare_app {
    my $self = shift;

    open(my $dummy_io, '<', \q{});
    $self->{'dummy.psgi.input'} = $dummy_io;

    $self->allow->{Response}[0] ||= 302 if(exists $self->allow->{Response});
    $self->{forward_status}       = $self->allow->{Response}[0];
}

sub call {
    my($self, $env) = @_;

    return $self->is_allow_forward(env => $env) ?
        $self->exec_with_forward($env):
        $self->app->($env);
}

sub exec_with_forward {    
    my($self, $env) = @_;

    my $res = $self->app->($env);

    return $self->is_allow_forward(res => $res) ?
        $self->forward($env, $res):
        $res;
}

sub forward {    
    my($self, $env, $res) = @_;
    
    my $old_path_info = $env->{PATH_INFO};
    my $new_path_info = Plack::Util::header_get($res->[1], 'Location');
    my($path, $query) = split /\?/, $new_path_info, 2;

    Scalar::Util::weaken($env);

    $env->{PATH_INFO}      = $path;
    $env->{QUERY_STRING}   = $query;
    $env->{REQUEST_METHOD} = 'GET';
    $env->{CONTENT_LENGTH} = 0;
    $env->{CONTENT_TYPE}   = '';
    $env->{'psgi.input'}   = $self->{'dummy.psgi.input'};
    push @{$env->{'plack.forward.old_path_info'}}, $old_path_info;
 
    $self->exec_with_forward($env);
}

sub is_allow_forward {
    my($self, %args) = @_;

    if ( exists $args{env} and exists $self->allow->{Request} ) {
        
        my $req = Plack::Request->new($args{env});
        
    }
    if ( exists $args{res} and exists $self->allow->{Request} ) {
        my $res = $args{res};

        return FALSE if($res->[0] != $self->{forward_status});
    }
}


1;
__END__

=head1 NAME

Plack::Middleware::Forward -

=head1 SYNOPSIS

  use Plack::Bulider;

  builder {
      enable 'Plack::Middleware::Forward',
          allow => +{
              Request => +{
                  'User-Agent' => qr{^(?:DoCoMo|UP\.Browser|KDDI|SoftBank|J-PHONE|Vodafone)},
              },
              Response => [
                  302,
                  ['Location' => qr{^http://fooapp\.mydomain\.com/}],
                  ['Forward']
              ],
          };

      sub {
          my $env = shift;

          return [
              302,
              ['Location' => 'http://fooapp.mydomain.com/forward/to'],
              []
          ];
      };
  };

=head1 DESCRIPTION

Plack::Middleware::Forward is

=head1 AUTHOR

Kenta Sato E<lt>karupa@cpan.orgE<gt>

=head1 SEE ALSO

L<Plack::Middleware::Requberse>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
