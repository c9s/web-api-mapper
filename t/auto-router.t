#!/usr/bin/env perl
package Test::API;

sub new { bless {} , shift; }

sub foo_find_all {  }

sub foo_find_id {  }

sub foo_get_id {
    my ($self,$args) = @_;
    return {  
        self => $self,
        args => $args,
    };
}

sub foo_set_id {

}

package main;
use Test::More tests => 6;
use Web::API::Mapper;

my $api = Test::API->new;

{
    my $routes = Web::API::Mapper->auto_route( $api , { prefix => 'foo' } );
    ok( $routes->{get} );
    ok( $routes->{post} );
    ok( $routes->{any} );
    my $m = Web::API::Mapper->new( "/foo" => $routes );
    ok( $m );
    my $ret = $m->dispatch( '/foo/get/id' , { data => 'John' } );
    is_deeply( $ret->{args} , { data => 'John' } );
    is( ref($ret->{self}) , 'Test::API' );
}
{
    my $routes = Web::API::Mapper->auto_route( $api , { 
        prefix => 'foo',
        map => sub { 

            } } );
}



1;
