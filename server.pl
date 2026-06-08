#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket::INET;
use POSIX qw();

my $port = $ARGV[0] || 3000;
my $root = $ARGV[1] || '.';

my %mime = (
    html => 'text/html; charset=utf-8',
    css  => 'text/css',
    js   => 'application/javascript',
    png  => 'image/png',
    jpg  => 'image/jpeg',
    svg  => 'image/svg+xml',
    ico  => 'image/x-icon',
    json => 'application/json',
);

my $server = IO::Socket::INET->new(
    LocalPort => $port,
    Proto     => 'tcp',
    Listen    => 10,
    Reuse     => 1,
) or die "Cannot start server: $!";

print "Serving $root on http://localhost:$port\n";
$| = 1;

while (my $client = $server->accept()) {
    my $request = '';
    while (my $line = <$client>) {
        $request .= $line;
        last if $line eq "\r\n";
    }

    my ($method, $path) = $request =~ /^(\w+)\s+(\S+)/;
    $path = '/' unless defined $path;
    $path =~ s/\?.*//;
    $path = '/index.html' if $path eq '/';
    $path =~ s|/||;

    my $file = "$root/$path";
    my ($ext) = $file =~ /\.(\w+)$/;
    my $type = $mime{lc($ext || '')} || 'application/octet-stream';

    if (-f $file) {
        open my $fh, '<:raw', $file or do {
            print $client "HTTP/1.1 500 Error\r\n\r\n";
            close $client; next;
        };
        local $/; my $body = <$fh>; close $fh;
        my $len = length($body);
        print $client "HTTP/1.1 200 OK\r\nContent-Type: $type\r\nContent-Length: $len\r\nAccess-Control-Allow-Origin: *\r\n\r\n$body";
    } else {
        print $client "HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\n\r\nNot Found: $path";
    }
    close $client;
}
