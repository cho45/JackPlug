#!/usr/bin/env plackup -s AnyEvent
# vim:set ft=perl:
use strict;
use warnings;
use lib 'lib/perl/lib/perl5', 'lib/perl/lib/perl5/x86_64-linux-thread-multi';

use Plack::Request;
use AnyEvent;
use JSON::XS;

my $template = <<'EOS';
<!DOCTYPE html>
<title>tail</title>
<script type="text/javascript" src="http://code.jquery.com/jquery-1.4.2.min.js"></script>
<script type="text/javascript" src="/js/script.js"></script>
<style type="text/css">
html,
body {
	padding: 0;
	margin: 0;
	width: 100%;
	height : 100%;
}

iframe {
	border: none;
	width: 100%;
	height : 100%;
}
</style>
<iframe id="content"></iframe>
EOS

my $i   = 0;
my $mid = 0;
my $sessions = {};
my $results  = {};

my $app = sub {
	my $env = shift;
	$env->{'psgi.streaming'} or die;
	sub {
		my $callback = shift;

		my $req = Plack::Request->new($env);
		my $res = $req->new_response(200);
		eval {
			+{
				'/' => sub {
					$res->content_type('text/html');
					$res->content($template);
					$callback->($res->finalize);
				},
				'/api/read' => sub {
					my $sid = $req->cookies->{sid} || $i++;
					my $session = $sessions->{$sid} || +{
						sid      => $sid,
						messages => [],
						callback => undef,
						expire   => 0,
						ua       => $req->header('User-Agent'),
					};
					$session->{expire} = time() + 60 * 60;
					$sessions->{$sid} = $session;
					$res->cookies->{sid} = $sid;

					if (@{ $session->{messages} }) {
						$res->content(encode_json +{
							sid => $sid,
							messages => $session->{messages},
						});
						$session->{messages} = [];
						$callback->($res->finalize);
					} else {
						$session->{callback} = sub {
							my $message = shift;
							delete $session->{callback};
							$res->content(encode_json +{
								sid => $sid,
								messages => [ $message ],
							});
							$res->content_type('application/json');
							$callback->($res->finalize);
						};
					}
				},
				'/api/run' => sub {
					my $message = {
						id   => $mid++,
						host => $req->address,
						body => $req->param('m'),
					};
					for my $sid (keys %$sessions) {
						my $session = $sessions->{$sid};
						if ($session->{expire} < time()) {
							delete $sessions->{$sid};
							next;
						}

						if ($session->{callback}) {
							$session->{callback}->($message);
						} else {
							push @{ $session->{messages} }, $message;
						}
						$results->{ $message->{id} }->{count}++;
					}

					$results->{ $message->{id} }->{callback} = sub {
						my $results = shift;
						$res->content_type('application/json');
						$res->content(encode_json +{ status => 'ok', results => $results });
						$callback->($res->finalize);
					};
				},
				'/api/done' => sub {
					my $id = $req->param('id');
					my $message = {
						host => $req->address,
						body => $req->param('m'),
					};
					my $result = $results->{$id};
					$result->{results}->{ $req->header('User-Agent') } = $message;
					$result->{count}--;

					if ($result->{count} == 0) {
						$result->{callback}->($result->{results});
					}

					$res->content_type('application/json');
					$res->content(encode_json +{ status => 'ok' });
					$callback->($res->finalize);
				},
			}->{ $req->path }->();
		};

		if ($@) {
			$res->code(200);
			$res->content($@);
			$callback->($res->finalize);
		}
	};
};

use Plack::Builder;

builder {
	enable "Plack::Middleware::Static",
		path => qr{^/(images|js|css)/}, root => 'static';

	enable "Plack::Middleware::ReverseProxy";
	$app;
};

