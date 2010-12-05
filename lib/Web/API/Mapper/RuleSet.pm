package Web::API::Mapper::RuleSet;
use warnings;
use strict;
use Any::Moose;
use Path::Dispatcher;


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


1;
