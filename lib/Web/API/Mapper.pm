package Web::API::Mapper;
use warnings;
use strict;
use Any::Moose;
use Web::API::Mapper::RuleSet;

our $VERSION = '0.01';

# path base
has base => ( is => 'rw' , isa => 'Str' , default => qq{} );

has route => ( is => 'rw' );

# post dispatcher
has post => ( is => 'rw' );

# get dispatcher
has get => ( is => 'rw' );

has fallback => ( is => 'rw' , isa => 'CodeRef' , default => sub {  sub {  } } );

sub BUILD {
    my ( $self ) = @_;
    my $route = $self->route;
    my $postdisp = Web::API::Mapper::RuleSet->new( $self->base ,  $route->{post} );
    my $getdisp  = Web::API::Mapper::RuleSet->new( $self->base , $route->{get} );
    $self->post( $postdisp );
    $self->get( $getdisp );
}

sub route {
    my ($self,$route) = @_;

}

sub dispatch {
    my ( $self, $path, $args ) = @_;

    my $base = $self->base;
    $path =~ s{^/$base/}{} if $base;


    my $ret;
    $ret = $self->post->dispatch( $path , $args );
    return $ret if $ret;

    $ret = $self->get->dispatch( $path , $args );
    return $ret if $ret;

    return $self->fallback->( $args ) if $self->fallback;
    return;
}

1;
__END__

=head1 NAME

Web::API::Mapper - Web API Mapping Class

=head1 SYNOPSIS

    my $m = Web::API::Mapper->new( base => 'foo', route => {
                    post => [
                        '/bar/(\d+)' => sub { my $args = shift;  return $1;  }
                    ]
                    get =>  [ 
                        ....
                    ]
                });
    my $ret = $m->post->dispatch( '/foo/bar' , { ... args ... } );
    my $ret = $m->get->dispatch(  '/foo/bar' );
    my $ret = $m->dispatch( '/foo/bar' , { args ... } );

=head1 TODO

Provide classes for mounting service to frameworks.

=head1 DESCRIPTION

L<Web::API::Mapper> is an API (Application Programming Interface) convergence class for mapping
API to web frameworks.

by using L<Web::API::Mapper> you can simply mount these api service like
Twitter, and dispatch paths to these services.

L<Web::API::Mapper> is using L<Path::Dispatcher> for dispatching.

=head1 ROUTE SPEC

API Provider can provide a route hash reference for dispatching rules.

=for 4

=item post => [ '/path/to/(\d+)' => sub {  } , ... ]

=item get => [  '/path/to/(\d+)' => sub {  } , ... ]

=item fallback => sub {    }

=back

=head1 EXAMPLE

    package Twitter::API;

    sub route { {
        post => [
            'timeline/add/' => sub { my $args = shift;  .... },
        ],
        get => [
            'timeline/get/(\w+)' => sub {  my $args = shift;  .... return $1 },
        ],
    } }

    package main;

    my $m = Web::API::Mapper->new( base => 'twitter', route => Twitter::API->route );
    # $m->route( Plurk::API->route );
    $m->dispatch(  '/path/to' , { args ... } );

    1;


=head1 AUTHOR

Cornelius E< cornelius.howl at gmail.com >

=cut

