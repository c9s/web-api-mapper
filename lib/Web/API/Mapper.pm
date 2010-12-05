package Web::API::Mapper::RuleSet;
use warnings;
use strict;
use Any::Moose;
use Path::Dispatcher;

our $VERSION = 0.01;

has base => ( is => 'rw' );

has disp => ( 
    is => 'rw' , 
    default => sub { 
        return Path::Dispatcher->new;
    } );

has rules => ( is => 'rw', isa => 'ArrayRef' );

has fallback => ( is => 'rw' , isa => 'CodeRef' , default => sub {  sub {  } } );

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    if ( ! ref $_[0] && ref $_[1] eq 'ARRAY') {
        my $base = shift @_;
        my $handlers = shift @_;
        my @rules;
        while (my($path, $code) = splice @$handlers, 0, 2) {
            $path = qr@^/$@    if $path eq '/';
            $path = qr/^$path/ unless ref $path eq 'RegExp';
            push @rules, { path => $path, code => $code };
        }
        $class->$orig( base => $base , rules => \@rules, @_);
    } else {
        $class->$orig(@_);
    }
};

sub BUILD {
    my $self = shift;
    $self->{_hits} = 0;
    $self->load();
}

sub route {
    my ($self,$rules) = @_;
    die('Unimplemented');
    # XXX:
}

sub load {
    my $self = shift;
    my $rules = $self->rules;
    my $disp = $self->disp;
    for my $rule ( @$rules ) {
        $disp->add_rule(
            Path::Dispatcher::Rule::Regex->new( regex => $rule->{path}, block => $rule->{code},)
        );
    }
    return $self;
}

sub dispatch {
    my ($self,$path,$args) = @_;
    # $self->{_hits}++;
    my $base = $self->base;
    $path =~ s{^/$base/}{} if $base;
    my $dispatch = $self->disp->dispatch( $path );
    return $dispatch->run( $args ) if $dispatch->has_matches;
    return $self->fallback->( $args ) if $self->fallback;
    return;
}


package Web::API::Mapper;
use warnings;
use strict;
use Any::Moose;

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
        base => 'twitter',
        post => [
            'timeline/add/' => sub { my $args = shift;  .... },
        ],
        get => [
            'timeline/get/(\w+)' => sub {  my $args = shift;  .... return $1 },
        ],
    } }

    package main;

    my $m = Web::API::Mapper->new( route => Twitter::API->route );
    $m->route( Plurk::API->route );

    1;


=head1 AUTHOR

Cornelius E< cornelius.howl at gmail.com >

=cut

