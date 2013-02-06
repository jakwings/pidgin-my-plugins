#!/usr/local/bin perl

require v5.6.12;    # not sure...
require Purple;     # I'm using Pidgin 2.10.6 (libpurple 2.10.6)
#require Pidgin;     # TODO: preference panel

use encoding "utf-8";


#####
### Preferences
#
our @NICK_NAMES = ("John", "J.M");


#####
### Plugin Initializations
#
our %PLUGIN_INFO = (
    perl_api_version => 2,
    name => "Chatroom At-Me Notifier",
    version => "1.0.0",
    summary => "Notify if someone @ you!",
    description => "Notify and show what others said.",
    author => "Jak Wings <jakwings\@gmail.com>",
    url => "http://likelikeslike.com",
    load => "plugin_load",
    unload => "plugin_unload"
);

sub plugin_init
{
    return %PLUGIN_INFO;
}

sub plugin_load
{
    my $plugin = shift;

    Purple::Debug::info($PLUGIN_INFO{name}, "loaded\n");

    ## Conversations Hook
    $conv = Purple::Conversations::get_handle();
    Purple::Signal::connect($conv, "received-chat-msg", $plugin,
                            \&conv_received_msg, "CHAT");
}

sub plugin_unload
{
    my $plugin = shift;

    Purple::Debug::info($PLUGIN_INFO{name}, "unloaded\n");
}


#####
### Conversations
#
sub conv_received_msg
{
	my ($account, $sender, $message, $conv, $flags, $data) = @_;

	Purple::Debug::misc("REC[$data]", $account->get_username() . " <-- $sender, $message, $flags)\n");

    if ( $data eq "CHAT" ) {
        foreach $name (@NICK_NAMES) {
            $message =~ s/<[^>]+>//g;
            if ( $message =~ /${name}/i ) {
                notify($account, $conv->get_title(), $sender, $message);
                break;
            }
        }
    }
}

sub notify
{
    my ($account, $chatroom, $sender, $message) = @_;
    my $conv = Purple::Conversation->new(1, $account, "\@ you!");

    $conv->get_im_data()->write("${chatroom} - ${sender}", $message, 0x2 | 0x1000, time);
}
