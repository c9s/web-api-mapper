#!/usr/bin/env perl
use Test::More tests => 10;
use lib 'lib';
use warnings;
use strict;

BEGIN {
    use_ok('Web::API::Mapper');
}

my $m = Web::API::Mapper->new( base => 'foo', route =>  {
    post => [
        'timeline/add/' => sub {
            my $args = shift;
            ok( $args->{name} , 'got name' );
            return "ok";
        },
    ],
    get => [
        'timeline/get/(\w+)' => sub { 
            my $args = shift;
            is( $1 , 'c9s' );
            ok( $args->{name} );
            is( $args->{name} , 'amy' );
            return { timeline => [ 1 .. 10 ] };
        },
    ],
}  );
ok( $m , 'obj' );
my $ret = $m->post->dispatch( '/foo/timeline/add/', { name => 'john' } );
ok( $ret );
is( $ret , 'ok' );

$ret = $m->get->dispatch(  '/foo/timeline/get/c9s' , { name => 'amy' } );
ok( $ret );
is( ref($ret) , 'HASH' );
