#!/usr/bin/perl -w
# $Id$
use strict;
use warnings;

use XML::Twig;

my $output = '';
my $rule   = '';

my $twig       = XML::Twig->new()->parsefile( $ARGV[0] );
my $interfaces = $twig->root->first_child('interfaces');
my $server     = uc $twig->root->first_child('system')->field('hostname');

if ( defined $ARGV[1] and $ARGV[1] ne '' and $ARGV[1] eq "--nat" ) {
	$rule = 'nat';
}
else {
	$rule = 'fw';
}

if ( defined $ARGV[2] and $ARGV[2] ne '' and $ARGV[2] eq "--tab" ) {
	$output = 'tab';
}
else {
	$output = 'txt';
}

my $inet        = '';
my $inet_name   = '';
my $dst_uri     = '';
my $dst_port    = '';
my $dst_net     = '';
my $dst_adr     = '';
my $target_uri  = '';
my $target_port = '';
my $proto       = '';
my $type        = '';
my $src         = '';
my $src_adr     = '';
my $src_net     = '';
my $port        = '';
my $not_dest    = '';
my $isNot       = '';

sub InterfaceName {
	my ( $interfaces, $inet ) = @_;
	if ( $interfaces->first_child($inet) ) {
		return $interfaces->first_child($inet)->field('descr');
	}
	else {
		return $inet;
	}
}

if ( $output eq "tab" ) {
	print("SERVEUR;INTERFACE;SOURCE;DESTINATION;TYPE;PORTS;CODE;\n");
}
if ( $rule eq "nat" ) {
	foreach my $record ( $twig->root->children('nat') ) {
		foreach my $data ( $record->children('rule') ) {
			$inet = $data->first_child_text('interface');
			if ( $inet =~ "," ) {
				next;
			}
			$inet_name = InterfaceName( $interfaces, $inet );
			$type = "nat";

			foreach my $dest ( $data->children('destination') ) {
				$dst_uri  = $dest->first_child_text('address');
				$dst_port = $dest->first_child_text('port');
			}

			$target_uri  = $data->first_child_text('target');
			$target_port = $data->first_child_text('local-port');
			$proto       = $data->first_child_text('protocol');
			if ( $target_port eq '' ) {
				$target_port = "*";
			}
			if ( $dst_uri eq '' ) {
				$dst_uri = "*";
			}
			if ( $dst_port eq '' ) {
				$dst_port = "*";
			}
			if ( $proto eq '' ) {
				$proto = "*";
			}
			if ( $dst_port eq $target_port ) {
				$port = $dst_port;
			}
			else {
				$port = $dst_port . "->" . $target_port;
			}
			if ( $output eq "txt" ) {
				print( "[", $data->first_child_text('descr'), "] " );
				print( $dst_uri, ' -> ', $target_uri, " [", $type,
					" ", $proto, ':', $port, "]\n"
				);
			}
			elsif ( $output eq "tab" ) {
				print( $server,                          ";" );
				print( $inet_name,                       ";" );
				print( $dst_uri,                         ";" );
				print( $target_uri,                      ";" );
				print( $type,                            ";" );
				print( $proto,                           ":", $port, ";" );
				print( $data->first_child_text('descr'), ";\n" );
			}
		}
	}
}

if ( $rule eq "fw" ) {
	foreach my $record ( $twig->root->children('filter') ) {
		foreach my $data ( $record->children('rule') ) {
			$inet = $data->first_child_text('interface');
			if ( $inet =~ "," || $inet eq '' ) {
				next;
			}
			$inet_name = InterfaceName( $interfaces, $inet );

			$type = $data->first_child_text('type');

			foreach my $source ( $data->children('source') ) {
				$src_adr = $source->first_child_text('address');
				$src_net = $source->first_child_text('network');
			}

			foreach my $dest ( $data->children('destination') ) {
				$dst_net  = $dest->first_child_text('network');
				$dst_adr  = $dest->first_child_text('address');
				$dst_port = $dest->first_child_text('port');
                                $not_dest = $dest->first_child('not');

				if ( defined $not_dest  ) {
					$isNot = 'NON_';
				} else {
					$isNot = '';
				}

				if ( $dst_net ne '' ) {
					$dst_uri = $isNot.
					  "Network_" . InterfaceName( $interfaces, $dst_net );
				}
				elsif ($dst_adr) {
					$dst_uri = $isNot.$dst_adr;
				}
				else {
					$dst_uri = $isNot."Network_" . InterfaceName( $interfaces, $inet );
				}
				$proto = $data->first_child_text('protocol');
			}

			if ( $type eq '' ) {
				$type = "nat";
			}
			if ( $src_adr eq '' && $src_net eq '' ) {
				$src = "any";
			}
			elsif ( !$src_adr eq '' ) {
				$src = $src_adr;
			}
			elsif ( !$src_net eq '' ) {
				$src = "Network_" . InterfaceName( $interfaces, $src_net );
			}
			if ( $dst_uri eq '' ) {
				$dst_uri = "Network_" . $inet_name . "_any";
			}
			if ( $dst_port eq '' ) {
				$dst_port = "*";
			}
			if ( $proto eq '' ) {
				$proto = "*";
			}
			if ( $output eq "txt" ) {
				print( "[", $data->first_child_text('descr'), "] " );
				print( $src, ' -> ', $dst_uri, " [", $type,
					" ", $proto, ':', $dst_port, "]\n"
				);
			}
			elsif ( $output eq "tab" ) {
				print( $server,                          ";" );
				print( $inet_name,                       ";" );
				print( $src,                             ";" );
				print( $dst_uri,                         ";" );
				print( $type,                            ";" );
				print( $proto,                           ":", $dst_port, ";" );
				print( $data->first_child_text('descr'), ";\n" );
			}
		}
	}
}
