package Web::API::Mapper;
use warnings;
use strict;
use Any::Moose;
use Web::API::Mapper::RuleSet;

our $VERSION = '0.021';

has route => ( is => 'rw' );

# post dispatcher
has post => ( is => 'rw' , default => sub { return Web::API::Mapper::RuleSet->new; } );

# get dispatcher
has get => ( is => 'rw' , default => sub { return Web::API::Mapper::RuleSet->new; } );

has fallback => ( is => 'rw' , isa => 'CodeRef' , default => sub {  sub {  } } );

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    if ( ! ref $_[0] && ref $_[1] eq 'HASH') {
        my $base = shift @_;
        my $route = shift @_;
        $class->$orig( base => $base , route => $route , @_);
    } else {
        $class->$orig(@_);
    }
};


sub BUILD {
    my ( $self , $args ) = @_;
    my $route = $args->{route};
    my $base  = $args->{base};
    $self->post( Web::API::Mapper::RuleSet->new( $base ,  $route->{post} ) ) if $route->{post};
    $self->get(Web::API::Mapper::RuleSet->new( $base , $route->{get} )) if $route->{get};
}

sub mount {
    my ($self,$base,$route) = @_;
    $self->post->mount( $base => $route->{post} ) if $route->{post};
    $self->get->mount( $base => $route->{get} ) if $route->{get};
    return $self;
}

sub dispatch {
    my ( $self, $path, $args ) = @_;

#     my $base = $self->base;
#     $path =~ s{^/$base/}{} if $base;

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

Web::API::Mapper - L<Web::API::Mapper> is an API (Application Programming Interface) convergence class for mapping/dispatching 
API to web frameworks.

=head1 SYNOPSIS

    my $m = Web::API::Mapper->new(  '/foo' => {
                    post => [
                        '/bar/(\d+)' => sub { my $args = shift;  return $1;  }
                    ]
                    get =>  [ 
                        ....
                    ]
                })->mount( ... );
    my $ret = $m->post->dispatch( '/foo/bar' , { ... args ... } );
    my $ret = $m->get->dispatch(  '/foo/bar' );
    my $ret = $m->dispatch( '/foo/bar' , { args ... } );

    $m->post->mount( '/foo' , [ '/subpath/to' => sub {  ....  } ]);
    $m->mount( '/fb' => {  post => [  ... ] , get => [  ... ] }  )->mount( ... );


=head1 DESCRIPTION

L<Web::API::Mapper> is an API (Application Programming Interface) convergence class for mapping/dispatching 
API to web frameworks.

This module is for reducing class coupling of web services on web frameworks.

Web frameworks are always changing, and one day you will need to migrate your code to 
the latest web framework. If your code heavily depends on your framework,
it's pretty hard to migrate and it takes time.

by using L<Web::API::Mapper> you can simply seperate service application and framework.
you can simply mount these api service like Twitter ... etc, and dispatch paths
to these services.

L<Web::API::Mapper> is using L<Path::Dispatcher> for dispatching.

=head1 TODO

=for 4 

=item Provide service classes for mounting.

=item Provide mounter for web frameworks.

=back

=head1 ROUTE SPEC

API Provider can provide a route hash reference for dispatching rules.

=for 4

=item post => [ '/path/to/(\d+)' => sub {  } , ... ]

=item get => [  '/path/to/(\d+)' => sub {  } , ... ]

=item fallback => sub {    }

=back

=head1 ACCESSORS

=head2 route

=head2 post

is a L<Web::API::Mapper::RuleSet> object.

=head2 get

is a L<Web::API::Mapper::RuleSet> object.

=head2 fallback

is a CodeRef, fallback handler.

=head1 FUNCTIONS

=head2 mount

=head2 dispatch

=head1 EXAMPLE

    package Twitter::API;

    sub route { {
        post => [
            '/timeline/add/' => sub { my $args = shift;  .... },
            '/timeline/remove/' => sub { ... },
        ],
        get => [
            '/timeline/get/(\w+)' => sub {  my $args = shift;  .... return $1 },
        ],
    } }

    package main;

    # This will add rule path to /twitter/timeline/add/  ... etc
    my $m = Web::API::Mapper->new( '/twitter' => Twitter::API->route );
    $m->mount(  '/basepath' , {  post => [  ... ] } );
    $m->post->mount( '/basepath' , [  ...  ]  );
    $m->dispatch( '/path/to' , { args ... } );

    1;

=head1 AUTHOR

Cornelius E< cornelius.howl at gmail.com >

=head1 LICENSE

Perl

=cut
